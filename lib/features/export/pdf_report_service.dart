import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../audit/domain/audit_models.dart';
import '../treasury/treasury_formatters.dart';

class PdfReportService {
  const PdfReportService();

  Future<PdfReportBundle> buildReports({required PdfReportInput input}) async {
    final files = <PdfReportFile>[
      await _buildOrganizationSummary(input),
      await _buildTreasuryLedger(input),
      await _buildBudgetVsActual(input),
      ...await _buildLiquidationReports(input),
    ]..sort((a, b) => a.path.compareTo(b.path));

    return PdfReportBundle(files: files);
  }
}

class PdfReportInput {
  const PdfReportInput({
    required this.asOf,
    required this.readinessScore,
    required this.readinessIssues,
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
    this.logoAssetPath = _defaultLogoAssetPath,
  });

  final DateTime asOf;
  final int readinessScore;
  final List<PdfReadinessIssue> readinessIssues;
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
  final String logoAssetPath;
}

const _defaultLogoAssetPath = 'assets/images/logo/usm_logo.png';

class PdfReadinessIssue {
  const PdfReadinessIssue({
    required this.message,
    required this.severity,
    this.targetRecordId,
  });

  final String message;
  final ExportReadinessSeverity severity;
  final StableId? targetRecordId;
}

class PdfReportBundle {
  const PdfReportBundle({required this.files});

  final List<PdfReportFile> files;
}

