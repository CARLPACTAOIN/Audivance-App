import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../audit/domain/audit_models.dart';
import '../treasury/treasury_formatters.dart';
import 'backup_history_service.dart';
import 'backup_package_io.dart';
import 'backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
    required this.service,
    this.writer = const FilePickerBackupPackageWriter(),
    this.reader = const FilePickerBackupPackageReader(),
    this.onRestoreBackup,
    this.historyService,
  });

  final BackupService service;
  final BackupPackageWriter writer;
  final BackupPackageReader reader;
  final BackupRestoreHandler? onRestoreBackup;
  final BackupHistoryService? historyService;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  BackupPackage? _backup;
  BackupWriteResult? _writeResult;
  PickedBackupPackage? _pickedBackup;
  BackupValidationResult? _validation;
  RestoreExecutionResult? _restoreResult;
  List<BackupHistoryEntry> _history = const [];
  String? _message;
  var _isGenerating = false;
  var _isValidating = false;
  var _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Backup & Restore',
      maxWidth: 620,
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a local backup ZIP with the encrypted SQLite database and app-private attachments.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const Key('backupGenerateButton'),
                  onPressed: _isBusy ? null : _generateBackup,
                  icon: const Icon(Icons.backup_outlined),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Backup',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('backupValidateButton'),
                  onPressed: _isBusy ? null : _validateBackup,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _isValidating ? 'Validating...' : 'Validate Backup',
                  ),
                ),
                FilledButton.icon(
                  key: const Key('backupRestoreButton'),
                  onPressed: _canRestore ? _confirmAndRestore : null,
                  icon: _isRestoring
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_outlined),
                  label: Text(_isRestoring ? 'Restoring...' : 'Restore Backup'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _RestoreNotice(),
            if (_message != null) ...[
              const SizedBox(height: 16),
              _StatusPanel(message: _message!),
            ],
            if (_backup != null && _writeResult != null) ...[
              const SizedBox(height: 16),
              _BackupResultPanel(backup: _backup!, writeResult: _writeResult!),
            ],
            if (_validation != null) ...[
              const SizedBox(height: 16),
              _ValidationPanel(
                result: _validation!,
                pickedBackup: _pickedBackup,
              ),
            ],
            if (_restoreResult != null) ...[
              const SizedBox(height: 16),
              _RestoreResultPanel(result: _restoreResult!),
            ],
            const SizedBox(height: 16),
            _BackupHistoryPanel(history: _history),
          ],
        ),
      ],
    );
  }

  Future<void> _generateBackup() async {
    setState(() {
      _isGenerating = true;
      _message = null;
      _backup = null;
      _writeResult = null;
      _pickedBackup = null;
      _validation = null;
      _restoreResult = null;
    });
    try {
      final backup = await widget.service.buildBackup();
      final writeResult = await widget.writer.save(backup);
      await widget.historyService?.recordSuccess(
        backup: backup,
        writeResult: writeResult,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _backup = backup;
        _writeResult = writeResult;
        _isGenerating = false;
      });
      await _refreshHistory();
    } on Object catch (error) {
      await widget.historyService?.recordFailure(
        generatedAt: DateTime.now(),
        message: error.toString(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Backup could not be generated.\n$error';
        _isGenerating = false;
      });
      await _refreshHistory();
    }
  }

  Future<void> _validateBackup() async {
    setState(() {
      _isValidating = true;
      _message = null;
      _pickedBackup = null;
      _validation = null;
      _restoreResult = null;
    });
    final picked = await widget.reader.pickBackup();
    if (!mounted) {
      return;
    }
    if (picked == null) {
      setState(() {
        _message = 'Backup validation was canceled.';
        _isValidating = false;
      });
      return;
    }
    final result = await widget.service.validateBackup(picked.bytes);
    if (!mounted) {
      return;
    }
    setState(() {
      _pickedBackup = picked;
      _validation = result;
      _isValidating = false;
    });
  }

  Future<void> _confirmAndRestore() async {
    final pickedBackup = _pickedBackup;
    final validation = _validation;
    if (pickedBackup == null || validation == null || validation.isInvalid) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RestoreConfirmationDialog(validation: validation),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    setState(() {
      _isRestoring = true;
      _message = null;
      _restoreResult = null;
    });
    try {
      final handler =
          widget.onRestoreBackup ??
          (package) async =>
              widget.service.restoreBackupDetailed(package.bytes);
      final result = await handler(pickedBackup);
      if (!mounted) {
        return;
      }
      setState(() {
        _restoreResult = result;
        _isRestoring = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _restoreResult = RestoreExecutionResult.restoreFailed(
          'Backup could not be restored.\n$error',
          validation: validation,
        );
        _isRestoring = false;
      });
    }
  }

  bool get _isBusy => _isGenerating || _isValidating || _isRestoring;

  bool get _canRestore =>
      !_isBusy && _pickedBackup != null && (_validation?.isValid ?? false);

  Future<void> _refreshHistory() async {
    final history = await widget.historyService?.listHistory();
    if (!mounted || history == null) {
      return;
    }
    setState(() {
      _history = history;
    });
  }
}

class _RestoreNotice extends StatelessWidget {
  const _RestoreNotice();

  @override
  Widget build(BuildContext context) {
    return const InlineStatusPanel(
      title: 'Same-device restore',
      message: 'The database inside this backup is encrypted with this device workspace key. Restore requires the same local secure credential context; cross-device recovery remains a future recovery-key workflow.',
      tone: InlineStatusTone.warning,
    );
  }
}

