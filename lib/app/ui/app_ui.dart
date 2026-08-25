import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'app_date_picker_form_field.dart';
export 'topographic_background.dart';

enum InlineStatusTone { info, success, warning, error }

class ResponsivePageScaffold extends StatelessWidget {
  const ResponsivePageScaffold({
    super.key,
    required this.children,
    this.maxWidth = 1180,
    this.bottomPadding = 32,
    this.topPadding = 20,
  });

  final List<Widget> children;
  final double maxWidth;
  final double bottomPadding;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 16.0;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isLoading = false,
  });

  const AppStateView.loading({
    super.key,
    this.title = 'Loading workspace',
    this.message = 'Preparing the latest local records.',
  }) : icon = Icons.hourglass_empty,
       actionLabel = null,
       onAction = null,
       isLoading = true;

  const AppStateView.error({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'Retry',
    this.onAction,
  }) : icon = Icons.error_outline,
       isLoading = false;

  const AppStateView.empty({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.inbox_outlined,
       isLoading = false;

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox.square(
                  dimension: 34,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class InlineStatusPanel extends StatelessWidget {
  const InlineStatusPanel({
    super.key,
    required this.message,
    this.title,
    this.tone = InlineStatusTone.info,
  });

  final String? title;
  final String message;
  final InlineStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      InlineStatusTone.info => const Color(0xFF38BDF8),
      InlineStatusTone.success => const Color(0xFF10B981),
      InlineStatusTone.warning => const Color(0xFFF59E0B),
      InlineStatusTone.error => const Color(0xFFEF4444),
    };
    final background = color.withValues(alpha: 0.12);
    final icon = switch (tone) {
      InlineStatusTone.info => Icons.info_outline,
      InlineStatusTone.success => Icons.check_circle_outline,
      InlineStatusTone.warning => Icons.warning_amber_outlined,
      InlineStatusTone.error => Icons.error_outline,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 13,
                      height: 1.4,
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

class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.maxWidth = 560,
    this.status,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxWidth;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.min(maxWidth, size.width - 32);
    final maxHeight = math.max(240.0, size.height - 220);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF161C26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF263345)),
      ),
      title: Text(title),
      content: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status != null) ...[status!, const SizedBox(height: 12)],
                ...children,
              ],
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}

class MetadataChip extends StatelessWidget {
  const MetadataChip({
    super.key,
    required this.label,
    this.icon = Icons.info_outline,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = InlineStatusTone.info,
    this.icon,
  });

  final String label;
  final InlineStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      InlineStatusTone.info => const Color(0xFF38BDF8),
      InlineStatusTone.success => const Color(0xFF10B981),
      InlineStatusTone.warning => const Color(0xFFF59E0B),
      InlineStatusTone.error => const Color(0xFFEF4444),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single horizontal stat row replacing tall summary card grids.
/// Shows N [items] separated by mid-dots. Wraps responsively.
class CompactStatRow extends StatelessWidget {
  const CompactStatRow({super.key, required this.items});

  final List<CompactStat> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final List<Widget> children = [];
    for (var i = 0; i < items.length; i++) {
      final stat = items[i];
      children.add(
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (stat.value.isNotEmpty)
              Text(
                stat.value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF8FAFC),
                  fontSize: 16,
                ),
              ),
            if (stat.label.isNotEmpty)
              Text(
                stat.label,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      );
      if (i < items.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '·',
              style: TextStyle(color: Color(0xFF475569), fontSize: 16),
            ),
          ),
        );
      }
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class CompactStat {
  const CompactStat({required this.value, required this.label});

  final String value;
  final String label;
}

/// A collapsible section panel for progressive disclosure.
/// Used in Export Center to hide detail sections behind expand/collapse.
class CollapsiblePanel extends StatelessWidget {
  const CollapsiblePanel({
    super.key,
    required this.title,
    required this.child,
    this.badge,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final String? badge;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Theme(
        // Override expansion tile divider colour so it matches dark card
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF263345),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [child],
        ),
      ),
    );
  }
}
