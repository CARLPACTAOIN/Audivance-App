import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'export_service.dart';

abstract class ExportPackageWriter {
  Future<ExportWriteResult> save(ExportArchivePackage package);
}

class FilePickerExportPackageWriter implements ExportPackageWriter {
  const FilePickerExportPackageWriter();

  @override
  Future<ExportWriteResult> save(ExportArchivePackage package) async {
    final destination = await FilePicker.saveFile(
      fileName: package.fileName,
      bytes: package.bytes,
      mimeType: 'application/zip',
    );
    return ExportWriteResult(
      fileName: package.fileName,
      bytes: package.bytes,
      byteLength: package.byteLength,
      checksum: package.checksum,
      destinationUri: destination,
    );
  }
}

class ExportWriteResult {
  const ExportWriteResult({
    required this.fileName,
    required this.bytes,
    required this.byteLength,
    required this.checksum,
    this.destinationUri,
  });

  final String fileName;
  final Uint8List bytes;
  final int byteLength;
  final String checksum;
  final Uri? destinationUri;

  bool get wasSaved => destinationUri != null;
}
