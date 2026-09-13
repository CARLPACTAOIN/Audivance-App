import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/audit/domain/audit_rules.dart';
import 'package:audivance/features/liquidation/domain/receipt_edit_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TreasuryRules', () {
    test('rejects Add Fund without supporting attachment', () {
      final result = TreasuryRules.validateAddFund(
        amount: Money.php(1000),
        supportingAttachment: null,
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('supporting document attachment'));
    });
  });

  group('EventRules', () {
    test('rejects budget allocations that do not equal the event budget', () {
      final result = EventRules.validateEventBudget(
        event: _event(budget: Money.php(10000), attachment: _attachment),
        allocations: [
          EventFundingAllocation(
            eventId: 'event-1',
            fundSourceId: 'source-1',
            amount: Money.php(6000),
          ),
        ],
        sourceBalances: {'source-1': Money.php(10000)},
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('must equal the event budget'));
    });

    test('rejects budget allocations that overdraw source balances', () {
      final result = EventRules.validateEventBudget(
        event: _event(budget: Money.php(10000), attachment: _attachment),
        allocations: [
          EventFundingAllocation(
            eventId: 'event-1',
            fundSourceId: 'source-1',
            amount: Money.php(10000),
          ),
        ],
        sourceBalances: {'source-1': Money.php(9000)},
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('insufficient balance'));
    });

    test('rejects events without resolution attachment', () {
      final result = EventRules.validateEventBudget(
        event: _event(budget: Money.php(10000)),
        allocations: [
          EventFundingAllocation(
            eventId: 'event-1',
            fundSourceId: 'source-1',
            amount: Money.php(10000),
          ),
        ],
        sourceBalances: {'source-1': Money.php(10000)},
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('resolution attachment'));
    });

    test('rejects budget increase when source balance is insufficient', () {
      final result = EventRules.validateBudgetIncrease(
        increaseAmount: Money.php(12000),
        sourceBalance: Money.php(11000),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.summary,
        contains('source treasury balance is insufficient'),
      );
    });

    test(
      'rejects budget decrease when approved budget balance is insufficient',
      () {
        final result = EventRules.validateBudgetDecrease(
          decreaseAmount: Money.php(6000),
          approvedBudgetBalance: Money.php(5000),
        );

        expect(result.isInvalid, isTrue);
        expect(
          result.summary,
          contains('Approved Budget balance is insufficient'),
        );
      },
    );

    test('calculates event status from end date and liquidation state', () {
      final event = _event(
        endDate: DateTime(2026, 8, 10),
        attachment: _attachment,
      );

      expect(
        EventRules.calculateStatus(event: event, asOf: DateTime(2026, 8, 10)),
        AuditEventStatus.ongoing,
      );
      expect(
        EventRules.calculateStatus(event: event, asOf: DateTime(2026, 8, 11)),
        AuditEventStatus.forLiquidation,
      );
      expect(
        EventRules.calculateStatus(event: event, asOf: DateTime(2026, 8, 17)),
        AuditEventStatus.due,
      );
      expect(
        EventRules.calculateStatus(
          event: _event(isLiquidated: true, attachment: _attachment),
          asOf: DateTime(2026, 8, 17),
        ),
        AuditEventStatus.liquidated,
      );
    });
  });

  group('FundMovementRules', () {
    test('rejects manual movement for system-only types', () {
      final result = FundMovementRules.validateManualMovement(
        type: FundMovementType.budgetAllocation,
        amount: Money.php(1000),
        availableBalance: Money.php(2000),
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('Manual fund movements are limited'));
    });

    test(
      'rejects transfer or release when available balance is insufficient',
      () {
        final result = FundMovementRules.validateManualMovement(
          type: FundMovementType.transfer,
          amount: Money.php(3000),
          availableBalance: Money.php(2000),
        );

        expect(result.isInvalid, isTrue);
        expect(result.summary, contains('available balance is insufficient'));
      },
    );

    test('marks system-generated movements as protected', () {
      final movement = FundMovement(
        id: 'movement-1',
        reference: 'FM-20260818-4F2A91C0',
        type: FundMovementType.budgetAllocation,
        date: DateTime(2026, 8, 18),
        amount: Money.php(1000),
        purpose: 'Budget allocation',
        isSystemGenerated: true,
      );

      expect(FundMovementRules.isProtected(movement), isTrue);
    });
  });

  group('OfficerRules', () {
    test('rejects duplicate committee heads', () {
      final result = OfficerRules.validateOfficers(const [
        Officer(
          id: 'officer-1',
          fullName: 'Ari Santos',
          position: OfficerPosition.head,
          committee: Committee.finance,
        ),
        Officer(
          id: 'officer-2',
          fullName: 'Bea Reyes',
          position: OfficerPosition.head,
          committee: Committee.finance,
        ),
      ]);

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('Only one active head'));
    });

    test('rejects committee heads without a committee', () {
      final result = OfficerRules.validateOfficers(const [
        Officer(
          id: 'officer-1',
          fullName: 'Ari Santos',
          position: OfficerPosition.head,
        ),
      ]);

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('must be assigned to a committee'));
    });

    test('calculateOfficerCustodyBalance tracks releases, transfers, liquidations, and returns', () {
      final movements = [
        FundMovement(
          id: 'mov-1',
          reference: 'REL-1',
          type: FundMovementType.fundRelease,
          date: DateTime(2026, 8, 1),
          amount: Money.php(1000),
          holderOfficerId: 'officer-1',
          purpose: 'Release',
          isSystemGenerated: true,
        ),
        FundMovement(
          id: 'mov-2',
          reference: 'TR-1',
          type: FundMovementType.transfer,
          date: DateTime(2026, 8, 2),
          amount: Money.php(300),
          holderOfficerId: 'officer-1',
          toHolderOfficerId: 'officer-2',
          purpose: 'Transfer',
          isSystemGenerated: true,
        ),
        FundMovement(
          id: 'mov-3',
          reference: 'LIQ-1',
          type: FundMovementType.liquidationSubmitted,
          date: DateTime(2026, 8, 3),
          amount: Money.php(400),
          holderOfficerId: 'officer-1',
          purpose: 'Liquidation',
          isSystemGenerated: true,
        ),
        FundMovement(
          id: 'mov-4',
          reference: 'RET-1',
          type: FundMovementType.officerReturn,
          date: DateTime(2026, 8, 4),
          amount: Money.php(200),
          holderOfficerId: 'officer-1',
          purpose: 'Return',
          isSystemGenerated: true,
        ),
      ];

      expect(
        OfficerRules.calculateOfficerCustodyBalance(
          officerId: 'officer-1',
          movements: movements,
        ),
        Money.php(100),
      );

      expect(
        OfficerRules.calculateOfficerCustodyBalance(
          officerId: 'officer-2',
          movements: movements,
        ),
        Money.php(300),
      );
    });

    test('validateArchiveOfficer rejects archiving when custody balance is positive', () {
      final result = OfficerRules.validateArchiveOfficer(
        officer: const Officer(
          id: 'officer-1',
          fullName: 'Ari Santos',
          position: OfficerPosition.member,
        ),
        custodyBalance: Money.php(150),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.summary,
        contains('because they still hold PHP 150.00 in fund custody'),
      );
      expect(result.summary, contains('150.00'));
    });

    test(
      'validateArchiveOfficer permits archiving when custody balance is zero',
      () {
        final result = OfficerRules.validateArchiveOfficer(
          officer: const Officer(
            id: 'officer-1',
            fullName: 'Ari Santos',
            position: OfficerPosition.member,
          ),
          custodyBalance: Money.zero,
        );

        expect(result.isValid, isTrue);
      },
    );
  });

  group('LiquidationRules', () {
    test(
      'maps funding mode to reimbursement or liquidation movement behavior',
      () {
        expect(
          LiquidationRules.createsReimbursementClaim(FundingMode.outOfPocket),
          isTrue,
        );
        expect(
          LiquidationRules.createsLiquidationSubmittedMovement(
            FundingMode.releasedFunds,
          ),
          isTrue,
        );
      },
    );

    group('classifyEdit', () {
      final baseReceipt = _receipt();
      final baseLines = [
        _line(id: 'line-1', quantity: 2, unitCost: Money.php(50)),
      ];

      test('classifies non-financial field changes as metadata', () {
        final modifiedReceipt = _receipt(
          payee: 'New Merchant Name',
          evidenceNumber: 'OR-999',
          type: ReceiptType.salesInvoice,
          remarks: 'Updated remarks',
          attachment: const AttachmentRef(
            id: 'att-2',
            fileName: 'new.pdf',
            localPath: 'attachments/new.pdf',
            checksum: 'chk-2',
          ),
        );
        final modifiedLines = [
          _line(
            id: 'line-1',
            description: 'Updated Supplies description',
            quantity: 2,
            unitCost: Money.php(50),
          ),
        ];

        final result = LiquidationRules.classifyEdit(
          before: baseReceipt,
          beforeLines: baseLines,
          after: modifiedReceipt,
          afterLines: modifiedLines,
        );

        expect(result, equals(ReceiptEditClassification.metadata));
      });

      test(
        'classifies date, officer, or funding mode changes as financial',
        () {
          expect(
            LiquidationRules.classifyEdit(
              before: baseReceipt,
              beforeLines: baseLines,
              after: _receipt(date: DateTime(2026, 8, 15)),
              afterLines: baseLines,
            ),
            equals(ReceiptEditClassification.financial),
          );

          expect(
            LiquidationRules.classifyEdit(
              before: baseReceipt,
              beforeLines: baseLines,
              after: _receipt(officerId: 'officer-2'),
              afterLines: baseLines,
            ),
            equals(ReceiptEditClassification.financial),
          );

          expect(
            LiquidationRules.classifyEdit(
              before: baseReceipt,
              beforeLines: baseLines,
              after: _receipt(fundingMode: FundingMode.outOfPocket),
              afterLines: baseLines,
            ),
            equals(ReceiptEditClassification.financial),
          );
        },
      );

      test(
        'classifies line changes (count, quantity, unitCost) as financial',
        () {
          // Line quantity change
          expect(
            LiquidationRules.classifyEdit(
              before: baseReceipt,
              beforeLines: baseLines,
              after: baseReceipt,
              afterLines: [
                _line(id: 'line-1', quantity: 3, unitCost: Money.php(50)),
              ],
            ),
            equals(ReceiptEditClassification.financial),
          );

          // Line unit cost change
          expect(
            LiquidationRules.classifyEdit(
              before: baseReceipt,
              beforeLines: baseLines,
              after: baseReceipt,
              afterLines: [
                _line(id: 'line-1', quantity: 2, unitCost: Money.php(60)),
              ],
            ),
            equals(ReceiptEditClassification.financial),
          );

          // Added line
          expect(
            LiquidationRules.classifyEdit(
              before: baseReceipt,
              beforeLines: baseLines,
              after: baseReceipt,
              afterLines: [
                ...baseLines,
                _line(id: 'line-2', quantity: 1, unitCost: Money.php(20)),
              ],
            ),
            equals(ReceiptEditClassification.financial),
          );
        },
      );
    });

    group('validateEdit', () {
      final receipt = _receipt();
      final lines = [_line(id: 'line-1')];

      test(
        'permits metadata edits even if event is liquidated or claims are paid',
        () {
          final liquidatedEvent = _event(isLiquidated: true);
          final paidClaim = const ReimbursementClaim(
            id: 'claim-1',
            eventId: 'event-1',
            officerId: 'officer-1',
            amount: Money.centavos(20000),
            status: ReimbursementStatus.paid,
            sourceLiquidationLineId: 'line-1',
          );

          final result = LiquidationRules.validateEdit(
            classification: ReceiptEditClassification.metadata,
            receipt: receipt,
            event: liquidatedEvent,
            allClaims: [paidClaim],
            receiptLines: lines,
          );

          expect(result.isValid, isTrue);
        },
      );

      test('blocks financial edit if event is liquidated', () {
        final liquidatedEvent = _event(isLiquidated: true);

        final result = LiquidationRules.validateEdit(
          classification: ReceiptEditClassification.financial,
          receipt: receipt,
          event: liquidatedEvent,
          allClaims: const [],
          receiptLines: lines,
        );

        expect(result.isInvalid, isTrue);
        expect(result.summary, contains('already been liquidated'));
      });

      test('blocks financial edit if related claim is paid', () {
        final ongoingEvent = _event(isLiquidated: false);
        final paidClaim = const ReimbursementClaim(
          id: 'claim-1',
          eventId: 'event-1',
          officerId: 'officer-1',
          amount: Money.centavos(20000),
          status: ReimbursementStatus.paid,
          sourceLiquidationLineId: 'line-1',
        );

        final result = LiquidationRules.validateEdit(
          classification: ReceiptEditClassification.financial,
          receipt: receipt,
          event: ongoingEvent,
          allClaims: [paidClaim],
          receiptLines: lines,
        );

        expect(result.isInvalid, isTrue);
        expect(result.summary, contains('claim has already been paid'));
      });

      test(
        'permits financial edit if event is active and claims are pending',
        () {
          final ongoingEvent = _event(isLiquidated: false);
          final pendingClaim = const ReimbursementClaim(
            id: 'claim-1',
            eventId: 'event-1',
            officerId: 'officer-1',
            amount: Money.centavos(20000),
            status: ReimbursementStatus.pending,
            sourceLiquidationLineId: 'line-1',
          );

          final result = LiquidationRules.validateEdit(
            classification: ReceiptEditClassification.financial,
            receipt: receipt,
            event: ongoingEvent,
            allClaims: [pendingClaim],
            receiptLines: lines,
          );

          expect(result.isValid, isTrue);
        },
      );
    });

    group('validateVoid', () {
      final receipt = _receipt();
      final lines = [_line(id: 'line-1')];

      test('blocks voiding an already voided receipt', () {
        final voidedReceipt = _receipt(isVoided: true);

        final result = LiquidationRules.validateVoid(
          receipt: voidedReceipt,
          event: _event(),
          allClaims: const [],
          receiptLines: lines,
        );

        expect(result.isInvalid, isTrue);
        expect(result.summary, contains('already been voided'));
      });

      test('blocks void if event is liquidated or claim is paid', () {
        final liquidatedEvent = _event(isLiquidated: true);
        final paidClaim = const ReimbursementClaim(
          id: 'claim-1',
          eventId: 'event-1',
          officerId: 'officer-1',
          amount: Money.centavos(20000),
          status: ReimbursementStatus.paid,
          sourceLiquidationLineId: 'line-1',
        );

        expect(
          LiquidationRules.validateVoid(
            receipt: receipt,
            event: liquidatedEvent,
            allClaims: const [],
            receiptLines: lines,
          ).isInvalid,
          isTrue,
        );

        expect(
          LiquidationRules.validateVoid(
            receipt: receipt,
            event: _event(),
            allClaims: [paidClaim],
            receiptLines: lines,
          ).isInvalid,
          isTrue,
        );
      });

      test(
        'permits void when receipt is active, event ongoing, and no paid claim',
        () {
          final result = LiquidationRules.validateVoid(
            receipt: receipt,
            event: _event(),
            allClaims: const [],
            receiptLines: lines,
          );

          expect(result.isValid, isTrue);
        },
      );
    });

    group('detectDuplicates', () {
      final proposed = _receipt(
        id: 'rec-proposed',
        eventId: 'event-1',
        evidenceNumber: 'OR-100',
        payee: 'Target Store',
        date: DateTime(2026, 8, 10),
        attachment: const AttachmentRef(
          id: 'att-proposed',
          fileName: 'rec.pdf',
          localPath: 'attachments/rec.pdf',
          checksum: 'hash-abc',
        ),
      );
      final proposedTotal = Money.php(200);

      test(
        'warns when evidence number matches another receipt in same event',
        () {
          final existing = _receipt(
            id: 'rec-existing',
            eventId: 'event-1',
            evidenceNumber: 'OR-100',
            payee: 'Different Store',
          );

          final warnings = LiquidationRules.detectDuplicates(
            proposed: proposed,
            proposedTotal: proposedTotal,
            existingReceipts: [existing],
            receiptTotals: {existing.id: Money.php(500)},
          );

          expect(warnings, hasLength(1));
          expect(
            warnings.first,
            contains('Evidence number "OR-100" already exists'),
          );
        },
      );

      test('warns when payee, date, and total match', () {
        final existing = _receipt(
          id: 'rec-existing',
          eventId: 'event-2', // different event, but same payee/date/total
          evidenceNumber: 'OR-999',
          payee: 'Target Store',
          date: DateTime(2026, 8, 10, 15, 30),
        );

        final warnings = LiquidationRules.detectDuplicates(
          proposed: proposed,
          proposedTotal: proposedTotal,
          existingReceipts: [existing],
          receiptTotals: {existing.id: proposedTotal},
        );

        expect(warnings, hasLength(1));
        expect(
          warnings.first,
          contains('same merchant, date, and total already exists'),
        );
      });

      test('warns when attachment checksum matches', () {
        final existing = _receipt(
          id: 'rec-existing',
          eventId: 'event-2',
          evidenceNumber: 'OR-999',
          payee: 'Different Store',
          attachment: const AttachmentRef(
            id: 'att-existing',
            fileName: 'old.pdf',
            localPath: 'attachments/old.pdf',
            checksum: 'hash-abc',
          ),
        );

        final warnings = LiquidationRules.detectDuplicates(
          proposed: proposed,
          proposedTotal: proposedTotal,
          existingReceipts: [existing],
          receiptTotals: {existing.id: Money.php(500)},
        );

        expect(warnings, hasLength(1));
        expect(
          warnings.first,
          contains('attachment appears to be a duplicate'),
        );
      });

      test('ignores voided receipts and ignores proposed receipt itself', () {
        final sameReceipt = _receipt(
          id: 'rec-proposed',
          eventId: 'event-1',
          evidenceNumber: 'OR-100',
        );
        final voidedReceipt = _receipt(
          id: 'rec-voided',
          eventId: 'event-1',
          evidenceNumber: 'OR-100',
          isVoided: true,
        );

        final warnings = LiquidationRules.detectDuplicates(
          proposed: proposed,
          proposedTotal: proposedTotal,
          existingReceipts: [sameReceipt, voidedReceipt],
          receiptTotals: {
            sameReceipt.id: proposedTotal,
            voidedReceipt.id: proposedTotal,
          },
        );

        expect(warnings, isEmpty);
      });
    });
  });

  group('ReimbursementRules', () {
    test('rejects payment when approved event budget is insufficient', () {
      final result = ReimbursementRules.validatePayment(
        claim: const ReimbursementClaim(
          id: 'claim-1',
          eventId: 'event-1',
          officerId: 'officer-1',
          amount: Money.centavos(785000),
          status: ReimbursementStatus.pending,
          sourceLiquidationLineId: 'line-1',
        ),
        approvedBudgetBalance: Money.php(5000),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.summary,
        contains('Approved Budget balance is insufficient'),
      );
    });
  });
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'resolution.pdf',
  localPath: 'attachments/resolution.pdf',
);

