import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('opens schema and inserts and loads organization profile', () async {
    expect(AuditDatabase.currentSchemaVersion, 4);

    const organization = OrganizationProfile(
      id: 'org-1',
      name: 'Junior Philippine Institute of Accountants',
      type: 'Academic',
      adviser: 'Prof. Santos',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      signatoryNames: ['Ari Santos', 'Bea Reyes'],
    );

    await repository.saveOrganization(organization);

    final loaded = await repository.getOrganization('org-1');
    expect(loaded, isNotNull);
    expect(loaded!.name, organization.name);
    expect(loaded.signatoryNames, organization.signatoryNames);
  });

  test('saves and loads the single local account profile', () async {
    final account = LocalAccountProfile(
      id: 'account-1',
      displayName: 'Local Auditor',
      emailOrStudentId: 'auditor@example.test',
      createdAt: DateTime(2026, 8, 18, 9),
      isCredentialConfigured: true,
    );

    await repository.saveLocalAccount(account);

    final loaded = await repository.getLocalAccount();
    expect(loaded, isNotNull);
    expect(loaded!.displayName, account.displayName);
    expect(loaded.emailOrStudentId, account.emailOrStudentId);
    expect(loaded.isCredentialConfigured, isTrue);
  });

  test('setup is incomplete with only a local account', () async {
    await repository.saveLocalAccount(
      LocalAccountProfile(
        id: 'account-1',
        displayName: 'Local Auditor',
        emailOrStudentId: 'auditor@example.test',
        createdAt: DateTime(2026, 8, 18, 9),
        isCredentialConfigured: true,
      ),
    );

    expect(await repository.isSetupComplete(), isFalse);
  });

  test('setup is incomplete with only an organization', () async {
    await repository.saveOrganization(_organization);

    expect(await repository.isSetupComplete(), isFalse);
  });

  test('setup is complete with local account and organization', () async {
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

    expect(await repository.isSetupComplete(), isTrue);
  });

  test('saves officers and rejects duplicate active committee heads', () async {
    final firstSave = await repository.saveOfficers(const [
      Officer(
        id: 'officer-1',
        fullName: 'Ari Santos',
        position: OfficerPosition.head,
        committee: Committee.finance,
      ),
    ]);

    final duplicateSave = await repository.saveOfficers(const [
      Officer(
        id: 'officer-2',
        fullName: 'Bea Reyes',
        position: OfficerPosition.head,
        committee: Committee.finance,
      ),
    ]);

    expect(firstSave.isValid, isTrue);
    expect(duplicateSave.isInvalid, isTrue);
    expect(duplicateSave.summary, contains('Only one active head'));
    expect(await repository.listOfficers(), hasLength(1));
  });

  test('rejects Add Fund without attachment', () async {
    final result = await repository.saveTreasuryFundSource(
      TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.donationSponsor,
        label: 'Sponsor Donation',
        balance: Money.php(1000),
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('supporting document attachment'));
    expect(await repository.listTreasuryFundSources(), isEmpty);
  });

  test('persists money as centavos without precision loss', () async {
    final result = await repository.saveTreasuryFundSource(
      const TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.donationSponsor,
        label: 'Sponsor Donation',
        balance: Money.centavos(12845099),
        supportingAttachment: _attachment,
      ),
    );

    final loaded = await repository.listTreasuryFundSources();

    expect(result.isValid, isTrue);
    expect(loaded.single.balance, const Money.centavos(12845099));
  });

  test('persists enum values as stable strings and round-trips them', () async {
    final result = await repository.saveTreasuryFundSource(
      const TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.studentCollections,
        label: 'Student Collections',
        balance: Money.centavos(500000),
        supportingAttachment: _attachment,
      ),
    );

    final loaded = await repository.listTreasuryFundSources();

    expect(result.isValid, isTrue);
    expect(loaded.single.type, TreasuryFundSourceType.studentCollections);
  });

  test('rejects update and delete of system-generated fund movement', () async {
    final movement = FundMovement(
      id: 'movement-1',
      reference: 'FM-20260818-4F2A91C0',
      type: FundMovementType.budgetAllocation,
      date: DateTime(2026, 8, 18),
      amount: Money.php(22000),
      purpose: 'Budget allocation',
      isSystemGenerated: true,
    );

    final saveResult = await repository.saveFundMovement(movement: movement);
    final updateResult = await repository.updateFundMovement(
      movement: FundMovement(
        id: 'movement-1',
        reference: 'FM-20260818-4F2A91C0',
        type: FundMovementType.budgetAllocation,
        date: DateTime(2026, 8, 18),
        amount: Money.php(21000),
        purpose: 'Edited allocation',
        isSystemGenerated: true,
      ),
    );
    final deleteResult = await repository.deleteFundMovement('movement-1');

    expect(saveResult.isValid, isTrue);
    expect(updateResult.isInvalid, isTrue);
    expect(deleteResult.isInvalid, isTrue);
    expect(await repository.listFundMovements(), hasLength(1));
  });

  test(
    'appends and reads audit logs through append-only repository API',
    () async {
      final entry = AuditLogEntry(
        id: 'log-1',
        action: 'treasury.add_fund',
        actor: 'Local Auditor',
        targetRecordId: 'source-1',
        occurredAt: DateTime(2026, 8, 18, 10, 30),
        amount: Money.php(1000),
        reference: 'FM-20260818-4F2A91C0',
        beforeSnapshot: const {'balance': 0},
        afterSnapshot: const {'balance': 100000},
        metadata: const {'deviceId': 'device-1'},
      );

      await repository.appendAuditLog(entry);

      final logs = await repository.listAuditLogs();
      expect(logs, hasLength(1));
      expect(logs.single.action, entry.action);
      expect(logs.single.amount, entry.amount);
      expect(logs.single.metadata['deviceId'], 'device-1');
    },
  );

  test('saves and loads auditor review snapshots by event', () async {
    final review = AuditorReviewSnapshot(
      id: 'review-1',
      eventId: 'event-1',
      findings: 'Variance is acceptable.',
      cause: 'Lower supplier prices',
      recommendation: 'Keep supplier canvass records.',
      budget: Money.php(1000),
      actual: Money.php(750),
      variance: Money.php(250),
      utilizationBasisPoints: 7500,
      health: BudgetHealth.healthy,
      createdAt: DateTime(2026, 8, 18, 12),
    );

    await repository.saveAuditorReview(review);

    final allReviews = await repository.listAuditorReviews();
    final eventReviews = await repository.listAuditorReviewsForEvent('event-1');
    final missingEventReviews = await repository.listAuditorReviewsForEvent(
      'event-2',
    );

    expect(allReviews, hasLength(1));
    expect(eventReviews, hasLength(1));
    expect(missingEventReviews, isEmpty);
    expect(eventReviews.single.actual, Money.php(750));
    expect(eventReviews.single.health, BudgetHealth.healthy);
    expect(eventReviews.single.utilizationBasisPoints, 7500);
  });

  test('export history round-trips stable values newest first', () async {
    await repository.appendExportHistory(
      ExportHistoryEntry(
        id: 'export-history-1',
        fileName: 'old.zip',
        generatedAt: DateTime(2026, 8, 17, 10),
        byteLength: 100,
        checksum: 'old-checksum',
        destinationUri: null,
        status: ExportHistoryStatus.canceled,
        backupReminderStatus: BackupReminderStatus.overridden,
        sameDayBackupFound: false,
        blockerCount: 1,
        warningCount: 2,
        createdAt: DateTime(2026, 8, 17, 10, 1),
        errorMessage: 'Save canceled',
      ),
    );
    await repository.appendExportHistory(
      ExportHistoryEntry(
        id: 'export-history-2',
        fileName: 'new.zip',
        generatedAt: DateTime(2026, 8, 18, 10),
        byteLength: 200,
        checksum: 'new-checksum',
        destinationUri: 'file:///new.zip',
        status: ExportHistoryStatus.success,
        backupReminderStatus: BackupReminderStatus.satisfied,
        sameDayBackupFound: true,
        blockerCount: 0,
        warningCount: 1,
        createdAt: DateTime(2026, 8, 18, 10, 1),
      ),
    );

    final history = await repository.listExportHistory();

    expect(history.map((entry) => entry.id), [
      'export-history-2',
      'export-history-1',
    ]);
    expect(history.first.status, ExportHistoryStatus.success);
    expect(history.first.backupReminderStatus, BackupReminderStatus.satisfied);
    expect(history.first.sameDayBackupFound, isTrue);
    expect(history.first.destinationUri, 'file:///new.zip');
    expect(history.last.status, ExportHistoryStatus.canceled);
    expect(history.last.errorMessage, 'Save canceled');
  });

  test('backup history round-trips stable values newest first', () async {
    await repository.appendBackupHistory(
      BackupHistoryEntry(
        id: 'backup-history-1',
        fileName: 'old-backup.zip',
        generatedAt: DateTime(2026, 8, 17, 10),
        byteLength: 100,
        checksum: 'old-checksum',
        destinationUri: null,
        status: BackupHistoryStatus.failed,
        createdAt: DateTime(2026, 8, 17, 10, 1),
        errorMessage: 'Disk full',
      ),
    );
    await repository.appendBackupHistory(
      BackupHistoryEntry(
        id: 'backup-history-2',
        fileName: 'new-backup.zip',
        generatedAt: DateTime(2026, 8, 18, 10),
        byteLength: 200,
        checksum: 'new-checksum',
        destinationUri: 'file:///new-backup.zip',
        status: BackupHistoryStatus.success,
        createdAt: DateTime(2026, 8, 18, 10, 1),
      ),
    );

    final history = await repository.listBackupHistory();

    expect(history.map((entry) => entry.id), [
      'backup-history-2',
      'backup-history-1',
    ]);
    expect(history.first.status, BackupHistoryStatus.success);
    expect(history.first.destinationUri, 'file:///new-backup.zip');
    expect(history.last.status, BackupHistoryStatus.failed);
    expect(history.last.errorMessage, 'Disk full');
  });
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
