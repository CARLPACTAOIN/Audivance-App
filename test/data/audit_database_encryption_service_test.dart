import 'dart:io';

import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/storage/audit_storage_paths.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/audit_database_encryption_service.dart';
import 'package:audivance/features/audit/data/audit_database_opener.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late AuditStoragePaths storagePaths;
  late AuditDatabaseEncryptionService encryptionService;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'audivance_encryption_test_',
    );
    storagePaths = AuditStoragePaths(
      supportDirectoryProvider: () async => tempDirectory,
    );
    encryptionService = AuditDatabaseEncryptionService(
      storagePaths: storagePaths,
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'new encrypted database opens with key and rejects no-key reads',
    () async {
      final database = _openEncryptedDatabase(storagePaths, 'secure-key-1');
      final repository = DriftAuditRepository(database);
      await repository.saveOrganization(_organization);
      await database.close();

      expect(
        await encryptionService.inspect(key: 'secure-key-1'),
        DatabaseEncryptionStatus.encrypted,
      );
      expect(
        await encryptionService.inspect(),
        DatabaseEncryptionStatus.invalidKey,
      );
    },
  );

  test('plaintext migration preserves repository records', () async {
    await _seedPlaintextWorkspace(storagePaths);

    final result = await encryptionService.migrateIfNeeded(key: 'secure-key-2');

    expect(result.didMigrate, isTrue);
    expect(result.statusBefore, DatabaseEncryptionStatus.plaintext);
    expect(result.statusAfter, DatabaseEncryptionStatus.encrypted);

    final database = _openEncryptedDatabase(storagePaths, 'secure-key-2');
    final repository = DriftAuditRepository(database);

    expect(
      (await repository.listOrganizations()).single.name,
      _organization.name,
    );
    expect((await repository.getLocalAccount())!.displayName, 'Local Auditor');
    expect(await repository.listOfficers(), hasLength(1));
    expect(await repository.listTreasuryFundSources(), hasLength(1));
    expect(await repository.listAuditEvents(), hasLength(1));
    expect(
      await repository.listEventFundingAllocations('event-1'),
      hasLength(1),
    );
    expect(await repository.listFundMovements(), hasLength(1));
    expect(await repository.listLiquidationReceipts(), hasLength(1));
    expect(await repository.listLiquidationLines(), hasLength(1));
    expect(await repository.listReimbursementClaims(), hasLength(1));
    expect(await repository.listAuditorReviews(), hasLength(1));
    expect(await repository.listAuditLogs(), hasLength(1));

    await database.close();
  });

  test('migration removes plaintext originals and stale sidecars', () async {
    await _seedPlaintextWorkspace(storagePaths);
    final databaseFile = await storagePaths.databaseFile();
    await File('${databaseFile.path}.encrypted.tmp').writeAsString('stale');
    await File('${databaseFile.path}.plaintext.bak').writeAsString('stale');
    await File('${databaseFile.path}-wal').writeAsString('stale');
    await File('${databaseFile.path}-shm').writeAsString('stale');

    await encryptionService.migrateIfNeeded(key: 'secure-key-3');

    expect(await File('${databaseFile.path}.encrypted.tmp').exists(), isFalse);
    expect(await File('${databaseFile.path}.plaintext.bak').exists(), isFalse);
    expect(await File('${databaseFile.path}-wal').exists(), isFalse);
    expect(await File('${databaseFile.path}-shm').exists(), isFalse);
    expect(
      await encryptionService.inspect(key: 'secure-key-3'),
      DatabaseEncryptionStatus.encrypted,
    );
  });

  test('already encrypted database is not migrated again', () async {
    final database = _openEncryptedDatabase(storagePaths, 'secure-key-4');
    final repository = DriftAuditRepository(database);
    await repository.saveOrganization(_organization);
    await database.close();

    final result = await encryptionService.migrateIfNeeded(key: 'secure-key-4');

    expect(result.didMigrate, isFalse);
    expect(result.statusBefore, DatabaseEncryptionStatus.encrypted);
    expect(result.statusAfter, DatabaseEncryptionStatus.encrypted);
  });

  test('wrong key returns controlled failure', () async {
    final database = _openEncryptedDatabase(storagePaths, 'secure-key-5');
    final repository = DriftAuditRepository(database);
    await repository.saveOrganization(_organization);
    await database.close();

    expect(
      await encryptionService.inspect(key: 'wrong-key'),
      DatabaseEncryptionStatus.invalidKey,
    );
    expect(
      () => encryptionService.migrateIfNeeded(key: 'wrong-key'),
      throwsA(isA<EncryptedDatabaseOpenException>()),
    );
  });
}

