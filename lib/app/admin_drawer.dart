import 'package:flutter/material.dart';

import '../core/domain/stable_id_generator.dart';
import '../core/storage/audit_storage_paths.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/backup/backup_history_service.dart';
import '../features/backup/backup_package_io.dart';
import '../features/backup/backup_screen.dart';
import '../features/backup/backup_service.dart';
import '../features/organization/organization_screen.dart';
import '../features/organization/organization_service.dart';
import 'brand_logo.dart';

/// Admin menu presented from the top app bar action.
/// Consolidates Organization Profile, Officer Roster, and Backup & Restore
/// into a clean, unified administration panel.
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
      backgroundColor: const Color(0xFF161C26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF263345)),
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
    final orgService = OrganizationService(
      repository: repository,
      idGenerator: idGenerator,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const BrandLogo(
                  key: Key('adminMenuBrandLogo'),
                  size: 28,
                  decorative: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Administration & Settings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('adminMenuProfileTile'),
                    leading: const Icon(
                      Icons.business_outlined,
                      color: Color(0xFF38BDF8),
                    ),
                    title: const Text(
                      'Organization & Officers',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Manage profile, advisers, signatories, and roster',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text('Profile'),
                            ),
                            body: SafeArea(
                              child: OrganizationScreen(service: orgService),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFF1E293B)),
                  ListTile(
                    key: const Key('adminMenuBackupTile'),
                    leading: const Icon(
                      Icons.backup_outlined,
                      color: Color(0xFFF59E0B),
                    ),
                    title: const Text(
                      'Backup & Restore',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Create archive backups or restore local database',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
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
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Audivance · Offline Local-first Audit System',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
