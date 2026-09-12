import 'dart:typed_data';

import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_selector.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/events/event_details_screen.dart';
import 'package:audivance/features/events/event_service.dart';
import 'package:audivance/features/liquidation/liquidation_service.dart';
import 'package:audivance/features/organization/organization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAttachmentPicker implements AttachmentPicker {
  @override
  bool get supportsCamera => true;

  @override
  Future<PickedAttachment?> pickAttachment() async => null;

  @override
  Future<PickedAttachment?> captureCamera() async => null;
}

class _FakeAttachmentStorageService implements AttachmentStorageService {
  @override
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  }) => throw UnimplementedError();

  @override
  Future<bool> exists(AttachmentRef attachment) async => true;

  @override
  Future<Uint8List> readBytes(AttachmentRef attachment) async {
    // Return minimal valid 1x1 transparent PNG bytes so Image.memory decodes cleanly
    return Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
  }

  @override
  Future<String> resolveLocalPath(AttachmentRef attachment) async =>
      attachment.localPath;

  @override
  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment) async =>
      const AttachmentIntegrityResult.present(
        checksumMatches: true,
        sizeMatches: true,
        actualChecksum: 'hash',
        actualSizeBytes: 67,
      );
}

class _FakeEventService implements EventService {
  _FakeEventService(this.event);

  final EventCardView event;

  @override
  Future<EventWorkspaceSnapshot> loadSnapshot({required DateTime asOf}) async {
    return EventWorkspaceSnapshot(
      events: [event],
      sourceOptions: const [],
    );
  }

