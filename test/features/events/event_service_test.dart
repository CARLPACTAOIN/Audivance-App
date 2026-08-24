import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/events/event_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late EventService service;
  late _DeterministicIdGenerator idGenerator;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    idGenerator = _DeterministicIdGenerator();
    service = EventService(
      repository: repository,
      idGenerator: idGenerator,
      now: () => DateTime(2026, 8, 18, 10),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('builds empty Events snapshot after setup', () async {
    await _seedSetup(repository);

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.events, isEmpty);
    expect(snapshot.sourceOptions, isEmpty);
  });

  test('rejects event creation when no Treasury sources exist', () async {
    await _seedSetup(repository);

    final result = await service.createEvent(_command());

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Create at least one Treasury source'));
    expect(await repository.listAuditEvents(), isEmpty);
  });

  test('rejects event creation without resolution attachment', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    final result = await service.createEvent(
      _command(resolutionAttachment: null),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('resolution attachment'));
  });

  test(
    'rejects event creation when allocation total does not equal budget',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

      final result = await service.createEvent(
        _command(
          budget: Money.php(4000),
          allocations: const [
            EventAllocationDraft(
              fundSourceId: 'source-1',
              amount: Money.centavos(300000),
            ),
          ],
        ),
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('Split funding allocations must equal'));
    },
  );

  test(
    'rejects event creation when allocation exceeds source balance',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(3000));

      final result = await service.createEvent(
        _command(
          budget: Money.php(4000),
          allocations: const [
            EventAllocationDraft(
              fundSourceId: 'source-1',
              amount: Money.centavos(400000),
            ),
          ],
        ),
      );

      expect(result.isInvalid, isTrue);
      expect(result.summary, contains('insufficient balance'));
    },
  );

  test('valid event persists event and allocations', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    final result = await service.createEvent(_command());

    final events = await repository.listAuditEvents();
    final allocations = await repository.listEventFundingAllocations(
      events.single.id,
    );

    expect(result.isValid, isTrue);
    expect(events.single.name, 'Leadership Summit');
    expect(allocations.single.amount, Money.php(4000));
  });

  test('valid event decreases Treasury source balances', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    await service.createEvent(_command());

    final source = (await repository.listTreasuryFundSources()).single;

    expect(source.balance, Money.php(1000));
  });

  test(
    'duplicate source allocations decrease balance by aggregate amount',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

      final result = await service.createEvent(
        _command(
          budget: Money.php(4000),
          allocations: const [
            EventAllocationDraft(
              fundSourceId: 'source-1',
              amount: Money.centavos(150000),
            ),
            EventAllocationDraft(
              fundSourceId: 'source-1',
              amount: Money.centavos(250000),
            ),
          ],
        ),
      );

      final source = (await repository.listTreasuryFundSources()).single;
      final movements = await repository.listFundMovements();

      expect(result.isValid, isTrue);
      expect(source.balance, Money.php(1000));
      expect(movements, hasLength(2));
    },
  );

  test(
    'valid event creates system-generated budget allocation movement',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

      await service.createEvent(_command());

      final movements = await repository.listFundMovements();

      expect(movements.single.type, FundMovementType.budgetAllocation);
      expect(movements.single.isSystemGenerated, isTrue);
      expect(movements.single.reference, startsWith('FM-20260818-'));
    },
  );

  test('valid event appends audit log', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    await service.createEvent(_command());

    final logs = await repository.listAuditLogs();

    expect(logs.single.action, 'events.create');
    expect(logs.single.amount, Money.php(4000));
  });

  test('event statuses use EventRules calculation', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(10000));
    await repository.saveAuditEvent(
      event: _event(id: 'ongoing', endDate: DateTime(2026, 8, 20)),
      allocations: const [
        EventFundingAllocation(
          eventId: 'ongoing',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
    await repository.saveAuditEvent(
      event: _event(id: 'for-liquidation', endDate: DateTime(2026, 8, 16)),
      allocations: const [
        EventFundingAllocation(
          eventId: 'for-liquidation',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
    await repository.saveAuditEvent(
      event: _event(id: 'due', endDate: DateTime(2026, 8, 10)),
      allocations: const [
        EventFundingAllocation(
          eventId: 'due',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
    await repository.saveAuditEvent(
      event: _event(
        id: 'liquidated',
        endDate: DateTime(2026, 8, 10),
        isLiquidated: true,
      ),
      allocations: const [
        EventFundingAllocation(
          eventId: 'liquidated',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));
    final statuses = {
      for (final event in snapshot.events) event.id: event.status,
    };

    expect(statuses['ongoing'], AuditEventStatus.ongoing);
    expect(statuses['for-liquidation'], AuditEventStatus.forLiquidation);
    expect(statuses['due'], AuditEventStatus.due);
    expect(statuses['liquidated'], AuditEventStatus.liquidated);
  });

  test('budget increase is rejected when event is missing', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    final result = await service.adjustEventBudget(
      _adjustCommand(eventId: 'missing-event'),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Selected event does not exist.'));
  });

  test('budget increase is rejected without remarks', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);

    final result = await service.adjustEventBudget(_adjustCommand(remarks: ''));

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('remarks are required'));
  });

  test(
    'budget increase is rejected when source balance is insufficient',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(1000));
      await _seedAdjustableEvent(repository);
      await _seedSource(repository, id: 'source-1', balance: Money.php(100));

      final result = await service.adjustEventBudget(
        _adjustCommand(amount: Money.php(500)),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.summary,
        contains('source treasury balance is insufficient'),
      );
    },
  );

  test('valid budget increase updates event and source balances', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);

    final result = await service.adjustEventBudget(
      _adjustCommand(amount: Money.php(500)),
    );

    final event = (await repository.listAuditEvents()).single;
    final source = (await repository.listTreasuryFundSources()).single;

    expect(result.isValid, isTrue);
    expect(event.budget, Money.php(1500));
    expect(event.approvedBudgetBalance, Money.php(1300));
    expect(source.balance, Money.php(4500));
  });

  test(
    'valid budget increase creates protected movement and audit log',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
      await _seedAdjustableEvent(repository);

      await service.adjustEventBudget(_adjustCommand(amount: Money.php(500)));

      final movements = await repository.listFundMovements();
      final logs = await repository.listAuditLogs();

      expect(movements.single.type, FundMovementType.budgetAdjustment);
      expect(movements.single.isSystemGenerated, isTrue);
      expect(movements.single.fromFundSourceId, 'source-1');
      expect(movements.single.toFundSourceId, isNull);
      expect(movements.single.remarks, 'Approved by adviser');
      expect(logs.single.action, 'events.budgetIncrease');
      expect(logs.single.amount, Money.php(500));
    },
  );

  test(
    'budget decrease is rejected when approved balance is insufficient',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
      await _seedAdjustableEvent(repository);

      final result = await service.adjustEventBudget(
        _adjustCommand(
          direction: BudgetAdjustmentDirection.decrease,
          amount: Money.php(900),
        ),
      );

      expect(result.isInvalid, isTrue);
      expect(
        result.summary,
        contains('event Approved Budget balance is insufficient'),
      );
    },
  );

  test(
    'valid budget decrease updates event and returns funds to source',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
      await _seedAdjustableEvent(repository);

      final result = await service.adjustEventBudget(
        _adjustCommand(
          direction: BudgetAdjustmentDirection.decrease,
          amount: Money.php(300),
        ),
      );

      final event = (await repository.listAuditEvents()).single;
      final source = (await repository.listTreasuryFundSources()).single;
      final movement = (await repository.listFundMovements()).single;

      expect(result.isValid, isTrue);
      expect(event.budget, Money.php(700));
      expect(event.approvedBudgetBalance, Money.php(500));
      expect(source.balance, Money.php(5300));
      expect(movement.fromFundSourceId, isNull);
      expect(movement.toFundSourceId, 'source-1');
    },
  );

  test('budget adjustment is rejected for liquidated events', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository, isLiquidated: true);

    final result = await service.adjustEventBudget(_adjustCommand());

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Liquidated events cannot be adjusted.'));
  });

  test(
    'original event funding allocations remain unchanged after adjustment',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
      await _seedAdjustableEvent(repository);

      await service.adjustEventBudget(_adjustCommand(amount: Money.php(500)));

      final allocations = await repository.listEventFundingAllocations(
        'event-1',
      );

      expect(allocations.single.amount, Money.php(1000));
    },
  );

  test('budget actual starts with zero actual and healthy status', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);

    final snapshot = await service.loadBudgetActual(
      'event-1',
      asOf: DateTime(2026, 8, 18),
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.actual, Money.zero);
    expect(snapshot.variance, Money.php(1000));
    expect(snapshot.utilizationBasisPoints, 0);
    expect(snapshot.health, BudgetHealth.healthy);
  });

  test('liquidation lines increase actual total', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);
    await _seedReceiptWithLines(
      repository,
      eventId: 'event-1',
      receiptId: 'receipt-1',
      lineTotals: [Money.php(250), Money.php(125, 50)],
    );

    final snapshot = await service.loadBudgetActual(
      'event-1',
      asOf: DateTime(2026, 8, 18),
    );

    expect(snapshot!.actual, const Money.centavos(37550));
    expect(snapshot.variance, const Money.centavos(62450));
  });

  test('pending and paid reimbursements are counted separately', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);
    await repository.saveReimbursementClaim(
      const ReimbursementClaim(
        id: 'claim-1',
        eventId: 'event-1',
        officerId: 'officer-1',
        amount: Money.centavos(12000),
        status: ReimbursementStatus.pending,
        sourceLiquidationLineId: 'line-1',
      ),
    );
    await repository.saveReimbursementClaim(
      const ReimbursementClaim(
        id: 'claim-2',
        eventId: 'event-1',
        officerId: 'officer-1',
        amount: Money.centavos(8000),
        status: ReimbursementStatus.paid,
        sourceLiquidationLineId: 'line-2',
      ),
    );

    final snapshot = await service.loadBudgetActual(
      'event-1',
      asOf: DateTime(2026, 8, 18),
    );

    expect(snapshot!.pendingReimbursementTotal, Money.php(120));
    expect(snapshot.paidReimbursementTotal, Money.php(80));
  });

  test('utilization and health use integer centavo calculations', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await repository.saveAuditEvent(
      event: _event(id: 'event-1', endDate: DateTime(2026, 8, 16)),
      allocations: const [
        EventFundingAllocation(
          eventId: 'event-1',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
    await _seedReceiptWithLines(
      repository,
      eventId: 'event-1',
      receiptId: 'receipt-1',
      lineTotals: [Money.php(833, 33)],
    );

    final snapshot = await service.loadBudgetActual(
      'event-1',
      asOf: DateTime(2026, 8, 18),
    );

    expect(snapshot!.utilizationBasisPoints, 8333);
    expect(snapshot.utilizationLabel, '83.33%');
    expect(snapshot.health, BudgetHealth.watch);
  });

  test('budget health marks over budget and critical thresholds', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await repository.saveAuditEvent(
      event: _event(id: 'over', endDate: DateTime(2026, 8, 16)),
      allocations: const [
        EventFundingAllocation(
          eventId: 'over',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
    await repository.saveAuditEvent(
      event: _event(id: 'critical', endDate: DateTime(2026, 8, 16)),
      allocations: const [
        EventFundingAllocation(
          eventId: 'critical',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
    await _seedReceiptWithLines(
      repository,
      eventId: 'over',
      receiptId: 'receipt-over',
      lineTotals: [Money.php(1100)],
    );
    await _seedReceiptWithLines(
      repository,
      eventId: 'critical',
      receiptId: 'receipt-critical',
      lineTotals: [Money.php(1250)],
    );

    final over = await service.loadBudgetActual(
      'over',
      asOf: DateTime(2026, 8, 18),
    );
    final critical = await service.loadBudgetActual(
      'critical',
      asOf: DateTime(2026, 8, 18),
    );

    expect(over!.health, BudgetHealth.overBudget);
    expect(critical!.health, BudgetHealth.critical);
  });

  test('review creation is rejected for missing event', () async {
    final result = await service.createAuditorReview(
      const CreateAuditorReviewCommand(
        eventId: 'missing',
        findings: 'Within plan',
        cause: 'Careful purchasing',
        recommendation: 'Continue monitoring',
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Selected event does not exist.'));
  });

  test('review creation requires findings cause and recommendation', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);

    final result = await service.createAuditorReview(
      const CreateAuditorReviewCommand(
        eventId: 'event-1',
        findings: '',
        cause: '',
        recommendation: '',
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Findings are required.'));
    expect(result.summary, contains('Cause is required.'));
    expect(result.summary, contains('Recommendation is required.'));
  });

  test('valid review persists captured values and audit log', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedAdjustableEvent(repository);
    await _seedReceiptWithLines(
      repository,
      eventId: 'event-1',
      receiptId: 'receipt-1',
      lineTotals: [Money.php(250)],
    );

    final result = await service.createAuditorReview(
      CreateAuditorReviewCommand(
        eventId: 'event-1',
        findings: 'Spending stayed below budget.',
        cause: 'Supplier discount',
        recommendation: 'Keep vendor quote documentation.',
        createdAt: DateTime(2026, 8, 18, 12),
      ),
    );

    final reviews = await repository.listAuditorReviewsForEvent('event-1');
    final logs = await repository.listAuditLogs();

    expect(result.isValid, isTrue);
    expect(reviews.single.actual, Money.php(250));
    expect(reviews.single.variance, Money.php(750));
    expect(reviews.single.health, BudgetHealth.healthy);
    expect(logs.single.action, 'events.auditorReview');
  });

  test(
    'later event changes do not mutate prior review snapshot values',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
      await _seedAdjustableEvent(repository);
      await _seedReceiptWithLines(
        repository,
        eventId: 'event-1',
        receiptId: 'receipt-1',
        lineTotals: [Money.php(250)],
      );
      await service.createAuditorReview(
        CreateAuditorReviewCommand(
          eventId: 'event-1',
          findings: 'Initial review.',
          cause: 'Initial liquidation.',
          recommendation: 'Monitor remaining expenses.',
          createdAt: DateTime(2026, 8, 18, 12),
        ),
      );

      await _seedReceiptWithLines(
        repository,
        eventId: 'event-1',
        receiptId: 'receipt-2',
        lineTotals: [Money.php(300)],
      );

      final reviews = await repository.listAuditorReviewsForEvent('event-1');
      final current = await service.loadBudgetActual(
        'event-1',
        asOf: DateTime(2026, 8, 18),
      );

      expect(reviews.single.actual, Money.php(250));
      expect(current!.actual, Money.php(550));
    },
  );
}

CreateEventCommand _command({
  Money budget = const Money.centavos(400000),
  AttachmentRef? resolutionAttachment = _attachment,
  List<EventAllocationDraft> allocations = const [
    EventAllocationDraft(
      fundSourceId: 'source-1',
      amount: Money.centavos(400000),
    ),
  ],
}) {
  return CreateEventCommand(
    name: 'Leadership Summit',
    type: 'Leadership',
    semester: '1st Semester',
    schoolYear: '2026-2027',
    startDate: DateTime(2026, 8, 20),
    endDate: DateTime(2026, 8, 21),
    resolutionNumber: 'RES-2026-001',
    budget: budget,
    resolutionAttachment: resolutionAttachment,
    allocations: allocations,
  );
}

AuditEvent _event({
  required StableId id,
  required DateTime endDate,
  bool isLiquidated = false,
}) {
  return AuditEvent(
    id: id,
    name: id,
    type: 'Academic',
    semester: '1st Semester',
    schoolYear: '2026-2027',
    startDate: DateTime(2026, 8, 8),
    endDate: endDate,
    resolutionNumber: 'RES-$id',
    budget: Money.php(1000),
    approvedBudgetBalance: Money.php(1000),
    resolutionAttachment: _attachment,
    isLiquidated: isLiquidated,
  );
}

AdjustEventBudgetCommand _adjustCommand({
  StableId eventId = 'event-1',
  BudgetAdjustmentDirection direction = BudgetAdjustmentDirection.increase,
  Money amount = const Money.centavos(50000),
  StableId treasurySourceId = 'source-1',
  String remarks = 'Approved by adviser',
}) {
  return AdjustEventBudgetCommand(
    eventId: eventId,
    direction: direction,
    amount: amount,
    treasurySourceId: treasurySourceId,
    adjustmentDate: DateTime(2026, 8, 18),
    remarks: remarks,
  );
}

Future<void> _seedAdjustableEvent(
  DriftAuditRepository repository, {
  bool isLiquidated = false,
}) async {
  await repository.saveAuditEvent(
    event: AuditEvent(
      id: 'event-1',
      name: 'Leadership Summit',
      type: 'Leadership',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 16),
      resolutionNumber: 'RES-2026-001',
      budget: Money.php(1000),
      approvedBudgetBalance: Money.php(800),
      resolutionAttachment: _attachment,
      isLiquidated: isLiquidated,
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

Future<void> _seedReceiptWithLines(
  DriftAuditRepository repository, {
  required StableId eventId,
  required StableId receiptId,
  required List<Money> lineTotals,
}) async {
  await repository.saveLiquidationReceipt(
    LiquidationReceipt(
      id: receiptId,
      eventId: eventId,
      payeeOrMerchant: 'Campus Supplier',
      date: DateTime(2026, 8, 18),
      evidenceNumber: 'OR-$receiptId',
      receiptType: ReceiptType.officialReceipt,
      fundingMode: FundingMode.releasedFunds,
      accountableOfficerId: 'officer-1',
      attachment: _attachment,
    ),
  );
  for (var index = 0; index < lineTotals.length; index += 1) {
    await repository.saveLiquidationLine(
      LiquidationLine(
        id: '$receiptId-line-$index',
        receiptId: receiptId,
        description: 'Expense $index',
        quantity: 1,
        unitCost: lineTotals[index],
      ),
    );
  }
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

Future<void> _seedSource(
  DriftAuditRepository repository, {
  required StableId id,
  required Money balance,
}) {
  return repository.updateTreasuryFundSource(
    TreasuryFundSource(
      id: id,
      type: TreasuryFundSourceType.studentCollections,
      label: id,
      balance: balance,
      supportingAttachment: _attachment,
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
  fileName: 'resolution.pdf',
  localPath: 'attachments/resolution.pdf',
);
