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
                16,
                isWide ? 32 : 16,
                80,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _EventHeaderCard(event: data.event),
                  const SizedBox(height: 14),
                  _FinancialSummaryCard(
                    event: data.event,
                    budgetActual: data.budgetActual,
                  ),
                  const SizedBox(height: 14),
                  _EventActionsBar(
                    event: data.event,
                    liquidationEvent: data.liquidationEvent,
                    hasOfficers: data.officerOptions.isNotEmpty,
                    onAdjustBudget: onAdjustBudget,
                    onReviewBudget: onReviewBudget,
                    onSubmitLiquidation: onSubmitLiquidation,
                    onMarkLiquidated: onMarkLiquidated,
                  ),
                  const SizedBox(height: 14),
                  _LiquidationSection(
                    receipts: data.receipts,
                    officerCount: data.officerOptions.length,
                    onCreateOfficer: onCreateOfficer,
                  ),
                  const SizedBox(height: 14),
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
        padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 2),
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
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFF1E293B)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
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
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
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
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 12),
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
              const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: Key('eventLiquidationButton${event.id}'),
                  onPressed: canLiquidate ? onSubmitLiquidation : null,
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Liquidate / Add Receipt'),
                ),
                OutlinedButton.icon(
                  key: Key('eventBudgetReviewButton${event.id}'),
                  onPressed: onReviewBudget,
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Budget Review'),
                ),
                if (event.canAdjustBudget)
                  OutlinedButton.icon(
                    key: Key('eventAdjustBudgetButton${event.id}'),
                    onPressed: onAdjustBudget,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Adjust Budget'),
                  ),
                FilledButton.tonalIcon(
                  key: Key('eventMarkLiquidatedButton${event.id}'),
                  onPressed: event.status == AuditEventStatus.liquidated
                      ? null
                      : onMarkLiquidated,
                  icon: const Icon(Icons.verified_outlined, size: 18),
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
        padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.32),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: Color(0xFFF59E0B),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accountable Officer Required',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add an officer to unlock receipt submission for this event.',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      key: const Key('eventAddOfficerPromptButton'),
                      onPressed: onCreateOfficer,
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text('Add Officer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (receipts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        size: 36,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 8),
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
                  for (var i = 0; i < receipts.length; i++)
                    _ReceiptRow(
                      receipt: receipts[i],
                      showDivider: i < receipts.length - 1,
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
    return ExpandableListRow(
      leading: const Icon(
        Icons.receipt_long,
        color: Color(0xFF10B981),
        size: 18,
      ),
      title: Text(
        receipt.payeeOrMerchant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFFF8FAFC),
        ),
      ),
      subtitle: Text(
        'Ref #${receipt.evidenceNumber} · ${receipt.dateLabel} · ${receipt.accountableOfficerName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11.5,
        ),
      ),
      trailing: Text(
        receipt.totalLabel,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: Color(0xFF10B981),
        ),
      ),
      expandedContent: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          MetadataChip(
            icon: Icons.payments_outlined,
            label: receipt.fundingModeLabel,
          ),
          MetadataChip(
            icon: Icons.person_outline,
            label: 'Custodian: ${receipt.accountableOfficerName}',
          ),
          MetadataChip(
            icon: Icons.tag,
            label: 'Evidence #${receipt.evidenceNumber}',
          ),
        ],
      ),
      showDivider: showDivider,
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
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 12),
            if (claims.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 36,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 8),
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
                  for (var i = 0; i < claims.length; i++)
                    _ReimbursementClaimRow(
                      claim: claims[i],
                      showDivider: i < claims.length - 1,
                      onPay: () => onPayReimbursement(claims[i]),
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
    return ExpandableListRow(
      leading: Icon(
        isPending ? Icons.schedule : Icons.check_circle_outline,
        color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        size: 18,
      ),
      title: Text(
        claim.officerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFFF8FAFC),
        ),
      ),
      subtitle: Text(
        '${claim.statusLabel} · After: ${claim.projectedRemainingLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11.5,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            claim.amountLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFFF59E0B),
            ),
          ),
          if (claim.canPay) ...[
            const SizedBox(width: 8),
            FilledButton(
              key: Key('reimbursementPayButton${claim.id}'),
              onPressed: onPay,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Pay', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
      showDivider: showDivider,
    );
  }
}