class PdfReportFile {
  PdfReportFile({required this.path, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes),
      byteLength = bytes.length,
      checksum = _sha256Hex(bytes);

  final String path;
  final Uint8List bytes;
  final int byteLength;
  final String checksum;
}

List<String> pdfReportPathsFor({
  required List<AuditEvent> events,
  required List<LiquidationReceipt> receipts,
}) {
  final liquidationPaths = <String>[
    for (final event in events) _liquidationReportPath(event),
  ]..sort();

  return [
    'reports/organization_summary.pdf',
    'reports/treasury_ledger.pdf',
    'reports/budget_vs_actual.pdf',
    ...liquidationPaths,
  ];
}

Future<PdfReportFile> _buildOrganizationSummary(PdfReportInput input) async {
  final organization = input.organizations.isEmpty
      ? null
      : input.organizations.first;
  return _pdfFile(
    path: 'reports/organization_summary.pdf',
    title: 'Organization Summary',
    asOf: input.asOf,
    build: () => [
      _sectionTitle('Organization Profile'),
      _keyValueTable([
        ['Name', organization?.name ?? 'No organization profile'],
        ['Type', organization?.type ?? 'Not encoded'],
        ['Adviser', organization?.adviser ?? 'Not encoded'],
        ['Semester', organization?.semester ?? 'Not encoded'],
        ['School Year', organization?.schoolYear ?? 'Not encoded'],
        [
          'Signatories',
          organization == null || organization.signatoryNames.isEmpty
              ? 'Not encoded'
              : organization.signatoryNames.join(', '),
        ],
      ]),
      _gap(),
      _sectionTitle('Officer Roster'),
      _dataTable(
        headers: ['Name', 'Position', 'Committee', 'Status'],
        rows: input.officers.isEmpty
            ? [
                ['No officers encoded', '', '', ''],
              ]
            : [
                for (final officer in input.officers)
                  [
                    officer.fullName,
                    _officerPositionLabel(officer.position),
                    officer.committee?.name ?? 'None',
                    officer.isArchived ? 'Archived' : 'Active',
                  ],
              ],
      ),
      _gap(),
      _sectionTitle('Readiness Summary'),
      _keyValueTable([
        ['Readiness Score', '${input.readinessScore}%'],
        [
          'Blockers',
          input.readinessIssues
              .where(
                (issue) => issue.severity == ExportReadinessSeverity.blocker,
              )
              .length
              .toString(),
        ],
        [
          'Warnings',
          input.readinessIssues
              .where(
                (issue) => issue.severity == ExportReadinessSeverity.warning,
              )
              .length
              .toString(),
        ],
      ]),
      if (input.readinessIssues.isNotEmpty) ...[
        _gap(),
        _dataTable(
          headers: ['Severity', 'Issue', 'Record'],
          rows: [
            for (final issue in input.readinessIssues)
              [issue.severity.name, issue.message, issue.targetRecordId ?? ''],
          ],
        ),
      ],
    ],
  );
}

Future<PdfReportFile> _buildTreasuryLedger(PdfReportInput input) async {
  final total = input.treasurySources.fold(
    Money.zero,
    (sum, source) => sum + source.balance,
  );
  return _pdfFile(
    path: 'reports/treasury_ledger.pdf',
    title: 'Treasury Ledger',
    asOf: input.asOf,
    build: () => [
      _sectionTitle('Source Balances'),
      _keyValueTable([
        ['Total Unallocated Balance', formatPhpMoney(total)],
      ]),
      _dataTable(
        headers: ['Source', 'Type', 'Balance'],
        rows: input.treasurySources.isEmpty
            ? [
                ['No treasury sources encoded', '', ''],
              ]
            : [
                for (final source in input.treasurySources)
                  [
                    source.label,
                    treasurySourceTypeLabel(source.type),
                    formatPhpMoney(source.balance),
                  ],
              ],
      ),
      _gap(),
      _sectionTitle('Fund Movement Ledger'),
      _dataTable(
        headers: [
          'Date',
          'Reference',
          'Type',
          'Amount',
          'Purpose',
          'Protected',
        ],
        rows: input.movements.isEmpty
            ? [
                ['No fund movements encoded', '', '', '', '', ''],
              ]
            : [
                for (final movement in _movementsNewestFirst(input.movements))
                  [
                    formatDate(movement.date),
                    movement.reference,
                    fundMovementTypeLabel(movement.type),
                    formatPhpMoney(movement.amount),
                    movement.purpose,
                    movement.isSystemGenerated ? 'Yes' : 'No',
                  ],
              ],
      ),
    ],
  );
}

Future<PdfReportFile> _buildBudgetVsActual(PdfReportInput input) async {
  final reviewByEvent = {
    for (final review in input.auditorReviews) review.eventId: review,
  };
  return _pdfFile(
    path: 'reports/budget_vs_actual.pdf',
    title: 'Budget vs Actual',
    asOf: input.asOf,
    build: () => [
      _sectionTitle('Event Budget Review'),
      _dataTable(
        headers: [
          'Event',
          'Budget',
          'Actual',
          'Variance',
          'Utilization',
          'Health',
        ],
        rows: input.events.isEmpty
            ? [
                ['No events encoded', '', '', '', '', ''],
              ]
            : [
                for (final event in input.events)
                  [
                    event.name,
                    formatPhpMoney(event.budget),
                    formatPhpMoney(_actualFor(input, event)),
                    formatPhpMoney(event.budget - _actualFor(input, event)),
                    _percent(
                      _utilizationBasisPoints(
                        actualCentavos: _actualFor(input, event).centavos,
                        budgetCentavos: event.budget.centavos,
                      ),
                    ),
                    _budgetHealth(
                      budgetCentavos: event.budget.centavos,
                      utilizationBasisPoints: _utilizationBasisPoints(
                        actualCentavos: _actualFor(input, event).centavos,
                        budgetCentavos: event.budget.centavos,
                      ),
                    ).name,
                  ],
              ],
      ),
      _gap(),
      _sectionTitle('Auditor Review Notes'),
      for (final event in input.events) ...[
        _subsectionTitle(event.name),
        _keyValueTable([
          [
            'Findings',
            reviewByEvent[event.id]?.findings ?? 'No review encoded',
          ],
          ['Cause', reviewByEvent[event.id]?.cause ?? 'No review encoded'],
          [
            'Recommendation',
            reviewByEvent[event.id]?.recommendation ?? 'No review encoded',
          ],
        ]),
        _gap(height: 8),
      ],
    ],
  );
}

Future<List<PdfReportFile>> _buildLiquidationReports(
  PdfReportInput input,
) async {
  final receiptsByEvent = <StableId, List<LiquidationReceipt>>{};
  for (final receipt in input.receipts) {
    receiptsByEvent.putIfAbsent(receipt.eventId, () => []).add(receipt);
  }
  final files = <PdfReportFile>[];
  for (final event in [...input.events]..sort((a, b) => a.id.compareTo(b.id))) {
    final receipts = [
      ...(receiptsByEvent[event.id] ?? const <LiquidationReceipt>[]),
    ];
    receipts.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.id.compareTo(b.id);
    });
    files.add(await _buildLiquidationReport(input, event, receipts));
  }
  return files;
}

