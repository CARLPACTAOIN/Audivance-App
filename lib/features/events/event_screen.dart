import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/attachments/attachment_picker.dart';
import '../../core/attachments/attachment_selector.dart';
import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import '../treasury/treasury_formatters.dart';
import '../liquidation/liquidation_service.dart';
import 'event_service.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({
    super.key,
    required this.service,
    required this.liquidationService,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.asOf,
  });

  final EventService service;
  final LiquidationService liquidationService;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final DateTime? asOf;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<_EventPageData> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadPageData();
  }

  @override
  void didUpdateWidget(EventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.liquidationService != widget.liquidationService ||
        oldWidget.asOf != widget.asOf) {
      _snapshotFuture = _loadPageData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_EventPageData>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppStateView.loading(
            title: 'Loading Events',
            message: 'Reading events, liquidation records, and claims.',
          );
        }
        if (snapshot.hasError) {
          return AppStateView.error(
            title: 'Events data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _refresh,
          );
        }
        return _EventContent(
          snapshot:
              snapshot.data?.eventSnapshot ??
              const EventWorkspaceSnapshot(events: [], sourceOptions: []),
          liquidationSnapshot:
              snapshot.data?.liquidationSnapshot ??
              const LiquidationWorkspaceSnapshot(
                events: [],
                receipts: [],
                reimbursementClaims: [],
                officerOptions: [],
              ),
          onCreateEvent: _showCreateEventDialog,
          onCreateOfficer: _showCreateOfficerDialog,
          onSubmitLiquidation: _showSubmitLiquidationDialog,
          onPayReimbursement: _showPayReimbursementDialog,
          onMarkLiquidated: _markEventLiquidated,
          onAdjustBudget: _showAdjustBudgetDialog,
          onReviewBudget: _showBudgetReviewDialog,
        );
      },
    );
  }

  Future<_EventPageData> _loadPageData() async {
    final asOf = widget.asOf ?? DateTime.now();
    final eventSnapshot = await widget.service.loadSnapshot(asOf: asOf);
    final liquidationSnapshot = await widget.liquidationService.loadSnapshot(
      asOf: asOf,
    );
    return _EventPageData(
      eventSnapshot: eventSnapshot,
      liquidationSnapshot: liquidationSnapshot,
    );
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = _loadPageData();
    });
  }

  Future<void> _showCreateEventDialog() async {
    final snapshot = await _snapshotFuture;
    if (!mounted) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _CreateEventDialog(
        service: widget.service,
        sourceOptions: snapshot.eventSnapshot.sourceOptions,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showCreateOfficerDialog() async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) =>
          _CreateOfficerDialog(service: widget.liquidationService),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showAdjustBudgetDialog(EventCardView event) async {
    final snapshot = await _snapshotFuture;
    if (!mounted) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _AdjustBudgetDialog(
        service: widget.service,
        event: event,
        sourceOptions: snapshot.eventSnapshot.sourceOptions,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showBudgetReviewDialog(EventCardView event) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _BudgetReviewDialog(
        service: widget.service,
        event: event,
        asOf: widget.asOf ?? DateTime.now(),
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showSubmitLiquidationDialog(LiquidationEventView event) async {
    final snapshot = await _snapshotFuture;
    if (!mounted) {
      return;
    }
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _SubmitLiquidationDialog(
        service: widget.liquidationService,
        event: event,
        officers: snapshot.liquidationSnapshot.officerOptions,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _showPayReimbursementDialog(ReimbursementClaimView claim) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => _PayReimbursementDialog(
        service: widget.liquidationService,
        claim: claim,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  Future<void> _markEventLiquidated(LiquidationEventView event) async {
    final result = await widget.liquidationService.markEventLiquidated(
      event.id,
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
}

class _EventContent extends StatelessWidget {
  const _EventContent({
    required this.snapshot,
    required this.liquidationSnapshot,
    required this.onCreateEvent,
    required this.onCreateOfficer,
    required this.onSubmitLiquidation,
    required this.onPayReimbursement,
    required this.onMarkLiquidated,
    required this.onAdjustBudget,
    required this.onReviewBudget,
  });

  final EventWorkspaceSnapshot snapshot;
  final LiquidationWorkspaceSnapshot liquidationSnapshot;
  final VoidCallback onCreateEvent;
  final VoidCallback onCreateOfficer;
  final ValueChanged<LiquidationEventView> onSubmitLiquidation;
  final ValueChanged<ReimbursementClaimView> onPayReimbursement;
  final ValueChanged<LiquidationEventView> onMarkLiquidated;
  final ValueChanged<EventCardView> onAdjustBudget;
  final ValueChanged<EventCardView> onReviewBudget;

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
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _EventHeader(
                    snapshot: snapshot,
                    onCreateEvent: onCreateEvent,
                  ),
                  const SizedBox(height: 20),
                  _EventSummary(snapshot: snapshot),
                  const SizedBox(height: 20),
                  _EventList(
                    events: snapshot.events,
                    onAdjustBudget: onAdjustBudget,
                    onReviewBudget: onReviewBudget,
                  ),
                  const SizedBox(height: 20),
                  _LiquidationQueue(
                    snapshot: liquidationSnapshot,
                    onCreateOfficer: onCreateOfficer,
                    onSubmitLiquidation: onSubmitLiquidation,
                    onMarkLiquidated: onMarkLiquidated,
                  ),
                  const SizedBox(height: 20),
                  _ReimbursementPanel(
                    claims: liquidationSnapshot.reimbursementClaims,
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

class _EventPageData {
  const _EventPageData({
    required this.eventSnapshot,
    required this.liquidationSnapshot,
  });

  final EventWorkspaceSnapshot eventSnapshot;
  final LiquidationWorkspaceSnapshot liquidationSnapshot;
}

class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.snapshot, required this.onCreateEvent});

  final EventWorkspaceSnapshot snapshot;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Events', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Create approved activities, attach resolution metadata, and allocate budget from Treasury sources.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          key: const Key('eventCreateButton'),
          onPressed: snapshot.sourceOptions.isEmpty ? null : onCreateEvent,
          icon: const Icon(Icons.add),
          label: const Text('Create Event'),
        ),
      ],
    );
  }
}

class _EventSummary extends StatelessWidget {
  const _EventSummary({required this.snapshot});

  final EventWorkspaceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final totalBudget = snapshot.events.fold(
      Money.zero,
      (total, event) => total + event.budget,
    );
    final openEvents = snapshot.events.where((event) {
      return event.statusLabel != 'Liquidated';
    }).length;
    final crossAxisCount = MediaQuery.sizeOf(context).width >= 700 ? 3 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 148,
      ),
      itemBuilder: (context, index) {
        return switch (index) {
          0 => _SummaryCard(
            icon: Icons.event_note_outlined,
            label: 'Events',
            value: snapshot.events.length.toString(),
            detail: '$openEvents open records',
          ),
          1 => _SummaryCard(
            icon: Icons.fact_check_outlined,
            label: 'Approved Budget',
            value: formatPhpMoney(totalBudget),
            detail: 'Across event records',
          ),
          _ => _SummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Available Sources',
            value: snapshot.sourceOptions.length.toString(),
            detail: 'Treasury funds for allocation',
          ),
        };
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.onAdjustBudget,
    required this.onReviewBudget,
  });

  final List<EventCardView> events;
  final ValueChanged<EventCardView> onAdjustBudget;
  final ValueChanged<EventCardView> onReviewBudget;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Event Records',
      child: events.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.event_available_outlined,
              text: 'Fund Treasury first, then create the first event with split funding.',
            )
          : Column(
              children: [
                for (final event in events)
                  _EventRow(
                    event: event,
                    showDivider: event != events.last,
                    onAdjustBudget: () => onAdjustBudget(event),
                    onReviewBudget: () => onReviewBudget(event),
                  ),
              ],
            ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.showDivider,
    required this.onAdjustBudget,
    required this.onReviewBudget,
  });

  final EventCardView event;
  final bool showDivider;
  final VoidCallback onAdjustBudget;
  final VoidCallback onReviewBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_note, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${event.type} - ${event.dateRangeLabel}'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(label: event.statusLabel),
                        _MetaChip(label: event.resolutionNumber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    key: Key('eventBudgetReviewButton${event.id}'),
                    onPressed: onReviewBudget,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Budget Review'),
                  ),
                  const SizedBox(height: 8),
                  if (event.canAdjustBudget) ...[
                    OutlinedButton.icon(
                      key: Key('eventAdjustBudgetButton${event.id}'),
                      onPressed: onAdjustBudget,
                      icon: const Icon(Icons.tune),
                      label: const Text('Adjust Budget'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    event.budgetLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Balance ${event.approvedBudgetBalanceLabel}'),
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

class _LiquidationQueue extends StatelessWidget {
  const _LiquidationQueue({
    required this.snapshot,
    required this.onCreateOfficer,
    required this.onSubmitLiquidation,
    required this.onMarkLiquidated,
  });

  final LiquidationWorkspaceSnapshot snapshot;
  final VoidCallback onCreateOfficer;
  final ValueChanged<LiquidationEventView> onSubmitLiquidation;
  final ValueChanged<LiquidationEventView> onMarkLiquidated;

  @override
  Widget build(BuildContext context) {
    final events = snapshot.events
        .where((event) {
          return event.status != AuditEventStatus.ongoing;
        })
        .toList(growable: false);
    return _Panel(
      title: 'Liquidation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: const Key('liquidationAddOfficerButton'),
                onPressed: onCreateOfficer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add Officer'),
              ),
              Text('${snapshot.officerOptions.length} accountable officers'),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const _EmptyPanelMessage(
              icon: Icons.receipt_long_outlined,
              text: 'Completed events will appear here for liquidation.',
            )
          else
            Column(
              children: [
                for (final event in events)
                  _LiquidationEventRow(
                    event: event,
                    hasOfficers: snapshot.officerOptions.isNotEmpty,
                    showDivider: event != events.last,
                    onSubmitLiquidation: () => onSubmitLiquidation(event),
                    onMarkLiquidated: () => onMarkLiquidated(event),
                  ),
              ],
            ),
          if (snapshot.receipts.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Recent Receipts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final receipt in snapshot.receipts.take(3))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long),
                title: Text(receipt.payeeOrMerchant),
                subtitle: Text(
                  '${receipt.eventName} - ${receipt.fundingModeLabel} - ${receipt.dateLabel}',
                ),
                trailing: Text(receipt.totalLabel),
              ),
          ],
        ],
      ),
    );
  }
}

