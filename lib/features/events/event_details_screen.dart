import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/attachments/attachment_picker.dart';
import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import '../liquidation/liquidation_service.dart';
import '../organization/organization_service.dart';
import '../treasury/treasury_formatters.dart';
import 'event_dialogs.dart';
import 'event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.service,
    required this.organizationService,
    required this.liquidationService,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.asOf,
  });

  final StableId eventId;
  final EventService service;
  final OrganizationService organizationService;
  final LiquidationService liquidationService;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final DateTime? asOf;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Future<_EventDetailsData> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  @override
  void didUpdateWidget(EventDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId ||
        oldWidget.service != widget.service ||
        oldWidget.organizationService != widget.organizationService ||
        oldWidget.liquidationService != widget.liquidationService ||
        oldWidget.asOf != widget.asOf) {
      _detailsFuture = _loadDetails();
    }
  }

  Future<_EventDetailsData> _loadDetails() async {
    final asOf = widget.asOf ?? DateTime.now();
    final eventSnapshot = await widget.service.loadSnapshot(asOf: asOf);
    final liquidationSnapshot = await widget.liquidationService.loadSnapshot(
      asOf: asOf,
    );

    EventCardView? event;
    for (final candidate in eventSnapshot.events) {
      if (candidate.id == widget.eventId) {
        event = candidate;
        break;
      }
    }

    if (event == null) {
      throw StateError('Event not found: ${widget.eventId}');
    }

    final budgetActual = await widget.service.loadBudgetActual(
      widget.eventId,
      asOf: asOf,
    );

    LiquidationEventView? liquidationEvent;
    for (final candidate in liquidationSnapshot.events) {
      if (candidate.id == widget.eventId) {
        liquidationEvent = candidate;
        break;
      }
    }

    final eventReceipts = liquidationSnapshot.receipts
        .where((r) => r.eventId == widget.eventId)
        .toList(growable: false);

    final eventClaims = liquidationSnapshot.reimbursementClaims
        .where((c) => c.eventId == widget.eventId)
        .toList(growable: false);
    final officerOptions = await widget.liquidationService
        .listOfficerOptionsForEvent(widget.eventId);

    return _EventDetailsData(
      event: event,
      budgetActual: budgetActual,
      liquidationEvent: liquidationEvent,
      receipts: eventReceipts,
      claims: eventClaims,
      sourceOptions: eventSnapshot.sourceOptions,
      officerOptions: officerOptions,
    );
  }

  void _refresh() {
    setState(() {
      _detailsFuture = _loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161C26),
        leading: IconButton(
          key: const Key('eventDetailsBackButton'),
          tooltip: 'Back to Events',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Financials'),
      ),
      body: FutureBuilder<_EventDetailsData>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppStateView.loading(
              title: 'Loading Event Financials',
              message: 'Reading budget, liquidation, and claims data.',
            );
          }
          if (snapshot.hasError) {
            return AppStateView.error(
              title: 'Event details could not be loaded',
              message: snapshot.error.toString(),
              onAction: _refresh,
            );
          }
          final data = snapshot.data!;
          return _EventDetailsContent(
            data: data,
            onAdjustBudget: () => _showAdjustBudget(data),
            onReviewBudget: () => _showBudgetReview(data),
            onSubmitLiquidation: () => _showSubmitLiquidation(data),
            onMarkLiquidated: () => _markLiquidated(data),
            onPayReimbursement: _showPayReimbursement,
            onCreateOfficer: _showCreateOfficer,
          );
        },
      ),
    );
  }

  Future<void> _showAdjustBudget(_EventDetailsData data) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => AdjustBudgetDialog(
        service: widget.service,
        event: data.event,
        sourceOptions: data.sourceOptions,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showBudgetReview(_EventDetailsData data) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => BudgetReviewDialog(
        service: widget.service,
        event: data.event,
        asOf: widget.asOf ?? DateTime.now(),
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showSubmitLiquidation(_EventDetailsData data) async {
    if (data.liquidationEvent == null) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => SubmitLiquidationDialog(
        service: widget.liquidationService,
        event: data.liquidationEvent!,
        officers: data.officerOptions,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showPayReimbursement(ReimbursementClaimView claim) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => PayReimbursementDialog(
        service: widget.liquidationService,
        claim: claim,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _markLiquidated(_EventDetailsData data) async {
    final result = await widget.liquidationService.markEventLiquidated(
      data.event.id,
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.summary)));
      return;
    }
    _refresh();
  }

  Future<void> _showCreateOfficer() async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) =>
          CreateOfficerDialog(service: widget.organizationService),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }
}

class _EventDetailsData {
  const _EventDetailsData({
    required this.event,
    required this.budgetActual,
    required this.liquidationEvent,
    required this.receipts,
    required this.claims,
    required this.sourceOptions,
    required this.officerOptions,
  });

