import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audivance/core/storage/audit_storage_paths.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/backup/backup_package_io.dart';
import 'package:audivance/features/backup/backup_restore_coordinator.dart';
import 'package:audivance/features/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory sourceDir;
  late Directory restoreDir;
  late BackupService service;

  setUp(() async {
    sourceDir = await Directory.systemTemp.createTemp('audivance-backup-src-');
    restoreDir = await Directory.systemTemp.createTemp(
      'audivance-backup-restore-',
    );
    await File(_path(sourceDir, 'audivance.sqlite')).writeAsString('db-bytes');
    await File(_path(sourceDir, 'audivance.sqlite-wal')).writeAsString('wal');
    final attachment = File(
      _path(sourceDir, 'attachments/events/event-1/resolution.pdf'),
    );
    await attachment.parent.create(recursive: true);
    await attachment.writeAsString('attachment-bytes');
    service = BackupService(
      storagePaths: AuditStoragePaths(
        supportDirectoryProvider: () async => sourceDir,
      ),
      now: () => DateTime(2026, 8, 18, 10),
    );
  });

  tearDown(() async {
    if (await sourceDir.exists()) {
      await sourceDir.delete(recursive: true);
    }
    if (await restoreDir.exists()) {
      await restoreDir.delete(recursive: true);
    }
  });

  test(
    'builds a backup ZIP with database, sidecars, attachments, and manifest',
    () async {
      final backup = await service.buildBackup();
      final validation = await service.validateBackup(backup.bytes);
      final archive = ZipDecoder().decodeBytes(backup.bytes);
      final paths = archive.files.map((file) => file.name).toSet();

      expect(backup.fileName, 'Audivance-Backup-2026-08-18.zip');
      expect(paths, contains('backup_manifest.json'));
      expect(paths, contains('database/audivance.sqlite'));
      expect(paths, contains('database/audivance.sqlite-wal'));
      expect(paths, contains('attachments/events/event-1/resolution.pdf'));
      expect(validation.isValid, isTrue);
      expect(
        validation.manifest?['schemaVersion'],
        AuditDatabase.currentSchemaVersion,
      );
    },
  );

  test('rejects unreadable or incomplete backup packages', () async {
    final unreadable = await service.validateBackup(
      Uint8List.fromList('not-a-zip'.codeUnits),
    );
    expect(unreadable.isInvalid, isTrue);
    expect(unreadable.summary, contains('not a readable ZIP archive'));

    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          'database/audivance.sqlite',
          Uint8List.fromList('db'.codeUnits),
        ),
      );
    final missingManifest = await service.validateBackup(
      Uint8List.fromList(ZipEncoder().encodeBytes(archive)),
    );
    expect(missingManifest.isInvalid, isTrue);
    expect(missingManifest.summary, contains('manifest is missing'));
  });

  test('rejects checksum mismatch without mutating active storage', () async {
    await File(_path(restoreDir, 'audivance.sqlite'))
        .writeAsString('active-db');
    final activeAttachment = File(
      _path(restoreDir, 'attachments/events/event-1/resolution.pdf'),
    );
    await activeAttachment.parent.create(recursive: true);
    await activeAttachment.writeAsString('active-attachment');

    final backup = await service.buildBackup();
    final archive = ZipDecoder().decodeBytes(backup.bytes);
    final corruptedArchive = Archive();
    for (final file in archive.files) {
      if (file.name == 'attachments/events/event-1/resolution.pdf') {
        corruptedArchive.addFile(
          ArchiveFile.bytes(
            file.name,
            Uint8List.fromList('corrupted'.codeUnits),
          ),
        );
      } else {
        corruptedArchive.addFile(
          ArchiveFile.bytes(
            file.name,
            Uint8List.fromList(file.content as List<int>),
          ),
        );
      }
    }
    final corruptedBytes = Uint8List.fromList(
      ZipEncoder().encodeBytes(corruptedArchive),
    );
    final restoreService = BackupService(
      storagePaths: AuditStoragePaths(
        supportDirectoryProvider: () async => restoreDir,
      ),
    );

    final result = await restoreService.restoreBackupDetailed(corruptedBytes);

    expect(result.status, RestoreExecutionStatus.invalidBackup);
    expect(result.message, contains('checksum mismatch'));
    expect(
      await File(_path(restoreDir, 'audivance.sqlite')).readAsString(),
      'active-db',
    );
    expect(await activeAttachment.readAsString(), 'active-attachment');
  });

  test('rejects unsafe manifest paths', () async {
    final backupBytes = _backupBytesWithManifestEntry(
      path: 'attachments/../escape.txt',
      sourceType: 'attachment',
      bytes: Uint8List.fromList('escape'.codeUnits),
    );

    final result = await service.validateBackup(backupBytes);

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('path is not allowed'));
  });

  test('restores validated backup contents into storage paths', () async {
    final backup = await service.buildBackup();
    final restoreService = BackupService(
      storagePaths: AuditStoragePaths(
        supportDirectoryProvider: () async => restoreDir,
      ),
    );

    final result = await restoreService.restoreBackup(backup.bytes);

    expect(result.isValid, isTrue);
    expect(
      await File(_path(restoreDir, 'audivance.sqlite')).readAsString(),
      'db-bytes',
    );
    expect(
      await File(_path(restoreDir, 'attachments/events/event-1/resolution.pdf'))
          .readAsString(),
      'attachment-bytes',
    );
    expect(
      await Directory(_path(restoreDir, '.restore-staging')).exists(),
      isFalse,
    );
  });

  test(
    'coordinator closes active workspace and reopens after restore',
    () async {
      final backup = await service.buildBackup();
      final restoreService = BackupService(
        storagePaths: AuditStoragePaths(
          supportDirectoryProvider: () async => restoreDir,
        ),
      );
      final calls = <String>[];
      final coordinator = BackupRestoreCoordinator(
        service: restoreService,
        closeActiveWorkspace: () async => calls.add('close'),
        reopenWorkspace: () async => calls.add('reopen'),
      );

      final result = await coordinator.restoreBackup(
        PickedBackupPackage(fileName: backup.fileName, bytes: backup.bytes),
      );

      expect(result.isSuccess, isTrue);
      expect(calls, ['close', 'reopen']);
      expect(
        await File(_path(restoreDir, 'audivance.sqlite')).readAsString(),
        'db-bytes',
      );
    },
  );
}