class _LiquidationEventRow extends StatelessWidget {
  const _LiquidationEventRow({
    required this.event,
    required this.hasOfficers,
    required this.showDivider,
    required this.onSubmitLiquidation,
    required this.onMarkLiquidated,
  });

  final LiquidationEventView event;
  final bool hasOfficers;
  final bool showDivider;
  final VoidCallback onSubmitLiquidation;
  final VoidCallback onMarkLiquidated;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment_turned_in_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${event.statusLabel} - ${event.dateRangeLabel}'),
                    const SizedBox(height: 4),
                    Text(
                      'Budget balance ${event.approvedBudgetBalanceLabel} - '
                      '${event.receiptCount} receipts - '
                      '${event.pendingClaimCount} pending claims',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: Key('eventLiquidationButton${event.id}'),
                    onPressed: event.canSubmitLiquidation && hasOfficers
                        ? onSubmitLiquidation
                        : null,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Liquidate'),
                  ),
                  FilledButton.icon(
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
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _ReimbursementPanel extends StatelessWidget {
  const _ReimbursementPanel({
    required this.claims,
    required this.onPayReimbursement,
  });

  final List<ReimbursementClaimView> claims;
  final ValueChanged<ReimbursementClaimView> onPayReimbursement;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Reimbursements',
      child: claims.isEmpty
          ? const _EmptyPanelMessage(
              icon: Icons.payments_outlined,
              text: 'Out-of-pocket liquidation claims will appear here.',
            )
          : Column(
              children: [
                for (final claim in claims)
                  _ReimbursementClaimRow(
                    claim: claim,
                    showDivider: claim != claims.last,
                    onPay: () => onPayReimbursement(claim),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                claim.status == ReimbursementStatus.pending
                    ? Icons.schedule
                    : Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.eventName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${claim.officerName} - ${claim.statusLabel}'),
                    const SizedBox(height: 4),
                    Text(
                      'Available ${claim.approvedBudgetBalanceLabel} - '
                      'After payment ${claim.projectedRemainingLabel}',
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    key: Key('reimbursementPayButton${claim.id}'),
                    onPressed: claim.canPay ? onPay : null,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pay'),
                  ),
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

class _CreateEventDialog extends StatefulWidget {
  const _CreateEventDialog({
    required this.service,
    required this.sourceOptions,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final EventService service;
  final List<TreasurySourceAllocationOption> sourceOptions;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _semesterController = TextEditingController(text: '1st Semester');
  final _schoolYearController = TextEditingController(text: '2026-2027');
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _permitDateController = TextEditingController();
  final _resolutionNumberController = TextEditingController();
  final _budgetController = TextEditingController();
  final List<_AllocationInput> _allocations = [];
  AttachmentRef? _resolutionAttachment;
  String? _serviceError;
  String? _formError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final input = _AllocationInput(
      sourceId: widget.sourceOptions.isEmpty
          ? null
          : widget.sourceOptions.first.id,
    );
    input.amountController.addListener(_refreshRemaining);
    _allocations.add(input);
    _budgetController.addListener(_refreshRemaining);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _permitDateController.dispose();
    _resolutionNumberController.dispose();
    _budgetController.dispose();
    for (final allocation in _allocations) {
      allocation.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      title: 'Create Event',
      maxWidth: 660,
      status: _formError == null && _serviceError == null
          ? null
          : InlineStatusPanel(
              title: _serviceError == null
                  ? 'Review required fields'
                  : 'Event could not be saved',
              message:
                  _serviceError ??
                  'Fix the highlighted fields before saving this event.',
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('eventCreateSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Event'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('eventNameField'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event name'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventTypeField'),
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Event type'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventSemesterField'),
                controller: _semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventSchoolYearField'),
                controller: _schoolYearController,
                decoration: const InputDecoration(labelText: 'School year'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventStartDateField'),
                controller: _startDateController,
                labelText: 'Start date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventEndDateField'),
                controller: _endDateController,
                labelText: 'End date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('eventPermitDateField'),
                controller: _permitDateController,
                labelText: 'Permit approval date',
                helperText: 'Optional. Select date or enter YYYY-MM-DD.',
                validator: _optionalDateValidator,
                isRequired: false,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventResolutionNumberField'),
                controller: _resolutionNumberController,
                decoration: const InputDecoration(
                  labelText: 'Resolution number',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventBudgetField'),
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Budget'),
                validator: _moneyValidator,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Resolution attachment',
                action: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              FormField<AttachmentRef>(
                key: const Key('eventResolutionAttachmentField'),
                validator: (_) => _resolutionAttachment == null
                    ? 'Select a resolution attachment.'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttachmentSelector(
                      label: 'Resolution attachment',
                      owner: const AttachmentOwner(module: 'events'),
                      picker: widget.attachmentPicker,
                      storage: widget.attachmentStorage,
                      selectedAttachment: _resolutionAttachment,
                      selectButtonKey: const Key(
                        'eventResolutionAttachmentSelectButton',
                      ),
                      clearButtonKey: const Key(
                        'eventResolutionAttachmentClearButton',
                      ),
                      isEnabled: !_isSubmitting,
                      onChanged: (attachment) {
                        setState(() {
                          _resolutionAttachment = attachment;
                        });
                        field.didChange(attachment);
                      },
                    ),
                    if (field.hasError) ...[
                      const SizedBox(height: 6),
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Split funding',
                action: OutlinedButton.icon(
                  key: const Key('eventAddAllocationButton'),
                  onPressed: _addAllocation,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Row'),
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < _allocations.length; index += 1)
                _AllocationRow(
                  key: ValueKey(_allocations[index]),
                  input: _allocations[index],
                  index: index,
                  sourceOptions: widget.sourceOptions,
                  canRemove: _allocations.length > 1,
                  onChanged: () => setState(() {}),
                  onRemove: () => _removeAllocation(index),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Remaining allocation: ${formatPhpMoney(_remainingAllocation())}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addAllocation() {
    final input = _AllocationInput(
      sourceId: widget.sourceOptions.isEmpty
          ? null
          : widget.sourceOptions.first.id,
    );
    input.amountController.addListener(_refreshRemaining);
    setState(() {
      _allocations.add(input);
    });
  }

  void _removeAllocation(int index) {
    setState(() {
      _allocations.removeAt(index).dispose();
    });
  }

  void _refreshRemaining() {
    if (mounted) {
      setState(() {});
    }
  }

  Money _remainingAllocation() {
    final budget = parsePhpMoney(_budgetController.text) ?? Money.zero;
    final allocated = _allocations.fold(
      Money.zero,
      (total, input) =>
          total + (parsePhpMoney(input.amountController.text) ?? Money.zero),
    );
    return budget - allocated;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _formError = 'Fix the highlighted fields before saving this event.';
        _serviceError = null;
      });
      return;
    }
    final startDate = _parseDate(_startDateController.text)!;
    final endDate = _parseDate(_endDateController.text)!;
    if (endDate.isBefore(startDate)) {
      setState(() {
        _serviceError = 'Event end date cannot be before the start date.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _serviceError = null;
      _formError = null;
    });
    final result = await widget.service.createEvent(
      CreateEventCommand(
        name: _nameController.text,
        type: _typeController.text,
        semester: _semesterController.text,
        schoolYear: _schoolYearController.text,
        startDate: startDate,
        endDate: endDate,
        permitApprovalDate: _parseDate(_permitDateController.text),
        resolutionNumber: _resolutionNumberController.text,
        budget: parsePhpMoney(_budgetController.text)!,
        resolutionAttachment: _resolutionAttachment,
        allocations: _allocations
            .map(
              (input) => EventAllocationDraft(
                fundSourceId: input.sourceId!,
                amount: parsePhpMoney(input.amountController.text)!,
              ),
            )
            .toList(growable: false),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _BudgetReviewDialog extends StatefulWidget {
  const _BudgetReviewDialog({
    required this.service,
    required this.event,
    required this.asOf,
  });

  final EventService service;
  final EventCardView event;
  final DateTime asOf;

  @override
  State<_BudgetReviewDialog> createState() => _BudgetReviewDialogState();
}

class _BudgetReviewDialogState extends State<_BudgetReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _findingsController = TextEditingController();
  final _causeController = TextEditingController();
  final _recommendationController = TextEditingController();
  late Future<BudgetActualSnapshot?> _snapshotFuture;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.service.loadBudgetActual(
      widget.event.id,
      asOf: widget.asOf,
    );
  }

  @override
  void dispose() {
    _findingsController.dispose();
    _causeController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Budget vs Actual'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: FutureBuilder<BudgetActualSnapshot?>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Text('Selected event could not be loaded.');
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.eventName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _BudgetActualMetrics(snapshot: data),
                  const SizedBox(height: 16),
                  Text(
                    'Add Review Snapshot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('auditorReviewFindingsField'),
                          controller: _findingsController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Findings',
                          ),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('auditorReviewCauseField'),
                          controller: _causeController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Cause'),
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('auditorReviewRecommendationField'),
                          controller: _recommendationController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Recommendation',
                          ),
                          validator: _requiredValidator,
                        ),
                      ],
                    ),
                  ),
                  if (_serviceError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _serviceError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Review History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (data.reviews.isEmpty)
                    const _EmptyPanelMessage(
                      icon: Icons.rate_review_outlined,
                      text: 'No auditor review snapshots have been recorded.',
                    )
                  else
                    Column(
                      children: [
                        for (final review in data.reviews)
                          _AuditorReviewHistoryRow(review: review),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          key: const Key('auditorReviewSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Review'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.createAuditorReview(
      CreateAuditorReviewCommand(
        eventId: widget.event.id,
        findings: _findingsController.text,
        cause: _causeController.text,
        recommendation: _recommendationController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _BudgetActualMetrics extends StatelessWidget {
  const _BudgetActualMetrics({required this.snapshot});

  final BudgetActualSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tileWidth = MediaQuery.sizeOf(context).width >= 560 ? 280.0 : 520.0;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Budget',
            value: snapshot.budgetLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Actual',
            value: snapshot.actualLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Variance',
            value: snapshot.varianceLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Utilization',
            value: snapshot.utilizationLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Remaining Approved',
            value: snapshot.approvedBudgetBalanceLabel,
          ),
        ),
        SizedBox(
          width: tileWidth,
          child: _BudgetMetricTile(
            label: 'Health',
            value: snapshot.healthLabel,
          ),
        ),
      ],
    );
  }
}

class _BudgetMetricTile extends StatelessWidget {
  const _BudgetMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditorReviewHistoryRow extends StatelessWidget {
  const _AuditorReviewHistoryRow({required this.review});

  final AuditorReviewView review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(label: review.createdAtLabel),
                  _StatusChip(label: review.healthLabel),
                  _MetaChip(label: review.utilizationLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text('Findings: ${review.findings}'),
              const SizedBox(height: 4),
              Text('Cause: ${review.cause}'),
              const SizedBox(height: 4),
              Text('Recommendation: ${review.recommendation}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdjustBudgetDialog extends StatefulWidget {
  const _AdjustBudgetDialog({
    required this.service,
    required this.event,
    required this.sourceOptions,
  });

  final EventService service;
  final EventCardView event;
  final List<TreasurySourceAllocationOption> sourceOptions;

  @override
  State<_AdjustBudgetDialog> createState() => _AdjustBudgetDialogState();
}

class _AdjustBudgetDialogState extends State<_AdjustBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _remarksController = TextEditingController();
  BudgetAdjustmentDirection _direction = BudgetAdjustmentDirection.increase;
  StableId? _sourceId;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sourceId = widget.sourceOptions.isEmpty
        ? null
        : widget.sourceOptions.first.id;
    _amountController.addListener(_refreshReview);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSource = _sourceById(widget.sourceOptions, _sourceId);
    final review = _review(selectedSource);
    return AlertDialog(
      title: const Text('Adjust Event Budget'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.event.name),
                const SizedBox(height: 4),
                Text(
                  'Current budget ${widget.event.budgetLabel} - '
                  'balance ${widget.event.approvedBudgetBalanceLabel}',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BudgetAdjustmentDirection>(
                  key: const Key('eventBudgetAdjustmentDirectionField'),
                  initialValue: _direction,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment direction',
                  ),
                  items: BudgetAdjustmentDirection.values
                      .map(
                        (direction) => DropdownMenuItem(
                          value: direction,
                          child: Text(
                            _budgetAdjustmentDirectionLabel(direction),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _direction = value;
                          });
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StableId>(
                  key: const Key('eventBudgetAdjustmentSourceField'),
                  initialValue: _sourceId,
                  decoration: const InputDecoration(
                    labelText: 'Treasury source',
                  ),
                  items: widget.sourceOptions
                      .map(
                        (source) => DropdownMenuItem(
                          value: source.id,
                          child: Text(source.label),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Select a Treasury source.' : null,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _sourceId = value;
                          });
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  selectedSource == null
                      ? 'No source selected.'
                      : 'Source balance ${selectedSource.balanceLabel}',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('eventBudgetAdjustmentAmountField'),
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: _moneyValidator,
                ),
                const SizedBox(height: 12),
                AppDatePickerFormField(
                  key: const Key('eventBudgetAdjustmentDateField'),
                  controller: _dateController,
                  labelText: 'Adjustment date',
                  validator: _dateValidator,
                  isEnabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('eventBudgetAdjustmentRemarksField'),
                  controller: _remarksController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment remarks',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                _BudgetAdjustmentReviewPanel(review: review),
                if (_serviceError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serviceError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('eventBudgetAdjustmentSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Adjustment'),
        ),
      ],
    );
  }

  BudgetAdjustmentReview _review(TreasurySourceAllocationOption? source) {
    final amount = parsePhpMoney(_amountController.text) ?? Money.zero;
    final isIncrease = _direction == BudgetAdjustmentDirection.increase;
    return BudgetAdjustmentReview(
      currentBudget: widget.event.budget,
      currentApprovedBudgetBalance: widget.event.approvedBudgetBalance,
      sourceBalance: source?.balance ?? Money.zero,
      projectedBudget: isIncrease
          ? widget.event.budget + amount
          : widget.event.budget - amount,
      projectedApprovedBudgetBalance: isIncrease
          ? widget.event.approvedBudgetBalance + amount
          : widget.event.approvedBudgetBalance - amount,
      projectedSourceBalance: isIncrease
          ? (source?.balance ?? Money.zero) - amount
          : (source?.balance ?? Money.zero) + amount,
    );
  }

  void _refreshReview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.adjustEventBudget(
      AdjustEventBudgetCommand(
        eventId: widget.event.id,
        direction: _direction,
        amount: parsePhpMoney(_amountController.text)!,
        treasurySourceId: _sourceId!,
        adjustmentDate: _parseDate(_dateController.text)!,
        remarks: _remarksController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _BudgetAdjustmentReviewPanel extends StatelessWidget {
  const _BudgetAdjustmentReviewPanel({required this.review});

  final BudgetAdjustmentReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projected Balances',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ReviewLine(
              label: 'Event budget',
              value: review.projectedBudgetLabel,
            ),
            _ReviewLine(
              label: 'Approved budget balance',
              value: review.projectedApprovedBudgetBalanceLabel,
            ),
            _ReviewLine(
              label: 'Treasury source balance',
              value: review.projectedSourceBalanceLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _CreateOfficerDialog extends StatefulWidget {
  const _CreateOfficerDialog({required this.service});

  final LiquidationService service;

  @override
  State<_CreateOfficerDialog> createState() => _CreateOfficerDialogState();
}

class _CreateOfficerDialogState extends State<_CreateOfficerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Officer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('officerNameField'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Officer name'),
              validator: _requiredValidator,
            ),
            if (_serviceError != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _serviceError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('officerSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Save Officer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.createOfficer(
      CreateOfficerCommand(fullName: _nameController.text),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _SubmitLiquidationDialog extends StatefulWidget {
  const _SubmitLiquidationDialog({
    required this.service,
    required this.event,
    required this.officers,
    required this.attachmentPicker,
    required this.attachmentStorage,
  });

  final LiquidationService service;
  final LiquidationEventView event;
  final List<OfficerOption> officers;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;

  @override
  State<_SubmitLiquidationDialog> createState() =>
      _SubmitLiquidationDialogState();
}

class _SubmitLiquidationDialogState extends State<_SubmitLiquidationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _payeeController = TextEditingController();
  final _dateController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _remarksController = TextEditingController();
  final List<_LiquidationLineInput> _lines = [_LiquidationLineInput()];
  AttachmentRef? _receiptAttachment;
  ReceiptType _receiptType = ReceiptType.officialReceipt;
  FundingMode _fundingMode = FundingMode.releasedFunds;
  StableId? _officerId;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _officerId = widget.officers.isEmpty ? null : widget.officers.first.id;
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _dateController.dispose();
    _evidenceController.dispose();
    _remarksController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Liquidate ${widget.event.name}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approved budget balance ${widget.event.approvedBudgetBalanceLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('liquidationPayeeField'),
                  controller: _payeeController,
                  decoration: const InputDecoration(
                    labelText: 'Payee or merchant',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                AppDatePickerFormField(
                  key: const Key('liquidationDateField'),
                  controller: _dateController,
                  labelText: 'Receipt date',
                  validator: _dateValidator,
                  isEnabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('liquidationEvidenceField'),
                  controller: _evidenceController,
                  decoration: const InputDecoration(
                    labelText: 'Evidence number',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReceiptType>(
                  key: const Key('liquidationReceiptTypeField'),
                  initialValue: _receiptType,
                  decoration: const InputDecoration(labelText: 'Receipt type'),
                  items: ReceiptType.values
                      .map(
                        (type) => DropdownMenuItem(
                          key: Key('liquidationReceiptTypeOption${type.name}'),
                          value: type,
                          child: Text(receiptTypeDisplayLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _receiptType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  key: const Key('liquidationFundingModeField'),
                  decoration: const InputDecoration(labelText: 'Funding mode'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FundingMode.values
                        .map(
                          (mode) => ChoiceChip(
                            key: Key(
                              'liquidationFundingModeOption${mode.name}',
                            ),
                            label: Text(fundingModeDisplayLabel(mode)),
                            selected: _fundingMode == mode,
                            onSelected: (_) {
                              setState(() {
                                _fundingMode = mode;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StableId>(
                  key: const Key('liquidationOfficerField'),
                  initialValue: _officerId,
                  decoration: const InputDecoration(
                    labelText: 'Accountable officer',
                  ),
                  items: widget.officers
                      .map(
                        (officer) => DropdownMenuItem(
                          value: officer.id,
                          child: Text(officer.fullName),
                        ),
                      )
                      .toList(growable: false),
                  validator: (value) =>
                      value == null ? 'Select an accountable officer.' : null,
                  onChanged: (value) {
                    setState(() {
                      _officerId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Receipt attachment',
                  action: const SizedBox.shrink(),
                ),
                const SizedBox(height: 12),
                FormField<AttachmentRef>(
                  key: const Key('liquidationAttachmentField'),
                  validator: (_) => _receiptAttachment == null
                      ? 'Select a receipt attachment.'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AttachmentSelector(
                        label: 'Receipt attachment',
                        owner: const AttachmentOwner(module: 'liquidation'),
                        picker: widget.attachmentPicker,
                        storage: widget.attachmentStorage,
                        selectedAttachment: _receiptAttachment,
                        selectButtonKey: const Key(
                          'liquidationAttachmentSelectButton',
                        ),
                        clearButtonKey: const Key(
                          'liquidationAttachmentClearButton',
                        ),
                        isEnabled: !_isSubmitting,
                        onChanged: (attachment) {
                          setState(() {
                            _receiptAttachment = attachment;
                          });
                          field.didChange(attachment);
                        },
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Line items',
                  action: OutlinedButton.icon(
                    key: const Key('liquidationAddLineButton'),
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Row'),
                  ),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _lines.length; index += 1)
                  _LiquidationLineRow(
                    key: ValueKey(_lines[index]),
                    input: _lines[index],
                    index: index,
                    canRemove: _lines.length > 1,
                    onRemove: () => _removeLine(index),
                  ),
                TextFormField(
                  key: const Key('liquidationRemarksField'),
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks'),
                ),
                if (_serviceError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serviceError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('liquidationSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Liquidation'),
        ),
      ],
    );
  }

  void _addLine() {
    setState(() {
      _lines.add(_LiquidationLineInput());
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.submitLiquidation(
      SubmitLiquidationCommand(
        eventId: widget.event.id,
        payeeOrMerchant: _payeeController.text,
        date: _parseDate(_dateController.text)!,
        evidenceNumber: _evidenceController.text,
        receiptType: _receiptType,
        fundingMode: _fundingMode,
        accountableOfficerId: _officerId!,
        attachment: _receiptAttachment,
        lines: _lines
            .map(
              (line) => SubmitLiquidationLineDraft(
                description: line.descriptionController.text,
                quantity: int.parse(line.quantityController.text.trim()),
                unitCost: parsePhpMoney(line.unitCostController.text)!,
              ),
            )
            .toList(growable: false),
        remarks: _remarksController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _LiquidationLineRow extends StatelessWidget {
  const _LiquidationLineRow({
    super.key,
    required this.input,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final _LiquidationLineInput input;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Line ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: Key('liquidationRemoveLineButton$index'),
                    tooltip: 'Remove line',
                    onPressed: canRemove ? onRemove : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('liquidationLineDescriptionField$index'),
                controller: input.descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('liquidationLineQuantityField$index'),
                controller: input.quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: _positiveIntValidator,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('liquidationLineUnitCostField$index'),
                controller: input.unitCostController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Unit cost'),
                validator: _moneyValidator,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayReimbursementDialog extends StatefulWidget {
  const _PayReimbursementDialog({required this.service, required this.claim});

  final LiquidationService service;
  final ReimbursementClaimView claim;

  @override
  State<_PayReimbursementDialog> createState() =>
      _PayReimbursementDialogState();
}

class _PayReimbursementDialogState extends State<_PayReimbursementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void dispose() {
    _dateController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pay Reimbursement'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.claim.eventName),
              const SizedBox(height: 6),
              Text('Claim amount ${widget.claim.amountLabel}'),
              Text('Available ${widget.claim.approvedBudgetBalanceLabel}'),
              Text('After payment ${widget.claim.projectedRemainingLabel}'),
              if (widget.claim.hasInsufficientBudget) ...[
                const SizedBox(height: 8),
                Text(
                  'Approved Budget is insufficient.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              AppDatePickerFormField(
                key: const Key('reimbursementPaymentDateField'),
                controller: _dateController,
                labelText: 'Payment date',
                validator: _dateValidator,
                isEnabled: !_isSubmitting,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('reimbursementRemarksField'),
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              if (_serviceError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _serviceError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('reimbursementPaymentSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Pay Claim'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _serviceError = null;
    });
    final result = await widget.service.payReimbursement(
      PayReimbursementCommand(
        claimId: widget.claim.id,
        paymentDate: _parseDate(_dateController.text)!,
        remarks: _remarksController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(context, result);
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    super.key,
    required this.input,
    required this.index,
    required this.sourceOptions,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _AllocationInput input;
  final int index;
  final List<TreasurySourceAllocationOption> sourceOptions;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedSource = _sourceById(sourceOptions, input.sourceId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Allocation ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove allocation',
                    onPressed: canRemove ? onRemove : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<StableId>(
                key: Key('eventAllocationSourceField$index'),
                initialValue: input.sourceId,
                decoration: const InputDecoration(labelText: 'Funding source'),
                items: sourceOptions
                    .map(
                      (source) => DropdownMenuItem(
                        value: source.id,
                        child: Text(source.label),
                      ),
                    )
                    .toList(growable: false),
                validator: (value) =>
                    value == null ? 'Select a funding source.' : null,
                onChanged: (value) {
                  input.sourceId = value;
                  onChanged();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedSource == null
                      ? 'No source selected.'
                      : 'Available: ${selectedSource.balanceLabel}',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: Key('eventAllocationAmountField$index'),
                controller: input.amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Allocation amount',
                ),
                validator: _moneyValidator,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllocationInput {
  _AllocationInput({required this.sourceId});

  StableId? sourceId;
  final amountController = TextEditingController();

  void dispose() {
    amountController.dispose();
  }
}

class _LiquidationLineInput {
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final unitCostController = TextEditingController();

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitCostController.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        action,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.24),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}

String? _moneyValidator(String? value) {
  final money = parsePhpMoney(value ?? '');
  if (money == null) {
    return 'Enter a valid PHP amount.';
  }
  if (!money.isPositive) {
    return 'Amount must be greater than zero.';
  }
  return null;
}

String? _dateValidator(String? value) {
  if (_parseDate(value ?? '') == null) {
    return 'Enter a valid date.';
  }
  return null;
}

String? _optionalDateValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  return _dateValidator(text);
}

String? _positiveIntValidator(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null) {
    return 'Enter a valid number.';
  }
  if (parsed <= 0) {
    return 'Number must be greater than zero.';
  }
  return null;
}

DateTime? _parseDate(String input) {
  final text = input.trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

TreasurySourceAllocationOption? _sourceById(
  List<TreasurySourceAllocationOption> sources,
  StableId? id,
) {
  if (id == null) {
    return null;
  }
  for (final source in sources) {
    if (source.id == id) {
      return source;
    }
  }
  return null;
}

String _budgetAdjustmentDirectionLabel(BudgetAdjustmentDirection direction) {
  return switch (direction) {
    BudgetAdjustmentDirection.increase => 'Increase budget',
    BudgetAdjustmentDirection.decrease => 'Decrease budget',
  };
}
