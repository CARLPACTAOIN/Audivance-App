import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import 'backup_package_io.dart';
import 'backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
    required this.service,
    this.writer = const FilePickerBackupPackageWriter(),
    this.reader = const FilePickerBackupPackageReader(),
  });

  final BackupService service;
  final BackupPackageWriter writer;
  final BackupPackageReader reader;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  BackupPackage? _backup;
  BackupWriteResult? _writeResult;
  BackupValidationResult? _validation;
  String? _message;
  var _isGenerating = false;
  var _isValidating = false;

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Backup & Restore',
      maxWidth: 620,
      actions: [
        TextButton(
          onPressed: _isGenerating || _isValidating
              ? null
              : () => Navigator.pop(context),
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
                  onPressed: _isGenerating || _isValidating
                      ? null
                      : _generateBackup,
                  icon: const Icon(Icons.backup_outlined),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Backup',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('backupValidateButton'),
                  onPressed: _isGenerating || _isValidating
                      ? null
                      : _validateBackup,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    _isValidating ? 'Validating...' : 'Validate Backup',
                  ),
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
              _ValidationPanel(result: _validation!),
            ],
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
      _validation = null;
    });
    try {
      final backup = await widget.service.buildBackup();
      final writeResult = await widget.writer.save(backup);
      if (!mounted) {
        return;
      }
      setState(() {
        _backup = backup;
        _writeResult = writeResult;
        _isGenerating = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Backup could not be generated.\n$error';
        _isGenerating = false;
      });
    }
  }

  Future<void> _validateBackup() async {
    setState(() {
      _isValidating = true;
      _message = null;
      _validation = null;
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
      _validation = result;
      _isValidating = false;
    });
  }
}

class _RestoreNotice extends StatelessWidget {
  const _RestoreNotice();

  @override
  Widget build(BuildContext context) {
    return const InlineStatusPanel(
      title: 'Same-device restore',
      message: 'The database inside this backup is encrypted with this device workspace key. Restore requires the same local secure credential context until cross-device recovery and one-tap active database replacement are added in Backup / Restore Hardening.',
      tone: InlineStatusTone.warning,
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

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.result});

  final BackupValidationResult result;

  @override
  Widget build(BuildContext context) {
    return _ResultPanel(
      title: result.isValid ? 'Backup Is Valid' : 'Backup Has Problems',
      children: [
        if (result.isValid) ...[
          Text('${result.entries.length} manifest entries verified.'),
          const SizedBox(height: 10),
          _MetadataWrap(
            labels: [
              'Schema ${result.manifest?['schemaVersion']}',
              'App ${result.manifest?['appVersion']}',
              'Restore ${result.manifest?['restoreScope']}',
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
