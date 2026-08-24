import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'backup_service.dart';

typedef BackupRestoreHandler = Future<RestoreExecutionResult> Function(
  PickedBackupPackage package,
);

abstract class BackupPackageWriter {
  Future<BackupWriteResult> save(BackupPackage package);
}

class FilePickerBackupPackageWriter implements BackupPackageWriter {
  const FilePickerBackupPackageWriter();

  @override
  Future<BackupWriteResult> save(BackupPackage package) async {
    final destination = await FilePicker.saveFile(
      fileName: package.fileName,
      bytes: package.bytes,
      mimeType: 'application/zip',
    );
    return BackupWriteResult(
      fileName: package.fileName,
      bytes: package.bytes,
      byteLength: package.byteLength,
      checksum: package.checksum,
      destinationUri: destination,
    );
  }
}

abstract class BackupPackageReader {
  Future<PickedBackupPackage?> pickBackup();
}

class FilePickerBackupPackageReader implements BackupPackageReader {
  const FilePickerBackupPackageReader();

  @override
  Future<PickedBackupPackage?> pickBackup() async {
    final file = await FilePicker.pickFile();
    if (file == null) {
      return null;
    }
    return PickedBackupPackage(
      fileName: file.name,
      bytes: await file.readAsBytes(),
    );
  }
}

class PickedBackupPackage {
  const PickedBackupPackage({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

class BackupWriteResult {
  const BackupWriteResult({
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