class _BackupHistoryPanel extends StatelessWidget {
  const _BackupHistoryPanel({required this.history});

  final List<BackupHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const InlineStatusPanel(
        title: 'Backup history',
        message: 'No backup attempts have been recorded yet.',
        tone: InlineStatusTone.info,
      );
    }
    final recent = history.take(5).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Backup History',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        for (final entry in recent)
          Padding(
            padding: EdgeInsets.only(bottom: entry == recent.last ? 0 : 8),
            child: _BackupHistoryRow(entry: entry),
          ),
      ],
    );
  }
}

class _BackupHistoryRow extends StatelessWidget {
  const _BackupHistoryRow({required this.entry});

  final BackupHistoryEntry entry;

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
                  label: _backupStatusLabel(entry.status),
                  tone: _backupStatusTone(entry.status),
                  icon: _backupStatusIcon(entry.status),
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

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return InlineStatusPanel(
      title: 'Backup action failed',
      message: message,
      tone: InlineStatusTone.error,
    );
  }
}

class _BackupResultPanel extends StatelessWidget {
  const _BackupResultPanel({required this.backup, required this.writeResult});

  final BackupPackage backup;
  final BackupWriteResult writeResult;

  @override
  Widget build(BuildContext context) {
    return _ResultPanel(
      title: 'Generated Backup',
      children: [
        Text(backup.fileName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _MetadataWrap(
          labels: [
            '${backup.byteLength} bytes',
            '${backup.entries.length} entries',
            'Encrypted DB',
            'SHA-256 ${backup.checksum}',
          ],
        ),
        const SizedBox(height: 10),
        Text(
          writeResult.wasSaved
              ? 'Saved to ${writeResult.destinationUri}'
              : 'Save was canceled before a destination was selected.',
        ),
      ],
    );
  }
}

String _backupStatusLabel(BackupHistoryStatus status) {
  return switch (status) {
    BackupHistoryStatus.success => 'Saved backup',
    BackupHistoryStatus.canceled => 'Save canceled',
    BackupHistoryStatus.failed => 'Failed',
  };
}

InlineStatusTone _backupStatusTone(BackupHistoryStatus status) {
  return switch (status) {
    BackupHistoryStatus.success => InlineStatusTone.success,
    BackupHistoryStatus.canceled => InlineStatusTone.warning,
    BackupHistoryStatus.failed => InlineStatusTone.error,
  };
}

IconData _backupStatusIcon(BackupHistoryStatus status) {
  return switch (status) {
    BackupHistoryStatus.success => Icons.check_circle_outline,
    BackupHistoryStatus.canceled => Icons.cancel_outlined,
    BackupHistoryStatus.failed => Icons.error_outline,
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

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.result, required this.pickedBackup});

  final BackupValidationResult result;
  final PickedBackupPackage? pickedBackup;

  @override
  Widget build(BuildContext context) {
    return _ResultPanel(
      title: result.isValid ? 'Backup Is Valid' : 'Backup Has Problems',
      children: [
        if (result.isValid) ...[
          Text(
            pickedBackup == null
                ? '${result.entries.length} manifest entries verified.'
                : '${pickedBackup!.fileName} is ready for same-device restore.',
          ),
          const SizedBox(height: 10),
          _MetadataWrap(
            labels: [
              'Schema ${result.schemaVersion}',
              'App ${result.appVersion}',
              '${result.databaseEntryCount} database files',
              '${result.attachmentEntryCount} attachments',
              '${result.totalByteLength} bytes',
              'Restore ${result.restoreScope}',
            ],
          ),
        ] else
          for (final message in result.messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(message),
            ),
      ],
    );
  }
}

class _RestoreResultPanel extends StatelessWidget {
  const _RestoreResultPanel({required this.result});

  final RestoreExecutionResult result;

  @override
  Widget build(BuildContext context) {
    if (result.isSuccess) {
      return InlineStatusPanel(
        title: 'Restore complete',
        message: result.message,
        tone: InlineStatusTone.success,
      );
    }
    return InlineStatusPanel(
      title: result.status == RestoreExecutionStatus.reopenFailed
          ? 'Workspace reopen failed'
          : 'Restore blocked',
      message: result.message,
      tone: InlineStatusTone.error,
    );
  }
}

class _RestoreConfirmationDialog extends StatefulWidget {
  const _RestoreConfirmationDialog({required this.validation});

  final BackupValidationResult validation;

  @override
  State<_RestoreConfirmationDialog> createState() =>
      _RestoreConfirmationDialogState();
}

class _RestoreConfirmationDialogState
    extends State<_RestoreConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRestore = _controller.text.trim() == 'RESTORE';
    return AppDialogFrame(
      title: 'Confirm Restore',
      maxWidth: 520,
      status: const InlineStatusPanel(
        title: 'This replaces local data',
        message: 'Audivance will replace the current encrypted database files and app-private attachments with this validated backup.',
        tone: InlineStatusTone.warning,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('backupRestoreConfirmButton'),
          onPressed: canRestore ? () => Navigator.pop(context, true) : null,
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Restore'),
        ),
      ],
      children: [
        _MetadataWrap(
          labels: [
            '${widget.validation.databaseEntryCount} database files',
            '${widget.validation.attachmentEntryCount} attachments',
            'Schema ${widget.validation.schemaVersion}',
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('backupRestoreConfirmationField'),
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Type RESTORE to continue',
          ),
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetadataWrap extends StatelessWidget {
  const _MetadataWrap({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          MetadataChip(
            icon: Icons.verified_outlined,
            label: label,
            tooltip: label,
          ),
      ],
    );
  }
}
