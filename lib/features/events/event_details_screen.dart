import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/attachments/attachment_picker.dart';
import '../../core/attachments/attachment_selector.dart';
import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import '../liquidation/liquidation_service.dart';
import '../organization/organization_service.dart';
import '../organization/widgets/officer_editor_dialog.dart';
import '../treasury/treasury_formatters.dart';
import '../treasury/treasury_service.dart';
import 'event_dialogs.dart';
import 'event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.eventId,
    required this.service,
    required this.liquidationService,
    required this.attachmentPicker,
    required this.attachmentStorage,
    required this.organizationService,
    this.treasuryService,
    this.asOf,
  });

  final StableId eventId;
  final EventService service;
  final LiquidationService liquidationService;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final OrganizationService organizationService;
  final TreasuryService? treasuryService;
  final DateTime? asOf;

  TreasuryService get effectiveTreasuryService =>
      treasuryService ??
      TreasuryService(
        repository: service.repository,
        idGenerator: service.idGenerator,
      );

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
        oldWidget.liquidationService != widget.liquidationService ||
        oldWidget.organizationService != widget.organizationService ||
        oldWidget.asOf != widget.asOf ||
        oldWidget.attachmentStorage != widget.attachmentStorage) {
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
          final Widget child;
          if (snapshot.connectionState != ConnectionState.done) {
            child = const AppStateView.loading(
              key: ValueKey('loading'),
              title: 'Loading Event Financials',
              message: 'Reading budget, liquidation, and claims data.',
            );
          } else if (snapshot.hasError) {
            child = AppStateView.error(
              key: const ValueKey('error'),
              title: 'Event details could not be loaded',
              message: snapshot.error.toString(),
              onAction: _refresh,
            );
          } else {
            final data = snapshot.data!;
            child = _EventDetailsContent(
              key: const ValueKey('content'),
              data: data,
              attachmentStorage: widget.attachmentStorage,
              onEditEvent: () => _showEditEvent(data),
              onAdjustBudget: () => _showAdjustBudget(data),
              onReviewBudget: () => _showBudgetReview(data),
              onSubmitLiquidation: () => _showSubmitLiquidation(data),
              onAddFundToOfficer: () => _showAddFundToOfficer(data),
              onMarkLiquidated: () => _markLiquidated(data),
              onPayReimbursement: _showPayReimbursement,
              onCreateOfficer: _showOfficerEditor,
              onEditReceipt: (receipt) => _showEditReceipt(data, receipt),
              onVoidReceipt: _showVoidReceipt,
              onViewReceiptHistory: _showReceiptHistory,
            );
          }
          return AppCrossfade(child: child);
        },
      ),
    );
  }

  Future<void> _showEditEvent(_EventDetailsData data) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => EditEventDialog(
        service: widget.service,
        event: data.event,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showAdjustBudget(_EventDetailsData data) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => AdjustBudgetDialog(
        service: widget.service,
        event: data.event,
        sourceOptions: data.sourceOptions,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showAddFundToOfficer(_EventDetailsData data) async {
    final result = await showDialog<StableId>(
      context: context,
      builder: (context) => AddFundToOfficerDialog(
        treasuryService: widget.effectiveTreasuryService,
        eventId: data.event.id,
        eventName: data.event.name,
        approvedBudgetBalance: data.event.approvedBudgetBalance,
        approvedBudgetBalanceLabel: data.event.approvedBudgetBalanceLabel,
        officers: data.officerOptions,
      ),
    );
    if (!mounted || result == null) {
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
        organizationService: widget.organizationService,
        treasuryService: widget.effectiveTreasuryService,
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

  Future<void> _showOfficerEditor() async {
    final result = await showDialog<OfficerEditorResult>(
      context: context,
      builder: (context) =>
          OfficerEditorDialog(service: widget.organizationService),
    );
    if (!mounted || result == null) {
      return;
    }
    _refresh();
  }

  Future<void> _showEditReceipt(
    _EventDetailsData data,
    LiquidationReceiptView receipt,
  ) async {
    if (data.liquidationEvent == null) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => EditLiquidationReceiptDialog(
        service: widget.liquidationService,
        event: data.liquidationEvent!,
        receipt: receipt,
        officers: data.officerOptions,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
        organizationService: widget.organizationService,
        treasuryService: widget.effectiveTreasuryService,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Receipt Ref #${receipt.evidenceNumber} updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    _refresh();
  }

  Future<void> _showVoidReceipt(LiquidationReceiptView receipt) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => VoidReceiptDialog(
        service: widget.liquidationService,
        receipt: receipt,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Receipt Ref #${receipt.evidenceNumber} voided.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    _refresh();
  }

  Future<void> _showReceiptHistory(LiquidationReceiptView receipt) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ReceiptHistoryDialog(
        service: widget.liquidationService,
        receipt: receipt,
      ),
    );
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
    super.key,
    required this.data,
    required this.attachmentStorage,
    required this.onEditEvent,
    required this.onAdjustBudget,
    required this.onReviewBudget,
    required this.onSubmitLiquidation,
    required this.onAddFundToOfficer,
    required this.onMarkLiquidated,
    required this.onPayReimbursement,
    required this.onCreateOfficer,
    required this.onEditReceipt,
    required this.onVoidReceipt,
    required this.onViewReceiptHistory,
  });

  final _EventDetailsData data;
  final AttachmentStorageService attachmentStorage;
  final VoidCallback onEditEvent;
  final VoidCallback onAdjustBudget;
  final VoidCallback onReviewBudget;
  final VoidCallback onSubmitLiquidation;
  final VoidCallback onAddFundToOfficer;
  final VoidCallback onMarkLiquidated;
  final ValueChanged<ReimbursementClaimView> onPayReimbursement;
  final VoidCallback onCreateOfficer;
  final ValueChanged<LiquidationReceiptView> onEditReceipt;
  final ValueChanged<LiquidationReceiptView> onVoidReceipt;
  final ValueChanged<LiquidationReceiptView> onViewReceiptHistory;

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
                  AppSlideFadeIn(
                    child: _EventHeaderCard(
                      event: data.event,
                      onEdit: onEditEvent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep,
                    child: _FinancialSummaryCard(
                      event: data.event,
                      budgetActual: data.budgetActual,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep * 2,
                    child: _EventActionsBar(
                      event: data.event,
                      liquidationEvent: data.liquidationEvent,
                      onEditDetails: onEditEvent,
                      onAdjustBudget: onAdjustBudget,
                      onReviewBudget: onReviewBudget,
                      onSubmitLiquidation: onSubmitLiquidation,
                      onAddFundToOfficer: onAddFundToOfficer,
                      onMarkLiquidated: onMarkLiquidated,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep * 3,
                    child: _LiquidationSection(
                      receipts: data.receipts,
                      attachmentStorage: attachmentStorage,
                      officerCount: data.officerOptions.length,
                      onCreateOfficer: onCreateOfficer,
                      onEditReceipt: onEditReceipt,
                      onVoidReceipt: onVoidReceipt,
                      onViewReceiptHistory: onViewReceiptHistory,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep * 4,
                    child: _ReimbursementsSection(
                      claims: data.claims,
                      onPayReimbursement: onPayReimbursement,
                    ),
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
  const _EventHeaderCard({required this.event, this.onEdit});

  final EventCardView event;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tone = switch (event.status) {
      AuditEventStatus.ongoing => InlineStatusTone.info,
      AuditEventStatus.forLiquidation => InlineStatusTone.warning,
      AuditEventStatus.due => InlineStatusTone.error,
      AuditEventStatus.liquidated => InlineStatusTone.success,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.type} · ${event.semester} (${event.schoolYear})',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    label: event.statusLabel,
                    tone: tone,
                    icon: event.status == AuditEventStatus.liquidated
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      key: Key('eventEditButton${event.id}'),
                      tooltip: event.canEdit
                          ? 'Edit Event Details'
                          : 'Liquidated events cannot be edited',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: event.canEdit ? onEdit : null,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
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
              if (event.permitApprovalDate != null)
                _MetaItem(
                  icon: Icons.verified_outlined,
                  label: 'Permit Date',
                  value: formatDate(event.permitApprovalDate!),
                ),
            ],
          ),
        ],
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
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Financial Summary',
            trailing: budgetActual != null
                ? StatusBadge(
                    label: budgetActual!.healthLabel,
                    tone: switch (budgetActual!.health) {
                      BudgetHealth.healthy => InlineStatusTone.success,
                      BudgetHealth.watch => InlineStatusTone.warning,
                      BudgetHealth.overBudget ||
                      BudgetHealth.critical => InlineStatusTone.error,
                      BudgetHealth.noBudget => InlineStatusTone.info,
                    },
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
            const InlineStatusPanel(
              tone: InlineStatusTone.error,
              message: 'Spending has exceeded the approved budget allocation.',
            ),
          ],
        ],
      ),
    );
  }
}

