import '../../core/domain/stable_id_generator.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../backup/backup_history_service.dart';
import 'export_package_writer.dart';
import 'export_service.dart';

class ExportHistoryService {
  const ExportHistoryService({
    required this.repository,
    required this.idGenerator,
    required this.backupHistoryService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final BackupHistoryService backupHistoryService;
  final DateTime Function() _now;

  Future<List<ExportHistoryEntry>> listHistory() {
    return repository.listExportHistory();
  }

  Future<bool> hasSameDayBackup(DateTime asOf) {
    return backupHistoryService.hasSuccessfulBackupOn(asOf);
  }

  Future<ExportHistoryEntry> recordResult({
    required ExportArchivePackage? archive,
    required ExportWriteResult? writeResult,
    required ExportHistoryStatus status,
    required BackupReminderStatus backupReminderStatus,
    required bool sameDayBackupFound,
    required int blockerCount,
    required int warningCount,
    DateTime? generatedAt,
    String? errorMessage,
  }) async {
    final entry = ExportHistoryEntry(
      id: idGenerator.nextId('export-history'),
      fileName: archive?.fileName ?? 'Export ZIP not saved',
      generatedAt: archive?.generatedAt ?? generatedAt ?? _now(),
      byteLength: archive?.byteLength ?? 0,
      checksum: archive?.checksum ?? '',
      destinationUri: writeResult?.destinationUri?.toString(),
      status: status,
      backupReminderStatus: backupReminderStatus,
      sameDayBackupFound: sameDayBackupFound,
      blockerCount: blockerCount,
      warningCount: warningCount,
      createdAt: _now(),
      errorMessage: errorMessage,
    );
    await repository.appendExportHistory(entry);
    return entry;
  }
}
