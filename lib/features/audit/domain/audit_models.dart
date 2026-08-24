import '../../../core/domain/attachment_ref.dart';
import '../../../core/domain/identity.dart';
import '../../../core/domain/money.dart';

enum Committee { finance, audit }

enum OfficerPosition { head, member }

enum TreasuryFundSourceType {
  previousAdmin,
  studentCollections,
  donationSponsor,
  incomeGeneratingProfit,
  ppmp,
}

enum AuditEventStatus { ongoing, forLiquidation, due, liquidated }

enum FundMovementType {
  addFund,
  budgetAllocation,
  budgetAdjustment,
  fundRelease,
  transfer,
  returnRefund,
  liquidationSubmitted,
  reimbursementPayment,
}

enum ReceiptType {
  officialReceipt,
  reimbursementExpenseReceipt,
  paymentAgreement,
  acknowledgementReceipt,
  salesInvoice,
}

enum FundingMode { releasedFunds, outOfPocket }

enum ReimbursementStatus { pending, paid }

enum ExportReadinessSeverity { warning, blocker }

enum BudgetHealth { noBudget, healthy, watch, overBudget, critical }

class LocalAccountProfile {
  const LocalAccountProfile({
    required this.id,
    required this.displayName,
    required this.emailOrStudentId,
    required this.createdAt,
    required this.isCredentialConfigured,
  });

  final StableId id;
  final String displayName;
  final String emailOrStudentId;
  final DateTime createdAt;
  final bool isCredentialConfigured;
}

class OrganizationProfile {
  const OrganizationProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.adviser,
    required this.semester,
    required this.schoolYear,
    required this.signatoryNames,
  });

  final StableId id;
  final String name;
  final String type;
  final String adviser;
  final String semester;
  final String schoolYear;
  final List<String> signatoryNames;
}

class Officer {
  const Officer({
    required this.id,
    required this.fullName,
    required this.position,
    this.committee,
    this.isArchived = false,
  });

  final StableId id;
  final String fullName;
  final OfficerPosition position;
  final Committee? committee;
  final bool isArchived;
}

class TreasuryFundSource {
  const TreasuryFundSource({
    required this.id,
    required this.type,
    required this.label,
    required this.balance,
    this.supportingAttachment,
  });

  final StableId id;
  final TreasuryFundSourceType type;
  final String label;
  final Money balance;
  final AttachmentRef? supportingAttachment;
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.semester,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.resolutionNumber,
    required this.budget,
    required this.approvedBudgetBalance,
    this.permitApprovalDate,
    this.resolutionAttachment,
    this.isLiquidated = false,
  });

  final StableId id;
  final String name;
  final String type;
  final String semester;
  final String schoolYear;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? permitApprovalDate;
  final String resolutionNumber;
  final Money budget;
  final Money approvedBudgetBalance;
  final AttachmentRef? resolutionAttachment;
  final bool isLiquidated;
}

class EventFundingAllocation {
  const EventFundingAllocation({
    required this.eventId,
    required this.fundSourceId,
    required this.amount,
  });

  final StableId eventId;
  final StableId fundSourceId;
  final Money amount;
}

class FundMovement {
  const FundMovement({
    required this.id,
    required this.reference,
    required this.type,
    required this.date,
    required this.amount,
    required this.purpose,
    required this.isSystemGenerated,
    this.remarks,
    this.eventId,
    this.fromFundSourceId,
    this.toFundSourceId,
    this.holderOfficerId,
  });

  final StableId id;
  final String reference;
  final FundMovementType type;
  final DateTime date;
  final Money amount;
  final String purpose;
  final String? remarks;
  final StableId? eventId;
  final StableId? fromFundSourceId;
  final StableId? toFundSourceId;
  final StableId? holderOfficerId;
  final bool isSystemGenerated;
}

class LiquidationReceipt {
  const LiquidationReceipt({
    required this.id,
    required this.eventId,
    required this.payeeOrMerchant,
    required this.date,
    required this.evidenceNumber,
    required this.receiptType,
    required this.fundingMode,
    required this.accountableOfficerId,
    required this.attachment,
  });

