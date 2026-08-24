import 'package:audivance/app/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatePickerFormField unit tests', () {
    test('parseIsoDate parses valid ISO dates correctly', () {
      final date = AppDatePickerFormField.parseIsoDate('2026-08-23');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 8);
      expect(date.day, 23);
    });

    test('parseIsoDate returns null on invalid dates or formats', () {
      expect(AppDatePickerFormField.parseIsoDate(''), isNull);
      expect(AppDatePickerFormField.parseIsoDate('2026/08/23'), isNull);
      expect(AppDatePickerFormField.parseIsoDate('Aug 23, 2026'), isNull);
      expect(AppDatePickerFormField.parseIsoDate('2026-02-30'), isNull);
      expect(AppDatePickerFormField.parseIsoDate('2026-13-01'), isNull);
    });

    test('formatIsoDate formats dates with leading zeroes', () {
      expect(
        AppDatePickerFormField.formatIsoDate(DateTime(2026, 8, 5)),
        '2026-08-05',
      );
      expect(
        AppDatePickerFormField.formatIsoDate(DateTime(2026, 12, 25)),
        '2026-12-25',
      );
    });
  });

  group('AppDatePickerFormField widget tests', () {
    testWidgets('renders label and calendar icon button', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerFormField(
              key: const Key('testDateField'),
              controller: controller,
              labelText: 'Event Date',
            ),
          ),
        ),
      );

      expect(find.text('Event Date'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });

    testWidgets('tapping calendar icon opens date picker and selects date', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      DateTime? selectedDate;
      String? changedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerFormField(
              key: const Key('testDateField'),
              controller: controller,
              labelText: 'Event Date',
              initialDate: DateTime(2026, 8, 15),
              firstDate: DateTime(2026, 1, 1),
              lastDate: DateTime(2026, 12, 31),
              onDateSelected: (date) => selectedDate = date,
              onChanged: (text) => changedDate = text,
            ),
          ),
        ),
      );

      // Tap calendar icon button
      final pickerButton = find.byKey(const Key('testDateFieldPickerButton'));
      expect(pickerButton, findsOneWidget);
      await tester.tap(pickerButton);
      await tester.pumpAndSettle();

      // DatePickerDialog is visible
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Select August 20, 2026 (day 20)
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(controller.text, '2026-08-20');
      expect(selectedDate, DateTime(2026, 8, 20));
      expect(changedDate, '2026-08-20');
    });

    testWidgets('allows manual keyboard text entry', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerFormField(
              key: const Key('testDateField'),
              controller: controller,
              labelText: 'Start Date',
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('testDateField')), '2026-09-01');
      await tester.pumpAndSettle();

      expect(controller.text, '2026-09-01');
    });

    testWidgets('shows clear button for optional fields with content', (
      tester,
    ) async {
      final controller = TextEditingController(text: '2026-08-15');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerFormField(
              key: const Key('testDateField'),
              controller: controller,
              labelText: 'Permit Date',
              isRequired: false,
            ),
          ),
        ),
      );

      final clearButton = find.byKey(const Key('testDateFieldClearButton'));
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(find.byKey(const Key('testDateFieldClearButton')), findsNothing);
    });

    testWidgets('disables interactions when isEnabled is false', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDatePickerFormField(
              key: const Key('testDateField'),
              controller: controller,
              labelText: 'Event Date',
              isEnabled: false,
            ),
          ),
        ),
      );

      final pickerButton = find.byKey(const Key('testDateFieldPickerButton'));
      expect(pickerButton, findsOneWidget);
      await tester.tap(pickerButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Dialog does not open
      expect(find.byType(DatePickerDialog), findsNothing);
    });
  });
}
