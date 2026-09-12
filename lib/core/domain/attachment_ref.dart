import 'identity.dart';

class AttachmentRef {
  const AttachmentRef({
    required this.id,
    required this.fileName,
    required this.localPath,
    this.sizeBytes,
    this.checksum,
  });

  final StableId id;
  final String fileName;
  final String localPath;
  final int? sizeBytes;
  final String? checksum;

  bool get isImage {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}
