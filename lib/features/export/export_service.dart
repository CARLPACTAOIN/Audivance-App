import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/validation_result.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';
import 'pdf_report_service.dart';

class ExportService {
  const ExportService({required this.repository, this.attachmentStorage});

  final AuditRepository repository;
  final AttachmentStorageService? attachmentStorage;

  Future<ExportCenterSnapshot> loadSnapshot({required DateTime asOf}) async {
    final data = await _loadData();
    final issues = await _buildIssues(
      data,
      asOf: asOf,
      attachmentStorage: attachmentStorage,
    );
    final attachments = _buildAttachments(data);
    final recordCounts = _buildRecordCounts(data);

    return ExportCenterSnapshot(
      organizationName: data.organizations.isEmpty
          ? 'Audivance Workspace'
          : data.organizations.first.name,
      term: data.organizations.isEmpty
          ? 'No organization profile'
          : '${data.organizations.first.semester}, SY ${data.organizations.first.schoolYear}',
      readinessScore: readinessScoreFor(issues),
      issues: issues,
      recordCounts: recordCounts,
      attachments: attachments,
      packageFiles: _packageStructureFor(data),
    );
  }

  Future<ExportPackagePreview> buildPreview({required DateTime asOf}) async {
    final data = await _loadData();
    final snapshot = await loadSnapshot(asOf: asOf);
    final filesWithoutManifest = _previewFilesWithoutManifest(data, snapshot);
    final manifest = _manifestFor(
      data: data,
      asOf: asOf,
      recordCounts: snapshot.recordCounts,
      files: filesWithoutManifest,
    );
    final manifestFile = _jsonFile('manifest.json', manifest);
    final files = [manifestFile, ...filesWithoutManifest];

    return ExportPackagePreview(
      fileName: _exportFileName(
        data.organizations.isEmpty ? null : data.organizations.first,
        asOf,
      ),
      generatedAt: asOf,
      files: files,
      manifest: manifest,
    );
  }

  Future<PdfReportBundle> buildReports({required DateTime asOf}) async {
    final data = await _loadData();
    final issues = await _buildIssues(
      data,
      asOf: asOf,
      attachmentStorage: attachmentStorage,
    );
    return const PdfReportService().buildReports(
      input: _pdfReportInputFor(data: data, asOf: asOf, issues: issues),
    );
  }

  Future<ValidationResult> validateCanExport({required DateTime asOf}) async {
    final data = await _loadData();
    final issues = await _buildIssues(
      data,
      asOf: asOf,
      attachmentStorage: attachmentStorage,
    );
    final blockerMessages = issues
        .where((issue) => issue.severity == ExportReadinessSeverity.blocker)
        .map((issue) => issue.message)
        .toList(growable: false);
    if (blockerMessages.isNotEmpty) {
      return ValidationResult.invalid([
        'Export ZIP cannot be generated until blockers are resolved.',
        ...blockerMessages,
      ]);
    }
    if (attachmentStorage == null && _buildAttachmentRecords(data).isNotEmpty) {
      return ValidationResult.failure(
        'Attachment storage is required to include supporting documents in the ZIP.',
      );
    }
    return const ValidationResult.valid();
  }

