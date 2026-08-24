import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/dashboard/dashboard_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late DashboardService service;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    service = DashboardService(repository);
  });

  tearDown(() async {
    await database.close();
  });

  test('builds empty workspace dashboard after setup', () async {
    await _seedSetup(repository);

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(
      snapshot.organizationName,
      'Junior Philippine Institute of Accountants',
    );
    expect(snapshot.term, '1st Semester, SY 2026-2027');
    expect(snapshot.metrics[0].value, 'PHP 0');
    expect(snapshot.metrics[0].detail, '0 source funds');
    expect(snapshot.metrics[1].value, 'PHP 0');
    expect(snapshot.movements, isEmpty);
    expect(snapshot.tasks.first.title, 'Add the first treasury source');
  });

  test('sums treasury balance across all fund sources', () async {
    await _seedSetup(repository);
    await repository.saveTreasuryFundSource(
      const TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.studentCollections,
        label: 'Collections',
        balance: Money.centavos(1000000),
        supportingAttachment: _attachment,
      ),
    );
    await repository.saveTreasuryFundSource(
      const TreasuryFundSource(
        id: 'source-2',
        type: TreasuryFundSourceType.donationSponsor,
        label: 'Donation',
        balance: Money.centavos(284500),
        supportingAttachment: _attachment,
      ),
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.metrics[0].value, 'PHP 12,845');
    expect(snapshot.metrics[0].detail, '2 source funds');
  });

  test('totals approved budget from persisted events', () async {
    await _seedSetup(repository);
    await _seedTreasury(repository);
    await _saveEvent(repository, id: 'event-1', budget: Money.php(22000));
    await _saveEvent(repository, id: 'event-2', budget: Money.php(14000));

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.metrics[1].value, 'PHP 36,000');
    expect(snapshot.metrics[1].detail, '2 events');
  });

  test('counts event liquidation statuses using event rules', () async {
    await _seedSetup(repository);
    await _seedTreasury(repository);
    await _saveEvent(
      repository,
      id: 'ongoing',
      budget: Money.php(1000),
      endDate: DateTime(2026, 8, 20),
    );
    await _saveEvent(
      repository,
      id: 'for-liquidation',
      budget: Money.php(1000),
      endDate: DateTime(2026, 8, 16),
    );
    await _saveEvent(
      repository,
      id: 'due',
      budget: Money.php(1000),
      endDate: DateTime(2026, 8, 10),
    );
    await _saveEvent(
      repository,
      id: 'liquidated',
      budget: Money.php(1000),
      endDate: DateTime(2026, 8, 10),
      isLiquidated: true,
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.metrics[2].value, '2 events');
    expect(snapshot.metrics[2].detail, '1 due now');
  });

  test('pending reimbursement total includes only pending claims', () async {
    await _seedSetup(repository);
    await repository.saveReimbursementClaim(
      const ReimbursementClaim(
        id: 'claim-1',
        eventId: 'event-1',
        officerId: 'officer-1',
        amount: Money.centavos(785000),
        status: ReimbursementStatus.pending,
        sourceLiquidationLineId: 'line-1',
      ),
    );
    await repository.saveReimbursementClaim(
      const ReimbursementClaim(
        id: 'claim-2',
        eventId: 'event-1',
        officerId: 'officer-1',
        amount: Money.centavos(100000),
        status: ReimbursementStatus.paid,
        sourceLiquidationLineId: 'line-2',
      ),
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.metrics[3].value, 'PHP 7,850');
    expect(snapshot.metrics[3].detail, '1 reimbursement');
  });

  test('recent movements sort newest first and preserve system flag', () async {
    await _seedSetup(repository);
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'movement-old',
        reference: 'FM-20260817-OLD',
        type: FundMovementType.addFund,
        date: DateTime(2026, 8, 17),
        amount: Money.php(1000),
        purpose: 'Older movement',
        isSystemGenerated: true,
      ),
    );
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'movement-new',
        reference: 'FM-20260818-NEW',
        type: FundMovementType.fundRelease,
        date: DateTime(2026, 8, 18),
        amount: Money.php(500),
        purpose: 'Newer movement',
        isSystemGenerated: false,
      ),
      availableBalance: Money.php(1000),
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.movements.first.reference, 'FM-20260818-NEW');
    expect(snapshot.movements.first.isSystemGenerated, isFalse);
    expect(snapshot.movements.last.reference, 'FM-20260817-OLD');
    expect(snapshot.movements.last.isSystemGenerated, isTrue);
  });
}

Future<void> _seedSetup(DriftAuditRepository repository) async {
  await repository.saveLocalAccount(
    LocalAccountProfile(
      id: 'account-1',
      displayName: 'Local Auditor',
      emailOrStudentId: 'auditor@example.test',
      createdAt: DateTime(2026, 8, 18, 9),
      isCredentialConfigured: true,
    ),
  );
  await repository.saveOrganization(
    const OrganizationProfile(
      id: 'org-1',
      name: 'Junior Philippine Institute of Accountants',
      type: 'Academic',
      adviser: 'Prof. Santos',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      signatoryNames: ['Ari Santos', 'Bea Reyes'],
    ),
  );
}

Future<void> _seedTreasury(DriftAuditRepository repository) async {
  await repository.saveTreasuryFundSource(
    const TreasuryFundSource(
      id: 'source-1',
      type: TreasuryFundSourceType.studentCollections,
      label: 'Collections',
      balance: Money.centavos(10000000),
      supportingAttachment: _attachment,
    ),
  );
}

Future<void> _saveEvent(
  DriftAuditRepository repository, {
  required String id,
  required Money budget,
  DateTime? endDate,
  bool isLiquidated = false,
}) async {
  await repository.saveAuditEvent(
    event: AuditEvent(
      id: id,
      name: id,
      type: 'Academic',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      startDate: DateTime(2026, 8, 8),
      endDate: endDate ?? DateTime(2026, 8, 9),
      resolutionNumber: 'RES-$id',
      budget: budget,
      approvedBudgetBalance: budget,
      resolutionAttachment: _attachment,
      isLiquidated: isLiquidated,
    ),
    allocations: [
      EventFundingAllocation(
        eventId: id,
        fundSourceId: 'source-1',
        amount: budget,
      ),
    ],
  );
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'support.pdf',
  localPath: 'attachments/support.pdf',
);
