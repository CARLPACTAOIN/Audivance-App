import '../../../core/domain/attachment_ref.dart';
import '../../../core/domain/identity.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation_result.dart';
import 'audit_models.dart';

class OfficerRules {
  const OfficerRules._();

  static ValidationResult validateOfficers(List<Officer> officers) {
    final messages = <String>[];
    final activeHeadsByCommittee = <Committee, Officer>{};

    for (final officer in officers.where((officer) => !officer.isArchived)) {
      if (officer.position == OfficerPosition.head &&
          officer.committee == null) {
        messages.add('Committee heads must be assigned to a committee.');
      }

      final committee = officer.committee;
      if (officer.position == OfficerPosition.head && committee != null) {
        final existingHead = activeHeadsByCommittee[committee];
        if (existingHead != null) {
          messages.add(
            'Only one active head is allowed for ${committee.label}.',
          );
        } else {
          activeHeadsByCommittee[committee] = officer;
        }
      }
    }

    return ValidationResult.invalid(messages);
  }
}

class TreasuryRules {
  const TreasuryRules._();

  static ValidationResult validateAddFund({
    required Money amount,
    required AttachmentRef? supportingAttachment,
  }) {
    final messages = <String>[];
    if (!amount.isPositive) {
      messages.add('Add Fund amount must be greater than zero.');
    }
    if (supportingAttachment == null) {
      messages.add(
        'Treasury Add Fund requires a supporting document attachment.',
      );
    }
    return ValidationResult.invalid(messages);
  }
}

class EventRules {
  const EventRules._();

  static ValidationResult validateEventBudget({
    required AuditEvent event,
    required List<EventFundingAllocation> allocations,
    required Map<StableId, Money> sourceBalances,
  }) {
    final messages = <String>[];
    if (event.resolutionAttachment == null) {
      messages.add('Event resolution attachment is required.');
    }

    final totalAllocated = allocations.fold(
      Money.zero,
      (total, allocation) => total + allocation.amount,
    );
    if (totalAllocated != event.budget) {
      messages.add('Split funding allocations must equal the event budget.');
    }

    final requestedBySource = <StableId, Money>{};
    for (final allocation in allocations) {
      requestedBySource.update(
        allocation.fundSourceId,
        (current) => current + allocation.amount,
        ifAbsent: () => allocation.amount,
      );
    }

    for (final entry in requestedBySource.entries) {
      final available = sourceBalances[entry.key] ?? Money.zero;
      if (entry.value > available) {
        messages.add('Source fund ${entry.key} has insufficient balance.');
      }
    }

    return ValidationResult.invalid(messages);
  }

  static ValidationResult validateBudgetIncrease({
    required Money increaseAmount,
    required Money sourceBalance,
  }) {
    if (!increaseAmount.isPositive) {
      return ValidationResult.failure(
        'Budget increase amount must be greater than zero.',
      );
    }
    if (increaseAmount > sourceBalance) {
      return ValidationResult.failure(
        'Budget increase is blocked because source treasury balance is insufficient.',
      );
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateBudgetDecrease({
    required Money decreaseAmount,
    required Money approvedBudgetBalance,
  }) {
    if (!decreaseAmount.isPositive) {
      return ValidationResult.failure(
        'Budget decrease amount must be greater than zero.',
      );
    }
    if (decreaseAmount > approvedBudgetBalance) {
      return ValidationResult.failure(
        'Budget decrease is blocked because event Approved Budget balance is insufficient.',
      );
    }
    return const ValidationResult.valid();
  }

  static AuditEventStatus calculateStatus({
    required AuditEvent event,
    required DateTime asOf,
  }) {
    if (event.isLiquidated) {
      return AuditEventStatus.liquidated;
    }

    final eventEndDate = DateTime(
      event.endDate.year,
      event.endDate.month,
      event.endDate.day,
    );
    final currentDate = DateTime(asOf.year, asOf.month, asOf.day);
    final dueDate = eventEndDate.add(const Duration(days: 7));

    if (currentDate.isAfter(dueDate) || currentDate.isAtSameMomentAs(dueDate)) {
      return AuditEventStatus.due;
    }
    if (currentDate.isAfter(eventEndDate)) {
      return AuditEventStatus.forLiquidation;
    }
    return AuditEventStatus.ongoing;
  }
}

class FundMovementRules {
  const FundMovementRules._();

  static const manualTypes = {
    FundMovementType.fundRelease,
    FundMovementType.transfer,
    FundMovementType.returnRefund,
  };

  static bool isProtected(FundMovement movement) => movement.isSystemGenerated;

  static ValidationResult validateManualMovement({
    required FundMovementType type,
    required Money amount,
    required Money availableBalance,
  }) {
    final messages = <String>[];
    if (!manualTypes.contains(type)) {
      messages.add(
        'Manual fund movements are limited to Fund Release, Transfer, and Return / Refund.',
      );
    }
    if (!amount.isPositive) {
      messages.add('Fund movement amount must be greater than zero.');
    }
    if (amount > availableBalance) {
      messages.add(
        'Fund movement is blocked because the available balance is insufficient.',
      );
    }
    return ValidationResult.invalid(messages);
  }
}

class LiquidationRules {
  const LiquidationRules._();

  static bool createsReimbursementClaim(FundingMode fundingMode) {
    return fundingMode == FundingMode.outOfPocket;
  }

  static bool createsLiquidationSubmittedMovement(FundingMode fundingMode) {
    return fundingMode == FundingMode.releasedFunds;
  }
}

class ReimbursementRules {
  const ReimbursementRules._();

  static ValidationResult validatePayment({
    required ReimbursementClaim claim,
    required Money approvedBudgetBalance,
  }) {
    final messages = <String>[];
    if (claim.status != ReimbursementStatus.pending) {
      messages.add('Only pending reimbursement claims can be paid.');
    }
    if (!claim.amount.isPositive) {
      messages.add('Reimbursement amount must be greater than zero.');
    }
    if (claim.amount > approvedBudgetBalance) {
      messages.add(
        'Reimbursement payment is blocked because event Approved Budget balance is insufficient.',
      );
    }
    return ValidationResult.invalid(messages);
  }
}

extension CommitteeLabel on Committee {
  String get label {
    return switch (this) {
      Committee.finance => 'Finance Committee',
      Committee.audit => 'Audit Committee',
    };
  }
}
