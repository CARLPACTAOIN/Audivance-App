import 'backup_package_io.dart';
import 'backup_service.dart';

class BackupRestoreCoordinator {
  const BackupRestoreCoordinator({
    required this.service,
    required this.closeActiveWorkspace,
    required this.reopenWorkspace,
  });

  final BackupService service;
  final Future<void> Function() closeActiveWorkspace;
  final Future<void> Function() reopenWorkspace;

  Future<RestoreExecutionResult> restoreBackup(
    PickedBackupPackage package,
  ) async {
    final validation = await service.validateBackup(package.bytes);
    if (validation.isInvalid) {
      return RestoreExecutionResult.invalidBackup(validation);
    }

    await closeActiveWorkspace();
    final restoreResult = await service.restoreBackupDetailed(package.bytes);
    if (!restoreResult.isSuccess) {
      try {
        await reopenWorkspace();
      } on Object catch (error) {
        return RestoreExecutionResult.reopenFailed(
          'Backup restore failed and the previous workspace could not be reopened.\n$error',
        );
      }
      return restoreResult;
    }

    try {
      await reopenWorkspace();
    } on Object catch (error) {
      return RestoreExecutionResult.reopenFailed(
        'Backup files were restored, but the workspace could not be reopened.\n$error',
      );
    }

    return restoreResult;
  }
}
