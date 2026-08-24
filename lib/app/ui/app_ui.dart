import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'app_date_picker_form_field.dart';

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
      InlineStatusTone.info => const Color(0xFF1E3A8A),
      InlineStatusTone.success => const Color(0xFF047857),
      InlineStatusTone.warning => const Color(0xFFA16207),
      InlineStatusTone.error => Theme.of(context).colorScheme.error,
    };
    final background = color.withValues(alpha: 0.08);
    final icon = switch (tone) {
      InlineStatusTone.info => Icons.info_outline,
      InlineStatusTone.success => Icons.check_circle_outline,
      InlineStatusTone.warning => Icons.warning_amber_outlined,
      InlineStatusTone.error => Icons.error_outline,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
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
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(message, style: TextStyle(color: color)),
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
      avatar: Icon(icon, size: 18),
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
      InlineStatusTone.info => const Color(0xFF1E3A8A),
      InlineStatusTone.success => const Color(0xFF047857),
      InlineStatusTone.warning => const Color(0xFFA16207),
      InlineStatusTone.error => Theme.of(context).colorScheme.error,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