  Future<ExportArchivePackage> buildArchive({required DateTime asOf}) async {
    final data = await _loadData();
    final issues = await _buildIssues(
      data,
      asOf: asOf,
      attachmentStorage: attachmentStorage,
    );
    final blockers = issues
        .where((issue) => issue.severity == ExportReadinessSeverity.blocker)
        .toList(growable: false);
    if (blockers.isNotEmpty) {
      throw StateError(
        ValidationResult.invalid([
          'Export ZIP cannot be generated until blockers are resolved.',
          ...blockers.map((issue) => issue.message),
        ]).summary,
      );
    }

    final recordCounts = _buildRecordCounts(data);
    final snapshot = ExportCenterSnapshot(
      organizationName: data.organizations.isEmpty
          ? 'Audivance Workspace'
          : data.organizations.first.name,
      term: data.organizations.isEmpty
          ? 'No organization profile'
          : '${data.organizations.first.semester}, SY ${data.organizations.first.schoolYear}',
      readinessScore: readinessScoreFor(issues),
      issues: issues,
      recordCounts: recordCounts,
      attachments: _buildAttachments(data),
      packageFiles: _packageStructureFor(data),
    );
    final textEntries = _archiveTextEntriesWithoutManifest(data, snapshot);
    final reportBundle = await const PdfReportService().buildReports(
      input: _pdfReportInputFor(data: data, asOf: asOf, issues: issues),
    );
    final reportEntries = [
      for (final report in reportBundle.files)
        _ArchiveFileData(
          path: report.path,
          bytes: report.bytes,
          sourceType: ExportArchiveEntrySource.report,
        ),
    ];
    final attachmentEntries = await _archiveAttachmentEntries(
      data,
      attachmentStorage: attachmentStorage,
    );
    final entriesWithoutManifest = [
      ...textEntries,
      ...reportEntries,
      ...attachmentEntries,
    ]..sort((a, b) => a.path.compareTo(b.path));
    final manifest = _archiveManifestFor(
      data: data,
      asOf: asOf,
      recordCounts: recordCounts,
      entries: entriesWithoutManifest,
    );
    final manifestEntry = _archiveTextEntry(
      path: 'manifest.json',
      content: const JsonEncoder.withIndent('  ').convert(manifest),
      sourceType: ExportArchiveEntrySource.manifest,
    );
    final packageEntries = [manifestEntry, ...entriesWithoutManifest];
    final archive = Archive();
    for (final entry in packageEntries) {
      final archiveFile = ArchiveFile.bytes(entry.path, entry.bytes);
      archiveFile.creationTime = 0;
      archiveFile.lastModTime = 0;
      archive.addFile(archiveFile);
    }
    final encoded = ZipEncoder().encodeBytes(
      archive,
      modified: DateTime.utc(asOf.year, asOf.month, asOf.day),
    );
    final bytes = Uint8List.fromList(encoded);
    return ExportArchivePackage(
      fileName: _exportFileName(
        data.organizations.isEmpty ? null : data.organizations.first,
        asOf,
      ),
      bytes: bytes,
      generatedAt: asOf,
      checksum: sha256Hex(bytes),
      manifest: manifest,
      entries: packageEntries
          .map(
            (entry) => ExportArchiveEntry(
              path: entry.path,
              byteLength: entry.bytes.length,
              checksum: sha256Hex(entry.bytes),
              sourceType: entry.sourceType,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<_ExportData> _loadData() async {
    final organizations = await repository.listOrganizations();
    final officers = await repository.listOfficers();
    final treasurySources = await repository.listTreasuryFundSources();
    final events = await repository.listAuditEvents();
    final allocations = <EventFundingAllocation>[];
    for (final event in events) {
      allocations.addAll(
        await repository.listEventFundingAllocations(event.id),
      );
    }
    final movements = await repository.listFundMovements();
    final receipts = await repository.listLiquidationReceipts();
    final lines = await repository.listLiquidationLines();
    final claims = await repository.listReimbursementClaims();
    final auditorReviews = await repository.listAuditorReviews();
    final auditLogs = await repository.listAuditLogs();

    return _ExportData(
      organizations: organizations..sort((a, b) => a.id.compareTo(b.id)),
      officers: officers..sort((a, b) => a.id.compareTo(b.id)),
      treasurySources: treasurySources..sort((a, b) => a.id.compareTo(b.id)),
      events: events..sort((a, b) => a.id.compareTo(b.id)),
      allocations: allocations
        ..sort((a, b) {
          final eventCompare = a.eventId.compareTo(b.eventId);
          if (eventCompare != 0) {
            return eventCompare;
          }
          return a.fundSourceId.compareTo(b.fundSourceId);
        }),
      movements: movements..sort((a, b) => a.id.compareTo(b.id)),
      receipts: receipts..sort((a, b) => a.id.compareTo(b.id)),
      lines: lines..sort((a, b) => a.id.compareTo(b.id)),
      claims: claims..sort((a, b) => a.id.compareTo(b.id)),
      auditorReviews: auditorReviews..sort((a, b) => a.id.compareTo(b.id)),
      auditLogs: auditLogs..sort((a, b) => a.id.compareTo(b.id)),
    );
  }
}

class ExportCenterSnapshot {
  const ExportCenterSnapshot({
    required this.organizationName,
    required this.term,
    required this.readinessScore,
    required this.issues,
    required this.recordCounts,
    required this.attachments,
    required this.packageFiles,
  });

  final String organizationName;
  final String term;
  final int readinessScore;
  final List<ExportReadinessIssueView> issues;
  final List<ExportRecordCount> recordCounts;
  final List<ExportAttachmentView> attachments;
  final List<String> packageFiles;

  int get blockerCount => issues
      .where((issue) => issue.severity == ExportReadinessSeverity.blocker)
      .length;
  int get warningCount => issues
      .where((issue) => issue.severity == ExportReadinessSeverity.warning)
      .length;
}

class ExportReadinessIssueView {
  const ExportReadinessIssueView({
    required this.id,
    required this.message,
    required this.severity,
    this.targetRecordId,
  });

  final StableId id;
  final String message;
  final ExportReadinessSeverity severity;
  final StableId? targetRecordId;

  String get severityLabel {
    return switch (severity) {
      ExportReadinessSeverity.blocker => 'Blocker',
      ExportReadinessSeverity.warning => 'Warning',
    };
  }
}

class ExportRecordCount {
  const ExportRecordCount({required this.label, required this.count});

  final String label;
  final int count;
}

class ExportAttachmentView {
  const ExportAttachmentView({
    required this.module,
    required this.recordId,
    required this.fileName,
    required this.localPath,
    this.sizeBytes,
    this.checksum,
  });

  final String module;
  final StableId recordId;
  final String fileName;
  final String localPath;
  final int? sizeBytes;
  final String? checksum;
}

class ExportPackagePreview {
  const ExportPackagePreview({
    required this.fileName,
    required this.generatedAt,
    required this.files,
    required this.manifest,
  });

  final String fileName;
  final DateTime generatedAt;
  final List<ExportPreviewFile> files;
  final Map<String, Object?> manifest;
}

class ExportPreviewFile {
  ExportPreviewFile({required this.path, required this.content})
    : byteLength = utf8.encode(content).length,
      checksum = crc32Hex(content);

  final String path;
  final String content;
  final int byteLength;
  final String checksum;
}

class ExportArchivePackage {
  const ExportArchivePackage({
    required this.fileName,
    required this.bytes,
    required this.generatedAt,
    required this.checksum,
    required this.manifest,
    required this.entries,
  });

  final String fileName;
  final Uint8List bytes;
  final DateTime generatedAt;
  final String checksum;
  final Map<String, Object?> manifest;
  final List<ExportArchiveEntry> entries;

  int get byteLength => bytes.length;
}

class ExportArchiveEntry {
  const ExportArchiveEntry({
    required this.path,
    required this.byteLength,
    required this.checksum,
    required this.sourceType,
  });

  final String path;
  final int byteLength;
  final String checksum;
  final ExportArchiveEntrySource sourceType;
}

enum ExportArchiveEntrySource {
  manifest,
  readme,
  data,
  csv,
  report,
  attachment,
}

class _AttachmentRecord {
  const _AttachmentRecord(this.module, this.recordId, this.attachment);

  final String module;
  final StableId recordId;
  final AttachmentRef attachment;
}

class _ArchiveFileData {
  const _ArchiveFileData({
    required this.path,
    required this.bytes,
    required this.sourceType,
  });

  final String path;
  final Uint8List bytes;
  final ExportArchiveEntrySource sourceType;
}

int readinessScoreFor(List<ExportReadinessIssueView> issues) {
  var score = 100;
  for (final issue in issues) {
    score -= issue.severity == ExportReadinessSeverity.blocker ? 20 : 8;
  }
  return score.clamp(0, 100);
}

String csv(List<List<Object?>> rows) {
  return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
}

String crc32Hex(String input) {
  var crc = 0xFFFFFFFF;
  for (final byte in utf8.encode(input)) {
    crc ^= byte;
    for (var i = 0; i < 8; i += 1) {
      if ((crc & 1) == 1) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  final value = (crc ^ 0xFFFFFFFF).toUnsigned(32);
  return value.toRadixString(16).padLeft(8, '0').toUpperCase();
}

String sha256Hex(List<int> bytes) {
  return crypto.sha256.convert(bytes).toString();
}

Future<List<ExportReadinessIssueView>> _buildIssues(
  _ExportData data, {
  required DateTime asOf,
  required AttachmentStorageService? attachmentStorage,
}) async {
  final issues = <ExportReadinessIssueView>[];
  if (data.organizations.isEmpty) {
    issues.add(
      const ExportReadinessIssueView(
        id: 'missing-organization',
        message: 'Organization profile is required before COA export.',
        severity: ExportReadinessSeverity.blocker,
      ),
    );
  } else {
    final organization = data.organizations.first;
    final missingFields = <String>[
      if (organization.name.trim().isEmpty) 'name',
      if (organization.type.trim().isEmpty) 'type',
      if (organization.adviser.trim().isEmpty) 'adviser',
      if (organization.semester.trim().isEmpty) 'semester',
      if (organization.schoolYear.trim().isEmpty) 'school year',
      if (organization.signatoryNames.isEmpty) 'signatories',
    ];
    if (missingFields.isNotEmpty) {
      issues.add(
        ExportReadinessIssueView(
          id: 'incomplete-organization',
          message:
              'Organization profile is missing ${missingFields.join(', ')}.',
          severity: ExportReadinessSeverity.blocker,
          targetRecordId: organization.id,
        ),
      );
    }
  }
  if (data.treasurySources.isEmpty) {
    issues.add(
      const ExportReadinessIssueView(
        id: 'missing-treasury-sources',
        message: 'At least one Treasury source fund is required.',
        severity: ExportReadinessSeverity.blocker,
      ),
    );
  }
  if (data.officers.where((officer) => !officer.isArchived).isEmpty) {
    issues.add(
      const ExportReadinessIssueView(
        id: 'missing-officers',
        message:
            'At least one active officer should be encoded for COA review.',
        severity: ExportReadinessSeverity.blocker,
      ),
    );
  }
  for (final event in data.events) {
    if (!_hasAttachmentMetadata(event.resolutionAttachment)) {
      issues.add(
        ExportReadinessIssueView(
          id: 'event-resolution-${event.id}',
          message:
              'Event "${event.name}" is missing resolution attachment metadata.',
          severity: ExportReadinessSeverity.warning,
          targetRecordId: event.id,
        ),
      );
    }
    final status = EventRules.calculateStatus(event: event, asOf: asOf);
    if (status == AuditEventStatus.due) {
      issues.add(
        ExportReadinessIssueView(
          id: 'event-due-${event.id}',
          message: 'Event "${event.name}" is due and not yet liquidated.',
          severity: ExportReadinessSeverity.blocker,
          targetRecordId: event.id,
        ),
      );
    }
  }
  for (final receipt in data.receipts) {
    if (!_hasAttachmentMetadata(receipt.attachment)) {
      issues.add(
        ExportReadinessIssueView(
          id: 'receipt-attachment-${receipt.id}',
          message:
              'Liquidation receipt "${receipt.evidenceNumber}" is missing attachment metadata.',
          severity: ExportReadinessSeverity.warning,
          targetRecordId: receipt.id,
        ),
      );
    }
  }
  for (final claim in data.claims.where(
    (claim) => claim.status == ReimbursementStatus.pending,
  )) {
    issues.add(
      ExportReadinessIssueView(
        id: 'pending-claim-${claim.id}',
        message:
            'Pending reimbursement claim ${claim.id} should be reviewed before export.',
        severity: ExportReadinessSeverity.warning,
        targetRecordId: claim.id,
      ),
    );
  }
  for (final attachmentRecord in _buildAttachmentRecords(data)) {
    final attachment = attachmentRecord.attachment;
    if (attachment.fileName.trim().isEmpty ||
        attachment.localPath.trim().isEmpty) {
      issues.add(
        ExportReadinessIssueView(
          id: 'attachment-metadata-${attachmentRecord.recordId}',
          message:
              'Attachment metadata for ${attachmentRecord.module} record ${attachmentRecord.recordId} is incomplete.',
          severity: ExportReadinessSeverity.warning,
          targetRecordId: attachmentRecord.recordId,
        ),
      );
      continue;
    }
    if (attachmentStorage != null) {
      final integrity = await attachmentStorage.verify(attachment);
      if (!integrity.exists) {
        issues.add(
          ExportReadinessIssueView(
            id: 'attachment-missing-file-${attachmentRecord.recordId}',
            message:
                'Attachment file for ${attachmentRecord.module} record ${attachmentRecord.recordId} is missing from app storage.',
            severity: ExportReadinessSeverity.blocker,
            targetRecordId: attachmentRecord.recordId,
          ),
        );
      } else if (!integrity.checksumMatches) {
        issues.add(
          ExportReadinessIssueView(
            id: 'attachment-checksum-${attachmentRecord.recordId}',
            message:
                'Attachment checksum for ${attachmentRecord.module} record ${attachmentRecord.recordId} does not match the stored file.',
            severity: ExportReadinessSeverity.blocker,
            targetRecordId: attachmentRecord.recordId,
          ),
        );
      } else if (!integrity.sizeMatches) {
        issues.add(
          ExportReadinessIssueView(
            id: 'attachment-size-${attachmentRecord.recordId}',
            message:
                'Attachment size for ${attachmentRecord.module} record ${attachmentRecord.recordId} does not match the stored file.',
            severity: ExportReadinessSeverity.warning,
            targetRecordId: attachmentRecord.recordId,
          ),
        );
      }
    }
  }
  return issues;
}

List<ExportRecordCount> _buildRecordCounts(_ExportData data) {
  return [
    ExportRecordCount(label: 'Organizations', count: data.organizations.length),
    ExportRecordCount(label: 'Officers', count: data.officers.length),
    ExportRecordCount(
      label: 'Treasury sources',
      count: data.treasurySources.length,
    ),
    ExportRecordCount(label: 'Events', count: data.events.length),
    ExportRecordCount(
      label: 'Funding allocations',
      count: data.allocations.length,
    ),
    ExportRecordCount(label: 'Fund movements', count: data.movements.length),
    ExportRecordCount(
      label: 'Liquidation receipts',
      count: data.receipts.length,
    ),
    ExportRecordCount(label: 'Liquidation lines', count: data.lines.length),
    ExportRecordCount(label: 'Reimbursement claims', count: data.claims.length),
    ExportRecordCount(
      label: 'Auditor reviews',
      count: data.auditorReviews.length,
    ),
    ExportRecordCount(label: 'Audit logs', count: data.auditLogs.length),
  ];
}

List<ExportAttachmentView> _buildAttachments(_ExportData data) {
  return _buildAttachmentRecords(data)
      .map(
        (record) =>
            _attachmentView(record.module, record.recordId, record.attachment),
      )
      .toList(growable: false);
}

List<String> _packageStructureFor(_ExportData data) {
  return [
    'manifest.json',
    'README.txt',
    'data/organizations.json',
    'data/officers.json',
    'data/treasury_fund_sources.json',
    'data/audit_events.json',
    'data/event_funding_allocations.json',
    'data/fund_movements.json',
    'data/liquidation_receipts.json',
    'data/liquidation_lines.json',
    'data/reimbursement_claims.json',
    'data/budget_vs_actual.json',
    'data/auditor_reviews.json',
    'data/audit_logs.json',
    'csv/treasury_ledger.csv',
    'csv/events.csv',
    'csv/liquidation_lines.csv',
    'csv/reimbursements.csv',
    'csv/budget_vs_actual.csv',
    'csv/auditor_reviews.csv',
    'csv/audit_logs.csv',
    ...pdfReportPathsFor(events: data.events, receipts: data.receipts),
    for (final record in _buildAttachmentRecords(data))
      _attachmentArchivePath(record),
  ];
}

PdfReportInput _pdfReportInputFor({
  required _ExportData data,
  required DateTime asOf,
  required List<ExportReadinessIssueView> issues,
}) {
  return PdfReportInput(
    asOf: asOf,
    readinessScore: readinessScoreFor(issues),
    readinessIssues: [
      for (final issue in issues)
        PdfReadinessIssue(
          message: issue.message,
          severity: issue.severity,
          targetRecordId: issue.targetRecordId,
        ),
    ],
    organizations: data.organizations,
    officers: data.officers,
    treasurySources: data.treasurySources,
    events: data.events,
    allocations: data.allocations,
    movements: data.movements,
    receipts: data.receipts,
    lines: data.lines,
    claims: data.claims,
    auditorReviews: data.auditorReviews,
    logoAssetPath: UsmOsaF46TemplateAssets.defaultLogoAssetPath,
  );
}

List<_AttachmentRecord> _buildAttachmentRecords(_ExportData data) {
  final records = <_AttachmentRecord>[];
  for (final source in data.treasurySources) {
    final attachment = source.supportingAttachment;
    if (attachment != null) {
      records.add(_AttachmentRecord('treasury', source.id, attachment));
    }
  }
  for (final event in data.events) {
    final attachment = event.resolutionAttachment;
    if (attachment != null) {
      records.add(_AttachmentRecord('events', event.id, attachment));
    }
  }
  for (final receipt in data.receipts) {
    records.add(
      _AttachmentRecord('liquidation', receipt.id, receipt.attachment),
    );
  }
  return records;
}

ExportAttachmentView _attachmentView(
  String module,
  StableId recordId,
  AttachmentRef attachment,
) {
  return ExportAttachmentView(
    module: module,
    recordId: recordId,
    fileName: attachment.fileName,
    localPath: attachment.localPath,
    sizeBytes: attachment.sizeBytes,
    checksum: attachment.checksum,
  );
}

bool _hasAttachmentMetadata(AttachmentRef? attachment) {
  return attachment != null &&
      attachment.fileName.trim().isNotEmpty &&
      attachment.localPath.trim().isNotEmpty;
}

List<ExportPreviewFile> _previewFilesWithoutManifest(
  _ExportData data,
  ExportCenterSnapshot snapshot,
) {
  return [
    ..._textPackageEntriesWithoutManifest(data, snapshot).map(
      (entry) => ExportPreviewFile(
        path: entry.path,
        content: utf8.decode(entry.bytes),
      ),
    ),
  ];
}

List<_ArchiveFileData> _archiveTextEntriesWithoutManifest(
  _ExportData data,
  ExportCenterSnapshot snapshot,
) {
  return _textPackageEntriesWithoutManifest(data, snapshot);
}

List<_ArchiveFileData> _textPackageEntriesWithoutManifest(
  _ExportData data,
  ExportCenterSnapshot snapshot,
) {
  return [
    _archiveJsonEntry(
      path: 'data/organizations.json',
      value: data.organizations.map(_organizationJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/officers.json',
      value: data.officers.map(_officerJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/treasury_fund_sources.json',
      value: data.treasurySources.map(_treasurySourceJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/audit_events.json',
      value: data.events.map(_eventJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/event_funding_allocations.json',
      value: data.allocations.map(_allocationJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/fund_movements.json',
      value: data.movements.map(_movementJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/liquidation_receipts.json',
      value: data.receipts.map(_receiptJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/liquidation_lines.json',
      value: data.lines.map(_lineJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/reimbursement_claims.json',
      value: data.claims.map(_claimJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/budget_vs_actual.json',
      value: data.events
          .map((event) => _budgetActualJson(data, event))
          .toList(),
    ),
    _archiveJsonEntry(
      path: 'data/auditor_reviews.json',
      value: data.auditorReviews.map(_auditorReviewJson).toList(),
    ),
    _archiveJsonEntry(
      path: 'data/audit_logs.json',
      value: data.auditLogs.map(_auditLogJson).toList(),
    ),
    _archiveTextEntry(
      path: 'csv/treasury_ledger.csv',
      content: _treasuryLedgerCsv(data.movements),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'csv/events.csv',
      content: _eventsCsv(data.events),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'csv/liquidation_lines.csv',
      content: _liquidationLinesCsv(data.receipts, data.lines),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'csv/reimbursements.csv',
      content: _reimbursementsCsv(data.claims),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'csv/budget_vs_actual.csv',
      content: _budgetVsActualCsv(data),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'csv/auditor_reviews.csv',
      content: _auditorReviewsCsv(data.auditorReviews),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'csv/audit_logs.csv',
      content: _auditLogsCsv(data.auditLogs),
      sourceType: ExportArchiveEntrySource.csv,
    ),
    _archiveTextEntry(
      path: 'README.txt',
      content: _readmeFor(snapshot),
      sourceType: ExportArchiveEntrySource.readme,
    ),
  ];
}

_ArchiveFileData _archiveJsonEntry({
  required String path,
  required Object? value,
}) {
  return _archiveTextEntry(
    path: path,
    content: const JsonEncoder.withIndent('  ').convert(value),
    sourceType: ExportArchiveEntrySource.data,
  );
}

_ArchiveFileData _archiveTextEntry({
  required String path,
  required String content,
  required ExportArchiveEntrySource sourceType,
}) {
  return _ArchiveFileData(
    path: path,
    bytes: Uint8List.fromList(utf8.encode(content)),
    sourceType: sourceType,
  );
}

Future<List<_ArchiveFileData>> _archiveAttachmentEntries(
  _ExportData data, {
  required AttachmentStorageService? attachmentStorage,
}) async {
  final records = _buildAttachmentRecords(data);
  if (records.isEmpty) {
    return const [];
  }
  if (attachmentStorage == null) {
    throw StateError(
      'Attachment storage is required to include supporting documents in the ZIP.',
    );
  }
  final entries = <_ArchiveFileData>[];
  for (final record in records) {
    entries.add(
      _ArchiveFileData(
        path: _attachmentArchivePath(record),
        bytes: await attachmentStorage.readBytes(record.attachment),
        sourceType: ExportArchiveEntrySource.attachment,
      ),
    );
  }
  return entries;
}

String _attachmentArchivePath(_AttachmentRecord record) {
  return p.posix.join(
    'attachments',
    sanitizeAttachmentPathSegment(record.module),
    sanitizeAttachmentPathSegment(record.recordId),
    sanitizeAttachmentFileName(record.attachment.fileName),
  );
}

ExportPreviewFile _jsonFile(String path, Object? value) {
  return ExportPreviewFile(
    path: path,
    content: const JsonEncoder.withIndent('  ').convert(value),
  );
}

Map<String, Object?> _manifestFor({
  required _ExportData data,
  required DateTime asOf,
  required List<ExportRecordCount> recordCounts,
  required List<ExportPreviewFile> files,
}) {
  final organization = data.organizations.isEmpty
      ? null
      : data.organizations.first;
  return {
    'organization': organization == null
        ? null
        : _organizationJson(organization),
    'semester': organization?.semester,
    'schoolYear': organization?.schoolYear,
    'exportTimestamp': asOf.toIso8601String(),
    'appVersion': '1.0.0+1',
    'recordCounts': {
      for (final count in recordCounts) count.label: count.count,
    },
    'files': [
      for (final file in files)
        {
          'path': file.path,
          'byteLength': file.byteLength,
          'checksum': file.checksum,
        },
    ],
  };
}

Map<String, Object?> _archiveManifestFor({
  required _ExportData data,
  required DateTime asOf,
  required List<ExportRecordCount> recordCounts,
  required List<_ArchiveFileData> entries,
}) {
  final organization = data.organizations.isEmpty
      ? null
      : data.organizations.first;
  return {
    'organization': organization == null
        ? null
        : _organizationJson(organization),
    'semester': organization?.semester,
    'schoolYear': organization?.schoolYear,
    'exportTimestamp': asOf.toIso8601String(),
    'appVersion': '1.0.0+1',
    'checksumAlgorithm': 'SHA-256',
    'recordCounts': {
      for (final count in recordCounts) count.label: count.count,
    },
    'files': [
      for (final entry in entries)
        {
          'path': entry.path,
          'byteLength': entry.bytes.length,
          'checksum': sha256Hex(entry.bytes),
          'sourceType': entry.sourceType.name,
        },
    ],
  };
}

String _readmeFor(ExportCenterSnapshot snapshot) {
  return [
    'Audivance COA Export Package',
    '',
    'Organization: ${snapshot.organizationName}',
    'Term: ${snapshot.term}',
    'Readiness: ${snapshot.readinessScore}%',
    '',
    'Folders:',
    '- data/: full structured JSON records',
    '- csv/: spreadsheet-friendly review tables',
    '- attachments/: app-private supporting documents grouped by module and record',
    '- reports/: generated COA-facing PDF summaries',
    '',
    'Use manifest.json checksums to verify package contents before review.',
  ].join('\n');
}

String _treasuryLedgerCsv(List<FundMovement> movements) {
  return csv([
    [
      'id',
      'reference',
      'type',
      'date',
      'amountCentavos',
      'purpose',
      'systemGenerated',
    ],
    for (final movement in movements)
      [
        movement.id,
        movement.reference,
        movement.type.name,
        movement.date.toIso8601String(),
        movement.amount.centavos,
        movement.purpose,
        movement.isSystemGenerated,
      ],
  ]);
}

String _eventsCsv(List<AuditEvent> events) {
  return csv([
    [
      'id',
      'name',
      'type',
      'startDate',
      'endDate',
      'budgetCentavos',
      'approvedBudgetBalanceCentavos',
      'liquidated',
    ],
    for (final event in events)
      [
        event.id,
        event.name,
        event.type,
        event.startDate.toIso8601String(),
        event.endDate.toIso8601String(),
        event.budget.centavos,
        event.approvedBudgetBalance.centavos,
        event.isLiquidated,
      ],
  ]);
}

String _liquidationLinesCsv(
  List<LiquidationReceipt> receipts,
  List<LiquidationLine> lines,
) {
  final receiptById = {for (final receipt in receipts) receipt.id: receipt};
  return csv([
    [
      'id',
      'receiptId',
      'eventId',
      'description',
      'quantity',
      'unitCostCentavos',
      'totalCentavos',
    ],
    for (final line in lines)
      [
        line.id,
        line.receiptId,
        receiptById[line.receiptId]?.eventId,
        line.description,
        line.quantity,
        line.unitCost.centavos,
        line.total.centavos,
      ],
  ]);
}

String _reimbursementsCsv(List<ReimbursementClaim> claims) {
  return csv([
    [
      'id',
      'eventId',
      'officerId',
      'amountCentavos',
      'status',
      'sourceLiquidationLineId',
    ],
    for (final claim in claims)
      [
        claim.id,
        claim.eventId,
        claim.officerId,
        claim.amount.centavos,
        claim.status.name,
        claim.sourceLiquidationLineId,
      ],
  ]);
}

String _budgetVsActualCsv(_ExportData data) {
  return csv([
    [
      'eventId',
      'eventName',
      'budgetCentavos',
      'approvedBudgetBalanceCentavos',
      'actualCentavos',
      'varianceCentavos',
      'pendingReimbursementCentavos',
      'paidReimbursementCentavos',
      'utilizationBasisPoints',
      'health',
    ],
    for (final event in data.events)
      [
        event.id,
        event.name,
        event.budget.centavos,
        event.approvedBudgetBalance.centavos,
        _actualFor(data, event).centavos,
        (event.budget - _actualFor(data, event)).centavos,
        _reimbursementTotalFor(
          data,
          event,
          ReimbursementStatus.pending,
        ).centavos,
        _reimbursementTotalFor(data, event, ReimbursementStatus.paid).centavos,
        _utilizationBasisPoints(
          actualCentavos: _actualFor(data, event).centavos,
          budgetCentavos: event.budget.centavos,
        ),
        _budgetHealth(
          budgetCentavos: event.budget.centavos,
          utilizationBasisPoints: _utilizationBasisPoints(
            actualCentavos: _actualFor(data, event).centavos,
            budgetCentavos: event.budget.centavos,
          ),
        ).name,
      ],
  ]);
}

String _auditorReviewsCsv(List<AuditorReviewSnapshot> reviews) {
  return csv([
    [
      'id',
      'eventId',
      'findings',
      'cause',
      'recommendation',
      'budgetCentavos',
      'actualCentavos',
      'varianceCentavos',
      'utilizationBasisPoints',
      'health',
      'createdAt',
    ],
    for (final review in reviews)
      [
        review.id,
        review.eventId,
        review.findings,
        review.cause,
        review.recommendation,
        review.budget.centavos,
        review.actual.centavos,
        review.variance.centavos,
        review.utilizationBasisPoints,
        review.health.name,
        review.createdAt.toIso8601String(),
      ],
  ]);
}

String _auditLogsCsv(List<AuditLogEntry> logs) {
  return csv([
    [
      'id',
      'action',
      'actor',
      'targetRecordId',
      'occurredAt',
      'amountCentavos',
      'reference',
    ],
    for (final log in logs)
      [
        log.id,
        log.action,
        log.actor,
        log.targetRecordId,
        log.occurredAt.toIso8601String(),
        log.amount?.centavos,
        log.reference,
      ],
  ]);
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  if (text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}

String _exportFileName(OrganizationProfile? organization, DateTime asOf) {
  final org = _slug(organization?.name ?? 'Audivance');
  final schoolYear = _slug(organization?.schoolYear ?? 'No-SY');
  final semester = _slug(organization?.semester ?? 'No-Term');
  final date =
      '${asOf.year.toString().padLeft(4, '0')}-${asOf.month.toString().padLeft(2, '0')}-${asOf.day.toString().padLeft(2, '0')}';
  return 'Audivance-$org-$schoolYear-$semester-$date.zip';
}

String _slug(String value) {
  final slug = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'Audivance' : slug;
}

Map<String, Object?> _attachmentJson(AttachmentRef? attachment) {
  if (attachment == null) {
    return {
      'id': null,
      'fileName': null,
      'localPath': null,
      'sizeBytes': null,
      'checksum': null,
    };
  }
  return {
    'id': attachment.id,
    'fileName': attachment.fileName,
    'localPath': attachment.localPath,
    'sizeBytes': attachment.sizeBytes,
    'checksum': attachment.checksum,
  };
}

Map<String, Object?> _organizationJson(OrganizationProfile organization) => {
  'id': organization.id,
  'name': organization.name,
  'type': organization.type,
  'adviser': organization.adviser,
  'semester': organization.semester,
  'schoolYear': organization.schoolYear,
  'signatoryNames': organization.signatoryNames,
};

Map<String, Object?> _officerJson(Officer officer) => {
  'id': officer.id,
  'fullName': officer.fullName,
  'position': officer.position.name,
  'committee': officer.committee?.name,
  'isArchived': officer.isArchived,
};

Map<String, Object?> _treasurySourceJson(TreasuryFundSource source) => {
  'id': source.id,
  'type': source.type.name,
  'label': source.label,
  'balanceCentavos': source.balance.centavos,
  'supportingAttachment': _attachmentJson(source.supportingAttachment),
};

Map<String, Object?> _eventJson(AuditEvent event) => {
  'id': event.id,
  'name': event.name,
  'type': event.type,
  'semester': event.semester,
  'schoolYear': event.schoolYear,
  'startDate': event.startDate.toIso8601String(),
  'endDate': event.endDate.toIso8601String(),
  'permitApprovalDate': event.permitApprovalDate?.toIso8601String(),
  'resolutionNumber': event.resolutionNumber,
  'budgetCentavos': event.budget.centavos,
  'approvedBudgetBalanceCentavos': event.approvedBudgetBalance.centavos,
  'resolutionAttachment': _attachmentJson(event.resolutionAttachment),
  'isLiquidated': event.isLiquidated,
};

Map<String, Object?> _allocationJson(EventFundingAllocation allocation) => {
  'eventId': allocation.eventId,
  'fundSourceId': allocation.fundSourceId,
  'amountCentavos': allocation.amount.centavos,
};

Map<String, Object?> _movementJson(FundMovement movement) => {
  'id': movement.id,
  'reference': movement.reference,
  'type': movement.type.name,
  'date': movement.date.toIso8601String(),
  'amountCentavos': movement.amount.centavos,
  'purpose': movement.purpose,
  'remarks': movement.remarks,
  'eventId': movement.eventId,
  'fromFundSourceId': movement.fromFundSourceId,
  'toFundSourceId': movement.toFundSourceId,
  'holderOfficerId': movement.holderOfficerId,
  'isSystemGenerated': movement.isSystemGenerated,
};

Map<String, Object?> _receiptJson(LiquidationReceipt receipt) => {
  'id': receipt.id,
  'eventId': receipt.eventId,
  'payeeOrMerchant': receipt.payeeOrMerchant,
  'date': receipt.date.toIso8601String(),
  'evidenceNumber': receipt.evidenceNumber,
  'receiptType': receipt.receiptType.name,
  'fundingMode': receipt.fundingMode.name,
  'accountableOfficerId': receipt.accountableOfficerId,
  'attachment': _attachmentJson(receipt.attachment),
};

Map<String, Object?> _lineJson(LiquidationLine line) => {
  'id': line.id,
  'receiptId': line.receiptId,
  'description': line.description,
  'quantity': line.quantity,
  'unitCostCentavos': line.unitCost.centavos,
  'totalCentavos': line.total.centavos,
};

Map<String, Object?> _claimJson(ReimbursementClaim claim) => {
  'id': claim.id,
  'eventId': claim.eventId,
  'officerId': claim.officerId,
  'amountCentavos': claim.amount.centavos,
  'status': claim.status.name,
  'sourceLiquidationLineId': claim.sourceLiquidationLineId,
};

Map<String, Object?> _budgetActualJson(_ExportData data, AuditEvent event) {
  final actual = _actualFor(data, event);
  final utilizationBasisPoints = _utilizationBasisPoints(
    actualCentavos: actual.centavos,
    budgetCentavos: event.budget.centavos,
  );
  return {
    'eventId': event.id,
    'eventName': event.name,
    'budgetCentavos': event.budget.centavos,
    'approvedBudgetBalanceCentavos': event.approvedBudgetBalance.centavos,
    'actualCentavos': actual.centavos,
    'varianceCentavos': (event.budget - actual).centavos,
    'pendingReimbursementCentavos': _reimbursementTotalFor(
      data,
      event,
      ReimbursementStatus.pending,
    ).centavos,
    'paidReimbursementCentavos': _reimbursementTotalFor(
      data,
      event,
      ReimbursementStatus.paid,
    ).centavos,
    'utilizationBasisPoints': utilizationBasisPoints,
    'health': _budgetHealth(
      budgetCentavos: event.budget.centavos,
      utilizationBasisPoints: utilizationBasisPoints,
    ).name,
  };
}

Map<String, Object?> _auditorReviewJson(AuditorReviewSnapshot review) => {
  'id': review.id,
  'eventId': review.eventId,
  'findings': review.findings,
  'cause': review.cause,
  'recommendation': review.recommendation,
  'budgetCentavos': review.budget.centavos,
  'actualCentavos': review.actual.centavos,
  'varianceCentavos': review.variance.centavos,
  'utilizationBasisPoints': review.utilizationBasisPoints,
  'health': review.health.name,
  'createdAt': review.createdAt.toIso8601String(),
};

Map<String, Object?> _auditLogJson(AuditLogEntry log) => {
  'id': log.id,
  'action': log.action,
  'actor': log.actor,
  'targetRecordId': log.targetRecordId,
  'occurredAt': log.occurredAt.toIso8601String(),
  'amountCentavos': log.amount?.centavos,
  'reference': log.reference,
  'beforeSnapshot': log.beforeSnapshot,
  'afterSnapshot': log.afterSnapshot,
  'metadata': log.metadata,
};

Money _actualFor(_ExportData data, AuditEvent event) {
  final receiptIds = {
    for (final receipt in data.receipts)
      if (receipt.eventId == event.id) receipt.id,
  };
  return data.lines
      .where((line) => receiptIds.contains(line.receiptId))
      .fold(Money.zero, (total, line) => total + line.total);
}

Money _reimbursementTotalFor(
  _ExportData data,
  AuditEvent event,
  ReimbursementStatus status,
) {
  return data.claims
      .where((claim) => claim.eventId == event.id && claim.status == status)
      .fold(Money.zero, (total, claim) => total + claim.amount);
}

int _utilizationBasisPoints({
  required int actualCentavos,
  required int budgetCentavos,
}) {
  if (budgetCentavos <= 0) {
    return 0;
  }
  return (actualCentavos * 10000) ~/ budgetCentavos;
}

BudgetHealth _budgetHealth({
  required int budgetCentavos,
  required int utilizationBasisPoints,
}) {
  if (budgetCentavos <= 0) {
    return BudgetHealth.noBudget;
  }
  if (utilizationBasisPoints <= 8000) {
    return BudgetHealth.healthy;
  }
  if (utilizationBasisPoints <= 10000) {
    return BudgetHealth.watch;
  }
  if (utilizationBasisPoints <= 12000) {
    return BudgetHealth.overBudget;
  }
  return BudgetHealth.critical;
}

class _ExportData {
  const _ExportData({
    required this.organizations,
    required this.officers,
    required this.treasurySources,
    required this.events,
    required this.allocations,
    required this.movements,
    required this.receipts,
    required this.lines,
    required this.claims,
    required this.auditorReviews,
    required this.auditLogs,
  });

  final List<OrganizationProfile> organizations;
  final List<Officer> officers;
  final List<TreasuryFundSource> treasurySources;
  final List<AuditEvent> events;
  final List<EventFundingAllocation> allocations;
  final List<FundMovement> movements;
  final List<LiquidationReceipt> receipts;
  final List<LiquidationLine> lines;
  final List<ReimbursementClaim> claims;
  final List<AuditorReviewSnapshot> auditorReviews;
  final List<AuditLogEntry> auditLogs;
}
