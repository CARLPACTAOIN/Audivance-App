import '../../core/domain/stable_id_generator.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import 'backup_package_io.dart';
import 'backup_service.dart';

class BackupHistoryService {
  const BackupHistoryService({
    required this.repository,
    required this.idGenerator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final DateTime Function() _now;

  Future<List<BackupHistoryEntry>> listHistory() {
    return repository.listBackupHistory();
  }

  Future<bool> hasSuccessfulBackupOn(DateTime date) async {
    final history = await repository.listBackupHistory();
    return history.any(
      (entry) =>
          entry.status == BackupHistoryStatus.success &&
          _sameLocalDate(entry.generatedAt, date),
    );
  }

  Future<BackupHistoryEntry> recordSuccess({
    required BackupPackage backup,
    required BackupWriteResult writeResult,
  }) {
    return _record(
      fileName: backup.fileName,
      generatedAt: backup.generatedAt,
      byteLength: backup.byteLength,
      checksum: backup.checksum,
      destinationUri: writeResult.destinationUri?.toString(),
      status: writeResult.wasSaved
          ? BackupHistoryStatus.success
          : BackupHistoryStatus.canceled,
    );
  }

  Future<BackupHistoryEntry> recordFailure({
    required DateTime generatedAt,
    required String message,
  }) {
    return _record(
      fileName: 'Backup not saved',
      generatedAt: generatedAt,
      byteLength: 0,
      checksum: '',
      destinationUri: null,
      status: BackupHistoryStatus.failed,
      errorMessage: message,
    );
  }

  Future<BackupHistoryEntry> _record({
    required String fileName,
    required DateTime generatedAt,
    required int byteLength,
    required String checksum,
    required String? destinationUri,
    required BackupHistoryStatus status,
    String? errorMessage,
  }) async {
    final entry = BackupHistoryEntry(
      id: idGenerator.nextId('backup-history'),
      fileName: fileName,
      generatedAt: generatedAt,
      byteLength: byteLength,
      checksum: checksum,
      destinationUri: destinationUri,
      status: status,
      createdAt: _now(),
      errorMessage: errorMessage,
    );
    await repository.appendBackupHistory(entry);
    return entry;
  }
}

bool _sameLocalDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
