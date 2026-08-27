import 'package:flutter/material.dart';

import '../../app/ui/app_ui.dart';
import '../../core/attachments/attachment_picker.dart';
import '../../core/attachments/attachment_storage_service.dart';
import '../../core/domain/money.dart';
import '../../core/domain/validation_result.dart';
import '../audit/domain/audit_models.dart';
import '../liquidation/liquidation_service.dart';
import '../organization/organization_service.dart';
import '../treasury/treasury_formatters.dart';
import 'event_details_screen.dart';
import 'event_dialogs.dart';
import 'event_service.dart';

export 'event_details_screen.dart';
export 'event_dialogs.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({
    super.key,
    required this.service,
    required this.organizationService,
    required this.liquidationService,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.asOf,
  });

  final EventService service;
  final OrganizationService organizationService;
  final LiquidationService liquidationService;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final DateTime? asOf;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<EventWorkspaceSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  @override
  void didUpdateWidget(EventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.organizationService != widget.organizationService ||
        oldWidget.liquidationService != widget.liquidationService ||
        oldWidget.asOf != widget.asOf) {
      _snapshotFuture = _loadSnapshot();
    }
  }

  Future<EventWorkspaceSnapshot> _loadSnapshot() async {
    final asOf = widget.asOf ?? DateTime.now();
    return widget.service.loadSnapshot(asOf: asOf);
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  Future<void> _openEventDetails(EventCardView event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          eventId: event.id,
          service: widget.service,
          organizationService: widget.organizationService,
          liquidationService: widget.liquidationService,
          attachmentPicker: widget.attachmentPicker,
          attachmentStorage: widget.attachmentStorage,
          asOf: widget.asOf,
        ),
      ),
    );
    if (mounted) {
      _refresh();
    }
  }

  Future<void> _showCreateEventDialog(
    List<TreasurySourceAllocationOption> sourceOptions,
  ) async {
    final result = await showDialog<ValidationResult>(
      context: context,
      builder: (context) => CreateEventDialog(
        service: widget.service,
        sourceOptions: sourceOptions,
        attachmentPicker: widget.attachmentPicker,
        attachmentStorage: widget.attachmentStorage,
      ),
    );
    if (!mounted || result == null || result.isInvalid) {
      return;
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventWorkspaceSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppStateView.loading(
            title: 'Loading Events',
            message: 'Reading events and treasury allocations.',
          );
        }
        if (snapshot.hasError) {
          return AppStateView.error(
            title: 'Events data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _refresh,
          );
        }
        final data =
            snapshot.data ??
            const EventWorkspaceSnapshot(events: [], sourceOptions: []);
        return _EventOverviewContent(
          snapshot: data,
          onCreateEvent: () => _showCreateEventDialog(data.sourceOptions),
          onSelectEvent: _openEventDetails,
        );
      },
    );
  }
}

class _EventOverviewContent extends StatelessWidget {
  const _EventOverviewContent({
    required this.snapshot,
    required this.onCreateEvent,
    required this.onSelectEvent,
  });

  final EventWorkspaceSnapshot snapshot;
  final VoidCallback onCreateEvent;
  final ValueChanged<EventCardView> onSelectEvent;

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
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _EventOverviewHeader(
                    snapshot: snapshot,
                    onCreateEvent: onCreateEvent,
                  ),
                  const SizedBox(height: 16),
                  _EventCardList(
                    events: snapshot.events,
                    onSelectEvent: onSelectEvent,
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

class _EventOverviewHeader extends StatelessWidget {
  const _EventOverviewHeader({
    required this.snapshot,
    required this.onCreateEvent,
  });

  final EventWorkspaceSnapshot snapshot;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalBudget = snapshot.events.fold(
      Money.zero,
      (total, event) => total + event.budget,
    );
    final openEvents =
        snapshot.events.where((e) => e.statusLabel != 'Liquidated').length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events', style: textTheme.headlineMedium),
            const SizedBox(height: 6),
            CompactStatRow(
              items: [
                CompactStat(
                  value: snapshot.events.length.toString(),
                  label: snapshot.events.length == 1 ? 'event' : 'events',
                ),
                CompactStat(
                  value: formatPhpMoney(totalBudget),
                  label: 'Approved Budget',
                ),
                CompactStat(
                  value: '$openEvents open records',
                  label: '',
                ),
              ],
            ),
          ],
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

class _EventCardList extends StatelessWidget {
  const _EventCardList({
    required this.events,
    required this.onSelectEvent,
  });

  final List<EventCardView> events;
  final ValueChanged<EventCardView> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      title: 'Event Records',
      child: events.isEmpty
          ? const _OverviewEmptyMessage(
              icon: Icons.event_busy_outlined,
              text:
                  'Fund Treasury first, then create the first event with split funding.',
            )
          : Column(
              children: [
                for (final event in events) ...[
                  _EventCard(
                    event: event,
                    onTap: () => onSelectEvent(event),
                  ),
                  if (event != events.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
  });

  final EventCardView event;
  final VoidCallback onTap;

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
      key: Key('eventCard${event.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_note,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event.type} · ${event.dateRangeLabel}',
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: event.statusLabel,
                    tone: tone,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFF1E293B)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CompactStatRow(
                      items: [
                        CompactStat(
                          value: event.budgetLabel,
                          label: 'budget',
                        ),
                        CompactStat(
                          value: event.approvedBudgetBalanceLabel,
                          label: 'balance',
                        ),
                        CompactStat(
                          value: event.resolutionNumber,
                          label: 'res',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('eventManageButton${event.id}'),
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    color: const Color(0xFF94A3B8),
                    onPressed: onTap,
                    tooltip: 'Manage Event',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _OverviewEmptyMessage extends StatelessWidget {
  const _OverviewEmptyMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF64748B)),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
