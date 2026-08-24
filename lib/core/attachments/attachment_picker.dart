import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedAttachment {
  const PickedAttachment({required this.fileName, this.sourcePath, this.bytes})
    : assert(sourcePath != null || bytes != null);

  final String fileName;
  final String? sourcePath;
  final Uint8List? bytes;
}

abstract class AttachmentPicker {
  Future<PickedAttachment?> pickAttachment();
}

class FilePickerAttachmentPicker implements AttachmentPicker {
  const FilePickerAttachmentPicker();

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
}
