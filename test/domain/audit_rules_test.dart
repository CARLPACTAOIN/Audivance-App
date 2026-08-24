import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/audit/domain/audit_rules.dart';
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
