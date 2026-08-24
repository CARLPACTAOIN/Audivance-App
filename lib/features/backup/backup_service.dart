import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../../core/domain/validation_result.dart';
import '../../core/storage/audit_storage_paths.dart';
import '../audit/data/audit_database.dart';

class BackupService {
  const BackupService({
    required this.storagePaths,
    this.appVersion = '1.0.0+1',
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditStoragePaths storagePaths;
  final String appVersion;
  final DateTime Function() _now;

  Future<BackupPackage> buildBackup() async {
    final generatedAt = _now();
    final entries = await _collectBackupEntries();
    final entriesWithoutManifest = [...entries]
      ..sort((a, b) => a.path.compareTo(b.path));
    final manifest = _manifestFor(
      generatedAt: generatedAt,
      entries: entriesWithoutManifest,
    );
    final manifestBytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest)),
    );
    final packageEntries = [
      BackupArchiveEntry(
        path: 'backup_manifest.json',
        byteLength: manifestBytes.length,
        checksum: _sha256Hex(manifestBytes),
        sourceType: BackupArchiveEntrySource.manifest,
        bytes: manifestBytes,
      ),
      ...entriesWithoutManifest,
    ];
    final archive = Archive();
    for (final entry in packageEntries) {
      final file = ArchiveFile.bytes(entry.path, entry.bytes);
      file.creationTime = 0;
      file.lastModTime = 0;
      archive.addFile(file);
    }
    final encoded = ZipEncoder().encodeBytes(
      archive,
      modified: DateTime.utc(
        generatedAt.year,
        generatedAt.month,
        generatedAt.day,
      ),
    );
    final bytes = Uint8List.fromList(encoded);
    return BackupPackage(
      fileName: _backupFileName(generatedAt),
      bytes: bytes,
      generatedAt: generatedAt,
      checksum: _sha256Hex(bytes),
      manifest: manifest,
      entries: packageEntries,
    );
  }

  Future<BackupValidationResult> validateBackup(Uint8List bytes) async {
    final archive = _decodeArchive(bytes);
    if (archive == null) {
      return const BackupValidationResult.invalid([
        'Backup file is not a readable ZIP archive.',
      ]);
    }
    final files = <String, Uint8List>{};
    final duplicatePaths = <String>{};
    for (final entry in archive.files.where((file) => file.isFile)) {
      if (files.containsKey(entry.name)) {
        duplicatePaths.add(entry.name);
      }
      files[entry.name] = Uint8List.fromList(entry.content as List<int>);
    }
    if (duplicatePaths.isNotEmpty) {
      return BackupValidationResult.invalid([
        for (final path in duplicatePaths) 'Backup contains duplicate $path.',
      ]);
    }

    final manifestBytes = files['backup_manifest.json'];
    if (manifestBytes == null) {
      return const BackupValidationResult.invalid([
        'Backup manifest is missing.',
      ]);
    }
    final manifest = _decodeManifest(manifestBytes);
    if (manifest == null) {
      return const BackupValidationResult.invalid([
        'Backup manifest is malformed.',
      ]);
    }
    if (manifest['type'] != 'audivance-backup') {
      return const BackupValidationResult.invalid([
        'Backup manifest type is not audivance-backup.',
      ]);
    }
    if (!files.containsKey('database/audivance.sqlite')) {
      return const BackupValidationResult.invalid([
        'Backup is missing database/audivance.sqlite.',
      ]);
    }

    final messages = <String>[];
    final entries = _manifestEntries(manifest);
    if (entries.isEmpty) {
      messages.add('Backup manifest does not list package entries.');
    }
    for (final entry in entries) {
      final path = entry.path;
      if (path == 'backup_manifest.json') {
        continue;
      }
      if (!_isAllowedArchivePath(path)) {
        messages.add('Backup entry path is not allowed: $path.');
        continue;
      }
      if (!_isAllowedSourceType(entry.sourceType)) {
        messages.add('Backup entry source type is not allowed: $path.');
        continue;
      }
      if (!_sourceTypeMatchesPath(entry)) {
        messages.add('Backup entry source type does not match path: $path.');
        continue;
      }
      final fileBytes = files[path];
      if (fileBytes == null) {
        messages.add('Backup is missing $path.');
        continue;
      }
      if (fileBytes.length != entry.byteLength) {
        messages.add('Backup entry length mismatch: $path.');
      }
      if (_sha256Hex(fileBytes) != entry.checksum) {
        messages.add('Backup entry checksum mismatch: $path.');
      }
    }
    if (messages.isNotEmpty) {
      return BackupValidationResult.invalid(messages);
    }
    return BackupValidationResult.valid(manifest: manifest, entries: entries);
  }

  Future<RestoreExecutionResult> restoreBackupDetailed(Uint8List bytes) async {
    final validation = await validateBackup(bytes);
    if (validation.isInvalid) {
      return RestoreExecutionResult.invalidBackup(validation);
    }
    try {
      final archive = _decodeArchive(bytes)!;
      final files = <String, Uint8List>{};
      for (final entry in archive.files.where((file) => file.isFile)) {
        files[entry.name] = Uint8List.fromList(entry.content as List<int>);
      }
      final stagingDirectory = await _stageRestoreFiles(validation, files);
      try {
        final stagingValidation = await _verifyStagedRestore(
          validation,
          stagingDirectory,
        );
        if (stagingValidation.isInvalid) {
          return RestoreExecutionResult.restoreFailed(
            stagingValidation.messages.join('\n'),
            validation: validation,
          );
        }
        await _promoteStagedRestore(validation, stagingDirectory);
      } finally {
        if (await stagingDirectory.exists()) {
          await stagingDirectory.delete(recursive: true);
        }
      }
      return RestoreExecutionResult.success(validation);
    } on Object catch (error) {
      return RestoreExecutionResult.restoreFailed(
        'Backup could not be restored.\n$error',
        validation: validation,
      );
    }
  }

  Future<ValidationResult> restoreBackup(Uint8List bytes) async {
    final result = await restoreBackupDetailed(bytes);
    if (result.isSuccess) {
      return const ValidationResult.valid();
    }
    return ValidationResult.failure(result.message);
  }

  Future<List<BackupArchiveEntry>> _collectBackupEntries() async {
    final database = await storagePaths.databaseFile();
    if (!await database.exists()) {
      throw StateError('The local database file does not exist yet.');
    }
    final entries = <BackupArchiveEntry>[];
    final databaseFiles = await storagePaths.databaseFiles();
    for (final file in databaseFiles) {
      final suffix = file.path.substring(database.path.length);
      final path = 'database/${storagePaths.databaseName}$suffix';
      entries.add(
        await _entryFromFile(file, path, BackupArchiveEntrySource.database),
      );
    }

    final attachmentsDirectory = await storagePaths.attachmentsDirectory();
    if (await attachmentsDirectory.exists()) {
      final files = attachmentsDirectory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .toList();
      for (final file in files) {
        final relative = p.relative(file.path, from: attachmentsDirectory.path);
        final path = p.posix.joinAll(['attachments', ...p.split(relative)]);
        entries.add(
          await _entryFromFile(file, path, BackupArchiveEntrySource.attachment),
        );
      }
    }
    return entries;
  }

  Future<File> _destinationForRestore(String archivePath) async {
    if (archivePath == 'database/audivance.sqlite') {
      return storagePaths.databaseFile();
    }
    if (archivePath.startsWith('database/audivance.sqlite-')) {
      final database = await storagePaths.databaseFile();
      final suffix = archivePath.substring('database/audivance.sqlite'.length);
      return File('${database.path}$suffix');
    }
    if (archivePath.startsWith('attachments/')) {
      return storagePaths.resolveRelativeFile(archivePath);
    }
    throw ArgumentError.value(archivePath, 'archivePath', 'Unknown path.');
  }

  Future<Directory> _stageRestoreFiles(
    BackupValidationResult validation,
    Map<String, Uint8List> files,
  ) async {
    final supportDirectory = await storagePaths.supportDirectory();
    await supportDirectory.create(recursive: true);
    final stagingDirectory = Directory(
      p.join(supportDirectory.path, '.restore-staging'),
    );
    if (await stagingDirectory.exists()) {
      await stagingDirectory.delete(recursive: true);
    }
    await stagingDirectory.create(recursive: true);
    for (final entry in validation.entries) {
      if (entry.path == 'backup_manifest.json') {
        continue;
      }
      final bytes = files[entry.path];
      if (bytes == null) {
        continue;
      }
      final destination = _stagingDestination(stagingDirectory, entry.path);
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(bytes, flush: true);
    }
    return stagingDirectory;
  }

  Future<BackupValidationResult> _verifyStagedRestore(
    BackupValidationResult validation,
    Directory stagingDirectory,
  ) async {
    final messages = <String>[];
    for (final entry in validation.entries) {
      if (entry.path == 'backup_manifest.json') {
        continue;
      }
      final file = _stagingDestination(stagingDirectory, entry.path);
      if (!await file.exists()) {
        messages.add('Staged restore is missing ${entry.path}.');
        continue;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length != entry.byteLength) {
        messages.add('Staged restore length mismatch: ${entry.path}.');
      }
      if (_sha256Hex(bytes) != entry.checksum) {
        messages.add('Staged restore checksum mismatch: ${entry.path}.');
      }
    }
    if (messages.isNotEmpty) {
      return BackupValidationResult.invalid(messages);
    }
    return validation;
  }

  Future<void> _promoteStagedRestore(
    BackupValidationResult validation,
    Directory stagingDirectory,
  ) async {
    await _deleteActiveDatabaseFiles();
    final attachmentsDirectory = await storagePaths.attachmentsDirectory();
    if (await attachmentsDirectory.exists()) {
      await attachmentsDirectory.delete(recursive: true);
    }

    for (final entry in validation.entries) {
      if (entry.path == 'backup_manifest.json') {
        continue;
      }
      final source = _stagingDestination(stagingDirectory, entry.path);
      final destination = await _destinationForRestore(entry.path);
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(await source.readAsBytes(), flush: true);
    }
  }

  Future<void> _deleteActiveDatabaseFiles() async {
    final database = await storagePaths.databaseFile();
    final candidates = [
      database,
      File('${database.path}-wal'),
      File('${database.path}-shm'),
    ];
    for (final file in candidates) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Map<String, Object?> _manifestFor({
    required DateTime generatedAt,
    required List<BackupArchiveEntry> entries,
  }) {
    return {
      'type': 'audivance-backup',
      'appVersion': appVersion,
      'schemaVersion': AuditDatabase.currentSchemaVersion,
      'generatedAt': generatedAt.toIso8601String(),
      'databaseName': storagePaths.databaseName,
      'databaseEncryption': 'encrypted-same-device-key',
      'restoreScope': 'same-device-secure-credential',
      'entries': entries.map((entry) => entry.toManifestJson()).toList(),
    };
  }
}

