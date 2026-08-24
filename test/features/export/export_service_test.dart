import 'dart:convert';
import 'dart:typed_data';

import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/export/export_service.dart';
import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late ExportService service;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    service = ExportService(repository: repository);
  });

  tearDown(() async {
    await database.close();
  });

  test('empty setup reports readiness blockers', () async {
    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(snapshot.readinessScore, lessThan(100));
    expect(snapshot.blockerCount, 3);
    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('missing-organization'),
    );
    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('missing-officers'),
    );
    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('missing-treasury-sources'),
    );
  });

  test(
    'complete records produce manifest, data JSON, CSV, and README previews',
    () async {
      await _seedCompleteWorkspace(repository);

      final preview = await service.buildPreview(
        asOf: DateTime(2026, 8, 18, 12),
      );
      final paths = preview.files.map((file) => file.path).toList();

      expect(
        preview.fileName,
        'Audivance-JPIA-2026-2027-1st-Semester-2026-08-18.zip',
      );
      expect(paths, contains('manifest.json'));
      expect(paths, contains('README.txt'));
      expect(paths, contains('data/audit_events.json'));
      expect(paths, contains('data/budget_vs_actual.json'));
      expect(paths, contains('data/auditor_reviews.json'));
      expect(paths, contains('csv/treasury_ledger.csv'));
      expect(paths, contains('csv/budget_vs_actual.csv'));
      expect(paths, contains('csv/auditor_reviews.csv'));
      expect(preview.manifest['appVersion'], '1.0.0+1');
    },
  );

  test(
    'generates organization, treasury, budget, and liquidation PDF reports',
    () async {
      await _seedCompleteWorkspace(repository);

      final reports = await service.buildReports(
        asOf: DateTime(2026, 8, 18, 12),
      );
      final paths = reports.files.map((file) => file.path).toList();

      expect(paths, contains('reports/organization_summary.pdf'));
      expect(paths, contains('reports/treasury_ledger.pdf'));
      expect(paths, contains('reports/budget_vs_actual.pdf'));
      expect(
        paths,
        contains('reports/liquidation/Leadership-Summit-event-1.pdf'),
      );
      for (final file in reports.files) {
        expect(file.bytes.take(4), '%PDF'.codeUnits);
        expect(file.byteLength, greaterThan(0));
        expect(file.checksum, hasLength(64));
      }
    },
  );

  test('generates liquidation PDFs for events without receipts', () async {
    await _seedWorkspaceWithoutLiquidation(repository);

    final reports = await service.buildReports(asOf: DateTime(2026, 8, 18, 12));

    expect(
      reports.files.map((file) => file.path),
      contains('reports/liquidation/Leadership-Summit-event-1.pdf'),
    );
  });

  test('PDF paths and checksums are deterministic and sanitized', () async {
    await _seedCompleteWorkspace(repository, eventName: 'Food & Fun: 2026!');

    final first = await service.buildReports(asOf: DateTime(2026, 8, 18, 12));
    final second = await service.buildReports(asOf: DateTime(2026, 8, 18, 12));

    expect(
      first.files.map((file) => file.path),
      contains('reports/liquidation/Food-Fun-2026-event-1.pdf'),
    );
    expect(
      first.files.map((file) => '${file.path}:${file.checksum}'),
      second.files.map((file) => '${file.path}:${file.checksum}'),
    );
  });

  test('ZIP generation is blocked by readiness blockers', () async {
    final result = await service.validateCanExport(asOf: DateTime(2026, 8, 18));

    expect(result.isInvalid, isTrue);
    expect(
      result.summary,
      contains('Export ZIP cannot be generated until blockers are resolved.'),
    );
    await expectLater(
      service.buildArchive(asOf: DateTime(2026, 8, 18)),
      throwsA(isA<StateError>()),
    );
  });

  test('complete workspace creates valid ZIP with manifest, JSON, CSV, README, reports, and attachments', () async {
    await _seedCompleteWorkspace(repository);
    service = ExportService(
      repository: repository,
      attachmentStorage: const _FakeAttachmentStorage.valid(),
    );

    final validation = await service.validateCanExport(
      asOf: DateTime(2026, 8, 18, 12),
    );
    final package = await service.buildArchive(asOf: DateTime(2026, 8, 18, 12));
    final decoded = ZipDecoder().decodeBytes(package.bytes);
    final paths = decoded.files.map((file) => file.name).toList();

    expect(validation.isValid, isTrue);
    expect(paths, contains('manifest.json'));
    expect(paths, contains('README.txt'));
    expect(paths, contains('data/audit_events.json'));
    expect(paths, contains('data/budget_vs_actual.json'));
    expect(paths, contains('data/auditor_reviews.json'));
    expect(paths, contains('csv/treasury_ledger.csv'));
    expect(paths, contains('csv/budget_vs_actual.csv'));
    expect(paths, contains('csv/auditor_reviews.csv'));
    expect(paths, contains('reports/organization_summary.pdf'));
    expect(paths, contains('reports/treasury_ledger.pdf'));
    expect(paths, contains('reports/budget_vs_actual.pdf'));
    expect(
      paths,
      contains('reports/liquidation/Leadership-Summit-event-1.pdf'),
    );
    expect(paths, contains('attachments/treasury/source-1/support.pdf'));
    expect(paths, contains('attachments/events/event-1/support.pdf'));
    expect(paths, contains('attachments/liquidation/receipt-1/support.pdf'));
    expect(package.byteLength, greaterThan(0));
    expect(package.checksum, hasLength(64));
    expect(
      package.entries.map((entry) => entry.sourceType),
      contains(ExportArchiveEntrySource.attachment),
    );
    expect(
      package.entries.map((entry) => entry.sourceType),
      contains(ExportArchiveEntrySource.report),
    );
    final manifestFiles = (package.manifest['files'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final reportManifestEntries = manifestFiles.where(
      (file) => file['sourceType'] == 'report',
    );
    expect(reportManifestEntries.length, 4);
    expect(
      reportManifestEntries.map((file) => file['path']),
      contains('reports/budget_vs_actual.pdf'),
    );
  });

  test('missing attachment file blocks ZIP generation', () async {
    await _seedCompleteWorkspace(repository);
    service = ExportService(
      repository: repository,
      attachmentStorage: const _FakeAttachmentStorage(
        result: AttachmentIntegrityResult.missing(),
      ),
    );

    final validation = await service.validateCanExport(
      asOf: DateTime(2026, 8, 18),
    );

    expect(validation.isInvalid, isTrue);
    expect(validation.summary, contains('missing from app storage'));
    await expectLater(
      service.buildArchive(asOf: DateTime(2026, 8, 18)),
      throwsA(isA<StateError>()),
    );
  });

  test('checksum mismatch blocks ZIP generation', () async {
    await _seedCompleteWorkspace(repository);
    service = ExportService(
      repository: repository,
      attachmentStorage: const _FakeAttachmentStorage(
        result: AttachmentIntegrityResult.present(
          checksumMatches: false,
          sizeMatches: true,
          actualChecksum: 'changed',
          actualSizeBytes: 1024,
        ),
      ),
    );

    final validation = await service.validateCanExport(
      asOf: DateTime(2026, 8, 18),
    );

    expect(validation.isInvalid, isTrue);
    expect(validation.summary, contains('does not match the stored file'));
  });

  test('warnings do not block ZIP generation', () async {
    await _seedCompleteWorkspace(
      repository,
      reimbursementStatus: ReimbursementStatus.pending,
    );
    service = ExportService(
      repository: repository,
      attachmentStorage: const _FakeAttachmentStorage.valid(),
    );

    final validation = await service.validateCanExport(
      asOf: DateTime(2026, 8, 18),
    );
    final package = await service.buildArchive(asOf: DateTime(2026, 8, 18));

    expect(validation.isValid, isTrue);
    expect(package.entries, isNotEmpty);
  });

  test('ZIP entries and manifest checksums are deterministic', () async {
    await _seedCompleteWorkspace(repository);
    service = ExportService(
      repository: repository,
      attachmentStorage: const _FakeAttachmentStorage.valid(),
    );

    final first = await service.buildArchive(asOf: DateTime(2026, 8, 18, 12));
    final second = await service.buildArchive(asOf: DateTime(2026, 8, 18, 12));

    expect(first.checksum, second.checksum);
    expect(
      first.entries.map((entry) => '${entry.path}:${entry.checksum}'),
      second.entries.map((entry) => '${entry.path}:${entry.checksum}'),
    );
    expect(first.manifest, second.manifest);
  });

  test('record counts match repository contents', () async {
    await _seedCompleteWorkspace(repository);

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));
    final counts = {
      for (final count in snapshot.recordCounts) count.label: count.count,
    };

    expect(counts['Organizations'], 1);
    expect(counts['Officers'], 1);
    expect(counts['Treasury sources'], 1);
    expect(counts['Events'], 1);
    expect(counts['Funding allocations'], 1);
    expect(counts['Fund movements'], 1);
    expect(counts['Liquidation receipts'], 1);
    expect(counts['Liquidation lines'], 1);
    expect(counts['Reimbursement claims'], 1);
    expect(counts['Auditor reviews'], 1);
    expect(counts['Audit logs'], 1);
  });

  test('due unliquidated events are flagged', () async {
    await _seedCompleteWorkspace(
      repository,
      eventEndDate: DateTime(2026, 8, 10),
      isLiquidated: false,
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(
      snapshot.issues
          .where((issue) => issue.id == 'event-due-event-1')
          .single
          .severity,
      ExportReadinessSeverity.blocker,
    );
  });

  test('pending reimbursements are flagged', () async {
    await _seedCompleteWorkspace(
      repository,
      reimbursementStatus: ReimbursementStatus.pending,
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('pending-claim-claim-1'),
    );
  });

  test('missing resolution and receipt attachments are flagged', () async {
    await _seedCompleteWorkspace(
      repository,
      eventAttachment: null,
      receiptAttachment: const AttachmentRef(
        id: 'receipt-attachment',
        fileName: '',
        localPath: '',
      ),
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('event-resolution-event-1'),
    );
    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('receipt-attachment-receipt-1'),
    );
    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('attachment-metadata-receipt-1'),
    );
  });

  test(
    'stored attachment files missing from app storage are blockers',
    () async {
      await _seedCompleteWorkspace(repository);
      service = ExportService(
        repository: repository,
        attachmentStorage: const _FakeAttachmentStorage(
          result: AttachmentIntegrityResult.missing(),
        ),
      );

      final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

      expect(
        snapshot.issues.map((issue) => issue.id),
        contains('attachment-missing-file-source-1'),
      );
      expect(
        snapshot.issues
            .where((issue) => issue.id == 'attachment-missing-file-source-1')
            .single
            .severity,
        ExportReadinessSeverity.blocker,
      );
    },
  );

  test('stored attachment checksum mismatches are blockers', () async {
    await _seedCompleteWorkspace(repository);
    service = ExportService(
      repository: repository,
      attachmentStorage: const _FakeAttachmentStorage(
        result: AttachmentIntegrityResult.present(
          checksumMatches: false,
          sizeMatches: true,
          actualChecksum: 'changed',
          actualSizeBytes: 1024,
        ),
      ),
    );

    final snapshot = await service.loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(
      snapshot.issues.map((issue) => issue.id),
      contains('attachment-checksum-source-1'),
    );
  });

  test('CSV escaping handles commas, quotes, and newlines', () {
    final output = csv([
      ['plain', 'a,b', 'a"b', 'a\nb'],
    ]);

    expect(output, 'plain,"a,b","a""b","a\nb"');
  });

  test('preview checksums are deterministic', () async {
    await _seedCompleteWorkspace(repository);

    final first = await service.buildPreview(asOf: DateTime(2026, 8, 18, 12));
    final second = await service.buildPreview(asOf: DateTime(2026, 8, 18, 12));

    expect(
      first.files.map((file) => file.checksum),
      second.files.map((file) => file.checksum),
    );
    expect(crc32Hex('Audivance'), crc32Hex('Audivance'));
  });

  test('data JSON includes structured records', () async {
    await _seedCompleteWorkspace(repository);

    final preview = await service.buildPreview(asOf: DateTime(2026, 8, 18));
    final eventsFile = preview.files.singleWhere(
      (file) => file.path == 'data/audit_events.json',
    );
    final events = jsonDecode(eventsFile.content) as List<Object?>;
    final event = events.single as Map<String, Object?>;

    expect(event['name'], 'Leadership Summit');
    expect(event['budgetCentavos'], 100000);
  });
}