Future<PdfReportFile> _buildLiquidationReport(
  PdfReportInput input,
  AuditEvent event,
  List<LiquidationReceipt> receipts,
) async {
  final linesByReceipt = <StableId, List<LiquidationLine>>{};
  for (final line in input.lines) {
    linesByReceipt.putIfAbsent(line.receiptId, () => []).add(line);
  }
  final organization = input.organizations.isEmpty
      ? null
      : input.organizations.first;
  final sourcesById = {
    for (final source in input.treasurySources) source.id: source,
  };
  final allocations = input.allocations
      .where((allocation) => allocation.eventId == event.id)
      .toList(growable: false);
  final fundSource = allocations.isEmpty
      ? ''
      : allocations
            .map((allocation) {
              final source = sourcesById[allocation.fundSourceId];
              return source?.label.trim().isNotEmpty == true
                  ? source!.label
                  : source == null
                  ? allocation.fundSourceId
                  : treasurySourceTypeLabel(source.type);
            })
            .toSet()
            .join(', ');
  final total = receipts.fold(
    Money.zero,
    (sum, receipt) =>
        sum +
        (linesByReceipt[receipt.id] ?? const <LiquidationLine>[]).fold(
          Money.zero,
          (lineSum, line) => lineSum + line.total,
        ),
  );
  final receiptTotals = {
    for (final receipt in receipts)
      receipt.id: (linesByReceipt[receipt.id] ?? const <LiquidationLine>[])
          .fold(Money.zero, (sum, line) => sum + line.total),
  };
  final remarksByReceipt = _remarksByReceipt(
    receipts: receipts,
    receiptTotals: receiptTotals,
    movements: input.movements,
  );
  final items = <_LiquidationReportItem>[];
  var itemNumber = 1;
  for (final receipt in receipts) {
    final lines = [...(linesByReceipt[receipt.id] ?? const <LiquidationLine>[])]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final line in lines) {
      items.add(
        _LiquidationReportItem(
          itemNumber: itemNumber,
          nature: line.description,
          payeeMerchant: receipt.payeeOrMerchant,
          amount: line.total,
          expenseDate: receipt.date,
          evidenceNumber: receipt.evidenceNumber,
          remarks: remarksByReceipt[receipt.id] ?? '',
        ),
      );
      itemNumber += 1;
    }
  }
  final signatories = _signatureNames(
    organization: organization,
    officers: input.officers,
  );
  final logo = await _loadLogo(input.logoAssetPath);

  return _liquidationPdfFile(
    path: _liquidationReportPath(event),
    logo: logo,
    organizationName: organization?.name ?? '',
    organizationType: organization?.type ?? '',
    semesterSchoolYear: _termText(event.semester, event.schoolYear),
    activityName: event.name,
    activityDateRange: _dateRangeText(event.startDate, event.endDate),
    permitApprovalDate: event.permitApprovalDate == null
        ? ''
        : formatDate(event.permitApprovalDate!),
    budgetAllocation: _formatPhpPaper(event.budget),
    fundSource: fundSource,
    resolutionNumber: event.resolutionNumber,
    items: items,
    totalAmount: total,
    treasurerName: signatories.treasurerName,
    auditorName: signatories.auditorName,
    organizationHeadName: signatories.organizationHeadName,
    adviserName: organization?.adviser ?? '',
  );
}

