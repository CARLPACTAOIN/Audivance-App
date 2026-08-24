import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../audit/domain/audit_models.dart';
import '../backup/backup_history_service.dart';
import '../backup/backup_package_io.dart';
import '../backup/backup_service.dart';
import '../treasury/treasury_formatters.dart';
import 'export_history_service.dart';
import 'export_package_writer.dart';
import 'export_service.dart';
import 'pdf_report_actions.dart';
import 'pdf_report_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({
    super.key,
    required this.service,
    this.writer = const FilePickerExportPackageWriter(),
    this.pdfWriter = const FilePickerPdfReportWriter(),
    this.pdfDispatcher = const PrintingPdfReportDispatcher(),
    this.historyService,
    this.backupHistoryService,
    this.backupService,
    this.backupWriter,
    this.asOf,
  });

  final ExportService service;
  final ExportPackageWriter writer;
  final PdfReportWriter pdfWriter;
  final PdfReportDispatcher pdfDispatcher;
  final ExportHistoryService? historyService;
  final BackupHistoryService? backupHistoryService;
  final BackupService? backupService;
  final BackupPackageWriter? backupWriter;
  final DateTime? asOf;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late Future<_ExportScreenData> _screenDataFuture;
  ExportPackagePreview? _preview;
  ExportArchivePackage? _archive;
  ExportWriteResult? _writeResult;
  ExportWriteResult? _pdfWriteResult;
  String? _pdfActionResult;
  String? _previewError;
  String? _archiveError;
  String? _pdfActionError;
  var _isGeneratingPreview = false;
  var _isGeneratingArchive = false;
  String? _activePdfActionKey;

  @override
  void initState() {
    super.initState();
    _screenDataFuture = _loadScreenData();
  }

  @override
  void didUpdateWidget(ExportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.asOf != widget.asOf ||
        oldWidget.writer != widget.writer ||
        oldWidget.pdfWriter != widget.pdfWriter ||
        oldWidget.pdfDispatcher != widget.pdfDispatcher ||
        oldWidget.historyService != widget.historyService ||
        oldWidget.backupHistoryService != widget.backupHistoryService ||
        oldWidget.backupService != widget.backupService ||
        oldWidget.backupWriter != widget.backupWriter) {
      _screenDataFuture = _loadScreenData();
      _preview = null;
      _archive = null;
      _writeResult = null;
      _pdfWriteResult = null;
      _pdfActionResult = null;
      _previewError = null;
      _archiveError = null;
      _pdfActionError = null;
      _activePdfActionKey = null;
    }
  }

  Future<_ExportScreenData> _loadScreenData() async {
    final asOf = widget.asOf ?? DateTime.now();
    final snapshot = await widget.service.loadSnapshot(asOf: asOf);
    final exportHistory =
        await widget.historyService?.listHistory() ??
        const <ExportHistoryEntry>[];
    final backupHistory =
        await widget.backupHistoryService?.listHistory() ??
        const <BackupHistoryEntry>[];
    return _ExportScreenData(
      snapshot: snapshot,
      exportHistory: exportHistory,
      backupHistory: backupHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ExportScreenData>(
      future: _screenDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppStateView.loading(
            title: 'Loading Export Center',
            message: 'Checking readiness, package entries, and reports.',
          );
        }
        if (snapshot.hasError) {
          return AppStateView.error(
            title: 'Export data could not be loaded',
            message: snapshot.error.toString(),
            onAction: () {
              setState(() {
                _screenDataFuture = _loadScreenData();
                _preview = null;
                _previewError = null;
                _archive = null;
                _archiveError = null;
              });
            },
          );
        }
        final data = snapshot.data;
        return _ExportContent(
          snapshot:
              data?.snapshot ??
              const ExportCenterSnapshot(
                organizationName: 'Audivance Workspace',
                term: 'No organization profile',
                readinessScore: 0,
                issues: [],
                recordCounts: [],
                attachments: [],
                packageFiles: [],
              ),
          exportHistory: data?.exportHistory ?? const [],
          backupHistory: data?.backupHistory ?? const [],
          preview: _preview,
          archive: _archive,
          writeResult: _writeResult,
          pdfWriteResult: _pdfWriteResult,
          pdfActionResult: _pdfActionResult,
          previewError: _previewError,
          archiveError: _archiveError,
          pdfActionError: _pdfActionError,
          isGeneratingPreview: _isGeneratingPreview,
          isGeneratingArchive: _isGeneratingArchive,
          activePdfActionKey: _activePdfActionKey,
          onGeneratePreview: _generatePreview,
          onGenerateArchive: _generateArchive,
          onSavePdf: (path) => _runPdfAction(path, _PdfAction.save),
          onSharePdf: (path) => _runPdfAction(path, _PdfAction.share),
          onPrintPdf: (path) => _runPdfAction(path, _PdfAction.print),
        );
      },
    );
  }

  Future<void> _generatePreview() async {
    setState(() {
      _isGeneratingPreview = true;
      _previewError = null;
    });
    try {
      final preview = await widget.service.buildPreview(
        asOf: widget.asOf ?? DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _previewError = 'Export preview could not be generated.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPreview = false;
        });
      }
    }
  }

  Future<void> _generateArchive() async {
    final asOf = widget.asOf ?? DateTime.now();
    var backupReminderStatus = BackupReminderStatus.notChecked;
    var sameDayBackupFound = true;
    if (widget.historyService != null) {
      sameDayBackupFound = await widget.historyService!.hasSameDayBackup(asOf);
      if (sameDayBackupFound) {
        backupReminderStatus = BackupReminderStatus.satisfied;
      } else {
        if (!mounted) {
          return;
        }
        final choice = await showDialog<_BackupReminderChoice>(
          context: context,
          builder: (context) => const _BackupReminderDialog(),
        );
        if (!mounted ||
            choice == null ||
            choice == _BackupReminderChoice.cancel) {
          return;
        }
        if (choice == _BackupReminderChoice.generateBackup) {
          final backupCreated = await _generateBackupBeforeExport();
          if (!mounted || !backupCreated) {
            return;
          }
          sameDayBackupFound = true;
          backupReminderStatus = BackupReminderStatus.satisfied;
        } else {
          backupReminderStatus = BackupReminderStatus.overridden;
        }
      }
    }
    setState(() {
      _isGeneratingArchive = true;
      _archiveError = null;
      _archive = null;
      _writeResult = null;
    });
    var blockerCount = 0;
    var warningCount = 0;
    final validation = await widget.service.validateCanExport(asOf: asOf);
    final latestSnapshot = await widget.service.loadSnapshot(asOf: asOf);
    blockerCount = latestSnapshot.blockerCount;
    warningCount = latestSnapshot.warningCount;
    if (validation.isInvalid) {
      await widget.historyService?.recordResult(
        archive: null,
        writeResult: null,
        status: ExportHistoryStatus.failed,
        backupReminderStatus: backupReminderStatus,
        sameDayBackupFound: sameDayBackupFound,
        blockerCount: blockerCount,
        warningCount: warningCount,
        generatedAt: asOf,
        errorMessage: validation.summary,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _archiveError = validation.summary;
        _isGeneratingArchive = false;
      });
      await _refreshScreenData();
      return;
    }
    try {
      final archive = await widget.service.buildArchive(asOf: asOf);
      final writeResult = await widget.writer.save(archive);
      await widget.historyService?.recordResult(
        archive: archive,
        writeResult: writeResult,
        status: writeResult.wasSaved
            ? ExportHistoryStatus.success
            : ExportHistoryStatus.canceled,
        backupReminderStatus: backupReminderStatus,
        sameDayBackupFound: sameDayBackupFound,
        blockerCount: blockerCount,
        warningCount: warningCount,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _archive = archive;
        _writeResult = writeResult;
        _isGeneratingArchive = false;
      });
      await _refreshScreenData();
    } on Object catch (error) {
      await widget.historyService?.recordResult(
        archive: null,
        writeResult: null,
        status: ExportHistoryStatus.failed,
        backupReminderStatus: backupReminderStatus,
        sameDayBackupFound: sameDayBackupFound,
        blockerCount: blockerCount,
        warningCount: warningCount,
        generatedAt: asOf,
        errorMessage: error.toString(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _archiveError = 'Export ZIP could not be generated.\n$error';
        _isGeneratingArchive = false;
      });
      await _refreshScreenData();
    }
  }

  Future<bool> _generateBackupBeforeExport() async {
    final backupService = widget.backupService;
    final backupWriter = widget.backupWriter;
    if (backupService == null || backupWriter == null) {
      setState(() {
        _archiveError =
            'Backup service is not available from the Export Center.';
      });
      return false;
    }
    setState(() {
      _isGeneratingArchive = true;
      _archiveError = null;
    });
    try {
      final backup = await backupService.buildBackup();
      final writeResult = await backupWriter.save(backup);
      await widget.backupHistoryService?.recordSuccess(
        backup: backup,
        writeResult: writeResult,
      );
      if (!mounted) {
        return false;
      }
      if (!writeResult.wasSaved) {
        setState(() {
          _archiveError =
              'Backup save was canceled. Export ZIP was not generated.';
          _isGeneratingArchive = false;
        });
        await _refreshScreenData();
        return false;
      }
      setState(() {
        _isGeneratingArchive = false;
      });
      await _refreshScreenData();
      return true;
    } on Object catch (error) {
      await widget.backupHistoryService?.recordFailure(
        generatedAt: DateTime.now(),
        message: error.toString(),
      );
      if (!mounted) {
        return false;
      }
      setState(() {
        _archiveError = 'Backup could not be generated before export.\n$error';
        _isGeneratingArchive = false;
      });
      await _refreshScreenData();
      return false;
    }
  }

  Future<void> _refreshScreenData() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _screenDataFuture = _loadScreenData();
    });
  }

  Future<void> _runPdfAction(String path, _PdfAction action) async {
    setState(() {
      _activePdfActionKey = '${action.name}:$path';
      _pdfActionError = null;
      _pdfActionResult = null;
      _pdfWriteResult = null;
    });
    try {
      final reports = await widget.service.buildReports(
        asOf: widget.asOf ?? DateTime.now(),
      );
      PdfReportFile? report;
      for (final file in reports.files) {
        if (file.path == path) {
          report = file;
          break;
        }
      }
      if (report == null) {
        throw StateError('PDF report was not generated: $path');
      }
      final selectedReport = report;
      switch (action) {
        case _PdfAction.save:
          final writeResult = await widget.pdfWriter.save(selectedReport);
          if (!mounted) {
            return;
          }
          setState(() {
            _pdfWriteResult = writeResult;
            _pdfActionResult = writeResult.wasSaved
                ? 'Saved ${writeResult.fileName} to ${writeResult.destinationUri}'
                : 'Save was canceled before a destination was selected.';
          });
          break;
        case _PdfAction.share:
          await widget.pdfDispatcher.share(selectedReport);
          if (!mounted) {
            return;
          }
          setState(() {
            _pdfActionResult = 'Shared ${selectedReport.path}.';
          });
          break;
        case _PdfAction.print:
          await widget.pdfDispatcher.print(selectedReport);
          if (!mounted) {
            return;
          }
          setState(() {
            _pdfActionResult =
                'Print dialog opened for ${selectedReport.path}.';
          });
          break;
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pdfActionError = 'PDF action could not be completed.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _activePdfActionKey = null;
        });
      }
    }
  }
}

