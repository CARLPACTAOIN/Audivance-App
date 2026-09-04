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
    this.refreshTrigger = 0,
  });

  final DashboardSnapshot? snapshot;
  final DashboardService? service;
  final DateTime? asOf;
  final VoidCallback? onOpenExportCenter;
  final VoidCallback? onOpenLedger;
  final int refreshTrigger;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardSnapshot>? _snapshotFuture;
  DashboardSnapshot? _cachedSnapshot;

  @override
  void initState() {
    super.initState();
    _resetFuture();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.asOf != widget.asOf ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _resetFuture();
    }
  }

  void _resetFuture() {
    final future = widget.service?.loadSnapshot(
      asOf: widget.asOf ?? DateTime.now(),
    );
    if (future != null) {
      _snapshotFuture = future.then((snapshot) {
        if (mounted) {
          setState(() {
            _cachedSnapshot = snapshot;
          });
        }
        return snapshot;
      });
    } else {
      _snapshotFuture = Future.value(demoDashboardSnapshot);
    }
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

    if (_cachedSnapshot != null) {
      return _DashboardContent(
        key: const ValueKey('content'),
        snapshot: _cachedSnapshot!,
        onOpenExportCenter: widget.onOpenExportCenter,
        onOpenLedger: widget.onOpenLedger,
      );
    }

    return FutureBuilder<DashboardSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const AppStateView.loading(
            key: ValueKey('loading'),
            title: 'Loading dashboard',
            message: 'Reading local audit records for this workspace.',
          );
        } else if (snapshot.hasError) {
          child = AppStateView.error(
            key: const ValueKey('error'),
            title: 'Dashboard data could not be loaded',
            message: snapshot.error.toString(),
            onAction: _retry,
          );
        } else {
          final data = snapshot.data ?? demoDashboardSnapshot;
          _cachedSnapshot = data;
          child = _DashboardContent(
            key: const ValueKey('content'),
            snapshot: data,
            onOpenExportCenter: widget.onOpenExportCenter,
            onOpenLedger: widget.onOpenLedger,
          );
        }
        return AppCrossfade(child: child);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    super.key,
    required this.snapshot,
    required this.onOpenExportCenter,
    required this.onOpenLedger,
  });

  final DashboardSnapshot snapshot;
  final VoidCallback? onOpenExportCenter;
  final VoidCallback? onOpenLedger;

  @override
  Widget build(BuildContext context) {
    return AppSlideFadeIn(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? AppSpacing.xxl : AppSpacing.lg,
                  AppSpacing.lg,
                  isWide ? AppSpacing.xxl : AppSpacing.lg,
                  110,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _DashboardHeader(snapshot: snapshot),
                    const SizedBox(height: AppSpacing.lg),
                    _MetricGrid(metrics: snapshot.metrics),
                    const SizedBox(height: AppSpacing.lg),
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
                          const SizedBox(width: AppSpacing.lg),
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
                      const SizedBox(height: AppSpacing.lg),
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
      ),
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
        Text(
          snapshot.organizationName,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            MetadataChip(
              icon: Icons.calendar_month_outlined,
              label: snapshot.term,
            ),
            MetadataChip(
              icon: Icons.backup_outlined,
              label: snapshot.lastBackup,
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
              const SizedBox(width: AppSpacing.md),
              if (i + 1 < metrics.length)
                Expanded(child: _MetricCard(metric: metrics[i + 1]))
              else
                const Spacer(),
            ],
          ),
          if (i + 2 < metrics.length) const SizedBox(height: AppSpacing.md),
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
    final toneColor = _signalToneColor(metric.tone);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.10),
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(metric.icon, color: toneColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        ? AppColors.success
        : score >= 50
        ? AppColors.warning
        : AppColors.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Export Readiness',
            trailing: FilledButton.icon(
              onPressed: onOpenExportCenter,
              icon: const Icon(Icons.archive_outlined, size: 16),
              label: const Text('Export Center'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$score%',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
              Text(
                'workspace readiness',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: AppColors.divider,
            color: scoreColor,
          ),
          if (firstTask != null) ...[
            const SizedBox(height: AppSpacing.md),
            _TaskRow(task: firstTask),
            if (snapshot.tasks.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: onOpenExportCenter,
                child: Text(
                  '${snapshot.tasks.length - 1} more issue${snapshot.tasks.length > 2 ? 's' : ''} — view in Export Center',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.brandLight,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.brandLight,
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
    final toneColor = _signalToneColor(task.tone);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: toneColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                task.detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                task.status,
                style: TextStyle(
                  color: toneColor,
                  fontWeight: FontWeight.w600,
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Fund Movements',
            trailing: OutlinedButton.icon(
              onPressed: onOpenLedger,
              icon: const Icon(Icons.list_alt_outlined, size: 16),
              label: const Text('View Ledger'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
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
        color: movement.isSystemGenerated ? AppColors.info : AppColors.warning,
        size: 18,
      ),
      title: Text(
        movement.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${movement.reference} · ${movement.date}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
      ),
      trailing: Text(
        movement.amount,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
          color: AppColors.textPrimary,
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

Color _signalToneColor(DashboardSignalTone tone) {
  return switch (tone) {
    DashboardSignalTone.success => AppColors.success,
    DashboardSignalTone.warning => AppColors.warning,
    DashboardSignalTone.danger => AppColors.error,
    DashboardSignalTone.neutral => AppColors.info,
  };
}