Future<PdfReportFile> _liquidationPdfFile({
  required String path,
  required pw.MemoryImage? logo,
  required String organizationName,
  required String organizationType,
  required String semesterSchoolYear,
  required String activityName,
  required String activityDateRange,
  required String permitApprovalDate,
  required String budgetAllocation,
  required String fundSource,
  required String resolutionNumber,
  required List<_LiquidationReportItem> items,
  required Money totalAmount,
  required String treasurerName,
  required String auditorName,
  required String organizationHeadName,
  required String adviserName,
}) async {
  final document = pw.Document(compress: false);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 34, 40, 34),
      build: (context) => [
        _officialHeader(logo),
        pw.SizedBox(height: 5),
        _metadataTable(
          organizationName: organizationName,
          organizationType: organizationType,
          semesterSchoolYear: semesterSchoolYear,
          activityName: activityName,
          activityDateRange: activityDateRange,
          permitApprovalDate: permitApprovalDate,
          budgetAllocation: budgetAllocation,
          fundSource: fundSource,
          resolutionNumber: resolutionNumber,
        ),
        pw.SizedBox(height: 14),
        _instructionBlock(),
        pw.SizedBox(height: 5),
        _liquidationItemsTable(items),
        _liquidationTotalRow(totalAmount),
        pw.SizedBox(height: 18),
        pw.Text(
          'We hereby attest to the correctness of this liquidation report.',
          style: _officialTextStyle(fontSize: 9.5, bold: true),
        ),
        pw.SizedBox(height: 20),
        _signatureTable(
          treasurerName: treasurerName,
          auditorName: auditorName,
          organizationHeadName: organizationHeadName,
          adviserName: adviserName,
        ),
        pw.SizedBox(height: 58),
        _commissionerLines(),
        pw.SizedBox(height: 52),
        pw.Text(
          'USM-OSA-F46-Rev.0.2025.05.05',
          style: _officialTextStyle(fontSize: 8, bold: true),
        ),
      ],
    ),
  );
  final bytes = Uint8List.fromList(await document.save());
  return PdfReportFile(path: path, bytes: _normalizePdfDocumentId(bytes));
}

pw.Widget _officialHeader(pw.MemoryImage? logo) {
  return pw.Column(
    children: [
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.9),
        columnWidths: const {
          0: pw.FixedColumnWidth(92),
          1: pw.FlexColumnWidth(),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                height: 72,
                alignment: pw.Alignment.center,
                child: logo == null
                    ? _logoPlaceholder()
                    : pw.Image(
                        logo,
                        width: 54,
                        height: 54,
                        fit: pw.BoxFit.contain,
                      ),
              ),
              pw.Container(
                height: 72,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(right: 72),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'UNIVERSITY OF SOUTHERN MINDANAO',
                      textAlign: pw.TextAlign.center,
                      style: _officialTextStyle(fontSize: 14, bold: true),
                    ),
                    pw.Text(
                      'Kabacan, Cotabato, Philippines',
                      textAlign: pw.TextAlign.center,
                      style: _officialTextStyle(fontSize: 10.5, bold: true),
                    ),
                    pw.Text(
                      'Office of Student Affairs',
                      textAlign: pw.TextAlign.center,
                      style: _officialTextStyle(fontSize: 10.5, bold: true),
                    ),
                    pw.Text(
                      'STUDENT DEVELOPMENT SERVICES',
                      textAlign: pw.TextAlign.center,
                      style: _officialTextStyle(fontSize: 13, bold: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      pw.Container(
        height: 18,
        alignment: pw.Alignment.center,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.black, width: 0.9),
            right: pw.BorderSide(color: PdfColors.black, width: 0.9),
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.9),
          ),
        ),
        child: pw.Text(
          'LIQUIDATION REPORT',
          style: _officialTextStyle(fontSize: 12, bold: true),
        ),
      ),
    ],
  );
}