Future<void> _seedCompleteWorkspace(
  DriftAuditRepository repository, {
  String eventName = 'Leadership Summit',
  DateTime? eventEndDate,
  bool isLiquidated = true,
  ReimbursementStatus reimbursementStatus = ReimbursementStatus.paid,
  AttachmentRef? eventAttachment = _attachment,
  AttachmentRef receiptAttachment = _attachment,
}) async {
  await repository.saveOrganization(
    const OrganizationProfile(
      id: 'org-1',
      name: 'JPIA',
      type: 'Academic',
      adviser: 'Prof. Santos',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      signatoryNames: ['Ari Santos', 'Bea Reyes'],
    ),
  );
  await repository.saveOfficers([
    const Officer(
      id: 'officer-1',
      fullName: 'Ari Santos',
      position: OfficerPosition.member,
      committee: Committee.finance,
    ),
  ]);
  await repository.updateTreasuryFundSource(
    const TreasuryFundSource(
      id: 'source-1',
      type: TreasuryFundSourceType.studentCollections,
      label: 'Student Collections',
      balance: Money.centavos(500000),
      supportingAttachment: _attachment,
    ),
  );
  final event = AuditEvent(
    id: 'event-1',
    name: eventName,
    type: 'Leadership',
    semester: '1st Semester',
    schoolYear: '2026-2027',
    startDate: DateTime(2026, 8, 10),
    endDate: eventEndDate ?? DateTime(2026, 8, 16),
    resolutionNumber: 'RES-2026-001',
    budget: Money.php(1000),
    approvedBudgetBalance: Money.php(800),
    resolutionAttachment: eventAttachment ?? _attachment,
    isLiquidated: isLiquidated,
  );
  await repository.saveAuditEvent(
    event: event,
    allocations: const [
      EventFundingAllocation(
        eventId: 'event-1',
        fundSourceId: 'source-1',
        amount: Money.centavos(100000),
      ),
    ],
  );
  if (eventAttachment == null) {
    await repository.updateAuditEvent(
      AuditEvent(
        id: 'event-1',
        name: eventName,
        type: 'Leadership',
        semester: '1st Semester',
        schoolYear: '2026-2027',
        startDate: DateTime(2026, 8, 10),
        endDate: eventEndDate ?? DateTime(2026, 8, 16),
        resolutionNumber: 'RES-2026-001',
        budget: Money.php(1000),
        approvedBudgetBalance: Money.php(800),
        isLiquidated: isLiquidated,
      ),
    );
  }
  await repository.saveFundMovement(
    movement: FundMovement(
      id: 'movement-1',
      reference: 'FM-20260818-ABCD1234',
      type: FundMovementType.budgetAllocation,
      date: DateTime(2026, 8, 18),
      amount: Money.php(1000),
      purpose: 'Budget allocation: $eventName',
      eventId: 'event-1',
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
      attachment: receiptAttachment,
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
    ReimbursementClaim(
      id: 'claim-1',
      eventId: 'event-1',
      officerId: 'officer-1',
      amount: Money.php(200),
      status: reimbursementStatus,
      sourceLiquidationLineId: 'line-1',
    ),
  );
  await repository.saveAuditorReview(
    AuditorReviewSnapshot(
      id: 'review-1',
      eventId: 'event-1',
      findings: 'Spending stayed within the approved budget.',
      cause: 'Expenses followed the approved plan.',
      recommendation: 'Retain all supporting documents for COA review.',
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
      id: 'audit-log-1',
      action: 'test.seed',
      actor: 'local-account',
      targetRecordId: 'event-1',
      occurredAt: DateTime(2026, 8, 18),
      amount: Money.php(1000),
      reference: 'RES-2026-001',
    ),
  );
}

Future<void> _seedWorkspaceWithoutLiquidation(
  DriftAuditRepository repository,
) async {
  await repository.saveOrganization(
    const OrganizationProfile(
      id: 'org-1',
      name: 'JPIA',
      type: 'Academic',
      adviser: 'Prof. Santos',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      signatoryNames: ['Ari Santos', 'Bea Reyes'],
    ),
  );
  await repository.saveOfficers([
    const Officer(
      id: 'officer-1',
      fullName: 'Ari Santos',
      position: OfficerPosition.member,
      committee: Committee.finance,
    ),
  ]);
  await repository.updateTreasuryFundSource(
    const TreasuryFundSource(
      id: 'source-1',
      type: TreasuryFundSourceType.studentCollections,
      label: 'Student Collections',
      balance: Money.centavos(500000),
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
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'support.pdf',
  localPath: 'attachments/support.pdf',
  sizeBytes: 1024,
  checksum: 'abc123',
);

class _FakeAttachmentStorage implements AttachmentStorageService {
  const _FakeAttachmentStorage({required this.result});

  const _FakeAttachmentStorage.valid()
    : result = const AttachmentIntegrityResult.present(
        checksumMatches: true,
        sizeMatches: true,
        actualChecksum: 'abc123',
        actualSizeBytes: 1024,
      );

  final AttachmentIntegrityResult result;

  @override
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> exists(AttachmentRef attachment) async => result.exists;

  @override
  Future<String> resolveLocalPath(AttachmentRef attachment) async {
    return attachment.localPath;
  }

  @override
  Future<Uint8List> readBytes(AttachmentRef attachment) async {
    if (!result.exists) {
      throw StateError('Attachment is missing.');
    }
    return Uint8List.fromList(utf8.encode(attachment.localPath));
  }

  @override
  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment) async {
    return result;
  }
}