class _EventActionsBar extends StatelessWidget {
  const _EventActionsBar({
    required this.event,
    required this.liquidationEvent,
    required this.onEditDetails,
    required this.onAdjustBudget,
    required this.onReviewBudget,
    required this.onSubmitLiquidation,
    required this.onAddFundToOfficer,
    required this.onMarkLiquidated,
  });

  final EventCardView event;
  final LiquidationEventView? liquidationEvent;
  final VoidCallback onEditDetails;
  final VoidCallback onAdjustBudget;
  final VoidCallback onReviewBudget;
  final VoidCallback onSubmitLiquidation;
  final VoidCallback onAddFundToOfficer;
  final VoidCallback onMarkLiquidated;

  @override
  Widget build(BuildContext context) {
    final canLiquidate =
        liquidationEvent != null && liquidationEvent!.canSubmitLiquidation;
    final isLiquidated = event.status == AuditEventStatus.liquidated;
    final canAddFund = !isLiquidated && event.approvedBudgetBalance.isPositive;

    final liquidationBtn = SizedBox(
      height: 44,
      child: FilledButton.icon(
        key: Key('eventLiquidationButton${event.id}'),
        onPressed: canLiquidate ? onSubmitLiquidation : null,
        icon: const Icon(Icons.add_task, size: 18),
        label: const Text('Liquidate / Add Receipt'),
      ),
    );

    final editDetailsBtn = SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        key: Key('eventEditDetailsButton${event.id}'),
        onPressed: event.canEdit ? onEditDetails : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceSubtle.withValues(alpha: 0.5),
        ),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit Details'),
      ),
    );

    final addFundToOfficerBtn = SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        key: Key('eventAddFundToOfficerButton${event.id}'),
        onPressed: canAddFund ? onAddFundToOfficer : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceSubtle.withValues(alpha: 0.5),
        ),
        icon: const Icon(Icons.payments_outlined, size: 18),
        label: const Text('Add Fund to Officer'),
      ),
    );

    final budgetReviewBtn = SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        key: Key('eventBudgetReviewButton${event.id}'),
        onPressed: onReviewBudget,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceSubtle.withValues(alpha: 0.5),
        ),
        icon: const Icon(Icons.analytics_outlined, size: 18),
        label: const Text('Budget Review'),
      ),
    );

    final adjustBudgetBtn = event.canAdjustBudget
        ? SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              key: Key('eventAdjustBudgetButton${event.id}'),
              onPressed: onAdjustBudget,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceSubtle.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Adjust Budget'),
            ),
          )
        : null;

    final markLiquidatedBtn = SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        key: Key('eventMarkLiquidatedButton${event.id}'),
        onPressed: isLiquidated ? null : onMarkLiquidated,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceSubtle.withValues(alpha: 0.5),
        ),
        icon: Icon(
          isLiquidated ? Icons.check_circle_outline : Icons.verified_outlined,
          size: 18,
        ),
        label: const Text('Mark Liquidated'),
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.bolt_rounded,
            title: 'Actions',
            trailing: StatusBadge(
              label: isLiquidated
                  ? 'Liquidated'
                  : canLiquidate
                  ? 'Ready'
                  : 'Pending',
              tone: isLiquidated
                  ? InlineStatusTone.success
                  : canLiquidate
                  ? InlineStatusTone.info
                  : InlineStatusTone.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              if (isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    liquidationBtn,
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: editDetailsBtn),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: addFundToOfficerBtn),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: budgetReviewBtn),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (adjustBudgetBtn != null) ...[
                          Expanded(child: adjustBudgetBtn),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(child: markLiquidatedBtn),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  liquidationBtn,
                  const SizedBox(height: AppSpacing.sm),
                  editDetailsBtn,
                  const SizedBox(height: AppSpacing.sm),
                  addFundToOfficerBtn,
                  const SizedBox(height: AppSpacing.sm),
                  budgetReviewBtn,
                  if (adjustBudgetBtn != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    adjustBudgetBtn,
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  markLiquidatedBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiquidationSection extends StatefulWidget {
  const _LiquidationSection({
    required this.receipts,
    required this.attachmentStorage,
    required this.officerCount,
    required this.onCreateOfficer,
    required this.onEditReceipt,
    required this.onVoidReceipt,
    required this.onViewReceiptHistory,
  });

  final List<LiquidationReceiptView> receipts;
  final AttachmentStorageService attachmentStorage;
  final int officerCount;
  final VoidCallback onCreateOfficer;
  final ValueChanged<LiquidationReceiptView> onEditReceipt;
  final ValueChanged<LiquidationReceiptView> onVoidReceipt;
  final ValueChanged<LiquidationReceiptView> onViewReceiptHistory;

  @override
  State<_LiquidationSection> createState() => _LiquidationSectionState();
}

class _LiquidationSectionState extends State<_LiquidationSection> {
  int _currentPage = 0;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.receipts.length;
    final totalPages = (totalItems / _pageSize).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    final pagedReceipts = widget.receipts
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList(growable: false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Liquidation Receipts',
            trailing: StatusBadge(
              label:
                  '${widget.receipts.length} receipt${widget.receipts.length == 1 ? '' : 's'}',
              tone: InlineStatusTone.info,
            ),
          ),
          if (widget.officerCount == 0) ...[
            const SizedBox(height: AppSpacing.md),
            InlineStatusPanel(
              tone: InlineStatusTone.warning,
              title: 'Accountable Officer Required',
              message:
                  'Add an officer to unlock receipt submission for this event.',
              action: FilledButton.icon(
                key: const Key('eventAddOfficerPromptButton'),
                onPressed: widget.onCreateOfficer,
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Add Officer'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (widget.receipts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_outlined,
                      size: 36,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No receipts submitted yet for this event.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Column(
              children: [
                for (var i = 0; i < pagedReceipts.length; i++)
                  _ReceiptRow(
                    receipt: pagedReceipts[i],
                    attachmentStorage: widget.attachmentStorage,
                    showDivider: i < pagedReceipts.length - 1,
                    onEdit: () => widget.onEditReceipt(pagedReceipts[i]),
                    onVoid: () => widget.onVoidReceipt(pagedReceipts[i]),
                    onHistory: () => widget.onViewReceiptHistory(pagedReceipts[i]),
                  ),
              ],
            ),
            if (totalItems > _pageSize || totalPages > 1) ...[
              const SizedBox(height: AppSpacing.md),
              AppPaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                totalItems: totalItems,
                pageSize: _pageSize,
                itemLabel: 'receipts',
                prevKey: const Key('liquidationReceiptsPrevButton'),
                nextKey: const Key('liquidationReceiptsNextButton'),
                pageSizeOptions: const [10, 15],
                onPageSizeChanged: (newSize) {
                  setState(() {
                    _pageSize = newSize;
                    _currentPage = 0;
                  });
                },
                onPageChanged: (newPage) {
                  setState(() {
                    _currentPage = newPage;
                  });
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.receipt,
    required this.attachmentStorage,
    required this.showDivider,
    required this.onEdit,
    required this.onVoid,
    required this.onHistory,
  });

  final LiquidationReceiptView receipt;
  final AttachmentStorageService attachmentStorage;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onVoid;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    final attachment = receipt.attachment;
    if (attachment != null && attachment.isImage) {
      leadingWidget = AttachmentThumbnail(
        key: Key('receiptThumbnail_${receipt.id}'),
        attachment: attachment,
        storage: attachmentStorage,
        size: 40,
        inkWellKey: Key('receiptThumbnailTap_${receipt.id}'),
        tooltipMessage:
            'Tap to inspect receipt photo (Ref #${receipt.evidenceNumber})',
        onTap: () => showAttachmentImagePreview(
          context,
          attachment: attachment,
          storage: attachmentStorage,
        ),
      );
    } else if (attachment != null) {
      leadingWidget = Container(
        key: Key('receiptDocumentIcon_${receipt.id}'),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: AppRadius.borderSm,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: Icon(
            Icons.description_outlined,
            color: receipt.isVoided ? AppColors.textMuted : const Color(0xFF10B981),
            size: 20,
          ),
        ),
      );
    } else {
      leadingWidget = Icon(
        receipt.isVoided ? Icons.block : Icons.receipt_long,
        color: receipt.isVoided ? AppColors.textMuted : const Color(0xFF10B981),
        size: 18,
      );
    }

    return ExpandableListRow(
      leading: leadingWidget,
      title: Text(
        receipt.payeeOrMerchant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: receipt.isVoided ? AppColors.textMuted : const Color(0xFFF8FAFC),
          decoration: receipt.isVoided ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        'Ref #${receipt.evidenceNumber} · ${receipt.dateLabel} · ${receipt.accountableOfficerName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (receipt.isVoided) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 10, color: AppColors.error),
                  SizedBox(width: 3),
                  Text(
                    'VOIDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            receipt.totalLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: receipt.isVoided ? AppColors.textMuted : const Color(0xFF10B981),
              decoration: receipt.isVoided ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            key: Key('receiptOverflowMenu_${receipt.id}'),
            icon: const Icon(
              Icons.more_vert,
              size: 20,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Receipt options',
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'void') onVoid();
              if (action == 'history') onHistory();
            },
            itemBuilder: (context) => [
              if (!receipt.isVoided) ...[
                const PopupMenuItem(
                  key: Key('receiptMenuEditItem'),
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.brandLight),
                      SizedBox(width: 10),
                      Text('Edit Receipt'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  key: Key('receiptMenuVoidItem'),
                  value: 'void',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Void Receipt', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              const PopupMenuItem(
                key: Key('receiptMenuHistoryItem'),
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Audit History'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt.isVoided) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.block, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Voided: ${receipt.voidReason ?? 'No reason provided'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Wrap(
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
              if (receipt.remarks != null && receipt.remarks!.isNotEmpty)
                MetadataChip(
                  icon: Icons.notes_outlined,
                  label: 'Remarks: ${receipt.remarks}',
                ),
              if (attachment != null)
                MetadataChip(
                  key: Key('receiptAttachmentChip_${receipt.id}'),
                  icon: attachment.isImage
                      ? Icons.photo_outlined
                      : Icons.attach_file,
                  label: attachment.isImage
                      ? 'Receipt: ${attachment.fileName} (Inspect)'
                      : 'Attachment: ${attachment.fileName}',
                  tooltip: attachment.isImage
                      ? 'Tap to inspect full receipt photo'
                      : attachment.fileName,
                  onTap: attachment.isImage
                      ? () => showAttachmentImagePreview(
                          context,
                          attachment: attachment,
                          storage: attachmentStorage,
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!receipt.isVoided) ...[
                OutlinedButton.icon(
                  key: Key('editReceiptButton_${receipt.id}'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Receipt'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: Key('voidReceiptButton_${receipt.id}'),
                  onPressed: onVoid,
                  icon: const Icon(Icons.block, size: 16, color: AppColors.error),
                  label: const Text(
                    'Void Receipt',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
              OutlinedButton.icon(
                key: Key('receiptHistoryButton_${receipt.id}'),
                onPressed: onHistory,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Audit History'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            icon: Icons.payments_outlined,
            title: 'Reimbursements',
            trailing: pendingTotal.isPositive
                ? StatusBadge(
                    label: 'Pending: ${formatPhpMoney(pendingTotal)}',
                    tone: InlineStatusTone.warning,
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          if (claims.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 36,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No reimbursement requests for this event.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
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
    final isSuperseded = claim.status == ReimbursementStatus.superseded;
    return ExpandableListRow(
      leading: Icon(
        isPending
            ? Icons.schedule
            : (isSuperseded
                ? Icons.cancel_outlined
                : Icons.check_circle_outline),
        color: isPending
            ? AppColors.warning
            : (isSuperseded ? AppColors.textMuted : AppColors.success),
        size: 18,
      ),
      title: Text(
        claim.officerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isSuperseded ? AppColors.textMuted : AppColors.textPrimary,
          decoration: isSuperseded ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${claim.statusLabel} · After: ${claim.projectedRemainingLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            claim.amountLabel,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isSuperseded ? AppColors.textMuted : AppColors.warning,
              decoration: isSuperseded ? TextDecoration.lineThrough : null,
            ),
          ),
          if (claim.canPay) ...[
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              key: Key('reimbursementPayButton${claim.id}'),
              onPressed: onPay,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
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
