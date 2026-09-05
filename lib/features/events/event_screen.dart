import 'dart:math' as math;

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
    required this.liquidationService,
    required this.attachmentPicker,
    required this.attachmentStorage,
    this.asOf,
    this.refreshTrigger = 0,
    required this.organizationService,
  });

  final EventService service;
  final LiquidationService liquidationService;
  final AttachmentPicker attachmentPicker;
  final AttachmentStorageService attachmentStorage;
  final DateTime? asOf;
  final int refreshTrigger;
  final OrganizationService organizationService;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<EventWorkspaceSnapshot> _snapshotFuture;
  EventWorkspaceSnapshot? _cachedSnapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(EventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.liquidationService != widget.liquidationService ||
        oldWidget.organizationService != widget.organizationService ||
        oldWidget.asOf != widget.asOf ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _load();
    }
  }

  Future<EventWorkspaceSnapshot> _loadSnapshot() async {
    final asOf = widget.asOf ?? DateTime.now();
    return widget.service.loadSnapshot(asOf: asOf);
  }

  void _load() {
    _snapshotFuture = _loadSnapshot().then((snapshot) {
      if (mounted) {
        setState(() {
          _cachedSnapshot = snapshot;
        });
      }
      return snapshot;
    });
  }

  void _refresh() {
    setState(_load);
  }

  Future<void> _openEventDetails(EventCardView event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          eventId: event.id,
          service: widget.service,
          liquidationService: widget.liquidationService,
          attachmentPicker: widget.attachmentPicker,
          attachmentStorage: widget.attachmentStorage,
          organizationService: widget.organizationService,
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
    if (_cachedSnapshot != null) {
      return _EventOverviewContent(
        key: const ValueKey('content'),
        snapshot: _cachedSnapshot!,
        onCreateEvent: () =>
            _showCreateEventDialog(_cachedSnapshot!.sourceOptions),
        onSelectEvent: _openEventDetails,
      );
    }

    return FutureBuilder<EventWorkspaceSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const AppStateView.loading(
            key: ValueKey('loading'),
            title: 'Loading Events',
            message: 'Reading events and treasury allocations.',
          );
        } else if (snapshot.hasError) {
          child = AppStateView.error(
            key: const ValueKey('error'),
            title: 'Events data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _refresh,
          );
        } else {
          final data =
              snapshot.data ??
              const EventWorkspaceSnapshot(events: [], sourceOptions: []);
          _cachedSnapshot = data;
          child = _EventOverviewContent(
            key: const ValueKey('content'),
            snapshot: data,
            onCreateEvent: () => _showCreateEventDialog(data.sourceOptions),
            onSelectEvent: _openEventDetails,
          );
        }
        return AppCrossfade(child: child);
      },
    );
  }
}

class _EventOverviewContent extends StatelessWidget {
  const _EventOverviewContent({
    super.key,
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
                  AppSlideFadeIn(
                    child: _EventOverviewHeader(
                      snapshot: snapshot,
                      onCreateEvent: onCreateEvent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep,
                    child: _EventCardList(
                      events: snapshot.events,
                      onSelectEvent: onSelectEvent,
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
    final openEvents = snapshot.events
        .where((e) => e.statusLabel != 'Liquidated')
        .length;

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
                CompactStat(value: '$openEvents open records', label: ''),
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
  const _EventCardList({required this.events, required this.onSelectEvent});

  final List<EventCardView> events;
  final ValueChanged<EventCardView> onSelectEvent;

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      title: 'Event Records',
      child: events.isEmpty
          ? const _OverviewEmptyMessage(
              icon: Icons.event_busy_outlined,
              text: 'Fund Treasury first, then create the first event with split funding.',
            )
          : Column(
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  AppSlideFadeIn(
                    delay: AppMotion.staggerStep * math.min(i, 5),
                    child: _EventCard(
                      event: events[i],
                      onTap: () => onSelectEvent(events[i]),
                    ),
                  ),
                  if (i < events.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

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

    return AppCard(
      key: Key('eventCard${event.id}'),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_note,
                    color: AppColors.brandLight,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event.type} · ${event.dateRangeLabel}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(label: event.statusLabel, tone: tone),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CompactStatRow(
                      items: [
                        CompactStat(value: event.budgetLabel, label: 'budget'),
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
                    color: AppColors.textMuted,
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
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
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.sm,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
