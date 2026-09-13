import 'dart:typed_data';

import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/validation_result.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/events/event_details_screen.dart';
import 'package:audivance/features/events/event_dialogs.dart';
import 'package:audivance/features/events/event_service.dart';
import 'package:audivance/features/liquidation/liquidation_service.dart';
import 'package:audivance/features/organization/organization_service.dart';
import 'package:audivance/features/treasury/treasury_service.dart';
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
  Future<Uint8List> readBytes(AttachmentRef attachment) async =>
      Uint8List.fromList(const []);

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
    return EventWorkspaceSnapshot(events: [event], sourceOptions: const []);
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

class _MockLiquidationService implements LiquidationService {
  _MockLiquidationService({
    required this.event,
    required this.receipts,
    this.officers = const [],
  });

  final LiquidationEventView event;
  final List<LiquidationReceiptView> receipts;
  final List<OfficerOption> officers;

  EditReceiptCommand? lastEditCommand;
  VoidReceiptCommand? lastVoidCommand;

  @override
  Future<LiquidationWorkspaceSnapshot> loadSnapshot({
    required DateTime asOf,
  }) async {
    return LiquidationWorkspaceSnapshot(
      events: [event],
      receipts: receipts,
      reimbursementClaims: const [],
      officerOptions: officers,
    );
  }

  @override
  Future<List<OfficerOption>> listOfficerOptionsForEvent(String eventId) async {
    return officers;
  }

  @override
  Future<List<LiquidationLine>> loadReceiptLines(String receiptId) async {
    return [
      LiquidationLine(
        id: 'line-1',
        receiptId: receiptId,
        description: 'Groceries',
        quantity: 2,
        unitCost: const Money.centavos(22500),
      ),
    ];
  }

  @override
  Future<ValidationResult> editReceipt(EditReceiptCommand command) async {
    lastEditCommand = command;
    return const ValidationResult.valid();
  }

  @override
  Future<ValidationResult> voidReceipt(VoidReceiptCommand command) async {
    lastVoidCommand = command;
    return const ValidationResult.valid();
  }

