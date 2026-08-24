import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/liquidation/liquidation_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late LiquidationService service;
  late _DeterministicIdGenerator idGenerator;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    idGenerator = _DeterministicIdGenerator();
    service = LiquidationService(
      repository: repository,
      idGenerator: idGenerator,
      now: () => DateTime(2026, 8, 18, 10),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('builds empty liquidation workspace after setup', () async {
    await _seedSetup(repository);

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.events, isEmpty);
    expect(snapshot.receipts, isEmpty);
    expect(snapshot.reimbursementClaims, isEmpty);
    expect(snapshot.officerOptions, isEmpty);
  });

  test('allows liquidation entries while event is ongoing', () async {
    await _seedOfficer(repository);
    await _seedEvent(
      repository,
      endDate: DateTime(2026, 8, 20),
      approvedBudgetBalance: Money.php(800),
    );
    await _seedFundRelease(repository, amount: Money.php(200));

    final result = await service.submitLiquidation(_command());

    expect(result.isValid, isTrue);
    expect(await repository.listLiquidationReceipts(), hasLength(1));
  });

  test('rejects receipt without attachment metadata', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository);

    final result = await service.submitLiquidation(_command(attachment: null));

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('receipt attachment'));
  });

  test('rejects missing or non-positive line items', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository);

    final noLines = await service.submitLiquidation(_command(lines: const []));
    final badLine = await service.submitLiquidation(
      _command(
        lines: const [
          SubmitLiquidationLineDraft(
            description: '',
            quantity: 0,
            unitCost: Money.zero,
          ),
        ],
      ),
    );

    expect(noLines.summary, contains('At least one liquidation line'));
    expect(badLine.summary, contains('Line item description'));
    expect(badLine.summary, contains('quantity must be greater than zero'));
    expect(badLine.summary, contains('unit cost must be greater than zero'));
  });

  test('rejects released-funds liquidation when officer held funds are insufficient', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository, approvedBudgetBalance: Money.php(900));
    await _seedFundRelease(repository, amount: Money.php(100));

    final result = await service.submitLiquidation(
      _command(
        lines: const [
          SubmitLiquidationLineDraft(
            description: 'Meals',
            quantity: 2,
            unitCost: Money.centavos(10000),
          ),
        ],
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(
      result.summary,
      contains('accountable officer has insufficient held funds'),
    );
  });

  test('valid released-funds liquidation persists receipt, lines, protected movement, audit log, and reduces officer custody only', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository, approvedBudgetBalance: Money.php(1000));
    await _seedFundRelease(repository, amount: Money.php(500));

    final result = await service.submitLiquidation(_command());

    final receipts = await repository.listLiquidationReceipts();
    final lines = await repository.listLiquidationLines();
    final movements = await repository.listFundMovements();
    final logs = await repository.listAuditLogs();
    final event = (await repository.listAuditEvents()).single;

    expect(result.isValid, isTrue);
    expect(receipts.single.payeeOrMerchant, 'Campus Canteen');
    expect(lines.single.total, Money.php(200));
    expect(
      movements.map((movement) => movement.type),
      contains(FundMovementType.liquidationSubmitted),
    );
    expect(movements.last.isSystemGenerated, isTrue);
    expect(logs.single.action, 'liquidation.submit');
    expect(event.approvedBudgetBalance, Money.php(500));

    final officerOptions = await service.listOfficerOptionsForEvent('event-1');
    expect(officerOptions.single.fundCustodyBalance, Money.php(300));
  });

  test('valid out-of-pocket liquidation creates pending claims without decreasing budget', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository, approvedBudgetBalance: Money.php(1000));

    final result = await service.submitLiquidation(
      _command(
        fundingMode: FundingMode.outOfPocket,
        lines: const [
          SubmitLiquidationLineDraft(
            description: 'Meals',
            quantity: 2,
            unitCost: Money.centavos(10000),
          ),
          SubmitLiquidationLineDraft(
            description: 'Printing',
            quantity: 1,
            unitCost: Money.centavos(5000),
          ),
        ],
      ),
    );

    final claims = await repository.listReimbursementClaims();
    final movements = await repository.listFundMovements();
    final event = (await repository.listAuditEvents()).single;

    expect(result.isValid, isTrue);
    expect(claims, hasLength(2));
    expect(claims.first.status, ReimbursementStatus.pending);
    expect(
      claims.fold(Money.zero, (total, claim) => total + claim.amount),
      Money.php(250),
    );
    expect(movements, isEmpty);
    expect(event.approvedBudgetBalance, Money.php(1000));
  });

  test(
    'rejects reimbursement payment when approved budget is insufficient',
    () async {
      await _seedOfficer(repository);
      await _seedEvent(repository, approvedBudgetBalance: Money.php(100));
      await service.submitLiquidation(
        _command(fundingMode: FundingMode.outOfPocket),
      );
      final claim = (await repository.listReimbursementClaims()).single;

      final result = await service.payReimbursement(
        PayReimbursementCommand(
          claimId: claim.id,
          paymentDate: DateTime(2026, 8, 18),
        ),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.summary,
        contains('Approved Budget balance is insufficient'),
      );
    },
  );

  test('valid reimbursement payment creates protected movement, marks paid, logs, and decreases budget', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository, approvedBudgetBalance: Money.php(1000));
    await service.submitLiquidation(
      _command(fundingMode: FundingMode.outOfPocket),
    );
    final claim = (await repository.listReimbursementClaims()).single;

    final result = await service.payReimbursement(
      PayReimbursementCommand(
        claimId: claim.id,
        paymentDate: DateTime(2026, 8, 18),
      ),
    );

    final paidClaim = (await repository.listReimbursementClaims()).single;
    final movements = await repository.listFundMovements();
    final logs = await repository.listAuditLogs();
    final event = (await repository.listAuditEvents()).single;

    expect(result.isValid, isTrue);
    expect(paidClaim.status, ReimbursementStatus.paid);
    expect(movements.single.type, FundMovementType.reimbursementPayment);
    expect(movements.single.isSystemGenerated, isTrue);
    expect(logs.map((log) => log.action), contains('reimbursement.pay'));
    expect(event.approvedBudgetBalance, Money.php(800));
  });

  test('does not mark event liquidated while claims remain pending', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository);
    await service.submitLiquidation(
      _command(fundingMode: FundingMode.outOfPocket),
    );

    final result = await service.markEventLiquidated('event-1');

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Pending reimbursement claims'));
  });

  test('marks event liquidated only after explicit mark', () async {
    await _seedOfficer(repository);
    await _seedEvent(repository);
    await _seedFundRelease(repository, amount: Money.php(500));
    await service.submitLiquidation(_command());

    var snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));
    expect(snapshot.events.single.status, AuditEventStatus.forLiquidation);

    final result = await service.markEventLiquidated('event-1');
    snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(result.isValid, isTrue);
    expect(snapshot.events.single.status, AuditEventStatus.liquidated);
  });
}