pw.Widget _logoPlaceholder() {
  return pw.Container(
    width: 54,
    height: 54,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 0.9),
      shape: pw.BoxShape.circle,
    ),
    child: pw.Text('USM', style: _officialTextStyle(fontSize: 10, bold: true)),
  );
}

pw.Widget _metadataTable({
  required String organizationName,
  required String organizationType,
  required String semesterSchoolYear,
  required String activityName,
  required String activityDateRange,
  required String permitApprovalDate,
  required String budgetAllocation,
  required String fundSource,
  required String resolutionNumber,
}) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
    columnWidths: const {
      0: pw.FlexColumnWidth(),
      1: pw.FlexColumnWidth(),
      2: pw.FlexColumnWidth(),
    },
    children: [
      pw.TableRow(
        children: [
          _metadataCell(label: 'Name of Organization', value: organizationName),
          _metadataCell(
            label: 'Type of Organization',
            helper: '(student government, academic, non-academic, frat/sor, religious, etc.)',
            value: organizationType,
          ),
          _metadataCell(
            label: 'Semester & School Year',
            value: semesterSchoolYear,
          ),
        ],
      ),
      pw.TableRow(
        children: [
          _metadataCell(
            label: 'Name of Activity/ Project',
            value: activityName,
          ),
          _metadataCell(
            label: 'Duration/ Date of Activity',
            value: activityDateRange,
          ),
          _metadataCell(
            label: 'Date of Approval of Activity Permit by OSA',
            value: permitApprovalDate,
          ),
        ],
      ),
      pw.TableRow(
        children: [
          _metadataCell(label: 'Budget Allocation', value: budgetAllocation),
          _metadataCell(
            label: 'Fund Source',
            helper: '(as reflected in the budget ordinance/resolution)',
            value: fundSource,
          ),
          _metadataCell(label: 'Resolution Number', value: resolutionNumber),
        ],
      ),
    ],
  );
}

pw.Widget _metadataCell({
  required String label,
  required String value,
  String? helper,
}) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 58),
    padding: const pw.EdgeInsets.fromLTRB(6, 5, 6, 5),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: label,
                style: _officialTextStyle(fontSize: 8.8, bold: true),
              ),
              if (helper != null) ...[
                const pw.TextSpan(text: ' '),
                pw.TextSpan(
                  text: helper,
                  style: _officialTextStyle(fontSize: 5.2, italic: true),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          value.trim().isEmpty ? ' ' : value,
          style: _officialTextStyle(fontSize: 8.5, bold: true),
        ),
      ],
    ),
  );
}

pw.Widget _instructionBlock() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Liquidation Report',
        style: _officialTextStyle(fontSize: 8.4, bold: true),
      ),
      pw.Text(
        'This liquidation report should be submitted to OSA a month after the completion of the activity. Submit digital copies of this report to sdsdosa@usm.edu.ph',
        style: _officialTextStyle(fontSize: 7.8, bold: true),
      ),
    ],
  );
}