  final EventCardView event;
  final BudgetActualSnapshot? budgetActual;
  final LiquidationEventView? liquidationEvent;
  final List<LiquidationReceiptView> receipts;
  final List<ReimbursementClaimView> claims;
  final List<TreasurySourceAllocationOption> sourceOptions;
  final List<OfficerOption> officerOptions;
}

class _EventDetailsContent extends StatelessWidget {
  const _EventDetailsContent({
    required this.data,
    required this.onAdjustBudget,
    required this.onReviewBudget,
    required this.onSubmitLiquidation,
    required this.onMarkLiquidated,
    required this.onPayReimbursement,
    required this.onCreateOfficer,
  });

  final _EventDetailsData data;
  final VoidCallback onAdjustBudget;
  final VoidCallback onReviewBudget;
  final VoidCallback onSubmitLiquidation;
  final VoidCallback onMarkLiquidated;
  final ValueChanged<ReimbursementClaimView> onPayReimbursement;
  final VoidCallback onCreateOfficer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                20,
                isWide ? 32 : 16,
                80,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _EventHeaderCard(event: data.event),
                  const SizedBox(height: 16),
                  _FinancialSummaryCard(
                    event: data.event,
                    budgetActual: data.budgetActual,
                  ),
                  const SizedBox(height: 16),
                  _EventActionsBar(
                    event: data.event,
                    liquidationEvent: data.liquidationEvent,
                    hasOfficers: data.officerOptions.isNotEmpty,
                    onAdjustBudget: onAdjustBudget,
                    onReviewBudget: onReviewBudget,
                    onSubmitLiquidation: onSubmitLiquidation,
                    onMarkLiquidated: onMarkLiquidated,
                  ),
                  const SizedBox(height: 20),
                  _LiquidationSection(
                    receipts: data.receipts,
                    officerCount: data.officerOptions.length,
                    onCreateOfficer: onCreateOfficer,
                  ),
                  const SizedBox(height: 20),
                  _ReimbursementsSection(
                    claims: data.claims,
                    onPayReimbursement: onPayReimbursement,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventHeaderCard extends StatelessWidget {
  const _EventHeaderCard({required this.event});

  final EventCardView event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tone = switch (event.status) {
      AuditEventStatus.ongoing => InlineStatusTone.info,
      AuditEventStatus.forLiquidation => InlineStatusTone.warning,
      AuditEventStatus.due => InlineStatusTone.error,
      AuditEventStatus.liquidated => InlineStatusTone.success,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.type} · ${event.semester} (${event.schoolYear})',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                StatusBadge(
                  label: event.statusLabel,
                  tone: tone,
                  icon: event.status == AuditEventStatus.liquidated
                      ? Icons.check_circle_outline
                      : Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetaItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date',
                  value: event.dateRangeLabel,
                ),
                _MetaItem(
                  icon: Icons.description_outlined,
                  label: 'Resolution',
                  value: event.resolutionNumber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: const Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.event,
    required this.budgetActual,
  });

  final EventCardView event;
  final BudgetActualSnapshot? budgetActual;

