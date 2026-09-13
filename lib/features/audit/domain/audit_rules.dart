import '../../../core/domain/attachment_ref.dart';
import '../../../core/domain/identity.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation_result.dart';
import '../../liquidation/domain/receipt_edit_models.dart';
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

  static Money calculateOfficerCustodyBalance({
    required List<FundMovement> movements,
    required StableId? officerId,
    StableId? eventId,
  }) {
    if (officerId == null) return Money.zero;
    var balance = Money.zero;
    for (final movement in movements) {
      if (eventId != null && movement.eventId != eventId) {
        continue;
      }
      if (movement.holderOfficerId == officerId) {
        switch (movement.type) {
          case FundMovementType.fundRelease:
            balance += movement.amount;
          case FundMovementType.liquidationSubmitted:
          case FundMovementType.returnRefund:
          case FundMovementType.officerReturn:
          case FundMovementType.transfer:
            balance -= movement.amount;
          // liquidationReversal credits the custody back to the officer.
          case FundMovementType.liquidationReversal:
            balance += movement.amount;
          case FundMovementType.addFund:
          case FundMovementType.budgetAllocation:
          case FundMovementType.budgetAdjustment:
          case FundMovementType.reimbursementPayment:
            break;
        }
      }
      if (movement.type == FundMovementType.transfer &&
          movement.toHolderOfficerId == officerId) {
        balance += movement.amount;
      }
    }
    return balance;
  }

  static ValidationResult validateArchiveOfficer({
    required Officer officer,
    required Money custodyBalance,
  }) {
    if (custodyBalance.isPositive) {
      return ValidationResult.failure(
        'Cannot archive ${officer.fullName} because they still hold '
        '${custodyBalance.formatPhp()} in fund custody. '
        'Liquidate, return, or transfer the custody balance first.',
      );
    }
    return const ValidationResult.valid();
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
    FundMovementType.officerReturn,
  };

  /// Movement types that are protected — cannot be manually edited or deleted.
  static const protectedTypes = {
    FundMovementType.liquidationSubmitted,
    FundMovementType.reimbursementPayment,
    FundMovementType.liquidationReversal,
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

  /// Validates a mixed-funding split: released portion = min(custody, total),
  /// out-of-pocket portion = max(0, total - custody).
  static ({Money released, Money outOfPocket}) computeMixedSplit({
    required Money receiptTotal,
    required Money officerCustody,
  }) {
    final released = officerCustody.isPositive
        ? (officerCustody > receiptTotal ? receiptTotal : officerCustody)
        : Money.zero;
    final oop = Money.centavos(receiptTotal.centavos - released.centavos);
    return (released: released, outOfPocket: oop);
  }
}

class LiquidationRules {
  const LiquidationRules._();

  static bool createsReimbursementClaim(FundingMode fundingMode) {
    return fundingMode == FundingMode.outOfPocket ||
        fundingMode == FundingMode.mixed;
  }

  static bool createsLiquidationSubmittedMovement(FundingMode fundingMode) {
    return fundingMode == FundingMode.releasedFunds ||
        fundingMode == FundingMode.mixed;
  }

  /// Classifies a proposed edit by comparing before/after receipt fields.
  ///
  /// Returns [ReceiptEditClassification.financial] when any of the following
  /// differ: eventId, date, accountableOfficerId, fundingMode, line count,
  /// or any line's quantity or unitCost.
  /// All other field changes (merchant, evidenceNumber, receiptType, remarks,
  /// attachment, line descriptions) are [ReceiptEditClassification.metadata].
  static ReceiptEditClassification classifyEdit({
    required LiquidationReceipt before,
    required List<LiquidationLine> beforeLines,
    required LiquidationReceipt after,
    required List<LiquidationLine> afterLines,
  }) {
    // Structural / financial field changes.
    if (before.eventId != after.eventId ||
        !before.date.isAtSameMomentAs(after.date) ||
        before.accountableOfficerId != after.accountableOfficerId ||
        before.fundingMode != after.fundingMode ||
        beforeLines.length != afterLines.length) {
      return ReceiptEditClassification.financial;
    }
    // Sort both lists by id for stable comparison.
    final sortedBefore = [...beforeLines]..sort((a, b) => a.id.compareTo(b.id));
    final sortedAfter = [...afterLines]..sort((a, b) => a.id.compareTo(b.id));
    for (var i = 0; i < sortedBefore.length; i++) {
      final bl = sortedBefore[i];
      final al = sortedAfter[i];
      if (bl.quantity != al.quantity ||
          bl.unitCost.centavos != al.unitCost.centavos) {
        return ReceiptEditClassification.financial;
      }
    }
    return ReceiptEditClassification.metadata;
  }

