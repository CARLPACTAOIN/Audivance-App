import '../../../core/domain/identity.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation_result.dart';
import '../domain/audit_models.dart';

abstract class AuditRepository {
  Future<void> saveLocalAccount(LocalAccountProfile account);
  Future<LocalAccountProfile?> getLocalAccount();
  Future<bool> isSetupComplete();

  Future<void> saveOrganization(OrganizationProfile organization);
  Future<OrganizationProfile?> getOrganization(StableId id);
  Future<List<OrganizationProfile>> listOrganizations();

  Future<ValidationResult> saveOfficers(List<Officer> officers);
  Future<List<Officer>> listOfficers();

  Future<ValidationResult> saveTreasuryFundSource(TreasuryFundSource source);
  Future<void> updateTreasuryFundSource(TreasuryFundSource source);
  Future<List<TreasuryFundSource>> listTreasuryFundSources();

  Future<ValidationResult> saveAuditEvent({
    required AuditEvent event,
    required List<EventFundingAllocation> allocations,
  });
  Future<void> updateAuditEvent(AuditEvent event);
  Future<List<AuditEvent>> listAuditEvents();
  Future<List<EventFundingAllocation>> listEventFundingAllocations(
    StableId eventId,
  );

  Future<ValidationResult> saveFundMovement({
    required FundMovement movement,
    Money? availableBalance,
  });
  Future<ValidationResult> updateFundMovement({
    required FundMovement movement,
    Money? availableBalance,
  });
  Future<ValidationResult> deleteFundMovement(StableId id);
  Future<List<FundMovement>> listFundMovements();

  Future<void> saveLiquidationReceipt(LiquidationReceipt receipt);

  /// In-place update of an existing receipt row. Does NOT create any financial
  /// movements — call [editReceiptAtomically] for full financial edits.
  Future<void> updateLiquidationReceipt(LiquidationReceipt receipt);
  Future<List<LiquidationReceipt>> listLiquidationReceipts();

  /// Returns only non-voided receipts (isVoided = false).
  Future<List<LiquidationReceipt>> listActiveLiquidationReceipts();

  Future<void> saveLiquidationLine(LiquidationLine line);
  Future<void> updateLiquidationLine(LiquidationLine line);
  Future<void> deleteLiquidationLine(StableId id);
  Future<List<LiquidationLine>> listLiquidationLines();

  Future<ValidationResult> saveReimbursementClaim(ReimbursementClaim claim);
  Future<void> updateReimbursementClaim(ReimbursementClaim claim);
  Future<List<ReimbursementClaim>> listReimbursementClaims();

  Future<void> saveAuditorReview(AuditorReviewSnapshot review);
  Future<List<AuditorReviewSnapshot>> listAuditorReviews();
  Future<List<AuditorReviewSnapshot>> listAuditorReviewsForEvent(
    StableId eventId,
  );

  Future<void> appendAuditLog(AuditLogEntry entry);
  Future<List<AuditLogEntry>> listAuditLogs();

  /// Returns audit log entries whose [AuditLogEntry.targetRecordId] matches
  /// [receiptId], ordered by [AuditLogEntry.occurredAt] ascending.
  Future<List<AuditLogEntry>> listAuditLogsForReceipt(StableId receiptId);

  Future<void> appendExportHistory(ExportHistoryEntry entry);
  Future<List<ExportHistoryEntry>> listExportHistory();

  Future<void> appendBackupHistory(BackupHistoryEntry entry);
  Future<List<BackupHistoryEntry>> listBackupHistory();

  // -- Atomic aggregate operations -----------------------------------------

  /// Posts a new receipt in a single Drift transaction.
  ///
  /// Writes: receipt, lines, optional [FundMovementType.liquidationSubmitted]
  /// movement, optional reimbursement claim(s), and a `liquidation.post`
  /// audit log entry. Any failure rolls the entire transaction back.
  Future<ValidationResult> postReceiptAtomically({
    required LiquidationReceipt receipt,
    required List<LiquidationLine> lines,
    FundMovement? submittedMovement,
    List<ReimbursementClaim> claims = const [],
    required AuditLogEntry auditLog,
  });

  /// Edits an existing posted receipt in a single Drift transaction.
  ///
  /// For metadata edits: updates receipt and lines in place, appends a
  /// `liquidation.edit` audit log entry.
  ///
  /// For financial edits additionally: inserts a protected
  /// [FundMovementType.liquidationReversal] movement, inserts a new
  /// [FundMovementType.liquidationSubmitted] movement, marks
  /// [claimsToSupersede] as [ReimbursementStatus.superseded], and inserts
  /// [replacementClaims].
  Future<ValidationResult> editReceiptAtomically({
    required LiquidationReceipt updatedReceipt,
    required List<LiquidationLine> updatedLines,
    List<StableId> lineIdsToDelete = const [],
    FundMovement? reversalMovement,
    FundMovement? newSubmittedMovement,
    List<ReimbursementClaim> claimsToSupersede = const [],
    List<ReimbursementClaim> replacementClaims = const [],
    required AuditLogEntry auditLog,
  });

  /// Voids a posted receipt in a single Drift transaction.
  ///
  /// Sets [LiquidationReceipt.isVoided] = true, writes the void timestamp
  /// and reason, inserts an optional [FundMovementType.liquidationReversal]
  /// movement, marks [claimsToSupersede] as [ReimbursementStatus.superseded],
  /// and appends a `liquidation.void` audit log entry.
  Future<ValidationResult> voidReceiptAtomically({
    required LiquidationReceipt voidedReceipt,
    FundMovement? reversalMovement,
    List<ReimbursementClaim> claimsToSupersede = const [],
    required AuditLogEntry auditLog,
  });
}