enum _PdfAction { save, share, print }

enum _BackupReminderChoice { generateBackup, continueExport, cancel }

class _ExportScreenData {
  const _ExportScreenData({
    required this.snapshot,
    required this.exportHistory,
    required this.backupHistory,
  });

  final ExportCenterSnapshot snapshot;
  final List<ExportHistoryEntry> exportHistory;
  final List<BackupHistoryEntry> backupHistory;
}

class _ExportContent extends StatelessWidget {
  const _ExportContent({
    required this.snapshot,
    required this.exportHistory,
    required this.backupHistory,
    required this.preview,
    required this.archive,
    required this.writeResult,
    required this.pdfWriteResult,
    required this.pdfActionResult,
    required this.previewError,
    required this.archiveError,
    required this.pdfActionError,
    required this.isGeneratingPreview,
    required this.isGeneratingArchive,
    required this.activePdfActionKey,
    required this.onGeneratePreview,
    required this.onGenerateArchive,
    required this.onSavePdf,
    required this.onSharePdf,
    required this.onPrintPdf,
  });

  final ExportCenterSnapshot snapshot;
  final List<ExportHistoryEntry> exportHistory;
  final List<BackupHistoryEntry> backupHistory;
  final ExportPackagePreview? preview;
  final ExportArchivePackage? archive;
  final ExportWriteResult? writeResult;
  final ExportWriteResult? pdfWriteResult;
  final String? pdfActionResult;
  final String? previewError;
  final String? archiveError;
  final String? pdfActionError;
  final bool isGeneratingPreview;
  final bool isGeneratingArchive;
  final String? activePdfActionKey;
  final VoidCallback onGeneratePreview;
  final VoidCallback onGenerateArchive;
  final ValueChanged<String> onSavePdf;
  final ValueChanged<String> onSharePdf;
  final ValueChanged<String> onPrintPdf;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                20,
                isWide ? 32 : 16,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ExportHeader(
                    snapshot: snapshot,
                    isGeneratingPreview: isGeneratingPreview,
                    isGeneratingArchive: isGeneratingArchive,
                    onGeneratePreview: onGeneratePreview,
                    onGenerateArchive: onGenerateArchive,
                  ),
                  const SizedBox(height: 20),
                  if (archiveError != null) ...[
                    _ArchiveErrorPanel(message: archiveError!),
                    const SizedBox(height: 20),
                  ],
                  if (previewError != null) ...[
                    InlineStatusPanel(
                      title: 'Preview failed',
                      message: previewError!,
                      tone: InlineStatusTone.error,
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (archive != null && writeResult != null) ...[
                    _ArchiveResultPanel(
                      archive: archive!,
                      writeResult: writeResult!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _ExportHistoryPanel(
                    exportHistory: exportHistory,
                    backupHistory: backupHistory,
                  ),
                  const SizedBox(height: 20),
                  _ReadinessSummary(snapshot: snapshot),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _IssuePanel(issues: snapshot.issues)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _RecordCountPanel(
                            counts: snapshot.recordCounts,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _IssuePanel(issues: snapshot.issues),
                    const SizedBox(height: 20),
                    _RecordCountPanel(counts: snapshot.recordCounts),
                  ],
                  const SizedBox(height: 20),
                  _AttachmentPanel(attachments: snapshot.attachments),
                  const SizedBox(height: 20),
                  _PackageStructurePanel(paths: snapshot.packageFiles),
                  const SizedBox(height: 20),
                  _LiquidationReportsPanel(
                    paths: snapshot.packageFiles
                        .where(isUsmOsaF46LiquidationReportPath)
                        .toList(growable: false),
                    pdfWriteResult: pdfWriteResult,
                    actionResult: pdfActionResult,
                    actionError: pdfActionError,
                    activeActionKey: activePdfActionKey,
                    onSave: onSavePdf,
                    onShare: onSharePdf,
                    onPrint: onPrintPdf,
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 20),
                    _PreviewPanel(preview: preview!),
                  ],
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExportHeader extends StatelessWidget {
  const _ExportHeader({
    required this.snapshot,
    required this.isGeneratingPreview,
    required this.isGeneratingArchive,
    required this.onGeneratePreview,
    required this.onGenerateArchive,
  });

  final ExportCenterSnapshot snapshot;
  final bool isGeneratingPreview;
  final bool isGeneratingArchive;
  final VoidCallback onGeneratePreview;
  final VoidCallback onGenerateArchive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Center',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${snapshot.organizationName} - ${snapshot.term}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const Key('exportGeneratePreviewButton'),
              onPressed: isGeneratingPreview || isGeneratingArchive
                  ? null
                  : onGeneratePreview,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(
                isGeneratingPreview ? 'Generating...' : 'Generate Preview',
              ),
            ),
            FilledButton.icon(
              key: const Key('exportGenerateZipButton'),
              onPressed: isGeneratingPreview || isGeneratingArchive
                  ? null
                  : onGenerateArchive,
              icon: const Icon(Icons.archive_outlined),
              label: Text(
                isGeneratingArchive ? 'Generating ZIP...' : 'Generate ZIP',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackupReminderDialog extends StatelessWidget {
  const _BackupReminderDialog();

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Backup recommended before export',
      maxWidth: 520,
      status: const InlineStatusPanel(
        title: 'Same-day backup not found',
        message: 'Create a local backup before generating the COA ZIP so this encrypted workspace and attachments can be restored on this device if needed.',
        tone: InlineStatusTone.warning,
      ),
      actions: [
        TextButton(
          key: const Key('exportBackupReminderCancelButton'),
          onPressed: () => Navigator.pop(context, _BackupReminderChoice.cancel),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          key: const Key('exportBackupReminderContinueButton'),
          onPressed: () =>
              Navigator.pop(context, _BackupReminderChoice.continueExport),
          icon: const Icon(Icons.warning_amber_outlined),
          label: const Text('Continue Export'),
        ),
        FilledButton.icon(
          key: const Key('exportBackupReminderGenerateButton'),
          onPressed: () =>
              Navigator.pop(context, _BackupReminderChoice.generateBackup),
          icon: const Icon(Icons.backup_outlined),
          label: const Text('Generate Backup'),
        ),
      ],
      children: const [
        Text(
          'You can continue without a same-day backup, but Audivance will record that the reminder was overridden in export history.',
        ),
      ],
    );
  }
}

class _ExportHistoryPanel extends StatelessWidget {
  const _ExportHistoryPanel({
    required this.exportHistory,
    required this.backupHistory,
  });

  final List<ExportHistoryEntry> exportHistory;
  final List<BackupHistoryEntry> backupHistory;

  @override
  Widget build(BuildContext context) {
    final latestBackup = backupHistory.isEmpty ? null : backupHistory.first;
    final recentExports = exportHistory.take(5).toList(growable: false);
    return _Panel(
      title: 'Export History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (latestBackup == null)
            const InlineStatusPanel(
              title: 'No backup recorded',
              message: 'Generate a same-day backup before COA export to avoid the reminder.',
              tone: InlineStatusTone.warning,
            )
          else
            InlineStatusPanel(
              title: 'Latest backup',
              message:
                  '${_backupStatusLabel(latestBackup.status)} on ${formatDate(latestBackup.generatedAt)}.',
              tone: _backupStatusTone(latestBackup.status),
            ),
          const SizedBox(height: 12),
          if (exportHistory.isEmpty)
            const _EmptyPanelMessage(
              icon: Icons.history_outlined,
              text: 'No COA ZIP export attempts have been recorded yet.',
            )
          else
            Column(
              children: [
                for (final entry in recentExports)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: entry == recentExports.last ? 0 : 8,
                    ),
                    child: _ExportHistoryRow(entry: entry),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ExportHistoryRow extends StatelessWidget {
  const _ExportHistoryRow({required this.entry});

  final ExportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusBadge(
                  label: _exportStatusLabel(entry.status),
                  tone: _exportStatusTone(entry.status),
                  icon: _exportStatusIcon(entry.status),
                ),
                StatusBadge(
                  label: _reminderStatusLabel(entry.backupReminderStatus),
                  tone:
                      entry.backupReminderStatus ==
                          BackupReminderStatus.overridden
                      ? InlineStatusTone.warning
                      : InlineStatusTone.info,
                ),
                Text(
                  formatDate(entry.generatedAt),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  _formatBytes(entry.byteLength),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Readiness: ${entry.blockerCount} blockers, ${entry.warningCount} warnings',
              style: theme.textTheme.bodySmall,
            ),
            if (entry.destinationUri?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                entry.destinationUri!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (entry.errorMessage?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                entry.errorMessage!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadinessSummary extends StatelessWidget {
  const _ReadinessSummary({required this.snapshot});

  final ExportCenterSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final score = snapshot.readinessScore;
    return _Panel(
      title: 'COA Export Readiness',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$score%',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              _StatusChip(
                label: '${snapshot.blockerCount} blockers',
                severity: ExportReadinessSeverity.blocker,
              ),
              _StatusChip(
                label: '${snapshot.warningCount} warnings',
                severity: ExportReadinessSeverity.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: const Color(0xFFE2E8F0),
            color: score == 100
                ? const Color(0xFF047857)
                : const Color(0xFFA16207),
          ),
        ],
      ),
    );
  }
}

class _IssuePanel extends StatelessWidget {
  const _IssuePanel({required this.issues});

  final List<ExportReadinessIssueView> issues;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Readiness Issues',
      child: issues.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.verified_outlined,
              text: 'No export readiness issues found.',
            )
          : Column(
              children: [
                for (final issue in issues)
                  _IssueRow(issue: issue, showDivider: issue != issues.last),
              ],
            ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.showDivider});

  final ExportReadinessIssueView issue;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                issue.severity == ExportReadinessSeverity.blocker
                    ? Icons.error_outline
                    : Icons.warning_amber_outlined,
                color: _severityColor(issue.severity),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.message),
                    const SizedBox(height: 4),
                    Text(
                      issue.severityLabel,
                      style: TextStyle(
                        color: _severityColor(issue.severity),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _RecordCountPanel extends StatelessWidget {
  const _RecordCountPanel({required this.counts});

  final List<ExportRecordCount> counts;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Record Counts',
      child: Column(
        children: [
          for (final count in counts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text(count.label)),
                  Text(
                    count.count.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentPanel extends StatelessWidget {
  const _AttachmentPanel({required this.attachments});

  final List<ExportAttachmentView> attachments;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Attachment Inventory',
      child: attachments.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.attach_file_outlined,
              text: 'Typed attachment metadata will appear here.',
            )
          : Column(
              children: [
                for (final attachment in attachments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      attachment.fileName.isEmpty
                          ? 'Missing file name'
                          : attachment.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${attachment.module} - ${attachment.localPath}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      attachment.sizeBytes == null
                          ? 'No size'
                          : '${attachment.sizeBytes} B',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PackageStructurePanel extends StatelessWidget {
  const _PackageStructurePanel({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Package Structure',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final path in paths)
            Chip(
              avatar: const Icon(Icons.insert_drive_file_outlined, size: 18),
              label: Text(path),
            ),
        ],
      ),
    );
  }
}

class _LiquidationReportsPanel extends StatelessWidget {
  const _LiquidationReportsPanel({
    required this.paths,
    required this.pdfWriteResult,
    required this.actionResult,
    required this.actionError,
    required this.activeActionKey,
    required this.onSave,
    required this.onShare,
    required this.onPrint,
  });

  final List<String> paths;
  final ExportWriteResult? pdfWriteResult;
  final String? actionResult;
  final String? actionError;
  final String? activeActionKey;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onShare;
  final ValueChanged<String> onPrint;

  @override
  Widget build(BuildContext context) {
    final hasActiveAction = activeActionKey != null;
    return _Panel(
      title: 'USM-OSA-F46 Liquidation Reports',
      child: paths.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.picture_as_pdf_outlined,
              text: 'USM-OSA-F46 liquidation reports will appear after events exist.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (actionError != null) ...[
                  InlineStatusPanel(
                    title: 'PDF action failed',
                    message: actionError!,
                    tone: InlineStatusTone.error,
                  ),
                  const SizedBox(height: 12),
                ] else if (actionResult != null) ...[
                  InlineStatusPanel(
                    title: 'PDF action complete',
                    message: actionResult!,
                    tone: InlineStatusTone.success,
                  ),
                  if (pdfWriteResult != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'SHA-256 ${pdfWriteResult!.checksum}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                for (final path in paths)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: path == paths.last ? 0 : 10,
                    ),
                    child: _LiquidationReportActionRow(
                      path: path,
                      isBusy: hasActiveAction,
                      activeActionKey: activeActionKey,
                      onSave: () => onSave(path),
                      onShare: () => onShare(path),
                      onPrint: () => onPrint(path),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LiquidationReportActionRow extends StatelessWidget {
  const _LiquidationReportActionRow({
    required this.path,
    required this.isBusy,
    required this.activeActionKey,
    required this.onSave,
    required this.onShare,
    required this.onPrint,
  });

  final String path;
  final bool isBusy;
  final String? activeActionKey;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usmOsaF46ReportLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          path,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: Key('liquidationPdfSaveButton$path'),
              onPressed: isBusy ? null : onSave,
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(_buttonLabel('Save', 'save:$path')),
            ),
            OutlinedButton.icon(
              key: Key('liquidationPdfShareButton$path'),
              onPressed: isBusy ? null : onShare,
              icon: const Icon(Icons.ios_share_outlined),
              label: Text(_buttonLabel('Share', 'share:$path')),
            ),
            OutlinedButton.icon(
              key: Key('liquidationPdfPrintButton$path'),
              onPressed: isBusy ? null : onPrint,
              icon: const Icon(Icons.print_outlined),
              label: Text(_buttonLabel('Print', 'print:$path')),
            ),
          ],
        ),
      ],
    );
  }

  String _buttonLabel(String label, String key) {
    return activeActionKey == key ? 'Working...' : label;
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview});

  final ExportPackagePreview preview;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Generated Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.fileName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final file in preview.files)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.article_outlined),
              title: Text(file.path),
              subtitle: Text(
                '${file.byteLength} bytes - CRC32 ${file.checksum}',
              ),
            ),
        ],
      ),
    );
  }
}

class _ArchiveErrorPanel extends StatelessWidget {
  const _ArchiveErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'ZIP Export Blocked',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7F1D1D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveResultPanel extends StatelessWidget {
  const _ArchiveResultPanel({required this.archive, required this.writeResult});

  final ExportArchivePackage archive;
  final ExportWriteResult writeResult;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Generated ZIP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            archive.fileName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetadataChip(
                icon: Icons.storage_outlined,
                label: '${archive.byteLength} bytes',
              ),
              _MetadataChip(
                icon: Icons.list_alt_outlined,
                label: '${archive.entries.length} entries',
              ),
              _MetadataChip(
                icon: Icons.verified_outlined,
                label: 'SHA-256 ${archive.checksum}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            writeResult.wasSaved
                ? 'Saved to ${writeResult.destinationUri}'
                : 'Save was canceled before a destination was selected.',
          ),
        ],
      ),
    );
  }
}

