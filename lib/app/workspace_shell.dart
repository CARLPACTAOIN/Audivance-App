import 'package:flutter/material.dart';

import '../core/attachments/attachment_picker.dart';
import '../core/attachments/attachment_storage_service.dart';
import '../core/domain/stable_id_generator.dart';
import '../core/storage/audit_storage_paths.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/backup/backup_package_io.dart';
import '../features/backup/backup_history_service.dart';
import '../features/backup/backup_service.dart';
import '../features/export/export_history_service.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/dashboard_service.dart';
import '../features/events/event_screen.dart';
import '../features/events/event_service.dart';
import '../features/export/export_package_writer.dart';
import '../features/export/export_screen.dart';
import '../features/export/export_service.dart';
import '../features/liquidation/liquidation_service.dart';
import '../features/organization/organization_service.dart';
import '../features/treasury/treasury_screen.dart';
import '../features/treasury/treasury_service.dart';
import 'admin_drawer.dart';
import 'brand_logo.dart';
import 'floating_pill_navigation_bar.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.repository,
    required this.idGenerator,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.exportPackageWriter,
    this.backupService,
    this.backupPackageWriter,
    this.backupPackageReader,
    this.onRestoreBackup,
    this.asOf,
    required this.storagePaths,
  });

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final ExportPackageWriter? exportPackageWriter;
  final BackupService? backupService;
  final BackupPackageWriter? backupPackageWriter;
  final BackupPackageReader? backupPackageReader;
  final BackupRestoreHandler? onRestoreBackup;
  final DateTime? asOf;
  final AuditStoragePaths storagePaths;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(
              key: Key('workspaceBrandLogo'),
              size: 32,
              decorative: true,
            ),
            SizedBox(width: 10),
            Text('Audivance'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Search records',
            onPressed: () => _showActionPending(context, 'Search records'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            key: const Key('workspaceSettingsButton'),
            tooltip: 'Open settings',
            onPressed: _openAdminMenu,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _selectedPage(),
      ),
      bottomNavigationBar: FloatingPillNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectIndex,
      ),
    );
  }

  Widget _selectedPage() {
    return switch (_selectedIndex) {
      0 => DashboardScreen(
        service: DashboardService(
          widget.repository,
          attachmentStorage: widget.attachmentStorage,
        ),
        asOf: widget.asOf,
        onOpenLedger: () => _selectIndex(1),
        onOpenExportCenter: () => _selectIndex(3),
      ),
      1 => TreasuryScreen(
        service: TreasuryService(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
        ),
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
      2 => EventScreen(
        service: EventService(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
        ),
        organizationService: OrganizationService(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
        ),
        liquidationService: LiquidationService(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
        ),
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
        asOf: widget.asOf,
      ),
      _ => ExportScreen(
        service: ExportService(
          repository: widget.repository,
          attachmentStorage: widget.attachmentStorage,
        ),
        historyService: ExportHistoryService(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
          backupHistoryService: BackupHistoryService(
            repository: widget.repository,
            idGenerator: widget.idGenerator,
          ),
        ),
        backupHistoryService: BackupHistoryService(
          repository: widget.repository,
          idGenerator: widget.idGenerator,
        ),
        backupService:
            widget.backupService ??
            BackupService(storagePaths: widget.storagePaths),
        backupWriter:
            widget.backupPackageWriter ?? const FilePickerBackupPackageWriter(),
        writer:
            widget.exportPackageWriter ?? const FilePickerExportPackageWriter(),
        asOf: widget.asOf,
      ),
    };
  }

  Future<void> _openAdminMenu() {
    return AdminMenuSheet.show(
      context,
      repository: widget.repository,
      idGenerator: widget.idGenerator,
      backupService: widget.backupService,
      backupPackageWriter: widget.backupPackageWriter,
      backupPackageReader: widget.backupPackageReader,
      onRestoreBackup: widget.onRestoreBackup,
      storagePaths: widget.storagePaths,
    );
  }

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

void _showActionPending(BuildContext context, String area) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$area workflow is next in the build sequence.')),
    );
}
