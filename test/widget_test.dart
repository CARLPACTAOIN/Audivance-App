import 'dart:convert';
import 'dart:io';
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
import 'package:audivance/core/storage/audit_storage_paths.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/audit_database_encryption_service.dart';
import 'package:audivance/features/audit/data/audit_repository.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/backup/backup_package_io.dart';
import 'package:audivance/features/backup/backup_service.dart';
import 'package:audivance/features/events/event_service.dart';
import 'package:audivance/features/export/export_package_writer.dart';
import 'package:audivance/features/export/export_service.dart';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
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

  testWidgets('startup failure shows retryable Android storage guidance', (
    tester,
  ) async {
    final repository = _ThrowingStartupRepository(
      const EncryptedDatabaseOpenException(
        'SQLite encryption support is not available in this build.',
      ),
    );

    await tester.pumpWidget(
      AudivanceApp(
        repository: repository,
        unlockService: InMemoryLocalUnlockService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Audivance could not open the local workspace'),
      findsOneWidget,
    );
    expect(
      find.textContaining('This Android build does not include'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.setupChecks, 2);
    expect(
      find.text('Audivance could not open the local workspace'),
      findsOneWidget,
    );
  });

  testWidgets('first launch shows setup screen', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setupBrandLogo')), findsOneWidget);
    expect(find.text('Audivance'), findsWidgets);
    expect(find.text('Your offline audit workspace.'), findsOneWidget);
    expect(find.byKey(const Key('setupGetStartedButton')), findsOneWidget);
  });

  testWidgets('setup form rejects empty required fields', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('setupGetStartedButton')));
    await tester.tap(find.byKey(const Key('setupGetStartedButton')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('setupContinueToOrgButton')),
    );
    await tester.tap(find.byKey(const Key('setupContinueToOrgButton')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
  });

  testWidgets(
    'setup form clears field error on interaction while preserving errors on other fields',
    (tester) async {
      final harness = _WidgetHarness();
      addTearDown(harness.close);

      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('setupGetStartedButton')),
      );
      await tester.tap(find.byKey(const Key('setupGetStartedButton')));
      await tester.pumpAndSettle();

      // Submit with empty fields to trigger validation errors
      await tester.ensureVisible(
        find.byKey(const Key('setupContinueToOrgButton')),
      );
      await tester.tap(find.byKey(const Key('setupContinueToOrgButton')));
      await tester.pumpAndSettle();

      // Initial validation state: multiple fields show 'This field is required.' (4 fields in step 1)
      expect(find.text('This field is required.'), findsNWidgets(4));

      // Tap / focus the first field (setupDisplayNameField)
      await tester.tap(find.byKey(const Key('setupDisplayNameField')));
      await tester.pumpAndSettle();

      // The focused field's error clears immediately, while the other 3 fields still show errors
      expect(find.text('This field is required.'), findsNWidgets(3));

      // Type text into setupDisplayNameField
      await tester.enterText(
        find.byKey(const Key('setupDisplayNameField')),
        'Auditor Name',
      );
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsNWidgets(3));

      // Tap into the second field (setupEmailOrStudentIdField)
      await tester.tap(find.byKey(const Key('setupEmailOrStudentIdField')));
      await tester.pumpAndSettle();

      // Now only 2 fields remain with errors
      expect(find.text('This field is required.'), findsNWidgets(2));
    },
  );

  testWidgets('setup form dismisses active field focus on submit', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('setupGetStartedButton')));
    await tester.tap(find.byKey(const Key('setupGetStartedButton')));
    await tester.pumpAndSettle();

    // Focus and enter text in account name
    await tester.tap(find.byKey(const Key('setupDisplayNameField')));
    await tester.pumpAndSettle();
    expect(
      FocusScope.of(
        tester.element(find.byKey(const Key('setupDisplayNameField'))),
      ).hasFocus,
      isTrue,
    );

    // Tap submit button
    await tester.ensureVisible(
      find.byKey(const Key('setupContinueToOrgButton')),
    );
    await tester.tap(find.byKey(const Key('setupContinueToOrgButton')));
    await tester.pumpAndSettle();

    // Focus is removed from the input field
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isTextFieldFocused =
        primaryFocus?.context?.widget is EditableText ||
        primaryFocus?.context?.widget is TextField;
    expect(isTextFieldFocused, isFalse);
  });

  testWidgets('setup form rejects mismatched PIN confirmation', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('setupGetStartedButton')));
    await tester.tap(find.byKey(const Key('setupGetStartedButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('setupDisplayNameField')),
      'Local Auditor',
    );
    await tester.enterText(
      find.byKey(const Key('setupEmailOrStudentIdField')),
      'auditor@example.test',
    );
    await tester.enterText(find.byKey(const Key('setupPinField')), '123456');
    await tester.enterText(
      find.byKey(const Key('setupPinConfirmationField')),
      '567890',
    );

    await tester.ensureVisible(
      find.byKey(const Key('setupContinueToOrgButton')),
    );
    await tester.tap(find.byKey(const Key('setupContinueToOrgButton')));
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
    expect(find.byKey(const Key('dashboardBrandLogo')), findsNothing);
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
    expect(find.byKey(const Key('dashboardBrandLogo')), findsNothing);
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
    await tester.scrollUntilVisible(
      find.text('COA Export Readiness'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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

  testWidgets('Profile workspace renders setup organization data', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openProfile(tester);

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Officer Roster'), findsOneWidget);
    expect(find.byKey(const Key('profileOrganizationName')), findsOneWidget);
    expect(find.text('Prof. Santos'), findsOneWidget);
    expect(find.text('Needs officers'), findsOneWidget);
  });

  testWidgets('Profile organization edit validates and saves updates', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openProfile(tester);
    await tester.tap(find.byKey(const Key('profileEditOrganizationButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profileOrganizationNameField')),
      '',
    );
    await tester.enterText(
      find.byKey(const Key('profileSignatoriesField')),
      '',
    );
    await tester.tap(find.byKey(const Key('profileOrganizationSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    expect(
      find.text('Fix the highlighted fields before saving.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('profileOrganizationNameField')),
      'Updated Accounting Guild',
    );
    await tester.enterText(
      find.byKey(const Key('profileSignatoriesField')),
      'Ari Santos, Bea Reyes, Cia Lim',
    );
    await tester.tap(find.byKey(const Key('profileOrganizationSubmitButton')));
    await tester.pumpAndSettle();

    final organization = (await harness.repository.listOrganizations()).single;
    expect(find.text('Updated Accounting Guild'), findsOneWidget);
    expect(organization.signatoryNames, ['Ari Santos', 'Bea Reyes', 'Cia Lim']);
    expect(
      (await harness.repository.listAuditLogs()).map((log) => log.action),
      contains('organization.update'),
    );
  });

  testWidgets('Profile adds officers and rejects duplicate committee heads', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openProfile(tester);
    await _tapVisible(tester, find.byKey(const Key('profileAddOfficerButton')));
    await tester.pumpAndSettle();
    await _fillProfileOfficerForm(
      tester,
      name: 'Ari Santos',
      position: OfficerPosition.head,
      committee: Committee.finance,
    );
    await tester.tap(find.byKey(const Key('profileOfficerSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Ari Santos'), findsOneWidget);
    expect(find.text('Finance Committee'), findsWidgets);

    await _tapVisible(tester, find.byKey(const Key('profileAddOfficerButton')));
    await tester.pumpAndSettle();
    await _fillProfileOfficerForm(
      tester,
      name: 'Bea Reyes',
      position: OfficerPosition.head,
      committee: Committee.finance,
    );
    await tester.tap(find.byKey(const Key('profileOfficerSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Only one active head'), findsOneWidget);
    expect((await harness.repository.listOfficers()), hasLength(1));
  });

  testWidgets('Profile archives and restores officers with visible status', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedOfficer();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openProfile(tester);
    await _tapVisible(
      tester,
      find.byKey(const Key('profileOfficerArchiveofficer-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profileArchiveConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('0 active'), findsOneWidget);
    expect(find.text('1 archived'), findsOneWidget);
    expect(find.text('Archived Officers'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const Key('profileArchivedOfficersTile')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsWidgets);
    await _tapVisible(
      tester,
      find.byKey(const Key('profileOfficerRestoreofficer-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profileRestoreConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.text('1 active'), findsOneWidget);
    expect(find.text('0 archived'), findsOneWidget);
  });

  testWidgets('archived officers are not available for new liquidation', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedCompletedEvent();
    await harness.repository.saveOfficers(const [
      Officer(
        id: 'officer-archived',
        fullName: 'Archived Treasurer',
        position: OfficerPosition.member,
        committee: Committee.finance,
        isArchived: true,
      ),
    ]);
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openEvents(tester);
    await _openEventDetails(tester, 'event-1');

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('eventLiquidationButtonevent-1')),
    );
    expect(find.text('Archived Treasurer'), findsNothing);
    expect(button.onPressed, isNull);
  });

  testWidgets('Profile handles long labels at 375px width', (tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup(
      organizationName: 'Junior Philippine Institute of Accountants With Extended Regional Chapter Name',
    );
    await harness.repository.saveOfficers(const [
      Officer(
        id: 'officer-long',
        fullName:
            'Ari Santos Bea Reyes Cia Lim Dan Cruz Long Officer Display Name',
        position: OfficerPosition.head,
        committee: Committee.audit,
      ),
    ]);
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openProfile(tester);

    expect(find.textContaining('Junior Philippine'), findsOneWidget);
    expect(
      find.byKey(const Key('profileOfficerNameofficer-long')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings opens Backup & Restore panel', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openBackup(tester);

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.textContaining('encrypted SQLite database'), findsOneWidget);
    expect(find.textContaining('same local secure credential'), findsOneWidget);
    expect(find.byKey(const Key('backupGenerateButton')), findsOneWidget);
    expect(find.byKey(const Key('backupValidateButton')), findsOneWidget);
    expect(find.byKey(const Key('backupRestoreButton')), findsOneWidget);
  });

  testWidgets('Backup dialog renders recent backup history', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedSameDayBackupHistory();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openBackup(tester);

    expect(find.text('Recent Backup History'), findsOneWidget);
    expect(find.text('Saved backup'), findsOneWidget);
    expect(find.text('Audivance-Backup-2026-08-18.zip'), findsOneWidget);
  });

  testWidgets('invalid backup validation shows blockers and disables restore', (
    tester,
  ) async {
    final harness = _WidgetHarness(
      backupPackageReader: _FakeBackupPackageReader(
        PickedBackupPackage(
          fileName: 'broken.zip',
          bytes: Uint8List.fromList('not-a-zip'.codeUnits),
        ),
      ),
    );
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openBackup(tester);
    await tester.tap(find.byKey(const Key('backupValidateButton')));
    await tester.pumpAndSettle();

    expect(find.text('Backup Has Problems'), findsOneWidget);
    expect(find.textContaining('not a readable ZIP archive'), findsOneWidget);
    final restoreButton = tester.widget<FilledButton>(
      find.byKey(const Key('backupRestoreButton')),
    );
    expect(restoreButton.onPressed, isNull);
  });

  testWidgets('valid backup restore requires typed confirmation', (
    tester,
  ) async {
    final backup = await _buildPickedBackup();
    var restoreCalls = 0;
    final harness = _WidgetHarness(
      backupPackageReader: _FakeBackupPackageReader(backup),
      backupRestoreHandler: (package) async {
        restoreCalls += 1;
        final service = BackupService(
          storagePaths: AuditStoragePaths(
            supportDirectoryProvider: () async => Directory.systemTemp,
          ),
        );
        final validation = await service.validateBackup(package.bytes);
        return RestoreExecutionResult.success(validation);
      },
    );
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openBackup(tester);
    await tester.tap(find.byKey(const Key('backupValidateButton')));
    await tester.pumpAndSettle();

    expect(find.text('Backup Is Valid'), findsOneWidget);
    expect(
      find.textContaining('is ready for same-device restore'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('backupRestoreButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Confirm Restore'), findsOneWidget);
    var confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('backupRestoreConfirmButton')),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('backupRestoreConfirmationField')),
      'RESTORE',
    );
    await tester.pump();
    confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('backupRestoreConfirmButton')),
    );
    expect(confirmButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('backupRestoreConfirmButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(restoreCalls, 1);
    expect(find.text('Restore complete'), findsOneWidget);
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
    expect(find.text('Select a supporting attachment.'), findsOneWidget);
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
      find.byKey(const Key('addFundAmountField')),
      '12845.50',
    );
    await tester.tap(find.byKey(const Key('addFundAttachmentSelectButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addFundSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fund from previous admin'), findsWidgets);
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
    await harness.seedOfficer();
    await harness.seedCompletedEvent(approvedBudgetBalance: Money.php(100));
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
    expect(find.text('Enter a valid PHP amount.'), findsOneWidget);
  });

  testWidgets(
    'Create Event derives total budget from source allocations and validates source balance',
    (tester) async {
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

      await _fillEventForm(tester, allocationAmount: '6000');
      await tester.tap(find.byKey(const Key('eventCreateSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('insufficient balance'), findsOneWidget);
    },
  );

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

  testWidgets(
    'Create Event allows selecting Project, Program, or Activity as event type',
    (tester) async {
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

      await _fillEventForm(tester, type: 'Activity');
      await tester.tap(find.byKey(const Key('eventCreateSubmitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Leadership Summit'), findsOneWidget);
      expect(find.textContaining('Activity'), findsWidgets);
    },
  );

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

  testWidgets(
    'tapping Manage Event opens Event Details screen and navigates back',
    (tester) async {
      final harness = _WidgetHarness();
      addTearDown(harness.close);
      await harness.seedSetup();
      await harness.seedCompletedEvent();
      await harness.unlockService.configurePin('123456');

      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await _openEvents(tester);

      expect(find.text('Event Records'), findsOneWidget);
      expect(find.byKey(const Key('eventManageButtonevent-1')), findsOneWidget);

      await _openEventDetails(tester, 'event-1');
      expect(find.text('Event Financials'), findsOneWidget);
      expect(find.text('Financial Summary'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Liquidation Receipts'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Liquidation Receipts'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Reimbursements'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reimbursements'), findsOneWidget);

      await tester.tap(find.byKey(const Key('eventDetailsBackButton')));
      await tester.pumpAndSettle();

      expect(find.text('Event Records'), findsOneWidget);
    },
  );

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
    await _openEventDetails(tester, 'event-1');

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

      await tester.tap(find.byKey(const Key('eventDetailsBackButton')));
      await tester.pumpAndSettle();

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

    await tester.tap(find.byKey(const Key('eventDetailsBackButton')));
    await tester.pumpAndSettle();

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
    await _openEventDetails(tester, 'event-1');

    expect(find.text('Liquidated'), findsWidgets);
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
    expect(find.text('20.00%'), findsWidgets);
    expect(find.text('Healthy'), findsWidgets);
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
      expect(find.textContaining('Pending'), findsWidgets);
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
      await _openEventDetails(tester, 'event-1');
      final payButton = find.byKey(const Key('reimbursementPayButtonclaim-1'));
      await tester.scrollUntilVisible(
        payButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(payButton),
        alignment: 0.35,
      );
      await tester.pumpAndSettle();
      await tester.tap(payButton);
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

      await tester.tap(find.byKey(const Key('eventDetailsBackButton')));
      await tester.pumpAndSettle();

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
    await _openEventDetails(tester, 'event-1');
    await tester.scrollUntilVisible(
      find.byKey(const Key('eventMarkLiquidatedButtonevent-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('eventMarkLiquidatedButtonevent-1')));
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
    expect(find.byKey(const Key('exportGenerateZipButton')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('COA Export Readiness'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('COA Export Readiness'), findsOneWidget);
  });

  testWidgets('empty Export Center shows readiness issues', (tester) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.unlockService.configurePin('123456');

    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await _openExport(tester);

    await tester.scrollUntilVisible(
      find.text('Readiness Issues'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Readiness Issues'), findsOneWidget);
    await tester.tap(find.text('Readiness Issues'));
    await tester.pumpAndSettle();
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

  testWidgets('Export Center expandable panels default to minimized', (
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

    await tester.scrollUntilVisible(
      find.text('Record Counts'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Record Counts'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Package Structure'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Package Structure'), findsOneWidget);
    expect(find.text('manifest.json'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('USM-OSA-F46 Liquidation Reports'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('USM-OSA-F46 Liquidation Reports'), findsOneWidget);
    expect(find.text('USM-OSA-F46 Liquidation Report'), findsNothing);
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
      await tester.tap(find.text('Record Counts'));
      await tester.pumpAndSettle();
      expect(find.text('Events'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Package Structure'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Package Structure'), findsOneWidget);
      await tester.tap(find.text('Package Structure'));
      await tester.pumpAndSettle();
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

  testWidgets('Export Center labels liquidation PDFs as USM-OSA-F46 reports', (
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

    await tester.scrollUntilVisible(
      find.text('USM-OSA-F46 Liquidation Reports'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('USM-OSA-F46 Liquidation Reports'), findsOneWidget);
    await tester.tap(find.text('USM-OSA-F46 Liquidation Reports'));
    await tester.pumpAndSettle();
    expect(find.text('USM-OSA-F46 Liquidation Report'), findsOneWidget);
    expect(
      find.text('reports/liquidation/Leadership-Summit-event-1.pdf'),
      findsWidgets,
    );
    expect(
      find.byKey(
        const Key(
          'liquidationPdfSaveButtonreports/liquidation/Leadership-Summit-event-1.pdf',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'liquidationPdfShareButtonreports/liquidation/Leadership-Summit-event-1.pdf',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key(
          'liquidationPdfPrintButtonreports/liquidation/Leadership-Summit-event-1.pdf',
        ),
      ),
      findsOneWidget,
    );
  });

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
    await tester.tap(find.text('Generated Preview'));
    await tester.pumpAndSettle();
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
    await tester.tap(
      find.byKey(const Key('exportBackupReminderContinueButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('ZIP Export Blocked'), findsOneWidget);
    expect(
      find.textContaining(
        'Export ZIP cannot be generated until blockers are resolved.',
      ),
      findsWidgets,
    );
  });

  testWidgets('Generate ZIP with no same-day backup shows reminder dialog', (
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

    expect(find.text('Backup recommended before export'), findsOneWidget);
    expect(find.text('Same-day backup not found'), findsOneWidget);
    expect(
      find.byKey(const Key('exportBackupReminderGenerateButton')),
      findsOneWidget,
    );
  });

  testWidgets('backup reminder cancel closes without export history', (
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
    await tester.tap(find.byKey(const Key('exportBackupReminderCancelButton')));
    await tester.pumpAndSettle();

    expect(find.text('Backup recommended before export'), findsNothing);
    expect(harness.exportPackageWriter.savedPackage, isNull);
    expect(await harness.repository.listExportHistory(), isEmpty);
  });

  testWidgets('Continue Export records backup reminder override', (
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
    await tester.tap(
      find.byKey(const Key('exportBackupReminderContinueButton')),
    );
    await tester.pumpAndSettle();

    final history = await harness.repository.listExportHistory();
    expect(find.text('Generated ZIP'), findsOneWidget);
    expect(harness.exportPackageWriter.savedPackage?.bytes, isNotEmpty);
    expect(
      history.single.backupReminderStatus,
      BackupReminderStatus.overridden,
    );
    expect(history.single.sameDayBackupFound, isFalse);
    await tester.scrollUntilVisible(
      find.text('Backup reminder overridden'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Backup reminder overridden'), findsOneWidget);
  });

  testWidgets(
    'Generate Backup from reminder records backup and continues export',
    (tester) async {
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
      await tester.tap(
        find.byKey(const Key('exportBackupReminderGenerateButton')),
      );
      await tester.pumpAndSettle();

      final backupHistory = await harness.repository.listBackupHistory();
      final exportHistory = await harness.repository.listExportHistory();
      expect(find.text('Generated ZIP'), findsOneWidget);
      expect(harness.backupPackageWriter.savedPackage, isNotNull);
      expect(backupHistory.single.status, BackupHistoryStatus.success);
      expect(
        exportHistory.single.backupReminderStatus,
        BackupReminderStatus.satisfied,
      );
      expect(exportHistory.single.sameDayBackupFound, isTrue);
    },
  );

  testWidgets('successful ZIP generation shows package metadata', (
    tester,
  ) async {
    final harness = _WidgetHarness();
    addTearDown(harness.close);
    await harness.seedSetup();
    await harness.seedExportWorkspace();
    await harness.seedSameDayBackupHistory();
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
  if (find.byKey(const Key('setupGetStartedButton')).evaluate().isNotEmpty) {
    await tester.ensureVisible(find.byKey(const Key('setupGetStartedButton')));
    await tester.tap(find.byKey(const Key('setupGetStartedButton')));
    await tester.pumpAndSettle();
  }

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

  await tester.ensureVisible(find.byKey(const Key('setupContinueToOrgButton')));
  await tester.tap(find.byKey(const Key('setupContinueToOrgButton')));
  await tester.pumpAndSettle();

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

Future<void> _openProfile(WidgetTester tester) async {
  final directProfile = find.text('Profile');
  if (directProfile.evaluate().isNotEmpty) {
    await tester.tap(directProfile.last);
    await tester.pumpAndSettle();
    return;
  }
  await tester.tap(find.byKey(const Key('workspaceSettingsButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('adminMenuProfileTile')));
  await tester.pumpAndSettle();
}

Future<void> _openBackup(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('workspaceSettingsButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('adminMenuBackupTile')));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _fillProfileOfficerForm(
  WidgetTester tester, {
  required String name,
  required OfficerPosition position,
  Committee? committee,
}) async {
  await tester.enterText(
    find.byKey(const Key('profileOfficerNameField')),
    name,
  );
  await tester.tap(find.byKey(const Key('profileOfficerPositionField')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(position == OfficerPosition.head ? 'Head' : 'Member').last,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('profileOfficerCommitteeField')));
  await tester.pumpAndSettle();
  final committeeLabel = switch (committee) {
    Committee.finance => 'Finance Committee',
    Committee.audit => 'Audit Committee',
    null => 'No committee',
  };
  await tester.tap(find.text(committeeLabel).last);
  await tester.pumpAndSettle();
}

Future<void> _fillEventForm(
  WidgetTester tester, {
  String type = 'Project',
  String allocationAmount = '4000',
}) async {
  await _enterTextByKey(
    tester,
    const Key('eventNameField'),
    'Leadership Summit',
  );
  if (type != 'Project') {
    await tester.tap(find.byKey(const Key('eventTypeField')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('eventTypeOption$type')).last);
    await tester.pumpAndSettle();
  }
  await _enterTextByKey(tester, const Key('eventStartDateField'), '2026-08-20');
  await _enterTextByKey(tester, const Key('eventEndDateField'), '2026-08-21');
  await _enterTextByKey(
    tester,
    const Key('eventResolutionNumberField'),
    'RES-2026-001',
  );
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

Future<void> _openEventDetails(WidgetTester tester, String eventId) async {
  final manageButton = find.byKey(Key('eventManageButton$eventId'));
  if (manageButton.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      manageButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(manageButton);
    await tester.pumpAndSettle();
  } else {
    final card = find.byKey(Key('eventCard$eventId'));
    if (card.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _openLiquidationDialog(
  WidgetTester tester, {
  String eventId = 'event-1',
}) async {
  await _openEventDetails(tester, eventId);
  final button = find.byKey(Key('eventLiquidationButton$eventId'));
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

Future<void> _openBudgetAdjustmentDialog(
  WidgetTester tester, {
  String eventId = 'event-1',
}) async {
  await _openEventDetails(tester, eventId);
  final button = find.byKey(Key('eventAdjustBudgetButton$eventId'));
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

Future<void> _openBudgetReviewDialog(
  WidgetTester tester, {
  String eventId = 'event-1',
}) async {
  await _openEventDetails(tester, eventId);
  final button = find.byKey(Key('eventBudgetReviewButton$eventId'));
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

Future<PickedBackupPackage> _buildPickedBackup() async {
  final dbBytes = Uint8List.fromList(utf8.encode('widget-db'));
  final attachmentBytes = Uint8List.fromList(utf8.encode('widget-attachment'));
  final entries = [
    _backupManifestEntry(
      'database/audivance.sqlite',
      dbBytes,
      BackupArchiveEntrySource.database,
    ),
    _backupManifestEntry(
      'attachments/events/event-1/resolution.pdf',
      attachmentBytes,
      BackupArchiveEntrySource.attachment,
    ),
  ];
  final manifestBytes = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'type': 'audivance-backup',
        'appVersion': '1.0.0+1',
        'schemaVersion': AuditDatabase.currentSchemaVersion,
        'generatedAt': DateTime(2026, 8, 18, 10).toIso8601String(),
        'databaseName': 'audivance.sqlite',
        'databaseEncryption': 'encrypted-same-device-key',
        'restoreScope': 'same-device-secure-credential',
        'entries': entries,
      }),
    ),
  );
  final archive = Archive()
    ..addFile(ArchiveFile.bytes('backup_manifest.json', manifestBytes))
    ..addFile(ArchiveFile.bytes('database/audivance.sqlite', dbBytes))
    ..addFile(
      ArchiveFile.bytes(
        'attachments/events/event-1/resolution.pdf',
        attachmentBytes,
      ),
    );
  return PickedBackupPackage(
    fileName: 'Audivance-Backup-2026-08-18.zip',
    bytes: Uint8List.fromList(ZipEncoder().encodeBytes(archive)),
  );
}

Map<String, Object?> _backupManifestEntry(
  String path,
  Uint8List bytes,
  BackupArchiveEntrySource sourceType,
) {
  return {
    'path': path,
    'byteLength': bytes.length,
    'checksum': crypto.sha256.convert(bytes).toString(),
    'sourceType': sourceType.name,
  };
}

class _WidgetHarness {
  _WidgetHarness({
    AttachmentStorageService? attachmentStorage,
    this.backupPackageReader,
    this.backupRestoreHandler,
  }) : database = AuditDatabase(NativeDatabase.memory()),
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
  final BackupPackageReader? backupPackageReader;
  final BackupRestoreHandler? backupRestoreHandler;
  final exportPackageWriter = _FakeExportPackageWriter();
  final backupPackageWriter = _FakeBackupPackageWriter();
  final backupService = _FakeBackupService();

  Widget app() {
    return AudivanceApp(
      database: database,
      repository: repository,
      unlockService: unlockService,
      idGenerator: idGenerator,
      attachmentPicker: _attachmentPicker,
      attachmentStorage: _attachmentStorage,
      exportPackageWriter: exportPackageWriter,
      backupService: backupService,
      backupPackageWriter: backupPackageWriter,
      backupPackageReader: backupPackageReader,
      backupRestoreHandler: backupRestoreHandler,
      asOf: DateTime(2026, 8, 18),
    );
  }

  Future<void> seedSetup({
    String organizationName = 'Junior Philippine Institute of Accountants',
  }) async {
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
      OrganizationProfile(
        id: 'org-1',
        name: organizationName,
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

  Future<void> seedSameDayBackupHistory() {
    return repository.appendBackupHistory(
      BackupHistoryEntry(
        id: 'backup-history-1',
        fileName: 'Audivance-Backup-2026-08-18.zip',
        generatedAt: DateTime(2026, 8, 18, 9),
        byteLength: 3,
        checksum: 'backup-checksum',
        destinationUri: 'file:///tmp/Audivance-Backup-2026-08-18.zip',
        status: BackupHistoryStatus.success,
        createdAt: DateTime(2026, 8, 18, 9, 1),
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
    final relativePath = buildNormalizedAttachmentRelativePath(
      module: owner.module,
      id: id,
      originalFileName: attachment.fileName,
      purpose: owner.purpose,
      contextLabel: owner.resolvedContextLabel,
    );
    return AttachmentRef(
      id: id,
      fileName: attachment.fileName,
      localPath: relativePath,
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

class _FakeBackupPackageReader implements BackupPackageReader {
  const _FakeBackupPackageReader(this.package);

  final PickedBackupPackage package;

  @override
  Future<PickedBackupPackage?> pickBackup() async => package;
}

class _FakeBackupPackageWriter implements BackupPackageWriter {
  BackupPackage? savedPackage;
  var shouldCancel = false;

  @override
  Future<BackupWriteResult> save(BackupPackage package) async {
    savedPackage = package;
    return BackupWriteResult(
      fileName: package.fileName,
      bytes: package.bytes,
      byteLength: package.byteLength,
      checksum: package.checksum,
      destinationUri: shouldCancel
          ? null
          : Uri.parse('file:///tmp/${package.fileName}'),
    );
  }
}

class _FakeBackupService extends BackupService {
  _FakeBackupService() : super(storagePaths: const AuditStoragePaths());

  var shouldFail = false;

  @override
  Future<BackupPackage> buildBackup() async {
    if (shouldFail) {
      throw StateError('simulated backup failure');
    }
    final bytes = Uint8List.fromList([7, 8, 9]);
    return BackupPackage(
      fileName: 'Audivance-Backup-2026-08-18.zip',
      bytes: bytes,
      generatedAt: DateTime(2026, 8, 18, 10),
      checksum: 'backup-checksum',
      manifest: const {},
      entries: const [],
    );
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

class _ThrowingStartupRepository implements AuditRepository {
  _ThrowingStartupRepository(this.error);

  final Object error;
  var setupChecks = 0;

  @override
  Future<bool> isSetupComplete() async {
    setupChecks += 1;
    throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _attachment = AttachmentRef(
  id: 'attachment-1',
  fileName: 'support.pdf',
  localPath: 'attachments/support.pdf',
);