AuditEvent _event({
  Money budget = const Money.centavos(1000000),
  DateTime? endDate,
  AttachmentRef? attachment,
  bool isLiquidated = false,
}) {
  return AuditEvent(
    id: 'event-1',
    name: 'General Assembly',
    type: 'Academic',
    semester: '1st Semester',
    schoolYear: '2026-2027',
    startDate: DateTime(2026, 8, 8),
    endDate: endDate ?? DateTime(2026, 8, 9),
    resolutionNumber: 'RES-2026-001',
    budget: budget,
    approvedBudgetBalance: budget,
    resolutionAttachment: attachment,
    isLiquidated: isLiquidated,
  );
}

LiquidationReceipt _receipt({
  String id = 'receipt-1',
  String eventId = 'event-1',
  String officerId = 'officer-1',
  DateTime? date,
  String payee = 'Store A',
  String evidenceNumber = 'OR-100',
  ReceiptType type = ReceiptType.officialReceipt,
  FundingMode fundingMode = FundingMode.releasedFunds,
  AttachmentRef? attachment = _attachment,
  String? remarks,
  bool isVoided = false,
  DateTime? voidedAt,
  String? voidReason,
}) {
  return LiquidationReceipt(
    id: id,
    eventId: eventId,
    payeeOrMerchant: payee,
    date: date ?? DateTime(2026, 8, 10),
    evidenceNumber: evidenceNumber,
    receiptType: type,
    fundingMode: fundingMode,
    accountableOfficerId: officerId,
    attachment: attachment ?? _attachment,
    remarks: remarks,
    isVoided: isVoided,
    voidedAt: voidedAt,
    voidReason: voidReason,
  );
}

LiquidationLine _line({
  String id = 'line-1',
  String receiptId = 'receipt-1',
  String description = 'Supplies',
  int quantity = 2,
  Money unitCost = const Money.centavos(10000),
}) {
  return LiquidationLine(
    id: id,
    receiptId: receiptId,
    description: description,
    quantity: quantity,
    unitCost: unitCost,
  );
}
