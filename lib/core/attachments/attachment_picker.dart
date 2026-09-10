import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickedAttachment {
  const PickedAttachment({required this.fileName, this.sourcePath, this.bytes})
    : assert(sourcePath != null || bytes != null);

  final String fileName;
  final String? sourcePath;
  final Uint8List? bytes;
}

abstract class AttachmentPicker {
  Future<PickedAttachment?> pickAttachment();

  /// Captures a photo using the device camera (e.g. for receipts).
  /// Falls back to [pickAttachment] if not supported or not implemented.
  Future<PickedAttachment?> captureCamera() => pickAttachment();

  /// Whether camera scanning/capture is supported in this environment.
  bool get supportsCamera => false;
}

class FilePickerAttachmentPicker implements AttachmentPicker {
  const FilePickerAttachmentPicker({
    this.imagePicker,
    this.enableCamera,
    this.maxImageDimension = 1920,
    this.imageQuality = 85,
  });

  final ImagePicker? imagePicker;
  final bool? enableCamera;
  final double maxImageDimension;
  final int imageQuality;

  @override
  bool get supportsCamera {
    if (enableCamera != null) {
      return enableCamera!;
    }
    if (kIsWeb) {
      return true;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<PickedAttachment?> pickAttachment() async {
    final file = await FilePicker.pickFile();
    if (file == null) {
      return null;
    }
    final sourcePath = file.path;
    return PickedAttachment(
      fileName: file.name,
      sourcePath: sourcePath,
      bytes: sourcePath == null ? await file.readAsBytes() : null,
    );
  }

  @override
  Future<PickedAttachment?> captureCamera() async {
    final picker = imagePicker ?? ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxImageDimension,
      maxHeight: maxImageDimension,
      imageQuality: imageQuality,
    );
    if (xFile == null) {
      return null;
    }
    final name = xFile.name.isNotEmpty
        ? xFile.name
        : 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final sourcePath = xFile.path;
    return PickedAttachment(
      fileName: name,
      sourcePath: sourcePath,
      bytes: sourcePath.isEmpty ? await xFile.readAsBytes() : null,
    );
  }
}