class RestoreExecutionResult {
  const RestoreExecutionResult._({
    required this.status,
    required this.message,
    this.validation,
  });

  factory RestoreExecutionResult.success(BackupValidationResult validation) {
    return RestoreExecutionResult._(
      status: RestoreExecutionStatus.success,
      message:
          'Backup restored. ${validation.entries.length} entries were replaced.',
      validation: validation,
    );
  }

  factory RestoreExecutionResult.invalidBackup(
    BackupValidationResult validation,
  ) {
    return RestoreExecutionResult._(
      status: RestoreExecutionStatus.invalidBackup,
      message: validation.summary,
      validation: validation,
    );
  }

  const RestoreExecutionResult.restoreFailed(
    String message, {
    BackupValidationResult? validation,
  }) : this._(
         status: RestoreExecutionStatus.restoreFailed,
         message: message,
         validation: validation,
       );

  const RestoreExecutionResult.reopenFailed(String message)
    : this._(
        status: RestoreExecutionStatus.reopenFailed,
        message: message,
        validation: null,
      );

  final RestoreExecutionStatus status;
  final String message;
  final BackupValidationResult? validation;

  bool get isSuccess => status == RestoreExecutionStatus.success;
}

enum RestoreExecutionStatus {
  success,
  invalidBackup,
  restoreFailed,
  reopenFailed,
}

