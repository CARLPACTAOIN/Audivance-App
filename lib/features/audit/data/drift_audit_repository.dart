import 'package:drift/drift.dart';

import '../../../core/domain/identity.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/validation_result.dart';
import '../domain/audit_models.dart' as domain;
import '../domain/audit_rules.dart';
import 'audit_database.dart';
import 'audit_mappers.dart';
import 'audit_repository.dart';

class DriftAuditRepository implements AuditRepository {
  const DriftAuditRepository(this._database);

  final AuditDatabase _database;

  @override
  Future<void> saveLocalAccount(domain.LocalAccountProfile account) {
    return _database.transaction(() async {
      await _database.delete(_database.localAccounts).go();
      await _database
          .into(_database.localAccounts)
          .insert(account.toCompanion());
    });
  }

  @override
  Future<domain.LocalAccountProfile?> getLocalAccount() async {
    final row = await _database
        .select(_database.localAccounts)
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<bool> isSetupComplete() async {
    final account = await getLocalAccount();
    final organizations = await listOrganizations();
    return account != null && organizations.isNotEmpty;
  }

  @override
  Future<void> saveOrganization(domain.OrganizationProfile organization) {
    return _database
        .into(_database.organizations)
        .insertOnConflictUpdate(organization.toCompanion());
  }

  @override
  Future<domain.OrganizationProfile?> getOrganization(StableId id) async {
    final row = await (_database.select(
      _database.organizations,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<domain.OrganizationProfile>> listOrganizations() async {
    final rows = await _database.select(_database.organizations).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<ValidationResult> saveOfficers(List<domain.Officer> officers) async {
    final existing = await listOfficers();
    final incomingIds = officers.map((officer) => officer.id).toSet();
    final merged = [
      ...existing.where((officer) => !incomingIds.contains(officer.id)),
      ...officers,
    ];
    final validation = OfficerRules.validateOfficers(merged);
    if (validation.isInvalid) {
      return validation;
    }

    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.officers,
        officers.map((officer) => officer.toCompanion()).toList(),
      );
    });
    return const ValidationResult.valid();
  }

  @override
  Future<List<domain.Officer>> listOfficers() async {
    final rows = await _database.select(_database.officers).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<ValidationResult> saveTreasuryFundSource(
    domain.TreasuryFundSource source,
  ) async {
    final validation = TreasuryRules.validateAddFund(
      amount: source.balance,
      supportingAttachment: source.supportingAttachment,
    );
    if (validation.isInvalid) {
      return validation;
    }

    await _database
        .into(_database.treasuryFundSources)
        .insertOnConflictUpdate(source.toCompanion());
    return const ValidationResult.valid();
  }

  @override
  Future<void> updateTreasuryFundSource(domain.TreasuryFundSource source) {
    return _database
        .into(_database.treasuryFundSources)
        .insertOnConflictUpdate(source.toCompanion());
  }

  @override
  Future<List<domain.TreasuryFundSource>> listTreasuryFundSources() async {
    final rows = await _database.select(_database.treasuryFundSources).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<ValidationResult> saveAuditEvent({
    required domain.AuditEvent event,
    required List<domain.EventFundingAllocation> allocations,
  }) async {
    final sourceBalances = {
      for (final source in await listTreasuryFundSources())
        source.id: source.balance,
    };
    final validation = EventRules.validateEventBudget(
      event: event,
      allocations: allocations,
      sourceBalances: sourceBalances,
    );
    if (validation.isInvalid) {
      return validation;
    }

    await _database.transaction(() async {
      await _database
          .into(_database.auditEvents)
          .insertOnConflictUpdate(event.toCompanion());
      await (_database.delete(
        _database.eventFundingAllocations,
      )..where((table) => table.eventId.equals(event.id))).go();
      await _database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          _database.eventFundingAllocations,
          allocations.map((allocation) => allocation.toCompanion()).toList(),
        );
      });
    });
    return const ValidationResult.valid();
  }

  @override
  Future<void> updateAuditEvent(domain.AuditEvent event) {
    return _database
        .into(_database.auditEvents)
        .insertOnConflictUpdate(event.toCompanion());
  }

  @override
  Future<List<domain.AuditEvent>> listAuditEvents() async {
    final rows = await _database.select(_database.auditEvents).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<List<domain.EventFundingAllocation>> listEventFundingAllocations(
    StableId eventId,
  ) async {
    final rows = await (_database.select(
      _database.eventFundingAllocations,
    )..where((table) => table.eventId.equals(eventId))).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<ValidationResult> saveFundMovement({
    required domain.FundMovement movement,
    Money? availableBalance,
  }) async {
    final validation = _validateManualMovementIfNeeded(
      movement: movement,
      availableBalance: availableBalance,
    );
    if (validation.isInvalid) {
      return validation;
    }

    await _database
        .into(_database.fundMovements)
        .insertOnConflictUpdate(movement.toCompanion());
    return const ValidationResult.valid();
  }

  @override
  Future<ValidationResult> updateFundMovement({
    required domain.FundMovement movement,
    Money? availableBalance,
  }) async {
    final existing = await _getFundMovement(movement.id);
    if (existing != null && FundMovementRules.isProtected(existing)) {
      return ValidationResult.failure(
        'System-generated fund movements cannot be updated.',
      );
    }

    final validation = _validateManualMovementIfNeeded(
      movement: movement,
      availableBalance: availableBalance,
    );
    if (validation.isInvalid) {
      return validation;
    }

    await (_database.update(_database.fundMovements)
          ..where((table) => table.id.equals(movement.id)))
        .write(movement.toCompanion());
    return const ValidationResult.valid();
  }

  @override
  Future<ValidationResult> deleteFundMovement(StableId id) async {
    final existing = await _getFundMovement(id);
    if (existing != null && FundMovementRules.isProtected(existing)) {
      return ValidationResult.failure(
        'System-generated fund movements cannot be deleted.',
      );
    }

    await (_database.delete(
      _database.fundMovements,
    )..where((table) => table.id.equals(id))).go();
    return const ValidationResult.valid();
  }

  @override
  Future<List<domain.FundMovement>> listFundMovements() async {
    final rows = await _database.select(_database.fundMovements).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> saveLiquidationReceipt(domain.LiquidationReceipt receipt) {
    return _database
        .into(_database.liquidationReceipts)
        .insertOnConflictUpdate(receipt.toCompanion());
  }

  @override
  Future<List<domain.LiquidationReceipt>> listLiquidationReceipts() async {
    final rows = await _database.select(_database.liquidationReceipts).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> saveLiquidationLine(domain.LiquidationLine line) {
    return _database
        .into(_database.liquidationLines)
        .insertOnConflictUpdate(line.toCompanion());
  }

  @override
  Future<List<domain.LiquidationLine>> listLiquidationLines() async {
    final rows = await _database.select(_database.liquidationLines).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<ValidationResult> saveReimbursementClaim(
    domain.ReimbursementClaim claim,
  ) async {
    if (!claim.amount.isPositive) {
      return ValidationResult.failure(
        'Reimbursement amount must be greater than zero.',
      );
    }
    await _database
        .into(_database.reimbursementClaims)
        .insertOnConflictUpdate(claim.toCompanion());
    return const ValidationResult.valid();
  }

  @override
  Future<List<domain.ReimbursementClaim>> listReimbursementClaims() async {
    final rows = await _database.select(_database.reimbursementClaims).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> saveAuditorReview(domain.AuditorReviewSnapshot review) {
    return _database
        .into(_database.auditorReviews)
        .insertOnConflictUpdate(review.toCompanion());
  }

  @override
  Future<List<domain.AuditorReviewSnapshot>> listAuditorReviews() async {
    final rows = await _database.select(_database.auditorReviews).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<List<domain.AuditorReviewSnapshot>> listAuditorReviewsForEvent(
    StableId eventId,
  ) async {
    final rows = await (_database.select(
      _database.auditorReviews,
    )..where((table) => table.eventId.equals(eventId))).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> appendAuditLog(domain.AuditLogEntry entry) {
    return _database
        .into(_database.auditLogEntries)
        .insert(entry.toCompanion());
  }

  @override
  Future<List<domain.AuditLogEntry>> listAuditLogs() async {
    final rows = await _database.select(_database.auditLogEntries).get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> appendExportHistory(domain.ExportHistoryEntry entry) {
    return _database
        .into(_database.exportHistoryEntries)
        .insert(entry.toCompanion());
  }

  @override
  Future<List<domain.ExportHistoryEntry>> listExportHistory() async {
    final rows =
        await (_database.select(_database.exportHistoryEntries)..orderBy([
              (table) => OrderingTerm(
                expression: table.createdAt,
                mode: OrderingMode.desc,
              ),
              (table) =>
                  OrderingTerm(expression: table.id, mode: OrderingMode.desc),
            ]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  @override
  Future<void> appendBackupHistory(domain.BackupHistoryEntry entry) {
    return _database
        .into(_database.backupHistoryEntries)
        .insert(entry.toCompanion());
  }

  @override
  Future<List<domain.BackupHistoryEntry>> listBackupHistory() async {
    final rows =
        await (_database.select(_database.backupHistoryEntries)..orderBy([
              (table) => OrderingTerm(
                expression: table.createdAt,
                mode: OrderingMode.desc,
              ),
              (table) =>
                  OrderingTerm(expression: table.id, mode: OrderingMode.desc),
            ]))
            .get();
    return rows.map((row) => row.toDomain()).toList(growable: false);
  }

  Future<domain.FundMovement?> _getFundMovement(StableId id) async {
    final row = await (_database.select(
      _database.fundMovements,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  ValidationResult _validateManualMovementIfNeeded({
    required domain.FundMovement movement,
    required Money? availableBalance,
  }) {
    if (movement.isSystemGenerated) {
      return const ValidationResult.valid();
    }
    return FundMovementRules.validateManualMovement(
      type: movement.type,
      amount: movement.amount,
      availableBalance: availableBalance ?? movement.amount,
    );
  }
}
