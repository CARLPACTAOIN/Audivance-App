import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/treasury/treasury_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late TreasuryService service;
  late _DeterministicIdGenerator idGenerator;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    idGenerator = _DeterministicIdGenerator();
    service = TreasuryService(
      repository: repository,
      idGenerator: idGenerator,
      now: () => DateTime(2026, 8, 18, 10),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('builds empty treasury snapshot after setup', () async {
    await _seedSetup(repository);

    final snapshot = await service.loadSnapshot();

    expect(snapshot.totalBalance, Money.zero);
    expect(snapshot.sources, isEmpty);
    expect(snapshot.ledgerRows, isEmpty);
  });

  test('rejects Add Fund without attachment metadata', () async {
    await _seedSetup(repository);

    final result = await service.addFund(
      AddFundCommand(
        type: TreasuryFundSourceType.studentCollections,
        label: 'Student Collections',
        amount: Money.php(5000),
        date: DateTime(2026, 8, 18),
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('supporting document attachment'));
    expect(await repository.listTreasuryFundSources(), isEmpty);
  });

  test('Add Fund creates source balance, movement, and audit log', () async {
    await _seedSetup(repository);

    final result = await service.addFund(
      AddFundCommand(
        type: TreasuryFundSourceType.studentCollections,
        label: 'Student Collections',
        amount: Money.centavos(1284550),
        date: DateTime(2026, 8, 18),
        supportingAttachment: _attachment,
      ),
    );

    final sources = await repository.listTreasuryFundSources();
    final movements = await repository.listFundMovements();
    final logs = await repository.listAuditLogs();

    expect(result.isValid, isTrue);
    expect(sources.single.balance, const Money.centavos(1284550));
    expect(movements.single.type, FundMovementType.addFund);
    expect(movements.single.isSystemGenerated, isTrue);
    expect(movements.single.reference, startsWith('FM-20260818-'));
    expect(logs.single.action, 'treasury.add_fund');
  });

  test(
    'Add Fund to existing source increases balance without precision loss',
    () async {
      await _seedSetup(repository);
      await service.addFund(
        AddFundCommand(
          type: TreasuryFundSourceType.studentCollections,
          label: 'Student Collections',
          amount: Money.centavos(1000050),
          date: DateTime(2026, 8, 18),
          supportingAttachment: _attachment,
        ),
      );
      final existing = (await repository.listTreasuryFundSources()).single;

      final result = await service.addFund(
        AddFundCommand(
          existingSourceId: existing.id,
          type: TreasuryFundSourceType.studentCollections,
          label: 'Ignored label',
          amount: Money.centavos(284500),
          date: DateTime(2026, 8, 19),
          supportingAttachment: _attachment,
        ),
      );

      final sources = await repository.listTreasuryFundSources();

      expect(result.isValid, isTrue);
      expect(sources, hasLength(1));
      expect(sources.single.balance, const Money.centavos(1284550));
    },
  );

  test('rejects manual system-only movement type', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    final result = await service.recordManualMovement(
      ManualFundMovementCommand(
        type: FundMovementType.budgetAllocation,
        amount: Money.php(1000),
        date: DateTime(2026, 8, 18),
        purpose: 'Invalid manual movement',
        fromFundSourceId: 'source-1',
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Manual fund movements are limited'));
  });

  test(
    'rejects transfer or release when source balance is insufficient',
    () async {
      await _seedSource(repository, id: 'source-1', balance: Money.php(500));
      await _seedSource(repository, id: 'source-2', balance: Money.php(100));

      final releaseResult = await service.recordManualMovement(
        ManualFundMovementCommand(
          type: FundMovementType.fundRelease,
          amount: Money.php(600),
          date: DateTime(2026, 8, 18),
          purpose: 'Release to officer',
          fromFundSourceId: 'source-1',
        ),
      );
      final transferResult = await service.recordManualMovement(
        ManualFundMovementCommand(
          type: FundMovementType.transfer,
          amount: Money.php(600),
          date: DateTime(2026, 8, 18),
          purpose: 'Move collections',
          fromFundSourceId: 'source-1',
          toFundSourceId: 'source-2',
        ),
      );

      expect(releaseResult.isInvalid, isTrue);
      expect(transferResult.isInvalid, isTrue);
      expect(await repository.listFundMovements(), isEmpty);
    },
  );

  test('valid transfer decreases source and increases target', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));
    await _seedSource(repository, id: 'source-2', balance: Money.php(1000));

    final result = await service.recordManualMovement(
      ManualFundMovementCommand(
        type: FundMovementType.transfer,
        amount: Money.php(1500),
        date: DateTime(2026, 8, 18),
        purpose: 'Transfer to sponsor fund',
        fromFundSourceId: 'source-1',
        toFundSourceId: 'source-2',
      ),
    );

    final sources = {
      for (final source in await repository.listTreasuryFundSources())
        source.id: source,
    };

    expect(result.isValid, isTrue);
    expect(sources['source-1']!.balance, Money.php(3500));
    expect(sources['source-2']!.balance, Money.php(2500));
  });

  test('valid return or refund increases target source', () async {
    await _seedSource(repository, id: 'source-1', balance: Money.php(5000));

    final result = await service.recordManualMovement(
      ManualFundMovementCommand(
        type: FundMovementType.returnRefund,
        amount: Money.php(750),
        date: DateTime(2026, 8, 18),
        purpose: 'Returned excess event funds',
        toFundSourceId: 'source-1',
      ),
    );

    final source = (await repository.listTreasuryFundSources()).single;

    expect(result.isValid, isTrue);
    expect(source.balance, Money.php(5750));
  });

  test('ledger rows sort newest first and preserve system flag', () async {
    await _seedSetup(repository);
    await service.addFund(
      AddFundCommand(
        type: TreasuryFundSourceType.previousAdmin,
        label: 'Previous Admin',
        amount: Money.php(1000),
        date: DateTime(2026, 8, 17),
        supportingAttachment: _attachment,
      ),
    );
    final source = (await repository.listTreasuryFundSources()).single;
    await service.recordManualMovement(
      ManualFundMovementCommand(
        type: FundMovementType.fundRelease,
        amount: Money.php(250),
        date: DateTime(2026, 8, 18),
        purpose: 'Release cash',
        fromFundSourceId: source.id,
      ),
    );

    final snapshot = await service.loadSnapshot();

    expect(snapshot.ledgerRows.first.type, FundMovementType.fundRelease);
    expect(snapshot.ledgerRows.first.isSystemGenerated, isFalse);
    expect(snapshot.ledgerRows.last.type, FundMovementType.addFund);
    expect(snapshot.ledgerRows.last.isSystemGenerated, isTrue);
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
  fileName: 'support.pdf',
  localPath: 'attachments/support.pdf',
);