String _exportStatusLabel(ExportHistoryStatus status) {
  return switch (status) {
    ExportHistoryStatus.success => 'Export saved',
    ExportHistoryStatus.canceled => 'Save canceled',
    ExportHistoryStatus.failed => 'Failed',
  };
}

InlineStatusTone _exportStatusTone(ExportHistoryStatus status) {
  return switch (status) {
    ExportHistoryStatus.success => InlineStatusTone.success,
    ExportHistoryStatus.canceled => InlineStatusTone.warning,
    ExportHistoryStatus.failed => InlineStatusTone.error,
  };
}

IconData _exportStatusIcon(ExportHistoryStatus status) {
  return switch (status) {
    ExportHistoryStatus.success => Icons.check_circle_outline,
    ExportHistoryStatus.canceled => Icons.cancel_outlined,
    ExportHistoryStatus.failed => Icons.error_outline,
  };
}

String _reminderStatusLabel(BackupReminderStatus status) {
  return switch (status) {
    BackupReminderStatus.notChecked => 'Backup not checked',
    BackupReminderStatus.satisfied => 'Same-day backup',
    BackupReminderStatus.overridden => 'Backup reminder overridden',
  };
}

String _backupStatusLabel(BackupHistoryStatus status) {
  return switch (status) {
    BackupHistoryStatus.success => 'Saved backup',
    BackupHistoryStatus.canceled => 'Backup save canceled',
    BackupHistoryStatus.failed => 'Backup failed',
  };
}

InlineStatusTone _backupStatusTone(BackupHistoryStatus status) {
  return switch (status) {
    BackupHistoryStatus.success => InlineStatusTone.success,
    BackupHistoryStatus.canceled => InlineStatusTone.warning,
    BackupHistoryStatus.failed => InlineStatusTone.error,
  };
}

String _formatBytes(int byteLength) {
  if (byteLength <= 0) {
    return '0 B';
  }
  if (byteLength < 1024) {
    return '$byteLength B';
  }
  final kib = byteLength / 1024;
  if (kib < 1024) {
    return '${kib.toStringAsFixed(1)} KB';
  }
  return '${(kib / 1024).toStringAsFixed(1)} MB';
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.severity});

  final String label;
  final ExportReadinessSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

Color _severityColor(ExportReadinessSeverity severity) {
  return switch (severity) {
    ExportReadinessSeverity.blocker => const Color(0xFFDC2626),
    ExportReadinessSeverity.warning => const Color(0xFFA16207),
  };
}