  /// Validates whether an edit of the given [classification] is allowed.
  ///
  /// Metadata edits are always allowed.
  /// Financial edits are blocked when the event is liquidated or any claim
  /// linked to the receipt's lines has been paid.
  static ValidationResult validateEdit({
    required ReceiptEditClassification classification,
    required LiquidationReceipt receipt,
    required AuditEvent event,
    required List<ReimbursementClaim> allClaims,
    required List<LiquidationLine> receiptLines,
  }) {
    if (classification == ReceiptEditClassification.metadata) {
      return const ValidationResult.valid();
    }
    return _validateFinancialEligibility(
      receipt: receipt,
      event: event,
      allClaims: allClaims,
      receiptLines: receiptLines,
      action: 'financially edit',
    );
  }

  /// Validates whether voiding [receipt] is allowed.
  ///
  /// Follows the same financial-eligibility rules as financial edits:
  /// blocked after event liquidation or paid reimbursement claims.
  static ValidationResult validateVoid({
    required LiquidationReceipt receipt,
    required AuditEvent event,
    required List<ReimbursementClaim> allClaims,
    required List<LiquidationLine> receiptLines,
  }) {
    if (receipt.isVoided) {
      return ValidationResult.failure('This receipt has already been voided.');
    }
    return _validateFinancialEligibility(
      receipt: receipt,
      event: event,
      allClaims: allClaims,
      receiptLines: receiptLines,
      action: 'void',
    );
  }

  static ValidationResult _validateFinancialEligibility({
    required LiquidationReceipt receipt,
    required AuditEvent event,
    required List<ReimbursementClaim> allClaims,
    required List<LiquidationLine> receiptLines,
    required String action,
  }) {
    final messages = <String>[];
    if (event.isLiquidated) {
      messages.add(
        'Cannot $action a receipt because the event has already been liquidated.',
      );
    }
    final lineIds = receiptLines.map((l) => l.id).toSet();
    final hasPaidClaim = allClaims.any(
      (c) =>
          lineIds.contains(c.sourceLiquidationLineId) &&
          c.status == ReimbursementStatus.paid,
    );
    if (hasPaidClaim) {
      messages.add(
        'Cannot $action a receipt because a related reimbursement claim has already been paid.',
      );
    }
    return ValidationResult.invalid(messages);
  }

  /// Returns non-blocking duplicate warning strings for a proposed receipt.
  ///
  /// Checks for:
  /// - Matching evidence number (same event, different receipt).
  /// - Same merchant + date + line total combination.
  /// - Same attachment checksum.
  static List<String> detectDuplicates({
    required LiquidationReceipt proposed,
    required Money proposedTotal,
    required List<LiquidationReceipt> existingReceipts,
    required Map<String, Money> receiptTotals,
  }) {
    final warnings = <String>[];
    for (final existing in existingReceipts) {
      if (existing.id == proposed.id) continue;
      if (existing.isVoided) continue;
      if (existing.eventId == proposed.eventId &&
          existing.evidenceNumber.trim().toLowerCase() ==
              proposed.evidenceNumber.trim().toLowerCase()) {
        warnings.add(
          'Evidence number "${proposed.evidenceNumber}" already exists for this event '
          '(receipt ${existing.id}).',
        );
      }
      final existingTotal = receiptTotals[existing.id];
      if (existingTotal != null &&
          existing.payeeOrMerchant.trim().toLowerCase() ==
              proposed.payeeOrMerchant.trim().toLowerCase() &&
          existing.date.year == proposed.date.year &&
          existing.date.month == proposed.date.month &&
          existing.date.day == proposed.date.day &&
          existingTotal == proposedTotal) {
        warnings.add(
          'A receipt with the same merchant, date, and total already exists '
          '(receipt ${existing.id}).',
        );
      }
      final proposedChecksum = proposed.attachment.checksum;
      if (proposedChecksum != null &&
          proposedChecksum.isNotEmpty &&
          existing.attachment.checksum == proposedChecksum) {
        warnings.add(
          'The attachment appears to be a duplicate of an existing receipt '
          '(receipt ${existing.id}).',
        );
      }
    }
    return warnings;
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
