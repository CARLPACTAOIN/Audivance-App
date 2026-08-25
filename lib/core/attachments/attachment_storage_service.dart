import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/attachment_ref.dart';
import '../domain/identity.dart';
import '../domain/stable_id_generator.dart';
import 'attachment_picker.dart';

class AttachmentOwner {
  const AttachmentOwner({
    required this.module,
    this.recordId,
    this.purpose,
    this.contextLabel,
    this.contextLabelProvider,
  });

  final String module;
  final StableId? recordId;
  final String? purpose;
  final String? contextLabel;
  final String? Function()? contextLabelProvider;

  String? get resolvedContextLabel =>
      contextLabelProvider?.call() ?? contextLabel;

  String get resolvedPurpose {
    if (purpose != null && purpose!.trim().isNotEmpty) {
      return purpose!.trim();
    }
    return defaultAttachmentPurposeFor(module);
  }
}

class AttachmentIntegrityResult {
  const AttachmentIntegrityResult._({
    required this.exists,
    required this.checksumMatches,
    required this.sizeMatches,
    this.actualChecksum,
    this.actualSizeBytes,
  });

  const AttachmentIntegrityResult.missing()
    : this._(exists: false, checksumMatches: false, sizeMatches: false);

  const AttachmentIntegrityResult.present({
    required bool checksumMatches,
    required bool sizeMatches,
    required String actualChecksum,
    required int actualSizeBytes,
  }) : this._(
         exists: true,
         checksumMatches: checksumMatches,
         sizeMatches: sizeMatches,
         actualChecksum: actualChecksum,
         actualSizeBytes: actualSizeBytes,
       );

  final bool exists;
  final bool checksumMatches;
  final bool sizeMatches;
  final String? actualChecksum;
  final int? actualSizeBytes;

  bool get isValid => exists && checksumMatches && sizeMatches;
}

abstract class AttachmentStorageService {
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  });

  Future<bool> exists(AttachmentRef attachment);

  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment);

  Future<String> resolveLocalPath(AttachmentRef attachment);

  Future<Uint8List> readBytes(AttachmentRef attachment);
}

class FileSystemAttachmentStorageService implements AttachmentStorageService {
  FileSystemAttachmentStorageService({
    required this.idGenerator,
    Future<Directory> Function()? baseDirectoryProvider,
  }) : _baseDirectoryProvider =
           baseDirectoryProvider ?? getApplicationSupportDirectory;

  final StableIdGenerator idGenerator;
  final Future<Directory> Function() _baseDirectoryProvider;

  @override
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  }) async {
    final bytes = await _readPickedAttachment(attachment);
    final id = idGenerator.nextId('attachment');
    final relativePath = buildNormalizedAttachmentRelativePath(
      module: owner.module,
      id: id,
      originalFileName: attachment.fileName,
      purpose: owner.purpose,
      contextLabel: owner.resolvedContextLabel,
    );
    final destinationPath = await _absolutePath(relativePath);
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(bytes, flush: true);

    return AttachmentRef(
      id: id,
      fileName: attachment.fileName,
      localPath: relativePath,
      sizeBytes: bytes.length,
      checksum: _sha256Hex(bytes),
    );
  }

  @override
  Future<bool> exists(AttachmentRef attachment) async {
    return File(await resolveLocalPath(attachment)).exists();
  }

  @override
  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment) async {
    final file = File(await resolveLocalPath(attachment));
    if (!await file.exists()) {
      return const AttachmentIntegrityResult.missing();
    }
    final bytes = await file.readAsBytes();
    final checksum = _sha256Hex(bytes);
    return AttachmentIntegrityResult.present(
      checksumMatches:
          attachment.checksum == null ||
          attachment.checksum!.trim().isEmpty ||
          attachment.checksum == checksum,
      sizeMatches:
          attachment.sizeBytes == null || attachment.sizeBytes == bytes.length,
      actualChecksum: checksum,
      actualSizeBytes: bytes.length,
    );
  }

  @override
  Future<String> resolveLocalPath(AttachmentRef attachment) async {
    return _absolutePath(attachment.localPath);
  }

  @override
  Future<Uint8List> readBytes(AttachmentRef attachment) async {
    return File(await resolveLocalPath(attachment)).readAsBytes();
  }

  Future<String> _absolutePath(String relativePath) async {
    if (p.isAbsolute(relativePath)) {
      return relativePath;
    }
    final base = await _baseDirectoryProvider();
    return p.joinAll([base.path, ...p.posix.split(relativePath)]);
  }
}

