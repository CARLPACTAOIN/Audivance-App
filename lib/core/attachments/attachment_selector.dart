import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/attachment_ref.dart';
import 'attachment_picker.dart';
import 'attachment_storage_service.dart';

enum AttachmentSourceChoice { camera, file }

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
    this.cameraOptionKey,
    this.fileOptionKey,
    this.isEnabled = true,
    this.allowCamera = true,
  });

  final String label;
  final AttachmentOwner owner;
  final AttachmentPicker picker;
  final AttachmentStorageService storage;
  final ValueChanged<AttachmentRef?> onChanged;
  final AttachmentRef? selectedAttachment;
  final Key? selectButtonKey;
  final Key? clearButtonKey;
  final Key? cameraOptionKey;
  final Key? fileOptionKey;
  final bool isEnabled;
  final bool allowCamera;

  @override
  State<AttachmentSelector> createState() => _AttachmentSelectorState();
}

class _AttachmentSelectorState extends State<AttachmentSelector> {
  var _isPicking = false;
  String? _error;

  Key get _cameraKey {
    if (widget.cameraOptionKey != null) return widget.cameraOptionKey!;
    final parentKey = widget.selectButtonKey;
    if (parentKey is ValueKey<String>) {
      return Key('${parentKey.value}CameraOption');
    }
    return const Key('attachmentSourceCameraButton');
  }

  Key get _fileKey {
    if (widget.fileOptionKey != null) return widget.fileOptionKey!;
    final parentKey = widget.selectButtonKey;
    if (parentKey is ValueKey<String>) {
      return Key('${parentKey.value}FileOption');
    }
    return const Key('attachmentSourceFileButton');
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.selectedAttachment;
    final theme = Theme.of(context);
    final borderColor = _error == null
        ? theme.colorScheme.outline
        : theme.colorScheme.error;
    final isImage = attachment != null && _isImageFile(attachment.fileName);

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (isImage)
                    _AttachmentThumbnail(
                      attachment: attachment,
                      storage: widget.storage,
                      onTap: () => _showImagePreview(context, attachment),
                    )
                  else
                    Icon(
                      attachment == null
                          ? Icons.attach_file
                          : (attachment.fileName.toLowerCase().endsWith('.pdf')
                                ? Icons.picture_as_pdf_outlined
                                : Icons.insert_drive_file_outlined),
                      color: attachment == null
                          ? const Color(0xFF64748B)
                          : (attachment.fileName.toLowerCase().endsWith('.pdf')
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF38BDF8)),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttachmentSummary(
                      attachment: attachment,
                      isImage: isImage,
                      onPreviewRequested: isImage
                          ? () => _showImagePreview(context, attachment)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    key: widget.selectButtonKey,
                    onPressed: widget.isEnabled && !_isPicking
                        ? _handleSelectPressed
                        : null,
                    icon: _isPicking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            widget.allowCamera && widget.picker.supportsCamera
                                ? Icons.add_a_photo_outlined
                                : Icons.upload_file_outlined,
                          ),
                    label: Text(attachment == null ? 'Select File' : 'Replace'),
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

  Future<void> _handleSelectPressed() async {
    if (widget.allowCamera && widget.picker.supportsCamera) {
      final choice = await showModalBottomSheet<AttachmentSourceChoice>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 540),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) => _AttachmentSourceSheet(
          title: widget.label.isNotEmpty ? widget.label : 'Select Attachment',
          cameraOptionKey: _cameraKey,
          fileOptionKey: _fileKey,
        ),
      );
      if (choice == null) {
        return;
      }
      await _pickAttachment(choice);
    } else {
      await _pickAttachment(AttachmentSourceChoice.file);
    }
  }

  Future<void> _pickAttachment([
    AttachmentSourceChoice choice = AttachmentSourceChoice.file,
  ]) async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final PickedAttachment? picked;
      if (choice == AttachmentSourceChoice.camera) {
        picked = await widget.picker.captureCamera();
      } else {
        picked = await widget.picker.pickAttachment();
      }
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

  void _showImagePreview(BuildContext context, AttachmentRef attachment) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attachment.fileName,
                          style: Theme.of(dialogContext).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        key: const Key('attachmentPreviewCloseButton'),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: FutureBuilder<Uint8List>(
                      future: widget.storage.readBytes(attachment),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'Could not display image preview.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text(
                                  'Could not decode image.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentSourceSheet extends StatelessWidget {
  const _AttachmentSourceSheet({
    required this.title,
    required this.cameraOptionKey,
    required this.fileOptionKey,
  });

  final String title;
  final Key cameraOptionKey;
  final Key fileOptionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose how you want to add this document',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            KeyedSubtree(
              key: const Key('attachmentSourceCameraButtonSubtree'),
              child: ListTile(
                key: cameraOptionKey,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Take Photo / Scan Receipt',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Capture physical receipt with camera'),
                onTap: () =>
                    Navigator.of(context).pop(AttachmentSourceChoice.camera),
              ),
            ),
            KeyedSubtree(
              key: const Key('attachmentSourceFileButtonSubtree'),
              child: ListTile(
                key: fileOptionKey,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Browse Files & PDFs',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Select PDF or photo from device storage'),
                onTap: () =>
                    Navigator.of(context).pop(AttachmentSourceChoice.file),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({
    required this.attachment,
    required this.storage,
    required this.onTap,
  });

  final AttachmentRef attachment;
  final AttachmentStorageService storage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: storage.readBytes(attachment),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.square(
            dimension: 48,
            child: Center(
              child: SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF64748B),
          );
        }
        final bytes = snapshot.data!;
        return Tooltip(
          message: 'Tap to view full receipt',
          child: InkWell(
            key: const Key('attachmentThumbnailTap'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_outlined,
                      size: 24,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentSummary extends StatelessWidget {
  const _AttachmentSummary({
    required this.attachment,
    this.isImage = false,
    this.onPreviewRequested,
  });

  final AttachmentRef? attachment;
  final bool isImage;
  final VoidCallback? onPreviewRequested;

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
        Row(
          children: [
            Expanded(
              child: Text(
                attachment.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (isImage && onPreviewRequested != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onPreviewRequested,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
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

bool _isImageFile(String fileName) {
  final lower = fileName.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}

String _shortChecksum(String checksum) {
  if (checksum.length <= 16) {
    return checksum;
  }
  return '${checksum.substring(0, 12)}...${checksum.substring(checksum.length - 4)}';
}
