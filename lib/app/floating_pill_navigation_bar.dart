import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/app_tokens.dart';

/// An item descriptor for [FloatingPillNavigationBar].
class FloatingPillDestination {
  const FloatingPillDestination({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.key,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Key key;
}

/// A modern, refined floating pill navigation bar featuring frosted glassmorphic
/// chassis, clean typography, and quiet, high-end fintech aesthetics.
class FloatingPillNavigationBar extends StatelessWidget {
  const FloatingPillNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations = defaultDestinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingPillDestination> destinations;

  static const List<FloatingPillDestination> defaultDestinations = [
    FloatingPillDestination(
      label: 'Dashboard',
      activeIcon: Icons.dashboard_rounded,
      inactiveIcon: Icons.dashboard_outlined,
      key: Key('navItemDashboard'),
    ),
    FloatingPillDestination(
      label: 'Treasury',
      activeIcon: Icons.account_balance_rounded,
      inactiveIcon: Icons.account_balance_outlined,
      key: Key('navItemTreasury'),
    ),
    FloatingPillDestination(
      label: 'Events',
      activeIcon: Icons.event_note_rounded,
      inactiveIcon: Icons.event_note_outlined,
      key: Key('navItemEvents'),
    ),
    FloatingPillDestination(
      label: 'Export',
      activeIcon: Icons.archive_rounded,
      inactiveIcon: Icons.archive_outlined,
      key: Key('navItemExport'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    final isDesktop = mediaQuery.size.width >= 600;
    final horizontalPadding = isDesktop ? AppSpacing.xl : AppSpacing.lg;
    final bottomPadding = bottomInset > 0 ? bottomInset + 4.0 : 14.0;
    const topPadding = 6.0;
    const pillHeight = 64.0;
    final totalHeight = pillHeight + topPadding + bottomPadding;

    return SizedBox(
      height: totalHeight,
      child: ColoredBox(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520.0),
              child: Container(
                height: pillHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20.0,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: Container(
                      height: pillHeight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEB131922),
                        borderRadius: BorderRadius.circular(32.0),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(destinations.length, (index) {
                          final destination = destinations[index];
                          final isSelected = index == selectedIndex;
                          return Expanded(
                            child: _PillNavigationItem(
                              key: destination.key,
                              destination: destination,
                              isSelected: isSelected,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onDestinationSelected(index);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavigationItem extends StatefulWidget {
  const _PillNavigationItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final FloatingPillDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PillNavigationItem> createState() => _PillNavigationItemState();
}

class _PillNavigationItemState extends State<_PillNavigationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isHovered = _isHovered && !isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: widget.destination.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              color: isSelected
                  ? AppColors.brandContainer.withValues(alpha: 0.55)
                  : isHovered
                  ? AppColors.surfaceSubtle
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? widget.destination.activeIcon
                      : widget.destination.inactiveIcon,
                  size: 20.0,
                  color: isSelected
                      ? const Color(0xFFFBBF24)
                      : isHovered
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  shadows: isSelected
                      ? const [
                          Shadow(color: Color(0x80D97706), blurRadius: 8.0),
                          Shadow(color: Color(0x4DFBBF24), blurRadius: 16.0),
                        ]
                      : null,
                ),
                const SizedBox(height: 3.0),
                Text(
                  widget.destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.1,
                    color: isSelected
                        ? AppColors.textPrimary
                        : isHovered
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
