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
    for (final entry in archive.files.where((file) => file.isFile)) {
      files[entry.name] = Uint8List.fromList(entry.content as List<int>);
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

  Future<ValidationResult> restoreBackup(Uint8List bytes) async {
    final validation = await validateBackup(bytes);
    if (validation.isInvalid) {
      return ValidationResult.invalid(validation.messages);
    }
    final archive = _decodeArchive(bytes)!;
    final files = <String, Uint8List>{};
    for (final entry in archive.files.where((file) => file.isFile)) {
      files[entry.name] = Uint8List.fromList(entry.content as List<int>);
    }

    final supportDirectory = await storagePaths.supportDirectory();
    await supportDirectory.create(recursive: true);
    final attachmentsDirectory = await storagePaths.attachmentsDirectory();
    if (await attachmentsDirectory.exists()) {
      await attachmentsDirectory.delete(recursive: true);
    }

    for (final entry in validation.entries) {
      if (entry.path == 'backup_manifest.json') {
        continue;
      }
      final bytes = files[entry.path];
      if (bytes == null) {
        continue;
      }
      final destination = await _destinationForRestore(entry.path);
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(bytes, flush: true);
    }
    return const ValidationResult.valid();
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
  try {
    return ZipDecoder().decodeBytes(bytes);
  } on Object {
    return null;
  }
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
