import '../../../core/domain/money.dart';
import '../../audit/domain/audit_models.dart';

/// Whether an edit touches only metadata or also financial fields.
///
/// - [metadata]: only merchant, evidence number, receipt type, remarks,
///   attachment, or line descriptions changed — identical line structure,
///   quantities, prices, event, date, funding, and officer.
/// - [financial]: any change to event, date, officer, funding mode, or any
///   line count, quantity, or unit-cost — even if the total happens to be equal.
enum ReceiptEditClassification { metadata, financial }

/// Result of classifying and validating a proposed receipt edit.
///
/// [isBlocked] is true when a financial edit is attempted after the event
/// has been liquidated or a related reimbursement claim has been paid.
/// Metadata edits are never blocked.
class ReceiptEditAnalysis {
  const ReceiptEditAnalysis({
    required this.classification,
    required this.isBlocked,
    this.blockedReason,
    required this.beforeSnapshot,
    required this.afterSnapshot,
    this.reversalAmount,
  });

  final ReceiptEditClassification classification;

  /// True when this edit is not allowed in the current event/claim state.
  final bool isBlocked;

  /// Human-readable explanation of why the edit is blocked. Non-null when
  /// [isBlocked] is true.
  final String? blockedReason;

  /// Serialisable representation of the receipt + lines before the edit.
  /// Stored verbatim in the audit log [AuditLogEntry.beforeSnapshot].
  final Map<String, Object?> beforeSnapshot;

  /// Serialisable representation of the receipt + lines after the edit.
  /// Stored verbatim in the audit log [AuditLogEntry.afterSnapshot].
  final Map<String, Object?> afterSnapshot;

  /// Amount of the protected [FundMovementType.liquidationReversal] movement
  /// that must be created to reverse the original released-funds portion.
  /// Non-null only for [ReceiptEditClassification.financial] edits where the
  /// original receipt used released funds (releasedFunds or mixed mode).
  final Money? reversalAmount;
}

/// Helper: serialise a [LiquidationReceipt] and its lines to a snapshot map
/// suitable for audit-log before/after storage.
Map<String, Object?> receiptSnapshot(
  LiquidationReceipt receipt,
  List<LiquidationLine> lines,
) {
  return {
    'id': receipt.id,
    'eventId': receipt.eventId,
    'payeeOrMerchant': receipt.payeeOrMerchant,
    'date': receipt.date.toIso8601String(),
    'evidenceNumber': receipt.evidenceNumber,
    'receiptType': receipt.receiptType.name,
    'fundingMode': receipt.fundingMode.name,
    'accountableOfficerId': receipt.accountableOfficerId,
    'releasedFundsCentavos': receipt.releasedFundsAmount?.centavos,
    'outOfPocketCentavos': receipt.outOfPocketAmount?.centavos,
    'remarks': receipt.remarks,
    'isVoided': receipt.isVoided,
    'attachmentId': receipt.attachment.id,
    'lines': lines
        .map(
          (l) => {
            'id': l.id,
            'description': l.description,
            'quantity': l.quantity,
            'unitCostCentavos': l.unitCost.centavos,
          },
        )
        .toList(),
  };
}