  @override
  Future<List<AuditLogEntry>> loadReceiptEditHistory(String receiptId) async {
    return [
      AuditLogEntry(
        id: 'log-1',
        action: 'liquidation.post',
        targetRecordId: receiptId,
        actor: 'treasurer',
        occurredAt: DateTime(2026, 9, 1, 10, 0),
        metadata: const {},
      ),
      AuditLogEntry(
        id: 'log-2',
        action: 'liquidation.edit',
        targetRecordId: receiptId,
        actor: 'treasurer',
        occurredAt: DateTime(2026, 9, 1, 11, 30),
        metadata: const {
          'classification': 'financial',
          'reason': 'Fixed item quantity from 1 to 2',
        },
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTreasuryService implements TreasuryService {
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

  final testOfficers = [
    const OfficerOption(
      id: 'off-1',
      fullName: 'Alex Treasurer',
      position: OfficerPosition.head,
      fundCustodyBalance: Money.centavos(500000),
    ),
  ];

  final activeReceipt = LiquidationReceiptView(
    id: 'rec-1',
    eventId: 'ev-1',
    eventName: 'Leadership Camp',
    payeeOrMerchant: 'Metro Mart',
    date: DateTime(2026, 9, 1),
    evidenceNumber: 'EVID-001',
    receiptType: ReceiptType.officialReceipt,
    fundingMode: FundingMode.releasedFunds,
    accountableOfficerName: 'Alex Treasurer',
    accountableOfficerId: 'off-1',
    total: const Money.centavos(45000),
    isVoided: false,
    remarks: 'Purchased for workshop snacks',
    attachment: const AttachmentRef(
      id: 'attachment-rec-1',
      fileName: 'receipt.pdf',
      localPath: 'attachments/receipt.pdf',
    ),
  );

  final voidedReceipt = LiquidationReceiptView(
    id: 'rec-2',
    eventId: 'ev-1',
    eventName: 'Leadership Camp',
    payeeOrMerchant: 'Duplicate Store',
    date: DateTime(2026, 9, 2),
    evidenceNumber: 'EVID-002',
    receiptType: ReceiptType.salesInvoice,
    fundingMode: FundingMode.outOfPocket,
    accountableOfficerName: 'Alex Treasurer',
    accountableOfficerId: 'off-1',
    total: const Money.centavos(120000),
    isVoided: true,
    voidReason: 'Accidental double entry by officer',
  );

  Widget buildSubject({required LiquidationService liquidationService}) {
    return MaterialApp(
      home: Scaffold(
        body: EventDetailsScreen(
          eventId: 'ev-1',
          service: _FakeEventService(testEventCard),
          liquidationService: liquidationService,
          attachmentPicker: _FakeAttachmentPicker(),
          attachmentStorage: _FakeAttachmentStorageService(),
          organizationService: _FakeOrganizationService(),
          treasuryService: _FakeTreasuryService(),
        ),
      ),
    );
  }

  testWidgets(
    'renders receipt rows with void badge and remarks, and opens Edit dialog',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final liquidationService = _MockLiquidationService(
        event: testEvent,
        receipts: [activeReceipt, voidedReceipt],
        officers: testOfficers,
      );

      await tester.pumpWidget(
        buildSubject(liquidationService: liquidationService),
      );
      await tester.pumpAndSettle();

      // Scroll to Liquidation Receipts section
      await tester.scrollUntilVisible(
        find.text('Liquidation Receipts'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify both receipts appear
      expect(find.text('Metro Mart'), findsOneWidget);
      expect(find.text('Duplicate Store'), findsOneWidget);

      // Verify VOIDED badge appears for voided receipt
      expect(find.text('VOIDED'), findsOneWidget);

      // Expand active receipt row
      await tester.tap(find.text('Metro Mart'));
      await tester.pumpAndSettle();

      // Verify remarks chip appears in expanded content
      expect(
        find.text('Remarks: Purchased for workshop snacks'),
        findsOneWidget,
      );

      // Verify action buttons in expanded content
      expect(find.byKey(const Key('editReceiptButton_rec-1')), findsOneWidget);
      expect(find.byKey(const Key('voidReceiptButton_rec-1')), findsOneWidget);
      expect(
        find.byKey(const Key('receiptHistoryButton_rec-1')),
        findsOneWidget,
      );

      // Expand voided receipt row
      await tester.tap(find.text('Duplicate Store'));
      await tester.pumpAndSettle();

      // Voided receipt should show void reason container
      expect(
        find.text('Voided: Accidental double entry by officer'),
        findsOneWidget,
      );
      // Voided receipt should NOT show edit/void buttons
      expect(find.byKey(const Key('editReceiptButton_rec-2')), findsNothing);
      expect(find.byKey(const Key('voidReceiptButton_rec-2')), findsNothing);
      // But it SHOULD show Audit History button
      expect(
        find.byKey(const Key('receiptHistoryButton_rec-2')),
        findsOneWidget,
      );

      // Tap Edit Receipt button on active receipt
      await tester.tap(find.byKey(const Key('editReceiptButton_rec-1')));
      await tester.pumpAndSettle();

      // Verify EditLiquidationReceiptDialog opens
      expect(find.byType(EditLiquidationReceiptDialog), findsOneWidget);
      expect(find.text('Edit Receipt Ref #EVID-001'), findsOneWidget);
      expect(find.byKey(const Key('editReceiptPayeeField')), findsOneWidget);
      expect(find.byKey(const Key('editReceiptSubmitButton')), findsOneWidget);

      // Submit the edit
      await tester.tap(find.byKey(const Key('editReceiptSubmitButton')));
      await tester.pumpAndSettle();

      // Verify dialog closes and edit was processed
      expect(find.byType(EditLiquidationReceiptDialog), findsNothing);
      expect(liquidationService.lastEditCommand, isNotNull);
      expect(liquidationService.lastEditCommand!.receiptId, 'rec-1');
      expect(liquidationService.lastEditCommand!.payeeOrMerchant, 'Metro Mart');
    },
  );

  testWidgets('opens VoidReceiptDialog, requires reason, and submits void', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final liquidationService = _MockLiquidationService(
      event: testEvent,
      receipts: [activeReceipt],
      officers: testOfficers,
    );

    await tester.pumpWidget(
      buildSubject(liquidationService: liquidationService),
    );
    await tester.pumpAndSettle();

    // Expand active receipt row
    await tester.tap(find.text('Metro Mart'));
    await tester.pumpAndSettle();

    // Tap Void Receipt button
    await tester.tap(find.byKey(const Key('voidReceiptButton_rec-1')));
    await tester.pumpAndSettle();

    // Verify VoidReceiptDialog opens
    expect(find.byType(VoidReceiptDialog), findsOneWidget);
    expect(find.text('Void Receipt Ref #EVID-001'), findsOneWidget);
    expect(find.textContaining('This will void the receipt'), findsOneWidget);
    expect(find.byKey(const Key('voidReceiptReasonField')), findsOneWidget);

    // Attempt to submit without reason
    await tester.tap(find.byKey(const Key('voidReceiptConfirmButton')));
    await tester.pumpAndSettle();
    expect(find.text('A void reason is required.'), findsOneWidget);

    // Enter reason and submit
    await tester.enterText(
      find.byKey(const Key('voidReceiptReasonField')),
      'Duplicate transaction with incorrect amount',
    );
    await tester.tap(find.byKey(const Key('voidReceiptConfirmButton')));
    await tester.pumpAndSettle();

    // Verify dialog closes and void was processed
    expect(find.byType(VoidReceiptDialog), findsNothing);
    expect(liquidationService.lastVoidCommand, isNotNull);
    expect(liquidationService.lastVoidCommand!.receiptId, 'rec-1');
    expect(
      liquidationService.lastVoidCommand!.reason,
      'Duplicate transaction with incorrect amount',
    );
  });

  testWidgets(
    'opens ReceiptHistoryDialog and displays chronological audit trail',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final liquidationService = _MockLiquidationService(
        event: testEvent,
        receipts: [activeReceipt],
        officers: testOfficers,
      );

      await tester.pumpWidget(
        buildSubject(liquidationService: liquidationService),
      );
      await tester.pumpAndSettle();

      // Expand active receipt row
      await tester.tap(find.text('Metro Mart'));
      await tester.pumpAndSettle();

      // Tap Audit History button
      await tester.tap(find.byKey(const Key('receiptHistoryButton_rec-1')));
      await tester.pumpAndSettle();

      // Verify ReceiptHistoryDialog is displayed
      expect(find.byType(ReceiptHistoryDialog), findsOneWidget);
      expect(find.text('Receipt Audit Ledger'), findsOneWidget);
      expect(find.text('Receipt Posted'), findsOneWidget);
      expect(find.text('Receipt Edited'), findsOneWidget);
      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(
        find.text('Reason: Fixed item quantity from 1 to 2'),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptHistoryDialog), findsNothing);
    },
  );
}