  final StableId id;
  final StableId eventId;
  final String payeeOrMerchant;
  final DateTime date;
  final String evidenceNumber;
  final ReceiptType receiptType;
  final FundingMode fundingMode;
  final StableId accountableOfficerId;
  final AttachmentRef attachment;
}

class LiquidationLine {
  const LiquidationLine({
    required this.id,
    required this.receiptId,
    required this.description,
    required this.quantity,
    required this.unitCost,
  });

  final StableId id;
  final StableId receiptId;
  final String description;
  final int quantity;
  final Money unitCost;

  Money get total => Money.centavos(unitCost.centavos * quantity);
}

class ReimbursementClaim {
  const ReimbursementClaim({
    required this.id,
    required this.eventId,
    required this.officerId,
    required this.amount,
    required this.status,
    required this.sourceLiquidationLineId,
  });

  final StableId id;
  final StableId eventId;
  final StableId officerId;
  final Money amount;
  final ReimbursementStatus status;
  final StableId sourceLiquidationLineId;
}

class AuditorReviewSnapshot {
  const AuditorReviewSnapshot({
    required this.id,
    required this.eventId,
    required this.findings,
    required this.cause,
    required this.recommendation,
    required this.budget,
    required this.actual,
    required this.variance,
    required this.utilizationBasisPoints,
    required this.health,
    required this.createdAt,
  });

  final StableId id;
  final StableId eventId;
  final String findings;
  final String cause;
  final String recommendation;
  final Money budget;
  final Money actual;
  final Money variance;
  final int utilizationBasisPoints;
  final BudgetHealth health;
  final DateTime createdAt;
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.targetRecordId,
    required this.occurredAt,
    this.amount,
    this.reference,
    this.beforeSnapshot,
    this.afterSnapshot,
    this.metadata = const {},
  });

  final StableId id;
  final String action;
  final String actor;
  final StableId targetRecordId;
  final DateTime occurredAt;
  final Money? amount;
  final String? reference;
  final Map<String, Object?>? beforeSnapshot;
  final Map<String, Object?>? afterSnapshot;
  final Map<String, Object?> metadata;
}

class ExportReadinessIssue {
  const ExportReadinessIssue({
    required this.id,
    required this.message,
    required this.severity,
    this.targetRecordId,
  });

  final StableId id;
  final String message;
  final ExportReadinessSeverity severity;
  final StableId? targetRecordId;
}

enum ExportHistoryStatus { success, canceled, failed }

enum BackupHistoryStatus { success, canceled, failed }

enum BackupReminderStatus { notChecked, satisfied, overridden }

class ExportHistoryEntry {
  const ExportHistoryEntry({
    required this.id,
    required this.fileName,
    required this.generatedAt,
    required this.byteLength,
    required this.checksum,
    this.destinationUri,
    required this.status,
    required this.backupReminderStatus,
    required this.sameDayBackupFound,
    required this.blockerCount,
    required this.warningCount,
    required this.createdAt,
    this.errorMessage,
  });

  final StableId id;
  final String fileName;
  final DateTime generatedAt;
  final int byteLength;
  final String checksum;
  final String? destinationUri;
  final ExportHistoryStatus status;
  final BackupReminderStatus backupReminderStatus;
  final bool sameDayBackupFound;
  final int blockerCount;
  final int warningCount;
  final DateTime createdAt;
  final String? errorMessage;
}

class BackupHistoryEntry {
  const BackupHistoryEntry({
    required this.id,
    required this.fileName,
    required this.generatedAt,
    required this.byteLength,
    required this.checksum,
    this.destinationUri,
    required this.status,
    required this.createdAt,
    this.errorMessage,
  });

  final StableId id;
  final String fileName;
  final DateTime generatedAt;
  final int byteLength;
  final String checksum;
  final String? destinationUri;
  final BackupHistoryStatus status;
  final DateTime createdAt;
  final String? errorMessage;
}
