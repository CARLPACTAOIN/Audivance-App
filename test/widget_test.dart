import 'dart:typed_data';

import 'package:audivance/app/audivance_app.dart';
import 'package:audivance/app/local_unlock_service.dart';
import 'package:audivance/app/ui/app_ui.dart';
import 'package:audivance/core/attachments/attachment_picker.dart';
import 'package:audivance/core/attachments/attachment_storage_service.dart';
import 'package:audivance/core/domain/attachment_ref.dart';
import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/events/event_service.dart';
import 'package:audivance/features/export/export_package_writer.dart';
import 'package:audivance/features/export/export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup loading screen renders the Audivance logo', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());

    expect(find.byKey(const Key('startupBrandLogo')), findsOneWidget);
  });

  testWidgets('first launch shows setup screen', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setupBrandLogo')), findsOneWidget);
    expect(find.text('Set up Audivance'), findsOneWidget);
    expect(find.byKey(const Key('setupSubmitButton')), findsOneWidget);
  });

  testWidgets('setup form rejects empty required fields', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('setupSubmitButton')));
    await tester.tap(find.byKey(const Key('setupSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
  });

  testWidgets('setup form rejects mismatched PIN confirmation', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _fillSetupForm(tester, pinConfirmation: '5678');
    await tester.ensureVisible(find.byKey(const Key('setupSubmitButton')));
    await tester.tap(find.byKey(const Key('setupSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('PIN confirmation must match.'), findsOneWidget);
  });

  testWidgets('successful setup navigates to dashboard', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _fillSetupForm(tester);
    await tester.ensureVisible(find.byKey(const Key('setupSubmitButton')));
    await tester.tap(find.byKey(const Key('setupSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Audivance'), findsOneWidget);
    expect(find.byKey(const Key('workspaceBrandLogo')), findsOneWidget);
    expect(find.byKey(const Key('dashboardBrandLogo')), findsOneWidget);
    expect(find.text('Treasury Balance'), findsOneWidget);
    expect(find.text('PHP 0'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Add the first treasury source'), findsOneWidget);
    expect(await harness.repository.isSetupComplete(), isTrue);
    expect(await harness.unlockService.hasStoredCredential(), isTrue);
  });

  testWidgets('existing pre-secure setup shows credential upgrade screen', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Secure workspace'), findsOneWidget);
    expect(find.byKey(const Key('credentialUpgradePinField')), findsOneWidget);
    expect(find.text('Treasury Balance'), findsNothing);
  });

  testWidgets('credential upgrade stores PIN and navigates to dashboard', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('credentialUpgradePinField')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('credentialUpgradePinConfirmationField')),
      '123456',
    );
    await tester.tap(find.byKey(const Key('credentialUpgradeSubmitButton')));
    await tester.pumpAndSettle();

    expect(await harness.unlockService.hasStoredCredential(), isTrue);
    expect(find.text('Treasury Balance'), findsOneWidget);
  });

  testWidgets('existing setup with stored credential shows unlock screen', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');
    await harness.unlockService.lock();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Unlock workspace'), findsOneWidget);
    expect(find.byKey(const Key('unlockBrandLogo')), findsOneWidget);
    expect(find.byKey(const Key('unlockPinField')), findsOneWidget);
    expect(find.text('Treasury Balance'), findsNothing);
  });

  testWidgets('unlock rejects wrong PIN with visible error', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');
    await harness.unlockService.lock();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('unlockPinField')), '000000');
    await tester.tap(find.byKey(const Key('unlockSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('PIN does not match this workspace.'), findsOneWidget);
    expect(find.text('Treasury Balance'), findsNothing);
  });

  testWidgets('unlock accepts correct PIN and navigates to dashboard', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');
    await harness.unlockService.lock();

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('unlockPinField')), '123456');
    await tester.tap(find.byKey(const Key('unlockSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Treasury Balance'), findsOneWidget);
  });

  testWidgets('shows the Audivance offline dashboard after unlock', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedDashboardData();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Audivance'), findsOneWidget);
    expect(find.byKey(const Key('workspaceBrandLogo')), findsOneWidget);
    expect(find.byKey(const Key('dashboardBrandLogo')), findsOneWidget);
    expect(
      find.text('Junior Philippine Institute of Accountants'),
      findsOneWidget,
    );
    expect(find.text('Treasury Balance'), findsOneWidget);
    expect(find.text('PHP 22,845'), findsOneWidget);
    expect(find.text('PHP 22,000'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Recent Fund Movements'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Export Readiness'), findsOneWidget);
    expect(find.text('Recent Fund Movements'), findsOneWidget);
    expect(find.textContaining('FM-20260818-4F2A91C0'), findsOneWidget);
    expect(find.text('System-generated'), findsOneWidget);
  });

  testWidgets('Dashboard Export Center action switches to Export', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Export Center'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Export Center'));
    await tester.pumpAndSettle();

    expect(find.text('Export Center'), findsWidgets);
    expect(find.text('COA Export Readiness'), findsOneWidget);
  });

  testWidgets('Dashboard View Ledger action switches to Treasury', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedDashboardData();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('View Ledger'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View Ledger'));
    await tester.pumpAndSettle();

    expect(find.text('Treasury'), findsWidgets);
    expect(find.text('Unallocated Treasury Balance'), findsOneWidget);
    expect(find.text('Student Collections'), findsWidgets);
  });

  testWidgets('settings opens Backup & Restore panel', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open settings'));
    await tester.pumpAndSettle();

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.textContaining('encrypted SQLite database'), findsOneWidget);
    expect(find.textContaining('same local secure credential'), findsOneWidget);
    expect(find.byKey(const Key('backupGenerateButton')), findsOneWidget);
    expect(find.byKey(const Key('backupValidateButton')), findsOneWidget);
  });

  testWidgets('navigates from Dashboard to Treasury', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openTreasury(tester);

    expect(find.text('Treasury'), findsWidgets);
    expect(find.text('Unallocated Treasury Balance'), findsOneWidget);
  });

  testWidgets('shows empty Treasury screen state', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openTreasury(tester);

    expect(find.text('PHP 0'), findsWidgets);
    expect(
      find.text('Add the first fund source to begin the Treasury ledger.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(
      find.text('Ledger movements appear after funds are added.'),
      findsOneWidget,
    );
  });

  testWidgets('Add Fund form validates required fields', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openTreasury(tester);
    await tester.tap(find.byKey(const Key('treasuryAddFundButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addFundSubmitButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Fix the highlighted fields before saving this fund.'),
      findsOneWidget,
    );
    expect(find.text('This field is required.'), findsWidgets);
    expect(find.text('Enter a valid PHP amount.'), findsOneWidget);
  });

  testWidgets('attachment import failure shows inline retryable error', (
    tester,
  ) async {
    final harness = _WidgetHarness(
      attachmentStorage: _FailingAttachmentStorageService(),
    );
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openTreasury(tester);
    await tester.tap(find.byKey(const Key('treasuryAddFundButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addFundAttachmentSelectButton')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Attachment could not be imported'),
      findsOneWidget,
    );
    expect(find.text('Select File'), findsOneWidget);
  });

  testWidgets('successful Add Fund updates Treasury totals and ledger', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openTreasury(tester);
    await tester.tap(find.byKey(const Key('treasuryAddFundButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('addFundLabelField')),
      'Student Collections',
    );
    await tester.enterText(
      find.byKey(const Key('addFundAmountField')),
      '12845.50',
    );
    await tester.tap(find.byKey(const Key('addFundAttachmentSelectButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addFundSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Student Collections'), findsWidgets);
    expect(find.text('PHP 12,845.50'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.textContaining('FM-'), findsOneWidget);
  });

  testWidgets('manual movement form rejects insufficient balance', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedTreasurySource(balance: Money.php(100));
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openTreasury(tester);
    await tester.tap(find.byKey(const Key('treasuryManualMovementButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manualMovementAmountField')),
      '200',
    );
    await tester.enterText(
      find.byKey(const Key('manualMovementPurposeField')),
      'Release to officer',
    );
    await tester.tap(find.byKey(const Key('manualMovementSubmitButton')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Fund movement is blocked because the available balance is insufficient.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('navigates from Dashboard to Events', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);

    expect(find.text('Events'), findsWidgets);
    expect(find.text('Event Records'), findsOneWidget);
  });

  testWidgets('shows empty Events screen state', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);

    expect(find.text('0 open records'), findsOneWidget);
    expect(
      find.text(
        'Fund Treasury first, then create the first event with split funding.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Create Event form validates required fields', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedTreasurySource(balance: Money.php(5000));
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await tester.tap(find.byKey(const Key('eventCreateButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('eventCreateSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    expect(find.text('Enter a valid date.'), findsWidgets);
    expect(find.text('Enter a valid PHP amount.'), findsWidgets);
  });

  testWidgets('Create Event form shows split funding mismatch error', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedTreasurySource(balance: Money.php(5000));
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await tester.tap(find.byKey(const Key('eventCreateButton')));
    await tester.pumpAndSettle();
    await _fillEventForm(tester, allocationAmount: '500');
    await tester.tap(find.byKey(const Key('eventCreateSubmitButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Split funding allocations must equal the event budget.'),
      findsOneWidget,
    );
  });

  testWidgets('successful event creation updates Events and Dashboard', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedTreasurySource(balance: Money.php(5000));
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await tester.tap(find.byKey(const Key('eventCreateButton')));
    await tester.pumpAndSettle();
    await _fillEventForm(tester);
    await tester.tap(find.byKey(const Key('eventCreateSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Leadership Summit'), findsOneWidget);
    expect(find.text('PHP 4,000'), findsWidgets);

    await tester.tap(find.text('Dashboard').last);
    await tester.pumpAndSettle();

    expect(find.text('Approved Budget'), findsOneWidget);
    expect(find.text('PHP 4,000'), findsOneWidget);
  });

  testWidgets('Create Event date pickers open calendar dialogs and set dates', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedTreasurySource(balance: Money.php(5000));
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await tester.tap(find.byKey(const Key('eventCreateButton')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('eventStartDateField')));
    await tester.tap(find.byKey(const Key('eventStartDateFieldPickerButton')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    final startDateField = tester.widget<AppDatePickerFormField>(
      find.byKey(const Key('eventStartDateField')),
    );
    expect(startDateField.controller.text, isNotEmpty);
  });

  testWidgets('Events screen shows Adjust Budget for non-liquidated events', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('eventAdjustBudgetButtonevent-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Adjust Budget'), findsOneWidget);
  });

  testWidgets('Adjust Budget form validates required fields', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openBudgetAdjustmentDialog(tester);
    await tester.tap(
      find.byKey(const Key('eventBudgetAdjustmentSubmitButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid PHP amount.'), findsOneWidget);
    expect(find.text('Enter a valid date.'), findsOneWidget);
    expect(find.text('This field is required.'), findsOneWidget);
  });

  testWidgets('Budget increase shows insufficient-source error', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openBudgetAdjustmentDialog(tester);
    await _fillBudgetAdjustmentForm(tester, amount: '6000');
    await tester.tap(
      find.byKey(const Key('eventBudgetAdjustmentSubmitButton')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('source treasury balance is insufficient'),
      findsOneWidget,
    );
  });

  testWidgets(
    'successful budget increase updates event, dashboard, and Treasury ledger',
    (tester) async {
      final harness = _WidgetHarness();
      addTearDown(harness.close);
      await harness.seedSetup();
      await harness.seedCompletedEvent();
      await harness.unlockService.configurePin('123456');

      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await _openEvents(tester);
      await _openBudgetAdjustmentDialog(tester);
      await _fillBudgetAdjustmentForm(tester, amount: '500');
      await tester.tap(
        find.byKey(const Key('eventBudgetAdjustmentSubmitButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('PHP 1,500'), findsWidgets);

      await tester.tap(find.text('Dashboard').last);
      await tester.pumpAndSettle();
      expect(find.text('PHP 1,500'), findsOneWidget);

      await _openTreasury(tester);
      expect(find.text('PHP 4,500'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Ledger'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Budget increase'), findsOneWidget);
    },
  );

  testWidgets('successful budget decrease returns funds to Treasury source', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openBudgetAdjustmentDialog(tester);
    await _fillBudgetAdjustmentForm(
      tester,
      direction: BudgetAdjustmentDirection.decrease,
      amount: '300',
    );
    await tester.tap(
      find.byKey(const Key('eventBudgetAdjustmentSubmitButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('PHP 700'), findsWidgets);

    await _openTreasury(tester);
    expect(find.text('PHP 5,300'), findsWidgets);
  });

  testWidgets('liquidated events do not allow budget adjustment', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent(isLiquidated: true);
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);

    expect(find.text('Liquidated'), findsOneWidget);
    expect(
      find.byKey(const Key('eventAdjustBudgetButtonevent-1')),
      findsNothing,
    );
  });

  testWidgets('budget review panel displays budget actual metrics', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.seedReleasedFundsLiquidation();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openBudgetReviewDialog(tester);

    expect(find.text('Budget vs Actual'), findsOneWidget);
    expect(find.text('PHP 1,000'), findsWidgets);
    expect(find.text('PHP 200'), findsWidgets);
    expect(find.text('PHP 800'), findsWidgets);
    expect(find.text('20.00%'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
  });

  testWidgets('auditor review form validates and saves history', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.seedReleasedFundsLiquidation();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openBudgetReviewDialog(tester);
    await tester.tap(find.byKey(const Key('auditorReviewSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);

    await _enterTextByKey(
      tester,
      const Key('auditorReviewFindingsField'),
      'Spending stayed below budget.',
    );
    await _enterTextByKey(
      tester,
      const Key('auditorReviewCauseField'),
      'Meals were purchased below the expected price.',
    );
    await _enterTextByKey(
      tester,
      const Key('auditorReviewRecommendationField'),
      'Keep the receipt and supplier canvass with the event file.',
    );
    await tester.tap(find.byKey(const Key('auditorReviewSubmitButton')));
    await tester.pumpAndSettle();

    final reviews = await harness.repository.listAuditorReviewsForEvent(
      'event-1',
    );
    expect(reviews, hasLength(1));

    await _openBudgetReviewDialog(tester);
    expect(
      find.textContaining('Spending stayed below budget.'),
      findsOneWidget,
    );
  });

  testWidgets('opens liquidation from an event record', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedOfficer();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openLiquidationDialog(tester);

    expect(find.text('Liquidate Leadership Summit'), findsOneWidget);
    expect(find.byKey(const Key('liquidationPayeeField')), findsOneWidget);
  });

  testWidgets('liquidation form validates required fields', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedOfficer();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openLiquidationDialog(tester);
    await tester.tap(find.byKey(const Key('liquidationSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    expect(find.text('Enter a valid date.'), findsOneWidget);
    expect(find.text('Enter a valid PHP amount.'), findsOneWidget);
  });

  testWidgets('liquidation form adds and removes line rows', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedOfficer();
    await harness.seedCompletedEvent();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openLiquidationDialog(tester);
    await tester.ensureVisible(
      find.byKey(const Key('liquidationAddLineButton')),
    );
    await tester.tap(find.byKey(const Key('liquidationAddLineButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('liquidationLineDescriptionField1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('liquidationRemoveLineButton1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('liquidationLineDescriptionField1')),
      findsNothing,
    );
  });

  testWidgets(
    'out-of-pocket liquidation displays pending reimbursement claim',
    (tester) async {
      final harness = _WidgetHarness();
      addTearDown(harness.close);
      await harness.seedSetup();
      await harness.seedOfficer();
      await harness.seedCompletedEvent();
      await harness.unlockService.configurePin('123456');

      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await _openEvents(tester);
      await _openLiquidationDialog(tester);
      await _fillLiquidationForm(tester, outOfPocket: true);
      await tester.tap(find.byKey(const Key('liquidationSubmitButton')));
      await tester.pumpAndSettle();

      final claims = await harness.repository.listReimbursementClaims();
      expect(claims.single.status, ReimbursementStatus.pending);
      await tester.scrollUntilVisible(
        find.text('Reimbursements'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reimbursements'), findsOneWidget);
      expect(find.textContaining('Pending'), findsOneWidget);
      expect(find.text('PHP 200'), findsWidgets);
    },
  );

  testWidgets(
    'reimbursement payment updates claim status and dashboard budget',
    (tester) async {
      final harness = _WidgetHarness();
      addTearDown(harness.close);
      await harness.seedSetup();
      await harness.seedOfficer();
      await harness.seedCompletedEvent();
      await harness.seedOutOfPocketClaim();
      await harness.unlockService.configurePin('123456');

      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await _openEvents(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('reimbursementPayButtonclaim-1')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reimbursementPayButtonclaim-1')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('reimbursementPaymentDateField')),
        '2026-08-18',
      );
      await tester.tap(
        find.byKey(const Key('reimbursementPaymentSubmitButton')),
      );
      await tester.pumpAndSettle();

      final claim = (await harness.repository.listReimbursementClaims()).single;
      expect(claim.status, ReimbursementStatus.paid);

      await tester.tap(find.text('Dashboard').last);
      await tester.pumpAndSettle();

      expect(find.text('Approved Budget'), findsOneWidget);
      expect(find.text('PHP 800'), findsOneWidget);
    },
  );

  testWidgets('mark-liquidated action updates event status', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedOfficer();
    await harness.seedCompletedEvent();
    await harness.seedReleasedFundsLiquidation();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('eventMarkLiquidatedButtonevent-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('eventMarkLiquidatedButtonevent-1')),
    );
    button.onPressed!();
    await tester.pumpAndSettle();

    final event = (await harness.repository.listAuditEvents()).single;
    expect(event.isLiquidated, isTrue);
    expect(find.text('Liquidated'), findsWidgets);
  });

  testWidgets('navigates from Dashboard to Export', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openExport(tester);

    expect(find.text('Export Center'), findsOneWidget);
    expect(find.text('COA Export Readiness'), findsOneWidget);
    expect(find.byKey(const Key('exportGenerateZipButton')), findsOneWidget);
  });

  testWidgets('empty Export Center shows readiness issues', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openExport(tester);

    expect(find.text('Readiness Issues'), findsOneWidget);
    expect(
      find.text('At least one Treasury source fund is required.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'At least one active officer should be encoded for COA review.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'seeded Export Center shows record counts and package structure',
    (tester) async {
      final harness = _WidgetHarness();
      addTearDown(harness.close);
      await harness.seedSetup();
      await harness.seedExportWorkspace();
      await harness.unlockService.configurePin('123456');

      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await _openExport(tester);

      await tester.scrollUntilVisible(
        find.text('Record Counts'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Record Counts'), findsOneWidget);
      expect(find.text('Events'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Package Structure'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Package Structure'), findsOneWidget);
      expect(find.text('manifest.json'), findsOneWidget);
      expect(find.text('data/audit_events.json'), findsOneWidget);
      expect(find.text('data/budget_vs_actual.json'), findsOneWidget);
      expect(find.text('reports/organization_summary.pdf'), findsOneWidget);
      expect(find.text('reports/treasury_ledger.pdf'), findsOneWidget);
      expect(find.text('reports/budget_vs_actual.pdf'), findsOneWidget);
      expect(
        find.text('reports/liquidation/Leadership-Summit-event-1.pdf'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Generate Preview displays files and manifest metadata', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedExportWorkspace();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openExport(tester);
    await tester.tap(find.byKey(const Key('exportGeneratePreviewButton')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Generated Preview'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Generated Preview'), findsOneWidget);
    expect(
      find.text(
        'Audivance-Junior-Philippine-Institute-of-Accountants-2026-2027-1st-Semester-2026-08-18.zip',
      ),
      findsOneWidget,
    );
    expect(find.text('manifest.json'), findsWidgets);
    expect(find.textContaining('CRC32'), findsWidgets);
  });

  testWidgets('Generate ZIP rejects readiness blockers with visible errors', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openExport(tester);
    await tester.tap(find.byKey(const Key('exportGenerateZipButton')));
    await tester.pumpAndSettle();

    expect(find.text('ZIP Export Blocked'), findsOneWidget);
    expect(
      find.textContaining(
        'Export ZIP cannot be generated until blockers are resolved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('successful ZIP generation shows package metadata', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedExportWorkspace();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openExport(tester);
    await tester.tap(find.byKey(const Key('exportGenerateZipButton')));
    await tester.pumpAndSettle();

    expect(find.text('Generated ZIP'), findsOneWidget);
    expect(find.textContaining('SHA-256'), findsOneWidget);
    expect(find.textContaining('entries'), findsOneWidget);
    expect(harness.exportPackageWriter.savedPackage?.bytes, isNotEmpty);
    expect(
      harness.exportPackageWriter.savedPackage?.entries.where(
        (entry) => entry.sourceType == ExportArchiveEntrySource.report,
      ),
      hasLength(4),
    );
    expect(
      harness.exportPackageWriter.savedPackage?.fileName,
      contains('Audivance-Junior-Philippine-Institute-of-Accountants'),
    );
  });

  testWidgets('Dashboard readiness panel uses shared export readiness logic', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('60%'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('60%'), findsOneWidget);

    expect(find.text('Add the first treasury source'), findsOneWidget);
  });
}

Future<void> _fillSetupForm(
  WidgetTester tester, {
  String pin = '123456',
  String pinConfirmation = '123456',
}) async {
  await tester.enterText(
    find.byKey(const Key('setupDisplayNameField')),
    'Local Auditor',
  );
  await tester.enterText(
    find.byKey(const Key('setupEmailOrStudentIdField')),
    'auditor@example.test',
  );
  await tester.enterText(find.byKey(const Key('setupPinField')), pin);
  await tester.enterText(
    find.byKey(const Key('setupPinConfirmationField')),
    pinConfirmation,
  );
  await tester.enterText(
    find.byKey(const Key('setupOrganizationNameField')),
    'Junior Philippine Institute of Accountants',
  );
  await tester.enterText(
    find.byKey(const Key('setupOrganizationTypeField')),
    'Academic',
  );
  await tester.enterText(
    find.byKey(const Key('setupAdviserField')),
    'Prof. Santos',
  );
  await tester.enterText(
    find.byKey(const Key('setupSemesterField')),
    '1st Semester',
  );
  await tester.enterText(
    find.byKey(const Key('setupSchoolYearField')),
    '2026-2027',
  );
  await tester.enterText(
    find.byKey(const Key('setupSignatoryNamesField')),
    'Ari Santos, Bea Reyes',
  );
}

Future<void> _openTreasury(WidgetTester tester) async {
  await tester.tap(find.text('Treasury').last);
  await tester.pumpAndSettle();
}

Future<void> _openEvents(WidgetTester tester) async {
  await tester.tap(find.text('Events').last);
  await tester.pumpAndSettle();
}

Future<void> _openExport(WidgetTester tester) async {
  await tester.tap(find.text('Export').last);
  await tester.pumpAndSettle();
}

Future<void> _fillEventForm(
  WidgetTester tester, {
  String allocationAmount = '4000',
}) async {
  await _enterTextByKey(
    tester,
    const Key('eventNameField'),
    'Leadership Summit',
  );
  await _enterTextByKey(tester, const Key('eventTypeField'), 'Leadership');
  await _enterTextByKey(tester, const Key('eventStartDateField'), '2026-08-20');
  await _enterTextByKey(tester, const Key('eventEndDateField'), '2026-08-21');
  await _enterTextByKey(
    tester,
    const Key('eventResolutionNumberField'),
    'RES-2026-001',
  );
  await _enterTextByKey(tester, const Key('eventBudgetField'), '4000');
  await tester.ensureVisible(
    find.byKey(const Key('eventResolutionAttachmentSelectButton')),
  );
  await tester.tap(
    find.byKey(const Key('eventResolutionAttachmentSelectButton')),
  );
  await tester.pumpAndSettle();
  await _enterTextByKey(
    tester,
    const Key('eventAllocationAmountField0'),
    allocationAmount,
  );
}

Future<void> _openLiquidationDialog(WidgetTester tester) async {
  final button = find.byKey(const Key('eventLiquidationButtonevent-1'));
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(button), alignment: 0.35);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openBudgetAdjustmentDialog(WidgetTester tester) async {
  final button = find.byKey(const Key('eventAdjustBudgetButtonevent-1'));
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(button), alignment: 0.35);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openBudgetReviewDialog(WidgetTester tester) async {
  final button = find.byKey(const Key('eventBudgetReviewButtonevent-1'));
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(button), alignment: 0.35);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _fillBudgetAdjustmentForm(
  WidgetTester tester, {
  BudgetAdjustmentDirection direction = BudgetAdjustmentDirection.increase,
  String amount = '500',
}) async {
  if (direction == BudgetAdjustmentDirection.decrease) {
    await tester.tap(
      find.byKey(const Key('eventBudgetAdjustmentDirectionField')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decrease budget').last);
    await tester.pumpAndSettle();
  }
  await _enterTextByKey(
    tester,
    const Key('eventBudgetAdjustmentAmountField'),
    amount,
  );
  await _enterTextByKey(
    tester,
    const Key('eventBudgetAdjustmentDateField'),
    '2026-08-18',
  );
  await _enterTextByKey(
    tester,
    const Key('eventBudgetAdjustmentRemarksField'),
    'Approved by adviser',
  );
}

Future<void> _fillLiquidationForm(
  WidgetTester tester, {
  bool outOfPocket = false,
}) async {
  if (outOfPocket) {
    await tester.ensureVisible(
      find.byKey(const Key('liquidationFundingModeField')),
    );
    await tester.tap(
      find.byKey(const Key('liquidationFundingModeOptionoutOfPocket')),
    );
    await tester.pumpAndSettle();
  }
  await _enterTextByKey(
    tester,
    const Key('liquidationPayeeField'),
    'Campus Canteen',
  );
  await _enterTextByKey(
    tester,
    const Key('liquidationDateField'),
    '2026-08-18',
  );
  await _enterTextByKey(
    tester,
    const Key('liquidationEvidenceField'),
    'OR-100',
  );
  await tester.ensureVisible(
    find.byKey(const Key('liquidationAttachmentSelectButton')),
  );
  await tester.tap(find.byKey(const Key('liquidationAttachmentSelectButton')));
  await tester.pumpAndSettle();
  await _enterTextByKey(
    tester,
    const Key('liquidationLineDescriptionField0'),
    'Meals',
  );
  await _enterTextByKey(
    tester,
    const Key('liquidationLineQuantityField0'),
    '2',
  );
  await _enterTextByKey(
    tester,
    const Key('liquidationLineUnitCostField0'),
    '100',
  );
}

Future<void> _enterTextByKey(WidgetTester tester, Key key, String value) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.enterText(find.byKey(key), value);
}

class _WidgetHarness {
  _WidgetHarness({AttachmentStorageService? attachmentStorage})
    : database = AuditDatabase(NativeDatabase.memory()),
      unlockService = InMemoryLocalUnlockService(),
      _attachmentStorage =
          attachmentStorage ?? _FakeAttachmentStorageService() {
    repository = DriftAuditRepository(database);
  }

  final AuditDatabase database;
  final InMemoryLocalUnlockService unlockService;
  late final DriftAuditRepository repository;
  final StableIdGenerator idGenerator = _DeterministicIdGenerator();
  final _attachmentPicker = _FakeAttachmentPicker();
  final AttachmentStorageService _attachmentStorage;
  final exportPackageWriter = _FakeExportPackageWriter();

  Widget app() {
    return AudivanceApp(
      database: database,
      repository: repository,
      unlockService: unlockService,
      idGenerator: idGenerator,
      attachmentPicker: _attachmentPicker,
      attachmentStorage: _attachmentStorage,
      exportPackageWriter: exportPackageWriter,
      asOf: DateTime(2026, 8, 18),
    );
  }

  Future<void> seedSetup() async {
    await repository.saveLocalAccount(
      LocalAccountProfile(
        id: 'account-1',
        displayName: 'Local Auditor',
        emailOrStudentId: 'auditor@example.test',
        createdAt: DateTime(2026, 8, 18, 9),
        isCredentialConfigured: true,
      ),
    );
    await repository.saveOrganization(
      const OrganizationProfile(
        id: 'org-1',
        name: 'Junior Philippine Institute of Accountants',
        type: 'Academic',
        adviser: 'Prof. Santos',
        semester: '1st Semester',
        schoolYear: '2026-2027',
        signatoryNames: ['Ari Santos', 'Bea Reyes'],
      ),
    );
  }

  Future<void> seedDashboardData() async {
    await repository.saveTreasuryFundSource(
      const TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.studentCollections,
        label: 'Student Collections',
        balance: Money.centavos(2284500),
        supportingAttachment: _attachment,
      ),
    );
    await repository.saveAuditEvent(
      event: AuditEvent(
        id: 'event-1',
        name: 'Leadership Summit',
        type: 'Leadership',
        semester: '1st Semester',
        schoolYear: '2026-2027',
        startDate: DateTime(2026, 8, 8),
        endDate: DateTime(2026, 8, 9),
        resolutionNumber: 'RES-2026-001',
        budget: Money.php(22000),
        approvedBudgetBalance: Money.php(22000),
        resolutionAttachment: _attachment,
      ),
      allocations: [
        EventFundingAllocation(
          eventId: 'event-1',
          fundSourceId: 'source-1',
          amount: Money.php(22000),
        ),
      ],
    );
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'movement-1',
        reference: 'FM-20260818-4F2A91C0',
        type: FundMovementType.budgetAllocation,
        date: DateTime(2026, 8, 18),
        amount: Money.php(22000),
        purpose: 'Budget allocation: Leadership Summit',
        isSystemGenerated: true,
      ),
    );
  }

  Future<void> seedTreasurySource({required Money balance}) {
    return repository.updateTreasuryFundSource(
      TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.studentCollections,
        label: 'Student Collections',
        balance: balance,
        supportingAttachment: _attachment,
      ),
    );
  }

  Future<void> seedOfficer() {
    return repository.saveOfficers([
      const Officer(
        id: 'officer-1',
        fullName: 'Ari Santos',
        position: OfficerPosition.member,
        committee: Committee.finance,
      ),
    ]);
  }

  Future<void> seedCompletedEvent({
    Money approvedBudgetBalance = const Money.centavos(100000),
    bool isLiquidated = false,
  }) async {
    await seedTreasurySource(balance: Money.php(5000));
    await repository.saveAuditEvent(
      event: AuditEvent(
        id: 'event-1',
        name: 'Leadership Summit',
        type: 'Leadership',
        semester: '1st Semester',
        schoolYear: '2026-2027',
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 16),
        resolutionNumber: 'RES-2026-001',
        budget: Money.php(1000),
        approvedBudgetBalance: approvedBudgetBalance,
        resolutionAttachment: _attachment,
        isLiquidated: isLiquidated,
      ),
      allocations: const [
        EventFundingAllocation(
          eventId: 'event-1',
          fundSourceId: 'source-1',
          amount: Money.centavos(100000),
        ),
      ],
    );
  }

  Future<void> seedOutOfPocketClaim() async {
    await repository.saveLiquidationReceipt(
      LiquidationReceipt(
        id: 'receipt-1',
        eventId: 'event-1',
        payeeOrMerchant: 'Campus Canteen',
        date: DateTime(2026, 8, 18),
        evidenceNumber: 'OR-100',
        receiptType: ReceiptType.officialReceipt,
        fundingMode: FundingMode.outOfPocket,
        accountableOfficerId: 'officer-1',
        attachment: _attachment,
      ),
    );
    await repository.saveLiquidationLine(
      const LiquidationLine(
        id: 'line-1',
        receiptId: 'receipt-1',
        description: 'Meals',
        quantity: 2,
        unitCost: Money.centavos(10000),
      ),
    );
    await repository.saveReimbursementClaim(
      const ReimbursementClaim(
        id: 'claim-1',
        eventId: 'event-1',
        officerId: 'officer-1',
        amount: Money.centavos(20000),
        status: ReimbursementStatus.pending,
        sourceLiquidationLineId: 'line-1',
      ),
    );
  }

  Future<void> seedReleasedFundsLiquidation() async {
    await repository.saveLiquidationReceipt(
      LiquidationReceipt(
        id: 'receipt-1',
        eventId: 'event-1',
        payeeOrMerchant: 'Campus Canteen',
        date: DateTime(2026, 8, 18),
        evidenceNumber: 'OR-100',
        receiptType: ReceiptType.officialReceipt,
        fundingMode: FundingMode.releasedFunds,
        accountableOfficerId: 'officer-1',
        attachment: _attachment,
      ),
    );
    await repository.saveLiquidationLine(
      const LiquidationLine(
        id: 'line-1',
        receiptId: 'receipt-1',
        description: 'Meals',
        quantity: 2,
        unitCost: Money.centavos(10000),
      ),
    );
  }

  Future<void> seedExportWorkspace() async {
    await seedOfficer();
    await seedCompletedEvent(isLiquidated: true);
    await repository.saveFundMovement(
      movement: FundMovement(
        id: 'movement-export-1',
        reference: 'FM-20260818-EXPORT',
        type: FundMovementType.budgetAllocation,
        date: DateTime(2026, 8, 18),
        amount: Money.php(1000),
        purpose: 'Budget allocation: Leadership Summit',
        eventId: 'event-1',
        isSystemGenerated: true,
      ),
    );
    await repository.saveLiquidationReceipt(
      LiquidationReceipt(
        id: 'receipt-export-1',
        eventId: 'event-1',
        payeeOrMerchant: 'Campus Canteen',
        date: DateTime(2026, 8, 18),
        evidenceNumber: 'OR-100',
        receiptType: ReceiptType.officialReceipt,
        fundingMode: FundingMode.releasedFunds,
        accountableOfficerId: 'officer-1',
        attachment: _attachment,
      ),
    );
    await repository.saveLiquidationLine(
      const LiquidationLine(
        id: 'line-export-1',
        receiptId: 'receipt-export-1',
        description: 'Meals',
        quantity: 2,
        unitCost: Money.centavos(10000),
      ),
    );
    await repository.saveReimbursementClaim(
      const ReimbursementClaim(
        id: 'claim-export-1',
        eventId: 'event-1',
        officerId: 'officer-1',
        amount: Money.centavos(20000),
        status: ReimbursementStatus.paid,
        sourceLiquidationLineId: 'line-export-1',
      ),
    );
    await repository.saveAuditorReview(
      AuditorReviewSnapshot(
        id: 'review-export-1',
        eventId: 'event-1',
        findings: 'Spending stayed within budget.',
        cause: 'Approved expenses matched liquidation.',
        recommendation: 'Retain receipts with the export package.',
        budget: Money.php(1000),
        actual: Money.php(200),
        variance: Money.php(800),
        utilizationBasisPoints: 2000,
        health: BudgetHealth.healthy,
        createdAt: DateTime(2026, 8, 18, 13),
      ),
    );
    await repository.appendAuditLog(
      AuditLogEntry(
        id: 'audit-log-export-1',
        action: 'export.seed',
        actor: 'local-account',
        targetRecordId: 'event-1',
        occurredAt: DateTime(2026, 8, 18),
        amount: Money.php(1000),
        reference: 'RES-2026-001',
      ),
    );
  }

  Future<void> close() => database.close();
}

class _DeterministicIdGenerator implements StableIdGenerator {
  var _counter = 0;

  @override
  StableId nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }
}

class _FakeAttachmentPicker implements AttachmentPicker {
  var _counter = 0;

  @override
  Future<PickedAttachment?> pickAttachment() async {
    _counter += 1;
    return PickedAttachment(
      fileName: 'selected-$_counter.pdf',
      bytes: Uint8List.fromList([_counter]),
    );
  }
}

class _FakeAttachmentStorageService implements AttachmentStorageService {
  var _counter = 0;

  @override
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  }) async {
    _counter += 1;
    final id = 'attachment-import-$_counter';
    final size = attachment.bytes?.length ?? 0;
    return AttachmentRef(
      id: id,
      fileName: attachment.fileName,
      localPath: 'attachments/${owner.module}/$id-${attachment.fileName}',
      sizeBytes: size,
      checksum: 'checksum-$_counter',
    );
  }

  @override
  Future<bool> exists(AttachmentRef attachment) async => true;

  @override
  Future<String> resolveLocalPath(AttachmentRef attachment) async {
    return attachment.localPath;
  }

  @override
  Future<Uint8List> readBytes(AttachmentRef attachment) async {
    return Uint8List.fromList(attachment.localPath.codeUnits);
  }

  @override
  Future<AttachmentIntegrityResult> verify(AttachmentRef attachment) async {
    return AttachmentIntegrityResult.present(
      checksumMatches: true,
      sizeMatches: true,
      actualChecksum: attachment.checksum ?? 'checksum',
      actualSizeBytes: attachment.sizeBytes ?? 0,
    );
  }
}

class _FailingAttachmentStorageService extends _FakeAttachmentStorageService {
  @override
  Future<AttachmentRef> importAttachment({
    required PickedAttachment attachment,
    required AttachmentOwner owner,
  }) {
    throw StateError('simulated import failure');
  }
}

class _FakeExportPackageWriter implements ExportPackageWriter {
  ExportArchivePackage? savedPackage;

  @override
  Future<ExportWriteResult> save(ExportArchivePackage package) async {
    savedPackage = package;
    return ExportWriteResult(
      fileName: package.fileName,
      bytes: package.bytes,
      byteLength: package.byteLength,
      checksum: package.checksum,
      destinationUri: Uri.parse('file:///tmp/${package.fileName}'),
    );
  }
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'support.pdf',
  localPath: 'attachments/support.pdf',
);
