import 'package:flutter/material.dart';

import '../core/domain/stable_id_generator.dart';
import '../core/storage/audit_storage_paths.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/backup/backup_history_service.dart';
import '../features/backup/backup_package_io.dart';
import '../features/backup/backup_screen.dart';
import '../features/backup/backup_service.dart';
import 'brand_logo.dart';
import 'ui/app_ui.dart';

/// Admin menu presented from the top app bar action.
/// Provides device-level maintenance and recovery actions.
class AdminMenuSheet extends StatelessWidget {
  const AdminMenuSheet({
    super.key,
    required this.repository,
    required this.idGenerator,
    this.backupService,
    this.backupPackageWriter,
    this.backupPackageReader,
    this.onRestoreBackup,
    required this.storagePaths,
  });

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final BackupService? backupService;
  final BackupPackageWriter? backupPackageWriter;
  final BackupPackageReader? backupPackageReader;
  final BackupRestoreHandler? onRestoreBackup;
  final AuditStoragePaths storagePaths;

  static Future<void> show(
    BuildContext context, {
    required AuditRepository repository,
    required StableIdGenerator idGenerator,
    BackupService? backupService,
    BackupPackageWriter? backupPackageWriter,
    BackupPackageReader? backupPackageReader,
    BackupRestoreHandler? onRestoreBackup,
    required AuditStoragePaths storagePaths,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      builder: (context) => AdminMenuSheet(
        repository: repository,
        idGenerator: idGenerator,
        backupService: backupService,
        backupPackageWriter: backupPackageWriter,
        backupPackageReader: backupPackageReader,
        onRestoreBackup: onRestoreBackup,
        storagePaths: storagePaths,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const BrandLogo(
                  key: Key('adminMenuBrandLogo'),
                  size: 28,
                  decorative: true,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Settings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    key: const Key('adminMenuBackupTile'),
                    leading: const Icon(
                      Icons.backup_outlined,
                      color: AppColors.warning,
                    ),
                    title: const Text(
                      'Backup & Restore',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Create archive backups or restore local database',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog<void>(
                        context: context,
                        builder: (context) => BackupRestoreScreen(
                          service:
                              backupService ??
                              BackupService(storagePaths: storagePaths),
                          writer:
                              backupPackageWriter ??
                              const FilePickerBackupPackageWriter(),
                          reader:
                              backupPackageReader ??
                              const FilePickerBackupPackageReader(),
                          historyService: BackupHistoryService(
                            repository: repository,
                            idGenerator: idGenerator,
                          ),
                          onRestoreBackup: onRestoreBackup,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Audivance · Offline Local-first Audit System',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
