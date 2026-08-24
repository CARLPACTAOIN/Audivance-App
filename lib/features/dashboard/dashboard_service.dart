import 'package:flutter/material.dart';

import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/money.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';
import '../export/export_service.dart';
import 'dashboard_models.dart';

class DashboardService {
  const DashboardService(this._repository, {this.attachmentStorage});

  final AuditRepository _repository;
  final AttachmentStorageService? attachmentStorage;

  Future<DashboardSnapshot> loadSnapshot({required DateTime asOf}) async {
    final organizations = await _repository.listOrganizations();
    final treasurySources = await _repository.listTreasuryFundSources();
    final events = await _repository.listAuditEvents();
    final reimbursements = await _repository.listReimbursementClaims();
    final movements = await _repository.listFundMovements();
    final exportSnapshot = await ExportService(
      repository: _repository,
      attachmentStorage: attachmentStorage,
    ).loadSnapshot(asOf: asOf);

    final organization = organizations.isEmpty ? null : organizations.first;
    final treasuryBalance = _sumMoney(
      treasurySources.map((source) => source.balance),
    );
    final approvedBudget = _sumMoney(
      events.map((event) => event.approvedBudgetBalance),
    );
    final eventStatuses = events
        .map((event) => EventRules.calculateStatus(event: event, asOf: asOf))
        .toList(growable: false);
    final forLiquidationCount = eventStatuses
        .where(
          (status) =>
              status == AuditEventStatus.forLiquidation ||
              status == AuditEventStatus.due,
        )
        .length;
    final dueCount = eventStatuses
        .where((status) => status == AuditEventStatus.due)
        .length;
    final pendingClaims = reimbursements
        .where((claim) => claim.status == ReimbursementStatus.pending)
        .toList(growable: false);
    final pendingClaimTotal = _sumMoney(
      pendingClaims.map((claim) => claim.amount),
    );
    final sortedMovements = [...movements]
      ..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSnapshot(
      organizationName: organization?.name ?? 'Audivance Workspace',
      term: _termFor(organization),
      lastBackup: 'No backup yet',
      exportReadiness: exportSnapshot.readinessScore,
      metrics: [
        DashboardMetric(
          label: 'Treasury Balance',
          value: _formatMoney(treasuryBalance),
          detail: _pluralize(treasurySources.length, 'source fund'),
          icon: Icons.account_balance_wallet_outlined,
          tone: treasurySources.isEmpty
              ? DashboardSignalTone.warning
              : DashboardSignalTone.success,
        ),
        DashboardMetric(
          label: 'Approved Budget',
          value: _formatMoney(approvedBudget),
          detail: _pluralize(events.length, 'event'),
          icon: Icons.fact_check_outlined,
          tone: DashboardSignalTone.neutral,
        ),
        DashboardMetric(
          label: 'For Liquidation',
          value: _pluralize(forLiquidationCount, 'event'),
          detail: '$dueCount due now',
          icon: Icons.receipt_long_outlined,
          tone: forLiquidationCount == 0
              ? DashboardSignalTone.success
              : DashboardSignalTone.warning,
        ),
        DashboardMetric(
          label: 'Pending Claims',
          value: _formatMoney(pendingClaimTotal),
          detail: _pluralize(pendingClaims.length, 'reimbursement'),
          icon: Icons.payments_outlined,
          tone: pendingClaims.isEmpty
              ? DashboardSignalTone.success
              : DashboardSignalTone.danger,
        ),
      ],
      tasks: _tasksFor(issues: exportSnapshot.issues),
      movements: sortedMovements
          .take(3)
          .map(
            (movement) => FundMovementPreview(
              reference: movement.reference,
              description: movement.purpose,
              amount: _formatMoney(movement.amount),
              date: _formatDate(movement.date),
              isSystemGenerated: movement.isSystemGenerated,
            ),
          )
          .toList(growable: false),
    );
  }
}

Money _sumMoney(Iterable<Money> amounts) {
  return amounts.fold(Money.zero, (total, amount) => total + amount);
}

String _termFor(OrganizationProfile? organization) {
  if (organization == null) {
    return 'No organization profile';
  }
  return '${organization.semester}, SY ${organization.schoolYear}';
}

List<DashboardTask> _tasksFor({
  required List<ExportReadinessIssueView> issues,
}) {
  final tasks = issues
      .take(4)
      .map(_dashboardTaskForIssue)
      .toList(growable: true);
  tasks.add(
    const DashboardTask(
      title: 'Back up local workspace',
      detail: 'Create an encrypted backup before COA export.',
      status: 'Recommended',
      tone: DashboardSignalTone.danger,
    ),
  );

  return tasks;
}

DashboardTask _dashboardTaskForIssue(ExportReadinessIssueView issue) {
  if (issue.id == 'missing-treasury-sources') {
    return const DashboardTask(
      title: 'Add the first treasury source',
      detail: 'Treasury balances remain zero until fund sources are encoded.',
      status: 'Blocker',
      tone: DashboardSignalTone.danger,
    );
  }

  return DashboardTask(
    title: issue.message,
    detail: issue.targetRecordId == null
        ? 'Workspace-level export readiness issue.'
        : 'Record ${issue.targetRecordId} needs review.',
    status: issue.severityLabel,
    tone: issue.severity == ExportReadinessSeverity.blocker
        ? DashboardSignalTone.danger
        : DashboardSignalTone.warning,
  );
}

String _formatMoney(Money money) {
  final sign = money.centavos < 0 ? '-' : '';
  final absolute = money.centavos.abs();
  final pesos = absolute ~/ 100;
  final centavos = absolute % 100;
  final pesosText = _formatInteger(pesos);
  if (centavos == 0) {
    return '${sign}PHP $pesosText';
  }
  return '${sign}PHP $pesosText.${centavos.toString().padLeft(2, '0')}';
}

String _formatInteger(int value) {
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

String _pluralize(int count, String singular) {
  if (count == 1) {
    return '1 $singular';
  }
  return '$count ${singular}s';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
