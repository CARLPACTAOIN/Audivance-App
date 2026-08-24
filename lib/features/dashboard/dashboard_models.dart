import 'package:flutter/material.dart';

enum DashboardSignalTone { neutral, warning, success, danger }

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final DashboardSignalTone tone;
}

class DashboardTask {
  const DashboardTask({
    required this.title,
    required this.detail,
    required this.status,
    required this.tone,
  });

  final String title;
  final String detail;
  final String status;
  final DashboardSignalTone tone;
}

class FundMovementPreview {
  const FundMovementPreview({
    required this.reference,
    required this.description,
    required this.amount,
    required this.date,
    required this.isSystemGenerated,
  });

  final String reference;
  final String description;
  final String amount;
  final String date;
  final bool isSystemGenerated;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.organizationName,
    required this.term,
    required this.lastBackup,
    required this.exportReadiness,
    required this.metrics,
    required this.tasks,
    required this.movements,
  });

  final String organizationName;
  final String term;
  final String lastBackup;
  final int exportReadiness;
  final List<DashboardMetric> metrics;
  final List<DashboardTask> tasks;
  final List<FundMovementPreview> movements;
}

const demoDashboardSnapshot = DashboardSnapshot(
  organizationName: 'Junior Philippine Institute of Accountants',
  term: '1st Semester, SY 2026-2027',
  lastBackup: 'No backup yet',
  exportReadiness: 64,
  metrics: [
    DashboardMetric(
      label: 'Treasury Balance',
      value: 'PHP 128,450',
      detail: 'Across 5 source funds',
      icon: Icons.account_balance_wallet_outlined,
      tone: DashboardSignalTone.success,
    ),
    DashboardMetric(
      label: 'Approved Budget',
      value: 'PHP 86,000',
      detail: '4 active events',
      icon: Icons.fact_check_outlined,
      tone: DashboardSignalTone.neutral,
    ),
    DashboardMetric(
      label: 'For Liquidation',
      value: '3 events',
      detail: '1 due within 7 days',
      icon: Icons.receipt_long_outlined,
      tone: DashboardSignalTone.warning,
    ),
    DashboardMetric(
      label: 'Pending Claims',
      value: 'PHP 7,850',
      detail: '2 reimbursements',
      icon: Icons.payments_outlined,
      tone: DashboardSignalTone.danger,
    ),
  ],
  tasks: [
    DashboardTask(
      title: 'Attach resolution for General Assembly',
      detail: 'Required before this event is export-ready.',
      status: 'Missing attachment',
      tone: DashboardSignalTone.warning,
    ),
    DashboardTask(
      title: 'Review outreach reimbursement',
      detail: 'Projected remaining event fund is PHP 3,200.',
      status: 'Pending review',
      tone: DashboardSignalTone.neutral,
    ),
    DashboardTask(
      title: 'Back up local workspace',
      detail: 'Create an encrypted backup before COA export.',
      status: 'Recommended',
      tone: DashboardSignalTone.danger,
    ),
  ],
  movements: [
    FundMovementPreview(
      reference: 'FM-20260818-4F2A91C0',
      description: 'Budget allocation: Leadership Summit',
      amount: 'PHP 22,000',
      date: 'Aug 18, 2026',
      isSystemGenerated: true,
    ),
    FundMovementPreview(
      reference: 'FM-20260818-31D8C6B4',
      description: 'Fund release to Finance Committee head',
      amount: 'PHP 9,500',
      date: 'Aug 18, 2026',
      isSystemGenerated: false,
    ),
    FundMovementPreview(
      reference: 'FM-20260817-9B0D12EE',
      description: 'Donation fund source added with support file',
      amount: 'PHP 35,000',
      date: 'Aug 17, 2026',
      isSystemGenerated: false,
    ),
  ],
);
