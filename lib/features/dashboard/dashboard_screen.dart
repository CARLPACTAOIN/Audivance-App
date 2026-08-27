import 'package:flutter/material.dart';

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
                16,
                isWide ? 32 : 16,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _DashboardHeader(snapshot: snapshot),
                  const SizedBox(height: 14),
                  _MetricGrid(metrics: snapshot.metrics),
                  const SizedBox(height: 14),
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
                        const SizedBox(width: 14),
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
                    const SizedBox(height: 14),
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
        Text(snapshot.organizationName, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              icon: Icons.calendar_month_outlined,
              label: snapshot.term,
              tone: DashboardSignalTone.neutral,
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
  const _MetricGrid({required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < metrics.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _MetricCard(metric: metrics[i])),
              const SizedBox(width: 10),
              if (i + 1 < metrics.length)
                Expanded(child: _MetricCard(metric: metrics[i + 1]))
              else
                const Spacer(),
            ],
          ),
          if (i + 2 < metrics.length) const SizedBox(height: 10),
        ],
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(metric.icon, color: toneColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF8FAFC),
                    ),
                  ),
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
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
    final firstTask = snapshot.tasks.isNotEmpty ? snapshot.tasks.first : null;
    final score = snapshot.exportReadiness;
    final scoreColor = score >= 80
        ? const Color(0xFF10B981)
        : score >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    return _Panel(
      title: 'Export Readiness',
      action: FilledButton.icon(
        onPressed: onOpenExportCenter,
        icon: const Icon(Icons.archive_outlined, size: 16),
        label: const Text('Export Center'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$score%',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
              Text(
                'workspace readiness',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: const Color(0xFF1E293B),
            color: scoreColor,
          ),
          if (firstTask != null) ...[
            const SizedBox(height: 12),
            _TaskRow(task: firstTask),
            if (snapshot.tasks.length > 1) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onOpenExportCenter,
                child: Text(
                  '${snapshot.tasks.length - 1} more issue${snapshot.tasks.length > 2 ? 's' : ''} — view in Export Center',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ],
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
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: toneColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                task.detail,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                task.status,
                style: TextStyle(
                  color: toneColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
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
        icon: const Icon(Icons.list_alt_outlined, size: 16),
        label: const Text('View Ledger'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 36),
        ),
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
            for (var i = 0; i < movements.length; i++)
              _MovementRow(
                movement: movements[i],
                showDivider: i < movements.length - 1,
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
    return ExpandableListRow(
      initiallyExpanded: true,
      leading: Icon(
        movement.isSystemGenerated
            ? Icons.lock_outline
            : Icons.edit_note_outlined,
        color: movement.isSystemGenerated
            ? const Color(0xFF38BDF8)
            : const Color(0xFFF59E0B),
        size: 18,
      ),
      title: Text(
        movement.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFFF8FAFC),
        ),
      ),
      subtitle: Text(
        '${movement.reference} · ${movement.date}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
      ),
      trailing: Text(
        movement.amount,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFFF8FAFC),
        ),
      ),
      expandedContent: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: StatusBadge(
          label: movement.isSystemGenerated
              ? 'System-generated'
              : 'Manual movement',
          icon: movement.isSystemGenerated
              ? Icons.lock_outline
              : Icons.edit_note_outlined,
          tone: movement.isSystemGenerated
              ? InlineStatusTone.info
              : InlineStatusTone.warning,
        ),
      ),
      showDivider: showDivider,
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
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
            const SizedBox(height: 12),
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
