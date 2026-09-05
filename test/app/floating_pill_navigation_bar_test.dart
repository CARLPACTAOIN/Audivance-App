import 'package:audivance/app/floating_pill_navigation_bar.dart';
import 'package:audivance/app/ui/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders all 5 destinations with clear labels and icons', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingPillNavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    // Verify all 5 labels are present and rendered
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Treasury'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Org'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    // Verify all 5 destination item keys are present
    expect(find.byKey(const Key('navItemDashboard')), findsOneWidget);
    expect(find.byKey(const Key('navItemTreasury')), findsOneWidget);
    expect(find.byKey(const Key('navItemEvents')), findsOneWidget);
    expect(find.byKey(const Key('navItemOrganization')), findsOneWidget);
    expect(find.byKey(const Key('navItemExport')), findsOneWidget);

    // Initial state: Dashboard is selected
    final dashboardIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('navItemDashboard')),
        matching: find.byType(Icon),
      ),
    );
    expect(dashboardIcon.icon, Icons.dashboard_rounded);
    expect(dashboardIcon.color, const Color(0xFFFBBF24));
    // Verify glowing icon shadows exist on the selected icon
    expect(dashboardIcon.shadows, isNotNull);
    expect(dashboardIcon.shadows!.length, greaterThanOrEqualTo(2));

    // Treasury is unselected
    final treasuryIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('navItemTreasury')),
        matching: find.byType(Icon),
      ),
    );
    expect(treasIcon(treasuryIcon).icon, Icons.account_balance_outlined);
    expect(treasuryIcon.shadows, isNull);
  });

  testWidgets('tapping a destination triggers onDestinationSelected callback', (
    tester,
  ) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingPillNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    // Tap Treasury
    await tester.tap(find.text('Treasury'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 1);

    // Tap Events
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 2);

    // Tap Organization
    await tester.tap(find.text('Org'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 3);

    // Tap Export
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 4);

    // Tap Dashboard
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(tappedIndex, 0);
  });

  testWidgets(
    'updates visual glow and active state when selectedIndex changes',
    (tester) async {
      final selectedNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: selectedNotifier,
              builder: (context, index, _) {
                return FloatingPillNavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (newIndex) =>
                      selectedNotifier.value = newIndex,
                );
              },
            ),
          ),
        ),
      );

      // Initial state: Dashboard glowing, Treasury inactive
      var dashboardIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('navItemDashboard')),
          matching: find.byType(Icon),
        ),
      );
      var treasuryIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('navItemTreasury')),
          matching: find.byType(Icon),
        ),
      );
      expect(dashboardIcon.shadows, isNotNull);
      expect(treasuryIcon.shadows, isNull);

      // Switch to Treasury
      selectedNotifier.value = 1;
      await tester.pumpAndSettle();

      dashboardIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('navItemDashboard')),
          matching: find.byType(Icon),
        ),
      );
      treasuryIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('navItemTreasury')),
          matching: find.byType(Icon),
        ),
      );
      expect(dashboardIcon.shadows, isNull);
      expect(treasuryIcon.shadows, isNotNull);
      expect(treasuryIcon.icon, Icons.account_balance_rounded);
    },
  );

  testWidgets(
    'constrained to max width and applies floating pill chassis padding',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingPillNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      final constrainedBoxFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 520.0,
      );
      expect(constrainedBoxFinder, findsOneWidget);
    },
  );

  testWidgets('pill chassis has a prominent elevated treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FloatingPillNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    final chassis = tester.widget<Container>(
      find.byKey(const Key('floatingNavPillChassis')),
    );
    final chassisDecoration = chassis.decoration! as BoxDecoration;
    expect(chassisDecoration.boxShadow, hasLength(2));
    expect(
      chassisDecoration.boxShadow!.first.color,
      AppColors.brandLight.withValues(alpha: 0.18),
    );

    final selectedItem = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('navItemDashboard')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final selectedDecoration = selectedItem.decoration! as BoxDecoration;
    expect(
      selectedDecoration.color,
      AppColors.brandContainer.withValues(alpha: 0.92),
    );
    expect(selectedDecoration.border, isNotNull);
    expect(selectedDecoration.boxShadow, isNotEmpty);
  });

  testWidgets(
    'five navigation destinations with no overflow at narrow widths',
    (tester) async {
      const narrowWidths = [320.0, 360.0, 375.0, 412.0];

      for (final width in narrowWidths) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FloatingPillNavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (index) => selected = index,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No RenderFlex overflow or layout exceptions
        expect(tester.takeException(), isNull);

        // Verify all 5 destination labels and keys exist and fit
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Treasury'), findsOneWidget);
        expect(find.text('Events'), findsOneWidget);
        expect(find.text('Org'), findsOneWidget);
        expect(find.text('Export'), findsOneWidget);

        expect(find.byKey(const Key('navItemDashboard')), findsOneWidget);
        expect(find.byKey(const Key('navItemTreasury')), findsOneWidget);
        expect(find.byKey(const Key('navItemEvents')), findsOneWidget);
        expect(find.byKey(const Key('navItemOrganization')), findsOneWidget);
        expect(find.byKey(const Key('navItemExport')), findsOneWidget);

        // Verify tapping each tab at narrow width works cleanly
        await tester.tap(find.byKey(const Key('navItemOrganization')));
        await tester.pumpAndSettle();
        expect(selected, 3);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

Icon treasIcon(Icon icon) => icon;
