import 'dart:typed_data';

import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/backup/backup_history_service.dart';
import 'package:audivance/features/backup/backup_package_io.dart';
import 'package:audivance/features/backup/backup_service.dart';
import 'package:audivance/features/export/export_history_service.dart';
import 'package:audivance/features/export/export_package_writer.dart';
import 'package:audivance/features/export/export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late _DeterministicIdGenerator idGenerator;
  late BackupHistoryService backupHistoryService;
  late ExportHistoryService exportHistoryService;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    idGenerator = _DeterministicIdGenerator();
    backupHistoryService = BackupHistoryService(
      repository: repository,
      idGenerator: idGenerator,
      now: () => DateTime(2026, 8, 18, 12),
    );
    exportHistoryService = ExportHistoryService(
      repository: repository,
      idGenerator: idGenerator,
      backupHistoryService: backupHistoryService,
      now: () => DateTime(2026, 8, 18, 12, 5),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('same-day successful backup suppresses reminder', () async {
    await backupHistoryService.recordSuccess(
      backup: _backupPackage(generatedAt: DateTime(2026, 8, 18, 9)),
      writeResult: _backupWriteResult(wasSaved: true),
    );

    expect(
      await exportHistoryService.hasSameDayBackup(DateTime(2026, 8, 18, 15)),
      isTrue,
    );
  });

  test('older backup still triggers reminder', () async {
    await backupHistoryService.recordSuccess(
      backup: _backupPackage(generatedAt: DateTime(2026, 8, 17, 23)),
      writeResult: _backupWriteResult(wasSaved: true),
    );

    expect(
      await exportHistoryService.hasSameDayBackup(DateTime(2026, 8, 18, 1)),
      isFalse,
    );
  });

  test('successful ZIP save records successful export history', () async {
    await exportHistoryService.recordResult(
      archive: _archivePackage(),
      writeResult: _exportWriteResult(wasSaved: true),
      status: ExportHistoryStatus.success,
      backupReminderStatus: BackupReminderStatus.satisfied,
      sameDayBackupFound: true,
      blockerCount: 0,
      warningCount: 1,
    );

    final history = await exportHistoryService.listHistory();

    expect(history.single.status, ExportHistoryStatus.success);
    expect(history.single.destinationUri, 'file:///export.zip');
    expect(history.single.backupReminderStatus, BackupReminderStatus.satisfied);
  });

  test('canceled ZIP save records canceled export history', () async {
    await exportHistoryService.recordResult(
      archive: _archivePackage(),
      writeResult: _exportWriteResult(wasSaved: false),
      status: ExportHistoryStatus.canceled,
      backupReminderStatus: BackupReminderStatus.overridden,
      sameDayBackupFound: false,
      blockerCount: 0,
      warningCount: 1,
    );

    final history = await exportHistoryService.listHistory();

    expect(history.single.status, ExportHistoryStatus.canceled);
    expect(history.single.destinationUri, isNull);
    expect(
      history.single.backupReminderStatus,
      BackupReminderStatus.overridden,
    );
  });

  test('failed ZIP generation records message metadata', () async {
    await exportHistoryService.recordResult(
      archive: null,
      writeResult: null,
      status: ExportHistoryStatus.failed,
      backupReminderStatus: BackupReminderStatus.notChecked,
      sameDayBackupFound: true,
      blockerCount: 2,
      warningCount: 3,
      generatedAt: DateTime(2026, 8, 18, 12),
      errorMessage: 'Export ZIP cannot be generated.',
    );

    final history = await exportHistoryService.listHistory();

    expect(history.single.status, ExportHistoryStatus.failed);
    expect(history.single.errorMessage, contains('cannot be generated'));
    expect(history.single.blockerCount, 2);
    expect(history.single.warningCount, 3);
  });

  test('backup save, cancel, and failure record backup history', () async {
    await backupHistoryService.recordSuccess(
      backup: _backupPackage(fileName: 'saved.zip'),
      writeResult: _backupWriteResult(wasSaved: true),
    );
    await backupHistoryService.recordSuccess(
      backup: _backupPackage(fileName: 'canceled.zip'),
      writeResult: _backupWriteResult(wasSaved: false),
    );
    await backupHistoryService.recordFailure(
      generatedAt: DateTime(2026, 8, 18, 12),
      message: 'Disk full',
    );

    final history = await backupHistoryService.listHistory();

    expect(history.map((entry) => entry.status), [
      BackupHistoryStatus.failed,
      BackupHistoryStatus.canceled,
      BackupHistoryStatus.success,
    ]);
    expect(history.first.errorMessage, 'Disk full');
  });
}

class _DeterministicIdGenerator implements StableIdGenerator {
  var _counter = 0;

  @override
  String nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }
}

ExportArchivePackage _archivePackage() {
  final bytes = Uint8List.fromList([1, 2, 3]);
  return ExportArchivePackage(
    fileName: 'export.zip',
    bytes: bytes,
    generatedAt: DateTime(2026, 8, 18, 12),
    checksum: 'export-checksum',
    manifest: const {},
    entries: const [],
  );
}

ExportWriteResult _exportWriteResult({required bool wasSaved}) {
  final bytes = Uint8List.fromList([1, 2, 3]);
  return ExportWriteResult(
    fileName: 'export.zip',
    bytes: bytes,
    byteLength: bytes.length,
    checksum: 'export-checksum',
    destinationUri: wasSaved ? Uri.parse('file:///export.zip') : null,
  );
}

BackupPackage _backupPackage({
  String fileName = 'backup.zip',
  DateTime? generatedAt,
}) {
  final bytes = Uint8List.fromList([4, 5, 6]);
  return BackupPackage(
    fileName: fileName,
    bytes: bytes,
    generatedAt: generatedAt ?? DateTime(2026, 8, 18, 10),
    checksum: 'backup-checksum',
    manifest: const {},
    entries: const [],
  );
}

BackupWriteResult _backupWriteResult({required bool wasSaved}) {
  final bytes = Uint8List.fromList([4, 5, 6]);
  return BackupWriteResult(
    fileName: 'backup.zip',
    bytes: bytes,
    byteLength: bytes.length,
    checksum: 'backup-checksum',
    destinationUri: wasSaved ? Uri.parse('file:///backup.zip') : null,
  );
}
