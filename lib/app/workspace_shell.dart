import 'package:flutter/material.dart';

import '../core/attachments/attachment_picker.dart';
import '../core/attachments/attachment_storage_service.dart';
import '../core/domain/stable_id_generator.dart';
import '../core/storage/audit_storage_paths.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/backup/backup_screen.dart';
import '../features/backup/backup_service.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/dashboard_service.dart';
import '../features/events/event_screen.dart';
import '../features/events/event_service.dart';
import '../features/export/export_package_writer.dart';
import '../features/export/export_screen.dart';
import '../features/export/export_service.dart';
import '../features/liquidation/liquidation_service.dart';
import '../features/treasury/treasury_screen.dart';
import '../features/treasury/treasury_service.dart';
import 'brand_logo.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.repository,
    required this.idGenerator,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.exportPackageWriter,
    this.asOf,
    required this.storagePaths,
  });

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final ExportPackageWriter? exportPackageWriter;
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
            tooltip: 'Open settings',
            onPressed: _showBackupRestore,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _selectedPage()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          _selectIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Treasury',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive),
            label: 'Export',
          ),
        ],
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
        writer:
            widget.exportPackageWriter ?? const FilePickerExportPackageWriter(),
        asOf: widget.asOf,
      ),
    };
  }

  Future<void> _showBackupRestore() {
    return showDialog<void>(
      context: context,
      builder: (context) => BackupRestoreScreen(
        service: BackupService(storagePaths: widget.storagePaths),
      ),
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
