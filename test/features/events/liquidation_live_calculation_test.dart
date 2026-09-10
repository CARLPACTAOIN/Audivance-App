import 'dart:typed_data';

import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/events/event_dialogs.dart';
import 'package:audivance/features/liquidation/liquidation_service.dart';
import 'package:audivance/features/organization/organization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAttachmentPicker implements AttachmentPicker {
  @override
  bool get supportsCamera => false;

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
  }) async {
    return const AttachmentRef(
      id: 'att-1',
      fileName: 'receipt.png',
      localPath: 'attachments/liquidation/receipt.png',
      sizeBytes: 100,
      checksum: 'fakehash',
    );
  }

  @override
  Future<bool> exists(AttachmentRef attachment) async => true;

  @override
  Future<Uint8List> readBytes(AttachmentRef attachment) async => Uint8List(0);

  @override
  Future<String> resolveLocalPath(AttachmentRef attachment) async => '';

  @override
  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment) async =>
      const AttachmentIntegrityResult.present(
        checksumMatches: true,
        sizeMatches: true,
        actualChecksum: 'hash',
        actualSizeBytes: 0,
      );
}

class _FakeLiquidationService implements LiquidationService {
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
    name: 'Year-End Assembly',
    type: 'Institutional',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 9, 2),
    approvedBudgetBalance: const Money.centavos(500000),
    status: AuditEventStatus.ongoing,
    receiptCount: 0,
    pendingClaimCount: 0,
  );

  final testOfficers = [
    const OfficerOption(
      id: 'off-1',
      fullName: 'Jane Auditor',
      position: OfficerPosition.head,
      fundCustodyBalance: Money.centavos(80000),
    ),
  ];

  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: SubmitLiquidationDialog(
          service: _FakeLiquidationService(),
          event: testEvent,
          officers: testOfficers,
          attachmentPicker: _FakeAttachmentPicker(),
          attachmentStorage: _FakeAttachmentStorageService(),
          organizationService: _FakeOrganizationService(),
        ),
      ),
    );
  }

  testWidgets(
    'live calculates line subtotals, grand total, and held custody comparison',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Initial state: 1 line with qty 1, empty unit cost -> Total: PHP 0
      expect(find.byKey(const Key('liquidationSummaryCard')), findsOneWidget);
      expect(find.text('Total: PHP 0'), findsOneWidget);
      expect(find.text('Subtotal: PHP 0'), findsOneWidget);

      // Verify prefix ₱ is rendered on unit cost
      final unitCostFinder = find.byKey(
        const Key('liquidationLineUnitCostField0'),
      );
      expect(unitCostFinder, findsOneWidget);
      final textField = tester.widget<TextField>(
        find.descendant(of: unitCostFinder, matching: find.byType(TextField)),
      );
      expect(textField.decoration?.prefixText, '₱ ');
      expect(textField.decoration?.hintText, '0.00');

      // Enter quantity 3 and unit cost 150 -> subtotal should be ₱450.00
      await tester.enterText(
        find.byKey(const Key('liquidationLineQuantityField0')),
        '3',
      );
      await tester.enterText(unitCostFinder, '150');
      await tester.pumpAndSettle();

      expect(find.text('Subtotal: PHP 450'), findsOneWidget);
      expect(find.text('Total: PHP 450'), findsOneWidget);
      // Under held custody (PHP 800), no warning
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

      // Add a second line
      await tester.tap(find.byKey(const Key('liquidationAddLineButton')));
      await tester.pumpAndSettle();

      // Second line: enter quantity 2 and unit cost 250 -> subtotal ₱500.00
      // Cumulative total becomes 450 + 500 = ₱950.00
      await tester.enterText(
        find.byKey(const Key('liquidationLineQuantityField1')),
        '2',
      );
      await tester.enterText(
        find.byKey(const Key('liquidationLineUnitCostField1')),
        '250',
      );
      await tester.pumpAndSettle();

      expect(find.text('Subtotal: PHP 500'), findsOneWidget);
      expect(find.text('Total: PHP 950'), findsOneWidget);

      // 950 exceeds officer held custody (800) -> warning banner displays!
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        find.textContaining('exceeds officer held custody'),
        findsOneWidget,
      );

      // Switch funding mode to Out of Pocket -> comparison changes to approved budget balance
      final outOfPocketFinder = find.byKey(
        const Key('liquidationFundingModeOptionoutOfPocket'),
      );
      await tester.ensureVisible(outOfPocketFinder);
      await tester.tap(outOfPocketFinder);
      await tester.pumpAndSettle();

      // In out-of-pocket mode with total 950 < approved balance (5,000), custody warning disappears
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.text('Approved budget balance:'), findsOneWidget);
    },
  );
}