class BackupPackage {
  const BackupPackage({
    required this.fileName,
    required this.bytes,
    required this.generatedAt,
    required this.checksum,
    required this.manifest,
    required this.entries,
  });

  final String fileName;
  final Uint8List bytes;
  final DateTime generatedAt;
  final String checksum;
  final Map<String, Object?> manifest;
  final List<BackupArchiveEntry> entries;

  int get byteLength => bytes.length;
}

class BackupArchiveEntry {
  const BackupArchiveEntry({
    required this.path,
    required this.byteLength,
    required this.checksum,
    required this.sourceType,
    required this.bytes,
  });

  final String path;
  final int byteLength;
  final String checksum;
  final BackupArchiveEntrySource sourceType;
  final Uint8List bytes;

  Map<String, Object?> toManifestJson() {
    return {
      'path': path,
      'byteLength': byteLength,
      'checksum': checksum,
      'sourceType': sourceType.name,
    };
  }
}

enum BackupArchiveEntrySource { manifest, database, attachment }

class BackupManifestEntry {
  const BackupManifestEntry({
    required this.path,
    required this.byteLength,
    required this.checksum,
    required this.sourceType,
  });

  final String path;
  final int byteLength;
  final String checksum;
  final String sourceType;
}

class BackupValidationResult {
  const BackupValidationResult._({
    required this.isValid,
    required this.messages,
    required this.manifest,
    required this.entries,
  });

  const BackupValidationResult.invalid(List<String> messages)
    : this._(
        isValid: false,
        messages: messages,
        manifest: null,
        entries: const [],
      );

  const BackupValidationResult.valid({
    required Map<String, Object?> manifest,
    required List<BackupManifestEntry> entries,
  }) : this._(
         isValid: true,
         messages: const [],
         manifest: manifest,
         entries: entries,
       );

  final bool isValid;
  final List<String> messages;
  final Map<String, Object?>? manifest;
  final List<BackupManifestEntry> entries;

