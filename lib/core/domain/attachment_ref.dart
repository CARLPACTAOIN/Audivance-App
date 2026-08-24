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
}