  @override
  Widget build(BuildContext context) {
    final actual = budgetActual?.actual ?? Money.zero;
    final remaining = event.approvedBudgetBalance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Text(
                  'Financial Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (budgetActual != null)
                  StatusBadge(
                    label: budgetActual!.healthLabel,
                    tone: switch (budgetActual!.health) {
                      BudgetHealth.healthy => InlineStatusTone.success,
                      BudgetHealth.watch => InlineStatusTone.warning,
                      BudgetHealth.overBudget ||
                      BudgetHealth.critical => InlineStatusTone.error,
                      BudgetHealth.noBudget => InlineStatusTone.info,
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CompactStatRow(
              items: [
                CompactStat(value: event.budgetLabel, label: 'Approved Budget'),
                CompactStat(
                  value: formatPhpMoney(actual),
                  label: 'Liquidated / Actual',
                ),
                CompactStat(
                  value: formatPhpMoney(remaining),
                  label: 'Remaining Balance',
                ),
                if (budgetActual != null)
                  CompactStat(
                    value: budgetActual!.utilizationLabel,
                    label: 'Utilization',
                  ),
              ],
            ),
            if (budgetActual != null && budgetActual!.isOverBudget) ...[
              const SizedBox(height: 12),
              const InlineStatusPanel(
                tone: InlineStatusTone.error,
                message:
                    'Spending has exceeded the approved budget allocation.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventActionsBar extends StatelessWidget {
  const _EventActionsBar({
    required this.event,
    required this.liquidationEvent,
    required this.hasOfficers,
    required this.onAdjustBudget,
    required this.onReviewBudget,
    required this.onSubmitLiquidation,
    required this.onMarkLiquidated,
  });

  final EventCardView event;
  final LiquidationEventView? liquidationEvent;
  final bool hasOfficers;
  final VoidCallback onAdjustBudget;
  final VoidCallback onReviewBudget;
  final VoidCallback onSubmitLiquidation;
  final VoidCallback onMarkLiquidated;

  @override
  Widget build(BuildContext context) {
    final canLiquidate =
        liquidationEvent != null &&
        liquidationEvent!.canSubmitLiquidation &&
        hasOfficers;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: Key('eventLiquidationButton${event.id}'),
                  onPressed: canLiquidate ? onSubmitLiquidation : null,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Liquidate / Add Receipt'),
                ),
                OutlinedButton.icon(
                  key: Key('eventBudgetReviewButton${event.id}'),
                  onPressed: onReviewBudget,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Budget Review'),
                ),
                if (event.canAdjustBudget)
                  OutlinedButton.icon(
                    key: Key('eventAdjustBudgetButton${event.id}'),
                    onPressed: onAdjustBudget,
                    icon: const Icon(Icons.tune),
                    label: const Text('Adjust Budget'),
                  ),
                FilledButton.tonalIcon(
                  key: Key('eventMarkLiquidatedButton${event.id}'),
                  onPressed: event.status == AuditEventStatus.liquidated
                      ? null
                      : onMarkLiquidated,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Mark Liquidated'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidationSection extends StatelessWidget {
  const _LiquidationSection({
    required this.receipts,
    required this.officerCount,
    required this.onCreateOfficer,
  });

  final List<LiquidationReceiptView> receipts;
  final int officerCount;
  final VoidCallback onCreateOfficer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Text(
                  'Liquidation Receipts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                StatusBadge(
                  label:
                      '${receipts.length} receipt${receipts.length == 1 ? '' : 's'}',
                  tone: InlineStatusTone.info,
                ),
              ],
            ),
            if (officerCount == 0) ...[
              const SizedBox(height: 12),
              const InlineStatusPanel(
                tone: InlineStatusTone.warning,
                message: 'No accountable officers registered. Add an officer before submitting receipts.',
              ),
            ],
            const SizedBox(height: 16),
            if (receipts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        size: 40,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No receipts submitted yet for this event.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (final receipt in receipts)
                    _ReceiptRow(
                      receipt: receipt,
                      showDivider: receipt != receipts.last,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt, required this.showDivider});

  final LiquidationReceiptView receipt;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.receipt_long,
                color: Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.payeeOrMerchant,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        MetadataChip(
                          icon: Icons.tag,
                          label: 'Ref #${receipt.evidenceNumber}',
                        ),
                        MetadataChip(
                          icon: Icons.calendar_today_outlined,
                          label: receipt.dateLabel,
                        ),
                        MetadataChip(
                          icon: Icons.payments_outlined,
                          label: receipt.fundingModeLabel,
                        ),
                        MetadataChip(
                          icon: Icons.person_outline,
                          label: receipt.accountableOfficerName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                receipt.totalLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ReimbursementsSection extends StatelessWidget {
  const _ReimbursementsSection({
    required this.claims,
    required this.onPayReimbursement,
  });

  final List<ReimbursementClaimView> claims;
  final ValueChanged<ReimbursementClaimView> onPayReimbursement;

  @override
  Widget build(BuildContext context) {
    final pendingTotal = claims
        .where((c) => c.status == ReimbursementStatus.pending)
        .fold(Money.zero, (total, c) => total + c.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reimbursements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (pendingTotal.isPositive)
                  StatusBadge(
                    label: 'Pending: ${formatPhpMoney(pendingTotal)}',
                    tone: InlineStatusTone.warning,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (claims.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No reimbursement requests for this event.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (final claim in claims)
                    _ReimbursementClaimRow(
                      claim: claim,
                      showDivider: claim != claims.last,
                      onPay: () => onPayReimbursement(claim),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ReimbursementClaimRow extends StatelessWidget {
  const _ReimbursementClaimRow({
    required this.claim,
    required this.showDivider,
    required this.onPay,
  });

  final ReimbursementClaimView claim;
  final bool showDivider;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final isPending = claim.status == ReimbursementStatus.pending;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isPending ? Icons.schedule : Icons.check_circle_outline,
                color: isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.officerName,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        StatusBadge(
                          label: claim.statusLabel,
                          tone: isPending
                              ? InlineStatusTone.warning
                              : InlineStatusTone.success,
                        ),
                        MetadataChip(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'After: ${claim.projectedRemainingLabel}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    claim.amountLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  if (claim.canPay) ...[
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      key: Key('reimbursementPayButton${claim.id}'),
                      onPressed: onPay,
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Pay'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
