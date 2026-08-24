import 'package:flutter/material.dart';

import '../../app/brand_logo.dart';
import '../../app/ui/app_ui.dart';
import 'dashboard_models.dart';
import 'dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.snapshot,
    this.service,
    this.asOf,
    this.onOpenExportCenter,
    this.onOpenLedger,
  });

  final DashboardSnapshot? snapshot;
  final DashboardService? service;
  final DateTime? asOf;
  final VoidCallback? onOpenExportCenter;
  final VoidCallback? onOpenLedger;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardSnapshot>? _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _resetFuture();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service || oldWidget.asOf != widget.asOf) {
      _resetFuture();
    }
  }

  void _resetFuture() {
    _snapshotFuture = widget.service?.loadSnapshot(
      asOf: widget.asOf ?? DateTime.now(),
    );
  }

  void _retry() {
    setState(_resetFuture);
  }

  @override
  Widget build(BuildContext context) {
    final providedSnapshot = widget.snapshot;
    if (providedSnapshot != null) {
      return _DashboardContent(
        snapshot: providedSnapshot,
        onOpenExportCenter: widget.onOpenExportCenter,
        onOpenLedger: widget.onOpenLedger,
      );
    }

    if (widget.service == null) {
      return _DashboardContent(
        snapshot: demoDashboardSnapshot,
        onOpenExportCenter: widget.onOpenExportCenter,
        onOpenLedger: widget.onOpenLedger,
      );
    }

    return FutureBuilder<DashboardSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppStateView.loading(
            title: 'Loading dashboard',
            message: 'Reading local audit records for this workspace.',
          );
        }
        if (snapshot.hasError) {
          return AppStateView.error(
            title: 'Dashboard data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _retry,
          );
        }
        return _DashboardContent(
          snapshot: snapshot.data ?? demoDashboardSnapshot,
          onOpenExportCenter: widget.onOpenExportCenter,
          onOpenLedger: widget.onOpenLedger,
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.snapshot,
    required this.onOpenExportCenter,
    required this.onOpenLedger,
  });

  final DashboardSnapshot snapshot;
  final VoidCallback? onOpenExportCenter;
  final VoidCallback? onOpenLedger;

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
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _DashboardHeader(snapshot: snapshot),
                  const SizedBox(height: 20),
                  _MetricGrid(
                    metrics: snapshot.metrics,
                    crossAxisCount: isWide
                        ? 4
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1,
                  ),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _FundMovementPanel(
                            movements: snapshot.movements,
                            onOpenLedger: onOpenLedger,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _ReadinessPanel(
                            snapshot: snapshot,
                            onOpenExportCenter: onOpenExportCenter,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _ReadinessPanel(
                      snapshot: snapshot,
                      onOpenExportCenter: onOpenExportCenter,
                    ),
                    const SizedBox(height: 20),
                    _FundMovementPanel(
                      movements: snapshot.movements,
                      onOpenLedger: onOpenLedger,
                    ),
                  ],
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandLogo(
              key: Key('dashboardBrandLogo'),
              size: 48,
              decorative: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                snapshot.organizationName,
                style: textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatusChip(
              icon: Icons.calendar_month_outlined,
              label: snapshot.term,
              tone: DashboardSignalTone.neutral,
            ),
            _StatusChip(
              icon: Icons.cloud_off_outlined,
              label: 'Offline workspace',
              tone: DashboardSignalTone.success,
            ),
            _StatusChip(
              icon: Icons.backup_outlined,
              label: snapshot.lastBackup,
              tone: DashboardSignalTone.warning,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics, required this.crossAxisCount});

  final List<DashboardMetric> metrics;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 150,
      ),
      itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final toneColor = _toneColor(metric.tone);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(metric.icon, color: toneColor, size: 26),
            const Spacer(),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(metric.label, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(metric.detail, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({
    required this.snapshot,
    required this.onOpenExportCenter,
  });

  final DashboardSnapshot snapshot;
  final VoidCallback? onOpenExportCenter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Panel(
      title: 'Export Readiness',
      action: FilledButton.icon(
        onPressed: onOpenExportCenter,
        icon: const Icon(Icons.archive_outlined),
        label: const Text('Export Center'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${snapshot.exportReadiness}%', style: textTheme.headlineMedium),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: snapshot.exportReadiness / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFFA16207),
          ),
          const SizedBox(height: 18),
          ...snapshot.tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TaskRow(task: task),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final DashboardTask task;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(task.tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: toneColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(task.detail),
              const SizedBox(height: 4),
              Text(
                task.status,
                style: TextStyle(color: toneColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FundMovementPanel extends StatelessWidget {
  const _FundMovementPanel({
    required this.movements,
    required this.onOpenLedger,
  });

  final List<FundMovementPreview> movements;
  final VoidCallback? onOpenLedger;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Recent Fund Movements',
      action: OutlinedButton.icon(
        onPressed: onOpenLedger,
        icon: const Icon(Icons.list_alt_outlined),
        label: const Text('View Ledger'),
      ),
      child: Column(
        children: [
          if (movements.isEmpty)
            const _EmptyPanelMessage(
              icon: Icons.timeline_outlined,
              text:
                  'Fund activity will appear after treasury records are saved.',
            )
          else
            for (final movement in movements)
              _MovementRow(
                movement: movement,
                showDivider: movement != movements.last,
              ),
        ],
      ),
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
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.showDivider});

  final FundMovementPreview movement;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                movement.isSystemGenerated
                    ? Icons.lock_outline
                    : Icons.edit_note_outlined,
                color: movement.isSystemGenerated
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${movement.reference} - ${movement.date}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    StatusBadge(
                      label: movement.isSystemGenerated
                          ? 'System-generated'
                          : 'Manual',
                      icon: movement.isSystemGenerated
                          ? Icons.lock_outline
                          : Icons.edit_note_outlined,
                      tone: movement.isSystemGenerated
                          ? InlineStatusTone.info
                          : InlineStatusTone.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  movement.amount,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
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

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final DashboardSignalTone tone;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(tone);
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        border: Border.all(color: toneColor.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: toneColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: toneColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(DashboardSignalTone tone) {
  return switch (tone) {
    DashboardSignalTone.success => const Color(0xFF10B981),
    DashboardSignalTone.warning => const Color(0xFFF59E0B),
    DashboardSignalTone.danger => const Color(0xFFEF4444),
    DashboardSignalTone.neutral => const Color(0xFF38BDF8),
  };
}