pw.Widget _liquidationItemsTable(List<_LiquidationReportItem> items) {
  final rows = items.isEmpty
      ? [
          pw.TableRow(
            children: [
              _itemCell('No receipts recorded', bold: true),
              _itemCell(''),
              _itemCell(''),
              _itemCell(''),
              _itemCell(''),
              _itemCell(''),
              _itemCell(''),
            ],
          ),
        ]
      : [
          for (final item in items)
            pw.TableRow(
              children: [
                _itemCell(
                  item.itemNumber.toString(),
                  alignment: pw.Alignment.center,
                ),
                _itemCell(item.nature),
                _itemCell(item.payeeMerchant),
                _itemCell(
                  _formatAmountPaper(item.amount),
                  alignment: pw.Alignment.centerRight,
                ),
                _itemCell(_formatNumericDate(item.expenseDate)),
                _itemCell(item.evidenceNumber),
                _itemCell(item.remarks),
              ],
            ),
        ];
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
    columnWidths: _itemColumnWidths,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey900),
        children: [
          _itemHeader('Item\nNumber'),
          _itemHeader('Nature'),
          _itemHeader('Payee/\nMerchant'),
          _itemHeader('Amount'),
          _itemHeader('Date'),
          _itemHeader('Evidence\nNumber (OR #)'),
          _itemHeader('Remarks'),
        ],
      ),
      ...rows,
    ],
  );
}