  @override
  Future<BudgetActualSnapshot> loadBudgetActual(
    String eventId, {
    required DateTime asOf,
  }) async {
    return const BudgetActualSnapshot(
      eventId: 'ev-1',
      eventName: 'Leadership Camp',
      status: AuditEventStatus.ongoing,
      budget: Money.centavos(1500000),
      approvedBudgetBalance: Money.centavos(1500000),
      actual: Money.centavos(45000),
      variance: Money.centavos(1455000),
      pendingReimbursementTotal: Money.zero,
      paidReimbursementTotal: Money.zero,
      utilizationBasisPoints: 300,
      health: BudgetHealth.healthy,
      reviews: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLiquidationService implements LiquidationService {
  _FakeLiquidationService({
    required this.event,
    required this.receipts,
  });

  final LiquidationEventView event;
  final List<LiquidationReceiptView> receipts;

  @override
  Future<LiquidationWorkspaceSnapshot> loadSnapshot({
    required DateTime asOf,
  }) async {
    return LiquidationWorkspaceSnapshot(
      events: [event],
      receipts: receipts,
      reimbursementClaims: const [],
      officerOptions: const [],
    );
  }

  @override
  Future<List<OfficerOption>> listOfficerOptionsForEvent(String eventId) async {
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationService implements OrganizationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testEvent = LiquidationEventView(
    id: 'ev-1',
    name: 'Leadership Camp',
    type: 'Leadership',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 9, 3),
    approvedBudgetBalance: const Money.centavos(1500000),
    status: AuditEventStatus.ongoing,
    receiptCount: 2,
    pendingClaimCount: 0,
  );

  const imageAttachment = AttachmentRef(
    id: 'att-1',
    fileName: 'grocery_receipt.png',
    localPath: 'attachments/liquidation/grocery_receipt.png',
    sizeBytes: 1024,
    checksum: 'abc123',
  );

  const pdfAttachment = AttachmentRef(
    id: 'att-2',
    fileName: 'venue_contract.pdf',
    localPath: 'attachments/liquidation/venue_contract.pdf',
    sizeBytes: 2048,
    checksum: 'def456',
  );

  final receipts = [
    LiquidationReceiptView(
      id: 'rec-1',
      eventId: 'ev-1',
      eventName: 'Leadership Camp',
      payeeOrMerchant: 'Metro Mart',
      date: DateTime(2026, 9, 1),
      evidenceNumber: 'EVID-001',
      receiptType: ReceiptType.officialReceipt,
      fundingMode: FundingMode.releasedFunds,
      accountableOfficerName: 'Alex Treasurer',
      total: const Money.centavos(45000),
      attachment: imageAttachment,
    ),
    LiquidationReceiptView(
      id: 'rec-2',
      eventId: 'ev-1',
      eventName: 'Leadership Camp',
      payeeOrMerchant: 'Grand Hall Co',
      date: DateTime(2026, 9, 2),
      evidenceNumber: 'EVID-002',
      receiptType: ReceiptType.salesInvoice,
      fundingMode: FundingMode.outOfPocket,
      accountableOfficerName: 'Alex Treasurer',
      total: const Money.centavos(120000),
      attachment: pdfAttachment,
    ),
  ];

  final testEventCard = EventCardView(
    id: 'ev-1',
    name: 'Leadership Camp',
    type: 'Leadership',
    semester: '1st Semester',
    schoolYear: '2026-2027',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 9, 3),
    resolutionNumber: 'RES-001',
    budget: const Money.centavos(1500000),
    approvedBudgetBalance: const Money.centavos(1500000),
    status: AuditEventStatus.ongoing,
  );

  Widget buildSubject({
    required AttachmentStorageService storage,
    required LiquidationService liquidationService,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EventDetailsScreen(
          eventId: 'ev-1',
          service: _FakeEventService(testEventCard),
          liquidationService: liquidationService,
          attachmentPicker: _FakeAttachmentPicker(),
          attachmentStorage: storage,
          organizationService: _FakeOrganizationService(),
        ),
      ),
    );
  }

  testWidgets(
    'renders compact thumbnail for image receipt and opens quick preview inspection modal',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = _FakeAttachmentStorageService();
      final liquidationService = _FakeLiquidationService(
        event: testEvent,
        receipts: receipts,
      );

      await tester.pumpWidget(
        buildSubject(
          storage: storage,
          liquidationService: liquidationService,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Liquidation Receipts section
      await tester.scrollUntilVisible(
        find.text('Liquidation Receipts'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2 receipts'), findsOneWidget);

      // Verify image receipt row (rec-1) has AttachmentThumbnail
      final thumbnailFinder = find.byKey(const Key('receiptThumbnail_rec-1'));
      expect(thumbnailFinder, findsOneWidget);

      // Verify PDF receipt row (rec-2) has document icon
      expect(
        find.byKey(const Key('receiptDocumentIcon_rec-2')),
        findsOneWidget,
      );

      // Tap on the image receipt thumbnail to open quick preview modal
      final thumbnailTapFinder = find.byKey(
        const Key('receiptThumbnailTap_rec-1'),
      );
      expect(thumbnailTapFinder, findsOneWidget);
      await tester.tap(thumbnailTapFinder);
      await tester.pumpAndSettle();

      // Verify AttachmentImagePreviewDialog is visible
      expect(find.byType(AttachmentImagePreviewDialog), findsOneWidget);
      expect(find.text('grocery_receipt.png'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const Key('attachmentPreviewCloseButton')), findsOneWidget);

      // Close the preview modal
      await tester.tap(find.byKey(const Key('attachmentPreviewCloseButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentImagePreviewDialog), findsNothing);

      // Expand the image receipt row to view expanded content
      await tester.tap(find.text('Metro Mart'));
      await tester.pumpAndSettle();

      // Verify attachment chip is displayed in expanded content
      final chipFinder = find.byKey(const Key('receiptAttachmentChip_rec-1'));
      expect(chipFinder, findsOneWidget);
      expect(find.textContaining('grocery_receipt.png'), findsOneWidget);

      // Tap on the expanded chip to open preview again
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentImagePreviewDialog), findsOneWidget);
    },
  );
}
