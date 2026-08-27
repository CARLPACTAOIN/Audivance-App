import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// An ultra-modern floating pill navigation bar featuring glowing vector icons,
/// frosted glassmorphic styling, crisp typography, and high-end fintech aesthetics.
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
    final horizontalPadding = isDesktop ? 24.0 : 16.0;
    final bottomPadding = bottomInset > 0 ? bottomInset + 4.0 : 14.0;
    const topPadding = 6.0;
    const pillHeight = 66.0;
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
                  borderRadius: BorderRadius.circular(36.0),
                  boxShadow: [
                    // Deep ambient contact shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 28.0,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                    // Soft amber bloom radiating from the chassis
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                      blurRadius: 22.0,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: Container(
                      height: 66.0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36.0),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(
                              0xCC151C2A,
                            ), // Frosted dark slate (80% opacity)
                            Color(
                              0xD90B0F17,
                            ), // Frosted deep obsidian (85% opacity)
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF334155)
                              .withValues(alpha: 0.70),
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
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26.0),
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33F59E0B), // 20% amber-500 tint
                        Color(0x12D97706), // 7% amber-600 tint
                      ],
                    )
                  : null,
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.40),
                      width: 1.0,
                    )
                  : Border.all(
                      color: isHovered
                          ? const Color(0x2294A3B8)
                          : Colors.transparent,
                      width: 1.0,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        blurRadius: 14.0,
                        spreadRadius: -1.0,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon
                AnimatedScale(
                  scale: isSelected ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected
                        ? widget.destination.activeIcon
                        : widget.destination.inactiveIcon,
                    size: 21.0,
                    color: isSelected
                        ? const Color(0xFFFBBF24) // Vivid warm gold
                        : isHovered
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF8899AC),
                    shadows: isSelected
                        ? [
                            // Vivid inner core glow
                            Shadow(
                              color: const Color(0xFFFDE68A)
                                  .withValues(alpha: 0.45),
                              blurRadius: 4.0,
                            ),
                            // Vibrant mid-field luminous bloom
                            Shadow(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.90),
                              blurRadius: 14.0,
                            ),
                            // Deep ambient aura
                            Shadow(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.55),
                              blurRadius: 24.0,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 3.0),
                // Razor-sharp Typography
                Text(
                  widget.destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSelected ? 11.2 : 11.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: isSelected ? 0.2 : 0.1,
                    color: isSelected
                        ? const Color(0xFFF8FAFC)
                        : isHovered
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF8899AC),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2.0),
                // Micro Glowing Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 14.0 : 0.0,
                  height: 2.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.0),
                    color: isSelected
                        ? const Color(0xFFFBBF24)
                        : Colors.transparent,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.9),
                              blurRadius: 6.0,
                              spreadRadius: 0.5,
                            ),
                          ]
                        : null,
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