String defaultAttachmentPurposeFor(String module) {
  final normalized = sanitizeAttachmentPathSegment(module);
  return switch (normalized) {
    'treasury' => 'supporting',
    'events' => 'resolution',
    'liquidation' => 'receipt',
    _ => 'document',
  };
}

String normalizeAttachmentFileExtension(String fileName) {
  final ext = p.extension(fileName.trim()).toLowerCase();
  if (ext.isEmpty) {
    return '';
  }
  final cleanExt = ext.replaceAll(RegExp(r'[^a-z0-9.]'), '');
  return cleanExt.startsWith('.') ? cleanExt : '.$cleanExt';
}

String buildNormalizedAttachmentFileName({
  required String module,
  required String id,
  required String originalFileName,
  String? purpose,
  String? contextLabel,
}) {
  final moduleSegment = sanitizeAttachmentPathSegment(module);
  final purposeSegment = sanitizeAttachmentPathSegment(
    (purpose != null && purpose.trim().isNotEmpty)
        ? purpose
        : defaultAttachmentPurposeFor(moduleSegment),
  );
  final idSegment = sanitizeAttachmentPathSegment(id);
  final ext = normalizeAttachmentFileExtension(originalFileName);

  final segments = <String>[moduleSegment, purposeSegment];
  if (contextLabel != null && contextLabel.trim().isNotEmpty) {
    final contextSegment = sanitizeAttachmentPathSegment(contextLabel);
    if (contextSegment != 'general') {
      segments.add(contextSegment);
    }
  }
  segments.add(idSegment);

  final baseName = segments.join('-');
  return '$baseName$ext';
}

String buildNormalizedAttachmentRelativePath({
  required String module,
  required String id,
  required String originalFileName,
  String? purpose,
  String? contextLabel,
}) {
  final moduleSegment = sanitizeAttachmentPathSegment(module);
  final fileName = buildNormalizedAttachmentFileName(
    module: module,
    id: id,
    originalFileName: originalFileName,
    purpose: purpose,
    contextLabel: contextLabel,
  );
  return p.posix.join('attachments', moduleSegment, fileName);
}

String sanitizeAttachmentFileName(String fileName) {
  final baseName = p
      .basename(fileName.trim())
      .replaceAll(RegExp(r'[^A-Za-z0-9._ -]+'), '_');
  final collapsed = baseName
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();
  final withoutDots = collapsed.replaceAll(RegExp(r'^\.+'), '');
  return withoutDots.isEmpty ? 'attachment' : withoutDots;
}

String sanitizeAttachmentPathSegment(String segment) {
  final sanitized = segment
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return sanitized.isEmpty ? 'general' : sanitized;
}

Future<Uint8List> _readPickedAttachment(PickedAttachment attachment) async {
  final bytes = attachment.bytes;
  if (bytes != null) {
    return Uint8List.fromList(bytes);
  }
  final sourcePath = attachment.sourcePath;
  if (sourcePath == null || sourcePath.trim().isEmpty) {
    throw ArgumentError(
      'Picked attachment must include bytes or a source path.',
    );
  }
  return File(sourcePath).readAsBytes();
}

String _sha256Hex(List<int> bytes) {
  return crypto.sha256.convert(bytes).toString();
}