Uint8List _backupBytesWithManifestEntry({
  required String path,
  required String sourceType,
  required Uint8List bytes,
}) {
  final manifest = {
    'type': 'audivance-backup',
    'appVersion': '1.0.0+1',
    'schemaVersion': 3,
    'generatedAt': DateTime(2026, 8, 18).toIso8601String(),
    'databaseName': 'audivance.sqlite',
    'databaseEncryption': 'encrypted-same-device-key',
    'restoreScope': 'same-device-secure-credential',
    'entries': [
      {
        'path': 'database/audivance.sqlite',
        'byteLength': 2,
        'checksum':
            '5f2bd7a84c3b5edb7b71b4e7c5a5b4b476104caf91cd8845c1ea7647607b0a34',
        'sourceType': 'database',
      },
      {
        'path': path,
        'byteLength': bytes.length,
        'checksum':
            'placeholder-checksum-intentionally-not-reached-for-bad-path',
        'sourceType': sourceType,
      },
    ],
  };
  final archive = Archive()
    ..addFile(
      ArchiveFile.bytes(
        'backup_manifest.json',
        Uint8List.fromList(
          const JsonEncoder.withIndent('  ').convert(manifest).codeUnits,
        ),
      ),
    )
    ..addFile(
      ArchiveFile.bytes(
        'database/audivance.sqlite',
        Uint8List.fromList('db'.codeUnits),
      ),
    )
    ..addFile(ArchiveFile.bytes(path, bytes));
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

String _path(Directory directory, String relative) {
  return '${directory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
}
