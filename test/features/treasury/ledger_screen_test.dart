import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/treasury/ledger_screen.dart';
import 'package:audivance/features/treasury/treasury_service.dart';
import 'package:drift/native.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late _TestIdGenerator idGenerator;
  late TreasuryService service;

  setUp(() async {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    idGenerator = _TestIdGenerator();
    service = TreasuryService(
      repository: repository,
      idGenerator: idGenerator,
      now: () => DateTime(2026, 8, 25),
    );

    // Seed movements
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'mov-1',
        reference: 'TR-001',
        type: FundMovementType.addFund,
        date: DateTime(2026, 8, 1),
        amount: Money.php(5000),
        purpose: 'Initial Student Collections Deposit',
        remarks: 'Official receipt #1001',
        toFundSourceId: 'source-1',
        isSystemGenerated: true,
      ),
    );
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'mov-2',
        reference: 'TR-002',
        type: FundMovementType.fundRelease,
        date: DateTime(2026, 8, 10),
        amount: Money.php(2000),
        purpose: 'Cash Advance for Leadership Seminar',
        holderOfficerId: 'officer-1',
        eventId: 'event-1',
        isSystemGenerated: false,
      ),
    );
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'mov-3',
        reference: 'TR-003',
        type: FundMovementType.returnRefund,
        date: DateTime(2026, 8, 15),
        amount: Money.php(500),
        purpose: 'Unused Cash Advance Return',
        toFundSourceId: 'source-1',
        isSystemGenerated: false,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Widget createSubject() {
    return MaterialApp(home: LedgerScreen(service: service));
  }

  testWidgets('LedgerScreen renders all records and search bar', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Treasury Ledger'), findsOneWidget);
    expect(find.byKey(const Key('ledgerSearchField')), findsOneWidget);
    expect(find.text('Initial Student Collections Deposit'), findsOneWidget);
    expect(find.text('Cash Advance for Leadership Seminar'), findsOneWidget);
    expect(find.text('Unused Cash Advance Return'), findsOneWidget);
  });

  testWidgets('LedgerScreen filters rows by search text', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ledgerSearchField')),
      'Leadership',
    );
    await tester.pumpAndSettle();

    expect(find.text('Cash Advance for Leadership Seminar'), findsOneWidget);
    expect(find.text('Initial Student Collections Deposit'), findsNothing);
    expect(find.text('Unused Cash Advance Return'), findsNothing);
  });

  testWidgets('LedgerScreen expands row on tap to reveal remarks and badges', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Remarks: Official receipt #1001'), findsNothing);

    await tester.tap(find.text('Initial Student Collections Deposit'));
    await tester.pumpAndSettle();

    expect(find.text('Remarks: Official receipt #1001'), findsOneWidget);
    expect(find.text('System-generated, protected'), findsOneWidget);
  });

  testWidgets(
    'LedgerScreen opens filter sheet and filters by movement origin',
    (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Open filter sheet
      await tester.tap(find.byKey(const Key('ledgerFilterButton')));
      await tester.pumpAndSettle();

      expect(find.text('Filter Ledger'), findsOneWidget);

      // Select Manual filter
      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.byKey(const Key('applyLedgerFilterButton')));
      await tester.pumpAndSettle();

      // Only manual rows should be visible
      expect(find.text('Cash Advance for Leadership Seminar'), findsOneWidget);
      expect(find.text('Unused Cash Advance Return'), findsOneWidget);
      expect(find.text('Initial Student Collections Deposit'), findsNothing);
      expect(find.text('2 of 3 rows'), findsOneWidget);
    },
  );
}

class _TestIdGenerator implements StableIdGenerator {
  @override
  StableId nextId(String prefix) => '$prefix-test';
}
