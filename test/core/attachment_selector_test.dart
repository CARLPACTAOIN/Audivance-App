import 'dart:typed_data';

import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_selector.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAttachmentPicker implements AttachmentPicker {
  _MockAttachmentPicker({this.cameraSupported = false});

  bool cameraSupported;
  int pickCallCount = 0;
  int cameraCallCount = 0;

  @override
  bool get supportsCamera => cameraSupported;

  @override
  Future<PickedAttachment?> pickAttachment() async {
    pickCallCount++;
    return PickedAttachment(
      fileName: 'uploaded_doc.pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
  }

  @override
  Future<PickedAttachment?> captureCamera() async {
    cameraCallCount++;
    return PickedAttachment(
      fileName: 'scanned_receipt.jpg',
      bytes: Uint8List.fromList([255, 216, 255, 224]),
    );
  }
}

class _MockAttachmentStorageService implements AttachmentStorageService {
  @override
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  }) async {
    return AttachmentRef(
      id: 'att-${attachment.fileName}',
      fileName: attachment.fileName,
      localPath: 'attachments/${attachment.fileName}',
      sizeBytes: attachment.bytes?.length ?? 100,
      checksum: 'abc1234567890def1234567890',
    );
  }

  @override
  Future<bool> exists(AttachmentRef attachment) async => true;

  @override
  Future<Uint8List> readBytes(AttachmentRef attachment) async {
    return attachment.fileName.endsWith('.jpg')
        ? Uint8List.fromList([255, 216, 255, 224])
        : Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<String> resolveLocalPath(AttachmentRef attachment) async {
    return attachment.localPath;
  }

  @override
  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment) async {
    return AttachmentIntegrityResult.present(
      checksumMatches: true,
      sizeMatches: true,
      actualChecksum: attachment.checksum ?? 'abc',
      actualSizeBytes: attachment.sizeBytes ?? 10,
    );
  }
}

