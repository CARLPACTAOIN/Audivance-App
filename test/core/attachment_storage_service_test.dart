import 'dart:io';
import 'dart:typed_data';

import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late _TestIdGenerator idGenerator;
  late FileSystemAttachmentStorageService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audivance-attachments-');
    idGenerator = _TestIdGenerator();
    service = FileSystemAttachmentStorageService(
      idGenerator: idGenerator,
      baseDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sanitizes attachment filenames and owner path segments', () {
    expect(sanitizeAttachmentFileName('../ OR #100.pdf'), 'OR _100.pdf');
    expect(sanitizeAttachmentFileName('...'), 'attachment');
    expect(
      sanitizeAttachmentPathSegment('Treasury Sources'),
      'treasury-sources',
    );
    expect(sanitizeAttachmentPathSegment(''), 'general');
  });

  test('imports picked bytes into app-private attachment storage', () async {
    final attachment = await service.importAttachment(
      attachment: PickedAttachment(
        fileName: 'receipt.pdf',
        bytes: Uint8List.fromList('hello'.codeUnits),
      ),
      owner: const AttachmentOwner(module: 'liquidation'),
    );

    expect(attachment.id, 'attachment-1');
    expect(attachment.fileName, 'receipt.pdf');
    expect(
      attachment.localPath,
      'attachments/liquidation/attachment-1-receipt.pdf',
    );
    expect(attachment.sizeBytes, 5);
    expect(
      attachment.checksum,
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
    expect(await service.exists(attachment), isTrue);
    expect(
      await File(await service.resolveLocalPath(attachment)).readAsString(),
      'hello',
    );
  });

  test(
    'imports source files and gives duplicate filenames unique paths',
    () async {
      final source = File('${tempDir.path}${Platform.pathSeparator}source.txt');
      await source.writeAsString('source-file');

      final first = await service.importAttachment(
        attachment: PickedAttachment(
          fileName: 'support.pdf',
          sourcePath: source.path,
        ),
        owner: const AttachmentOwner(module: 'treasury'),
      );
      final second = await service.importAttachment(
        attachment: PickedAttachment(
          fileName: 'support.pdf',
          sourcePath: source.path,
        ),
        owner: const AttachmentOwner(module: 'treasury'),
      );

      expect(first.localPath, isNot(second.localPath));
      expect(await service.exists(first), isTrue);
      expect(await service.exists(second), isTrue);
    },
  );

  test('detects missing files and checksum mismatches', () async {
    const missing = AttachmentRef(
      id: 'missing',
      fileName: 'missing.pdf',
      localPath: 'attachments/events/missing.pdf',
      sizeBytes: 10,
      checksum: 'abc',
    );
    expect((await service.verify(missing)).exists, isFalse);

    final imported = await service.importAttachment(
      attachment: PickedAttachment(
        fileName: 'resolution.pdf',
        bytes: Uint8List.fromList('original'.codeUnits),
      ),
      owner: const AttachmentOwner(module: 'events'),
    );
    await File(await service.resolveLocalPath(imported))
        .writeAsString('changed');

    final integrity = await service.verify(imported);
    expect(integrity.exists, isTrue);
    expect(integrity.checksumMatches, isFalse);
    expect(integrity.sizeMatches, isFalse);
  });
}

class _TestIdGenerator implements StableIdGenerator {
  var _counter = 0;

  @override
  StableId nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }
}
