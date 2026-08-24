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
  Future<List<LiquidationReceipt>> listLiquidationReceipts();

  Future<void> saveLiquidationLine(LiquidationLine line);
  Future<List<LiquidationLine>> listLiquidationLines();

  Future<ValidationResult> saveReimbursementClaim(ReimbursementClaim claim);
  Future<List<ReimbursementClaim>> listReimbursementClaims();

  Future<void> saveAuditorReview(AuditorReviewSnapshot review);
  Future<List<AuditorReviewSnapshot>> listAuditorReviews();
  Future<List<AuditorReviewSnapshot>> listAuditorReviewsForEvent(
    StableId eventId,
  );

  Future<void> appendAuditLog(AuditLogEntry entry);
  Future<List<AuditLogEntry>> listAuditLogs();

  Future<void> appendExportHistory(ExportHistoryEntry entry);
  Future<List<ExportHistoryEntry>> listExportHistory();

  Future<void> appendBackupHistory(BackupHistoryEntry entry);
  Future<List<BackupHistoryEntry>> listBackupHistory();
}