pw.Widget _liquidationTotalRow(Money totalAmount) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
    columnWidths: const {
      0: pw.FlexColumnWidth(3.45),
      1: pw.FlexColumnWidth(4.4),
    },
    children: [
      pw.TableRow(
        children: [
          pw.Container(
            height: 16,
            color: PdfColors.grey900,
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.only(right: 6),
            child: pw.Text(
              'TOTAL:',
              style: _officialTextStyle(
                fontSize: 9,
                bold: true,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Container(
            height: 16,
            alignment: pw.Alignment.centerLeft,
            padding: const pw.EdgeInsets.only(left: 8),
            child: pw.Text(
              _formatPhpPaper(totalAmount),
              style: _officialTextStyle(fontSize: 8.5, bold: true),
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _itemHeader(String text) {
  return pw.Container(
    height: 20,
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: _officialTextStyle(
        fontSize: 5.8,
        bold: true,
        color: PdfColors.white,
      ),
    ),
  );
}

pw.Widget _itemCell(
  String text, {
  bool bold = false,
  pw.Alignment alignment = pw.Alignment.centerLeft,
}) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 16),
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: pw.Text(
      text,
      textAlign: alignment == pw.Alignment.centerRight
          ? pw.TextAlign.right
          : alignment == pw.Alignment.center
          ? pw.TextAlign.center
          : pw.TextAlign.left,
      style: _officialTextStyle(fontSize: 6.2, bold: bold),
    ),
  );
}

pw.Widget _signatureTable({
  required String treasurerName,
  required String auditorName,
  required String organizationHeadName,
  required String adviserName,
}) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
    columnWidths: const {
      0: pw.FlexColumnWidth(),
      1: pw.FlexColumnWidth(),
      2: pw.FlexColumnWidth(),
      3: pw.FlexColumnWidth(),
    },
    children: [
      pw.TableRow(
        children: [
          _signatureCell(
            title: 'Prepared by:',
            name: treasurerName,
            caption: 'Name and Signature of\nOrganization Treasurer',
          ),
          _signatureCell(
            title: 'Audited by:',
            name: auditorName,
            caption: 'Name and Signature of\nOrganization Auditor',
          ),
          _signatureCell(
            title: 'Submitted by',
            name: organizationHeadName,
            caption: 'Name and Signature of\nOrganization Head',
          ),
          _signatureCell(
            title: 'Noted:',
            name: adviserName,
            caption: 'Name and Signature of\nAdviser',
          ),
        ],
      ),
    ],
  );
}

pw.Widget _signatureCell({
  required String title,
  required String name,
  required String caption,
}) {
  return pw.Container(
    height: 88,
    padding: const pw.EdgeInsets.fromLTRB(8, 7, 8, 7),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: _officialTextStyle(fontSize: 9, bold: true)),
        pw.Spacer(),
        pw.Center(
          child: pw.Text(
            name.trim().isEmpty ? ' ' : name.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: _officialTextStyle(fontSize: 7.2, bold: true),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            caption,
            textAlign: pw.TextAlign.center,
            style: _officialTextStyle(fontSize: 6.2),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _commissionerLines() {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [_commissionerLine(), _commissionerLine()],
  );
}

pw.Widget _commissionerLine() {
  return pw.Container(
    width: 188,
    child: pw.Column(
      children: [
        pw.Container(height: 0.9, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text('COMMISSIONER', style: _officialTextStyle(fontSize: 6.5)),
      ],
    ),
  );
}

const _itemColumnWidths = {
  0: pw.FlexColumnWidth(0.72),
  1: pw.FlexColumnWidth(1.38),
  2: pw.FlexColumnWidth(1.35),
  3: pw.FlexColumnWidth(0.95),
  4: pw.FlexColumnWidth(0.95),
  5: pw.FlexColumnWidth(1.35),
  6: pw.FlexColumnWidth(1.15),
};

pw.TextStyle _officialTextStyle({
  required double fontSize,
  bool bold = false,
  bool italic = false,
  PdfColor color = PdfColors.black,
}) {
  return pw.TextStyle(
    fontSize: fontSize,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
    color: color,
  );
}

Future<pw.MemoryImage?> _loadLogo(String assetPath) async {
  try {
    final data = await rootBundle.load(assetPath);
    return pw.MemoryImage(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } on Object {
    return null;
  }
}

Map<StableId, String> _remarksByReceipt({
  required List<LiquidationReceipt> receipts,
  required Map<StableId, Money> receiptTotals,
  required List<FundMovement> movements,
}) {
  final remarksByReceipt = <StableId, String>{};
  for (final receipt in receipts) {
    final total = receiptTotals[receipt.id] ?? Money.zero;
    for (final movement in movements) {
      if (movement.type == FundMovementType.liquidationSubmitted &&
          movement.eventId == receipt.eventId &&
          movement.holderOfficerId == receipt.accountableOfficerId &&
          _sameDate(movement.date, receipt.date) &&
          movement.amount == total &&
          movement.remarks?.trim().isNotEmpty == true) {
        remarksByReceipt[receipt.id] = movement.remarks!.trim();
        break;
      }
    }
  }
  return remarksByReceipt;
}

_SignatureNames _signatureNames({
  required OrganizationProfile? organization,
  required List<Officer> officers,
}) {
  final active = officers.where((officer) => !officer.isArchived).toList();
  String firstOfficer({
    required Committee committee,
    required int fallbackIndex,
  }) {
    final head = active.where(
      (officer) =>
          officer.committee == committee &&
          officer.position == OfficerPosition.head,
    );
    if (head.isNotEmpty) {
      return head.first.fullName;
    }
    final member = active.where((officer) => officer.committee == committee);
    if (member.isNotEmpty) {
      return member.first.fullName;
    }
    final signatories = organization?.signatoryNames ?? const <String>[];
    if (fallbackIndex < signatories.length) {
      return signatories[fallbackIndex];
    }
    return '';
  }

  final signatories = organization?.signatoryNames ?? const <String>[];
  return _SignatureNames(
    treasurerName: firstOfficer(committee: Committee.finance, fallbackIndex: 0),
    auditorName: firstOfficer(committee: Committee.audit, fallbackIndex: 1),
    organizationHeadName: signatories.length > 2
        ? signatories[2]
        : signatories.isNotEmpty
        ? signatories.first
        : '',
  );
}

String _termText(String semester, String schoolYear) {
  final parts = [
    semester.trim(),
    schoolYear.trim(),
  ].where((part) => part.isNotEmpty);
  return parts.join(' ');
}

String _dateRangeText(DateTime startDate, DateTime endDate) {
  if (_sameDate(startDate, endDate)) {
    return formatDate(startDate);
  }
  return '${formatDate(startDate)} - ${formatDate(endDate)}';
}

String _formatNumericDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$month/$day/$year';
}

String _formatPhpPaper(Money money) => 'Php ${_formatAmountPaper(money)}';

String _formatAmountPaper(Money money) {
  final sign = money.centavos < 0 ? '-' : '';
  final absolute = money.centavos.abs();
  final pesos = absolute ~/ 100;
  final centavos = absolute % 100;
  return '$sign${_formatIntegerPaper(pesos)}.${centavos.toString().padLeft(2, '0')}';
}

String _formatIntegerPaper(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i += 1) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

bool _sameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

class _LiquidationReportItem {
  const _LiquidationReportItem({
    required this.itemNumber,
    required this.nature,
    required this.payeeMerchant,
    required this.amount,
    required this.expenseDate,
    required this.evidenceNumber,
    required this.remarks,
  });

  final int itemNumber;
  final String nature;
  final String payeeMerchant;
  final Money amount;
  final DateTime expenseDate;
  final String evidenceNumber;
  final String remarks;
}

class _SignatureNames {
  const _SignatureNames({
    required this.treasurerName,
    required this.auditorName,
    required this.organizationHeadName,
  });

  final String treasurerName;
  final String auditorName;
  final String organizationHeadName;
}

Future<PdfReportFile> _pdfFile({
  required String path,
  required String title,
  required DateTime asOf,
  required List<pw.Widget> Function() build,
}) async {
  final document = pw.Document(compress: false);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Audivance',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated ${formatDate(asOf)}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ),
      build: (context) => build(),
    ),
  );
  final bytes = Uint8List.fromList(await document.save());
  return PdfReportFile(path: path, bytes: _normalizePdfDocumentId(bytes));
}

Uint8List _normalizePdfDocumentId(Uint8List bytes) {
  final text = latin1.decode(bytes);
  final normalized = text.replaceFirst(
    RegExp(r'/ID\s*\[\s*<[^>]+>\s*<[^>]+>\s*\]'),
    '/ID [<0000000000000000000000000000000000000000000000000000000000000000><0000000000000000000000000000000000000000000000000000000000000000>]',
  );
  return Uint8List.fromList(latin1.encode(normalized));
}

pw.Widget _sectionTitle(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _subsectionTitle(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
  );
}

pw.Widget _gap({double height = 14}) => pw.SizedBox(height: height);

pw.Widget _keyValueTable(List<List<String>> rows) {
  return _dataTable(
    headers: ['Field', 'Value'],
    rows: rows,
    columnWidths: const {
      0: pw.FlexColumnWidth(1.1),
      1: pw.FlexColumnWidth(2.9),
    },
  );
}

pw.Widget _dataTable({
  required List<String> headers,
  required List<List<String>> rows,
  Map<int, pw.TableColumnWidth>? columnWidths,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 8),
    columnWidths: columnWidths,
  );
}

List<FundMovement> _movementsNewestFirst(List<FundMovement> movements) {
  return [...movements]..sort((a, b) {
    final dateCompare = b.date.compareTo(a.date);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return b.id.compareTo(a.id);
  });
}

Money _actualFor(PdfReportInput input, AuditEvent event) {
  final receiptIds = {
    for (final receipt in input.receipts)
      if (receipt.eventId == event.id) receipt.id,
  };
  return input.lines
      .where((line) => receiptIds.contains(line.receiptId))
      .fold(Money.zero, (total, line) => total + line.total);
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

String _percent(int basisPoints) {
  final whole = basisPoints ~/ 100;
  final decimals = (basisPoints % 100).toString().padLeft(2, '0');
  return '$whole.$decimals%';
}

String _officerPositionLabel(OfficerPosition position) {
  return switch (position) {
    OfficerPosition.head => 'Head',
    OfficerPosition.member => 'Member',
  };
}

String _liquidationReportPath(AuditEvent event) {
  return p.posix.join(
    'reports',
    'liquidation',
    '${_slug(event.name)}-${_slug(event.id)}.pdf',
  );
}

String _slug(String value) {
  final slug = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'record' : slug;
}

String _sha256Hex(List<int> bytes) {
  return crypto.sha256.convert(bytes).toString();
}