AuditDatabase _openEncryptedDatabase(
  AuditStoragePaths storagePaths,
  String key,
) {
  return AuditDatabaseOpener(
    keyProvider: _StaticDatabaseKeyProvider(key),
    storagePaths: storagePaths,
  ).open();
}

Future<void> _seedPlaintextWorkspace(AuditStoragePaths storagePaths) async {
  final file = await storagePaths.databaseFile();
  await file.parent.create(recursive: true);
  final database = AuditDatabase(NativeDatabase(file));
  final repository = DriftAuditRepository(database);

  await repository.saveLocalAccount(
    LocalAccountProfile(
      id: 'account-1',
      displayName: 'Local Auditor',
      emailOrStudentId: 'auditor@example.test',
      createdAt: DateTime(2026, 8, 18, 9),
      isCredentialConfigured: true,
    ),
  );
  await repository.saveOrganization(_organization);
  await repository.saveOfficers([
    const Officer(
      id: 'officer-1',
      fullName: 'Ari Santos',
      position: OfficerPosition.member,
      committee: Committee.finance,
    ),
  ]);
  await repository.saveTreasuryFundSource(
    const TreasuryFundSource(
      id: 'source-1',
      type: TreasuryFundSourceType.studentCollections,
      label: 'Student Collections',
      balance: Money.centavos(100000),
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
      endDate: DateTime(2026, 8, 16),
      resolutionNumber: 'RES-2026-001',
      budget: Money.php(1000),
      approvedBudgetBalance: Money.php(1000),
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
  await repository.saveFundMovement(
    movement: FundMovement(
      id: 'movement-1',
      reference: 'FM-20260818-00000001',
      type: FundMovementType.budgetAllocation,
      date: DateTime(2026, 8, 18),
      amount: Money.php(1000),
      purpose: 'Budget allocation',
      isSystemGenerated: true,
    ),
  );
  await repository.saveLiquidationReceipt(
    LiquidationReceipt(
      id: 'receipt-1',
      eventId: 'event-1',
      payeeOrMerchant: 'Campus Canteen',
      date: DateTime(2026, 8, 18),
      evidenceNumber: 'OR-100',
      receiptType: ReceiptType.officialReceipt,
      fundingMode: FundingMode.outOfPocket,
      accountableOfficerId: 'officer-1',
      attachment: _attachment,
    ),
  );
  await repository.saveLiquidationLine(
    const LiquidationLine(
      id: 'line-1',
      receiptId: 'receipt-1',
      description: 'Meals',
      quantity: 2,
      unitCost: Money.centavos(10000),
    ),
  );
  await repository.saveReimbursementClaim(
    const ReimbursementClaim(
      id: 'claim-1',
      eventId: 'event-1',
      officerId: 'officer-1',
      amount: Money.centavos(20000),
      status: ReimbursementStatus.pending,
      sourceLiquidationLineId: 'line-1',
    ),
  );
  await repository.saveAuditorReview(
    AuditorReviewSnapshot(
      id: 'review-1',
      eventId: 'event-1',
      findings: 'Findings',
      cause: 'Cause',
      recommendation: 'Recommendation',
      budget: Money.php(1000),
      actual: Money.php(200),
      variance: Money.php(800),
      utilizationBasisPoints: 2000,
      health: BudgetHealth.healthy,
      createdAt: DateTime(2026, 8, 18, 13),
    ),
  );
  await repository.appendAuditLog(
    AuditLogEntry(
      id: 'log-1',
      action: 'seed',
      actor: 'local-account',
      targetRecordId: 'event-1',
      occurredAt: DateTime(2026, 8, 18),
      amount: Money.php(1000),
      reference: 'RES-2026-001',
    ),
  );
  await database.close();
}

class _StaticDatabaseKeyProvider implements DatabaseKeyProvider {
  const _StaticDatabaseKeyProvider(this.key);

  final String key;

  @override
  Future<String?> databaseKey() async => key;
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'support.pdf',
  localPath: 'attachments/support.pdf',
  sizeBytes: 1200,
  checksum: 'checksum-1',
);

const _organization = OrganizationProfile(
  id: 'org-1',
  name: 'Junior Philippine Institute of Accountants',
  type: 'Academic',
  adviser: 'Prof. Santos',
  semester: '1st Semester',
  schoolYear: '2026-2027',
  signatoryNames: ['Ari Santos', 'Bea Reyes'],
);
