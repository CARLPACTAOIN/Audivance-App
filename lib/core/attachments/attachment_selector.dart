import 'package:flutter/material.dart';

import '../domain/attachment_ref.dart';
import 'attachment_picker.dart';
import 'attachment_storage_service.dart';

class AttachmentSelector extends StatefulWidget {
  const AttachmentSelector({
    super.key,
    this.label = '',
    required this.owner,
    required this.picker,
    required this.storage,
    required this.onChanged,
    required this.selectedAttachment,
    this.selectButtonKey,
    this.clearButtonKey,
    this.isEnabled = true,
  });

  final String label;
  final AttachmentOwner owner;
  final AttachmentPicker picker;
  final AttachmentStorageService storage;
  final ValueChanged<AttachmentRef?> onChanged;
  final AttachmentRef? selectedAttachment;
  final Key? selectButtonKey;
  final Key? clearButtonKey;
  final bool isEnabled;

  @override
  State<AttachmentSelector> createState() => _AttachmentSelectorState();
}

class _AttachmentSelectorState extends State<AttachmentSelector> {
  var _isPicking = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final attachment = widget.selectedAttachment;
    final theme = Theme.of(context);
    final borderColor = _error == null
        ? theme.colorScheme.outline
        : theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    attachment == null
                        ? Icons.attach_file
                        : Icons.insert_drive_file_outlined,
                    color: attachment == null
                        ? const Color(0xFF64748B)
                        : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttachmentSummary(attachment: attachment),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    key: widget.selectButtonKey,
                    onPressed: widget.isEnabled && !_isPicking
                        ? _pickAttachment
                        : null,
                    icon: _isPicking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      attachment == null ? 'Select File' : 'Replace',
                    ),
                  ),
                  if (attachment != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      key: widget.clearButtonKey,
                      tooltip: 'Remove selected file',
                      onPressed: widget.isEnabled && !_isPicking
                          ? () {
                              setState(() {
                                _error = null;
                              });
                              widget.onChanged(null);
                            }
                          : null,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }

  Future<void> _pickAttachment() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final picked = await widget.picker.pickAttachment();
      if (picked == null) {
        return;
      }
      final imported = await widget.storage.importAttachment(
        attachment: picked,
        owner: widget.owner,
      );
      widget.onChanged(imported);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Attachment could not be imported: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }
}

class _AttachmentSummary extends StatelessWidget {
  const _AttachmentSummary({required this.attachment});

  final AttachmentRef? attachment;

  @override
  Widget build(BuildContext context) {
    final attachment = this.attachment;
    if (attachment == null) {
      return const Text('No file selected.');
    }
    final details = [
      attachment.localPath,
      if (attachment.sizeBytes != null) '${attachment.sizeBytes} B',
    ];
    final checksum = attachment.checksum;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attachment.fileName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(details.join(' - '), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (checksum != null) ...[
          const SizedBox(height: 4),
          Tooltip(
            message: 'SHA-256 $checksum',
            child: Text(
              'SHA-256 ${_shortChecksum(checksum)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

String _shortChecksum(String checksum) {
  if (checksum.length <= 16) {
    return checksum;
  }
  return '${checksum.substring(0, 12)}...${checksum.substring(checksum.length - 4)}';
}
