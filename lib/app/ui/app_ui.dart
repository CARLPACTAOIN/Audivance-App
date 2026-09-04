import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_tokens.dart';

export 'app_date_picker_form_field.dart';
export 'app_tokens.dart';
export 'topographic_background.dart';

enum InlineStatusTone { info, success, warning, error }

/// Standard page scaffold with responsive horizontal padding and safe bottom clearance.
class ResponsivePageScaffold extends StatelessWidget {
  const ResponsivePageScaffold({
    super.key,
    required this.children,
    this.maxWidth = 1180,
    this.bottomPadding = 110,
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
        final horizontalPadding = constraints.maxWidth >= 900
            ? AppSpacing.xxl
            : AppSpacing.lg;
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

/// Standard full-screen or section placeholder for loading, empty, and error states.
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox.square(
                  dimension: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh, size: 18),
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

/// An inline callout message with semantic background tint and icon.
class InlineStatusPanel extends StatelessWidget {
  const InlineStatusPanel({
    super.key,
    required this.message,
    this.title,
    this.tone = InlineStatusTone.info,
    this.action,
  });

  final String? title;
  final String message;
  final InlineStatusTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      InlineStatusTone.info => AppColors.info,
      InlineStatusTone.success => AppColors.success,
      InlineStatusTone.warning => AppColors.warning,
      InlineStatusTone.error => AppColors.error,
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
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: AppRadius.borderMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard modal dialog shell with constrained width and scrollable body.
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
    final maxHeight = math.max(240.0, size.height - 200);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                if (status != null) ...[
                  status!,
                  const SizedBox(height: AppSpacing.md),
                ],
                ...children,
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      actions: actions,
    );
  }
}

/// A calm, neutral pill chip for non-status metadata (term, timestamp, category).
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
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: AppRadius.borderSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// A restrained semantic badge for true state indicators (ongoing, due, liquidated, error).
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
      InlineStatusTone.info => AppColors.info,
      InlineStatusTone.success => AppColors.success,
      InlineStatusTone.warning => AppColors.warning,
      InlineStatusTone.error => AppColors.error,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: AppRadius.borderSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 1,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable section title with optional subtitle, icon, and trailing action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.brandLight),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

/// Reusable standardized card surface with clean borders and unified padding.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = padding == EdgeInsets.zero
        ? child
        : Padding(padding: padding, child: child);

    if (onTap != null) {
      return AppScaleOnTap(
        onTap: onTap,
        child: Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderLg,
            side: BorderSide(color: AppColors.borderSubtle),
          ),
          child: InkWell(onTap: onTap, child: content),
        ),
      );
    }

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: content,
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
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            if (stat.label.isNotEmpty)
              Text(
                stat.label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
          ],
        ),
      );
      if (i < items.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '·',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 14),
            ),
          ),
        );
      }
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
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
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textMuted,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
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

/// A compact, readable list row with optional tap-to-expand details.
class ExpandableListRow extends StatefulWidget {
  const ExpandableListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.expandedContent,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    this.initiallyExpanded = false,
    this.onTap,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? expandedContent;
  final bool showDivider;
  final EdgeInsetsGeometry padding;
  final bool initiallyExpanded;
  final VoidCallback? onTap;

  @override
  State<ExpandableListRow> createState() => _ExpandableListRowState();
}

class _ExpandableListRowState extends State<ExpandableListRow> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggle() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.expandedContent != null) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExpandable = widget.expandedContent != null;
    final rowContent = InkWell(
      onTap: hasExpandable || widget.onTap != null ? _toggle : null,
      borderRadius: AppRadius.borderMd,
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.title,
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        widget.subtitle!,
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  widget.trailing!,
                ],
                if (hasExpandable) ...[
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: AppMotion.durationStandard,
                    curve: AppMotion.curveStandard,
                    child: const Icon(
                      Icons.expand_more,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            if (hasExpandable)
              AnimatedSize(
                duration: AppMotion.durationStandard,
                curve: AppMotion.curveStandard,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          left: 2,
                        ),
                        child: widget.expandedContent!,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );

    if (!widget.showDivider) {
      return rowContent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        rowContent,
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

/// A subtle entrance transition combining fade and vertical translation.
/// Respects [MediaQueryData.disableAnimations] for accessibility.
class AppSlideFadeIn extends StatefulWidget {
  const AppSlideFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.durationEntrance,
    this.offset = AppMotion.offsetEntrance,
    this.curve = AppMotion.curveStandard,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<AppSlideFadeIn> createState() => _AppSlideFadeInState();
}

class _AppSlideFadeInState extends State<AppSlideFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isCompleted) {
          return child!;
        }
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A standardized smooth crossfade between widgets (e.g. loading -> content).
class AppCrossfade extends StatelessWidget {
  const AppCrossfade({
    super.key,
    required this.child,
    this.duration = AppMotion.durationStandard,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.curveStandard,
      switchOutCurve: AppMotion.curveStandard,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: alignment,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }
}

/// Subtle press micro-interaction (`1.0 -> 0.98 -> 1.0`) on tap down/up/cancel.
/// Does not block pointer gestures or interfere with Material ripples.
class AppScaleOnTap extends StatefulWidget {
  const AppScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.98,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool enabled;

  @override
  State<AppScaleOnTap> createState() => _AppScaleOnTapState();
}

class _AppScaleOnTapState extends State<AppScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.curveStandard),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enabled && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.enabled && widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled && widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      return widget.child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