void main() {
  Widget buildTestSubject({
    required AttachmentPicker picker,
    required AttachmentStorageService storage,
    required ValueChanged<AttachmentRef?> onChanged,
    AttachmentRef? selectedAttachment,
    bool allowCamera = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AttachmentSelector(
            label: 'Receipt attachment',
            owner: const AttachmentOwner(
              module: 'liquidation',
              purpose: 'receipt',
            ),
            picker: picker,
            storage: storage,
            selectedAttachment: selectedAttachment,
            onChanged: onChanged,
            allowCamera: allowCamera,
            selectButtonKey: const Key('receiptSelectButton'),
            clearButtonKey: const Key('receiptClearButton'),
          ),
        ),
      ),
    );
  }

  testWidgets('directly calls pickAttachment when camera is not supported', (
    tester,
  ) async {
    final picker = _MockAttachmentPicker(cameraSupported: false);
    final storage = _MockAttachmentStorageService();
    AttachmentRef? selected;

    await tester.pumpWidget(
      buildTestSubject(
        picker: picker,
        storage: storage,
        onChanged: (att) => selected = att,
      ),
    );

    await tester.tap(find.byKey(const Key('receiptSelectButton')));
    await tester.pumpAndSettle();

    expect(picker.pickCallCount, 1);
    expect(picker.cameraCallCount, 0);
    expect(selected?.fileName, 'uploaded_doc.pdf');
  });

  testWidgets(
    'shows bottom sheet when camera is supported and allows camera capture',
    (tester) async {
      final picker = _MockAttachmentPicker(cameraSupported: true);
      final storage = _MockAttachmentStorageService();
      AttachmentRef? selected;

      await tester.pumpWidget(
        buildTestSubject(
          picker: picker,
          storage: storage,
          onChanged: (att) => selected = att,
        ),
      );

      // Tap select button
      await tester.tap(find.byKey(const Key('receiptSelectButton')));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible with options
      expect(find.text('Take Photo / Scan Receipt'), findsOneWidget);
      expect(find.text('Browse Files & PDFs'), findsOneWidget);

      // Select camera option
      await tester.tap(find.text('Take Photo / Scan Receipt'));
      await tester.pumpAndSettle();

      expect(picker.cameraCallCount, 1);
      expect(picker.pickCallCount, 0);
      expect(selected?.fileName, 'scanned_receipt.jpg');
    },
  );

  testWidgets(
    'allows choosing file from bottom sheet when camera is supported',
    (tester) async {
      final picker = _MockAttachmentPicker(cameraSupported: true);
      final storage = _MockAttachmentStorageService();
      AttachmentRef? selected;

      await tester.pumpWidget(
        buildTestSubject(
          picker: picker,
          storage: storage,
          onChanged: (att) => selected = att,
        ),
      );

      await tester.tap(find.byKey(const Key('receiptSelectButton')));
      await tester.pumpAndSettle();

      // Select file option
      await tester.tap(find.text('Browse Files & PDFs'));
      await tester.pumpAndSettle();

      expect(picker.pickCallCount, 1);
      expect(picker.cameraCallCount, 0);
      expect(selected?.fileName, 'uploaded_doc.pdf');
    },
  );

  testWidgets(
    'renders thumbnail for image receipt and opens full-size preview',
    (tester) async {
      final picker = _MockAttachmentPicker(cameraSupported: true);
      final storage = _MockAttachmentStorageService();
      const imageAttachment = AttachmentRef(
        id: 'att-receipt-1',
        fileName: 'grocery_receipt.jpg',
        localPath: 'attachments/grocery_receipt.jpg',
        sizeBytes: 154200,
        checksum: '1234567890abcdef1234567890abcdef',
      );

      await tester.pumpWidget(
        buildTestSubject(
          picker: picker,
          storage: storage,
          selectedAttachment: imageAttachment,
          onChanged: (_) {},
        ),
      );

      await tester.pumpAndSettle();

      // Thumbnail tap target exists
      expect(find.byKey(const Key('attachmentThumbnailTap')), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      // Tap to open full preview
      await tester.tap(find.byKey(const Key('attachmentThumbnailTap')));
      await tester.pumpAndSettle();

      // Dialog is open with image viewer and close button
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(
        find.byKey(const Key('attachmentPreviewCloseButton')),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.byKey(const Key('attachmentPreviewCloseButton')));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
    },
  );

  testWidgets(
    'renders without overflow in narrow constraints (e.g. width 228.0)',
    (tester) async {
      final picker = _MockAttachmentPicker(cameraSupported: true);
      final storage = _MockAttachmentStorageService();
      AttachmentRef? cleared;

      const imageAttachment = AttachmentRef(
        id: 'att-receipt-narrow',
        fileName: 'official_receipt_march_2026.jpg',
        localPath: 'attachments/official_receipt_march_2026.jpg',
        sizeBytes: 98450,
        checksum: 'abcdef1234567890abcdef1234567890',
      );

      // 1. Narrow width without attachment (empty state at 228px)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 228.0,
                child: AttachmentSelector(
                  label: 'Receipt attachment',
                  owner: const AttachmentOwner(
                    module: 'liquidation',
                    purpose: 'receipt',
                  ),
                  picker: picker,
                  storage: storage,
                  selectedAttachment: null,
                  onChanged: (_) {},
                  selectButtonKey: const Key('receiptSelectButtonNarrow'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('receiptSelectButtonNarrow')),
        findsOneWidget,
      );
      expect(find.text('No file selected.'), findsOneWidget);

      // 2. Narrow width with image attachment (populated state with replace & clear at 228px)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 228.0,
                child: AttachmentSelector(
                  label: 'Receipt attachment',
                  owner: const AttachmentOwner(
                    module: 'liquidation',
                    purpose: 'receipt',
                  ),
                  picker: picker,
                  storage: storage,
                  selectedAttachment: imageAttachment,
                  onChanged: (att) => cleared = att,
                  selectButtonKey: const Key('receiptSelectButtonNarrow'),
                  clearButtonKey: const Key('receiptClearButtonNarrow'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('attachmentThumbnailTap')), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(
        find.byKey(const Key('receiptSelectButtonNarrow')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('receiptClearButtonNarrow')), findsOneWidget);

      // Test tapping clear button in compact layout
      await tester.tap(find.byKey(const Key('receiptClearButtonNarrow')));
      await tester.pumpAndSettle();
      expect(cleared, isNull);
    },
  );
}