SubmitLiquidationCommand _command({
  FundingMode fundingMode = FundingMode.releasedFunds,
  AttachmentRef? attachment = _attachment,
  List<SubmitLiquidationLineDraft> lines = const [
    SubmitLiquidationLineDraft(
      description: 'Meals',
      quantity: 2,
      unitCost: Money.centavos(10000),
    ),
  ],
}) {
  return SubmitLiquidationCommand(
    eventId: 'event-1',
    payeeOrMerchant: 'Campus Canteen',
    date: DateTime(2026, 8, 18),
    evidenceNumber: 'OR-100',
    receiptType: ReceiptType.officialReceipt,
    fundingMode: fundingMode,
    accountableOfficerId: 'officer-1',
    attachment: attachment,
    lines: lines,
  );
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

Future<void> _seedOfficer(DriftAuditRepository repository) {
  return repository.saveOfficers([
    const Officer(
      id: 'officer-1',
      fullName: 'Ari Santos',
      position: OfficerPosition.member,
      committee: Committee.finance,
    ),
  ]);
}

Future<void> _seedEvent(
  DriftAuditRepository repository, {
  DateTime? endDate,
  Money approvedBudgetBalance = const Money.centavos(100000),
}) async {
  await repository.updateTreasuryFundSource(
    const TreasuryFundSource(
      id: 'source-1',
      type: TreasuryFundSourceType.studentCollections,
      label: 'Student Collections',
      balance: Money.centavos(1000000),
      supportingAttachment: _attachment,
    ),
  );
  await repository.saveAuditEvent(
    event: AuditEvent(
      id: 'event-1',
      name: 'Leadership Summit',
      type: 'Leadership',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      startDate: DateTime(2026, 8, 10),
      endDate: endDate ?? DateTime(2026, 8, 16),
      resolutionNumber: 'RES-2026-001',
      budget: Money.php(1000),
      approvedBudgetBalance: approvedBudgetBalance,
      resolutionAttachment: _attachment,
    ),
    allocations: const [
      EventFundingAllocation(
        eventId: 'event-1',
        fundSourceId: 'source-1',
        amount: Money.centavos(100000),
      ),
    ],
  );
}

Future<void> _seedFundRelease(
  DriftAuditRepository repository, {
  required Money amount,
}) async {
  final event = (await repository.listAuditEvents()).single;
  await repository.updateAuditEvent(
    AuditEvent(
      id: event.id,
      name: event.name,
      type: event.type,
      semester: event.semester,
      schoolYear: event.schoolYear,
      startDate: event.startDate,
      endDate: event.endDate,
      permitApprovalDate: event.permitApprovalDate,
      resolutionNumber: event.resolutionNumber,
      budget: event.budget,
      approvedBudgetBalance: event.approvedBudgetBalance - amount,
      resolutionAttachment: event.resolutionAttachment,
      isLiquidated: event.isLiquidated,
    ),
  );
  await repository.saveFundMovement(
    movement: FundMovement(
      id: 'release-1',
      reference: 'FM-20260818-RELEASE',
      type: FundMovementType.fundRelease,
      date: DateTime(2026, 8, 18),
      amount: amount,
      purpose: 'Release to officer',
      eventId: event.id,
      holderOfficerId: 'officer-1',
      isSystemGenerated: false,
    ),
  );
}

class _DeterministicIdGenerator implements StableIdGenerator {
  var _counter = 0;

  @override
  StableId nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'receipt.pdf',
  localPath: 'attachments/receipt.pdf',
);
