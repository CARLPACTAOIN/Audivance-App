import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audivance/core/storage/audit_storage_paths.dart';
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
      expect(validation.manifest?['schemaVersion'], 3);
    },
  );

  test('rejects unreadable or incomplete backup packages', () async {
    final unreadable = await service.validateBackup(
      Uint8List.fromList('not-a-zip'.codeUnits),
    );
    expect(unreadable.isInvalid, isTrue);
    expect(unreadable.summary, contains('manifest is missing'));

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
  });
}

String _path(Directory directory, String relative) {
  return '${directory.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';
}