  bool get isInvalid => !isValid;
  String get summary => messages.join('\n');

  int get databaseEntryCount =>
      entries.where((entry) => entry.sourceType == 'database').length;

  int get attachmentEntryCount =>
      entries.where((entry) => entry.sourceType == 'attachment').length;

  int get totalByteLength =>
      entries.fold(0, (total, entry) => total + entry.byteLength);

  Object? get appVersion => manifest?['appVersion'];

  Object? get schemaVersion => manifest?['schemaVersion'];

  Object? get generatedAt => manifest?['generatedAt'];

  Object? get restoreScope => manifest?['restoreScope'];
}

Future<BackupArchiveEntry> _entryFromFile(
  File file,
  String path,
  BackupArchiveEntrySource sourceType,
) async {
  final bytes = await file.readAsBytes();
  return BackupArchiveEntry(
    path: path,
    byteLength: bytes.length,
    checksum: _sha256Hex(bytes),
    sourceType: sourceType,
    bytes: bytes,
  );
}

Archive? _decodeArchive(Uint8List bytes) {
  if (!_hasZipSignature(bytes)) {
    return null;
  }
  try {
    return ZipDecoder().decodeBytes(bytes);
  } on Object {
    return null;
  }
}

bool _hasZipSignature(Uint8List bytes) {
  if (bytes.length < 4) {
    return false;
  }
  if (bytes[0] != 0x50 || bytes[1] != 0x4b) {
    return false;
  }
  final signature = bytes[2] << 8 | bytes[3];
  return signature == 0x0304 || signature == 0x0506 || signature == 0x0708;
}

Map<String, Object?>? _decodeManifest(Uint8List bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
    return null;
  } on Object {
    return null;
  }
}

List<BackupManifestEntry> _manifestEntries(Map<String, Object?> manifest) {
  final rawEntries = manifest['entries'];
  if (rawEntries is! List) {
    return const [];
  }
  final entries = <BackupManifestEntry>[];
  for (final rawEntry in rawEntries) {
    if (rawEntry is! Map) {
      continue;
    }
    final entry = rawEntry.cast<String, Object?>();
    final path = entry['path'];
    final byteLength = entry['byteLength'];
    final checksum = entry['checksum'];
    final sourceType = entry['sourceType'];
    if (path is String &&
        byteLength is int &&
        checksum is String &&
        sourceType is String) {
      entries.add(
        BackupManifestEntry(
          path: path,
          byteLength: byteLength,
          checksum: checksum,
          sourceType: sourceType,
        ),
      );
    }
  }
  return entries;
}

String _backupFileName(DateTime generatedAt) {
  final date =
      '${generatedAt.year.toString().padLeft(4, '0')}-${generatedAt.month.toString().padLeft(2, '0')}-${generatedAt.day.toString().padLeft(2, '0')}';
  return 'Audivance-Backup-$date.zip';
}

String _sha256Hex(List<int> bytes) {
  return crypto.sha256.convert(bytes).toString();
}

bool _isAllowedArchivePath(String archivePath) {
  if (archivePath.contains(r'\') ||
      p.posix.isAbsolute(archivePath) ||
      p.posix.split(archivePath).contains('..')) {
    return false;
  }
  return archivePath == 'database/audivance.sqlite' ||
      archivePath.startsWith('database/audivance.sqlite-') ||
      archivePath.startsWith('attachments/');
}

bool _isAllowedSourceType(String sourceType) {
  return BackupArchiveEntrySource.values.any((type) => type.name == sourceType);
}

bool _sourceTypeMatchesPath(BackupManifestEntry entry) {
  if (entry.path.startsWith('database/')) {
    return entry.sourceType == BackupArchiveEntrySource.database.name;
  }
  if (entry.path.startsWith('attachments/')) {
    return entry.sourceType == BackupArchiveEntrySource.attachment.name;
  }
  return entry.path == 'backup_manifest.json' &&
      entry.sourceType == BackupArchiveEntrySource.manifest.name;
}

File _stagingDestination(Directory stagingDirectory, String archivePath) {
  if (!_isAllowedArchivePath(archivePath)) {
    throw ArgumentError.value(archivePath, 'archivePath', 'Unknown path.');
  }
  if (archivePath == 'database/audivance.sqlite') {
    return File(p.join(stagingDirectory.path, 'audivance.sqlite'));
  }
  if (archivePath.startsWith('database/audivance.sqlite-')) {
    final suffix = archivePath.substring('database/audivance.sqlite'.length);
    return File(p.join(stagingDirectory.path, 'audivance.sqlite$suffix'));
  }
  return File(
    p.joinAll([stagingDirectory.path, ...p.posix.split(archivePath)]),
  );
}
