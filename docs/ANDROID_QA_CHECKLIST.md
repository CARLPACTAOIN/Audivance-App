# Audivance Android QA Checklist

Use this checklist before sharing a build with stakeholders. Record the APK/AAB path, app version, device model, Android version, and tester name in the test notes.

## Build Identity

- App label shows `Audivance`.
- Launcher icon is the Audivance logo and is not clipped on the launcher.
- Native splash shows the Audivance logo on a light background.
- Android application ID is `com.audivance.app`.
- Version name and version code match `pubspec.yaml`.
- Release signing uses `android/key.properties`; debug signing is acceptable only for local QA.
- `android:allowBackup` remains `false` because secure storage and the encrypted database key must not be separated by Android Auto Backup.

## Install And Startup

- Fresh install opens the first-launch setup screen.
- Setup rejects empty required fields.
- Setup rejects mismatched or short PINs.
- Successful setup opens Dashboard.
- Force-close and reopen routes to Unlock before Dashboard.
- Wrong PIN shows a visible error and does not open the workspace.
- Correct PIN unlocks and loads Dashboard.
- Existing pre-secure/plaintext workspace routes to Secure Workspace and upgrades cleanly.
- Startup database/cipher/key failures show the release error screen with Retry and support guidance.

## Android Storage And File Actions

- Treasury Add Fund can select a local attachment through the Android file picker.
- Event creation can select a resolution attachment.
- Liquidation receipt can select a receipt attachment.
- Long file names wrap or truncate without overflow on a 375px-wide phone.
- Attachment import failure shows an inline error and allows retry.
- Generate Backup opens the Android save dialog and records success, cancel, or failure.
- Validate Backup opens the Android picker and reports valid/invalid backup status.
- Restore requires typing `RESTORE` and reopens the encrypted workspace after success.

## Export Center

- Export Center loads readiness, record counts, attachment inventory, report paths, and history.
- Generate ZIP with no same-day backup shows the reminder dialog.
- Reminder Cancel closes without creating export history.
- Reminder Continue Export records an overridden reminder state.
- Reminder Generate Backup records backup history and continues export only after save succeeds.
- Readiness blockers prevent ZIP generation.
- Warnings remain visible but do not block ZIP generation.
- Successful ZIP includes manifest, README, JSON, CSV, PDF reports, and attachments.
- Export history records success, cancel, failure, checksum, byte length, destination URI, and readiness issue counts.

## Core Workflow Smoke Test

- Profile renders setup organization data.
- Profile can edit organization metadata and add/archive/restore officers.
- Treasury Add Fund updates source balance and ledger.
- Manual transfer rejects insufficient balance.
- Event creation validates split funding and updates Dashboard approved budget.
- Budget adjustment requires remarks and updates event/source balances.
- Liquidation creates receipt lines and pending reimbursement claims where applicable.
- Reimbursement payment updates claim status and Dashboard approved budget.
- Mark Liquidated changes event status only after liquidation requirements are met.

## Layout And Accessibility

- Test at 375px phone width in portrait.
- Test a large phone in portrait and landscape.
- Test a tablet-width viewport or device.
- Bottom navigation remains visible and tappable.
- Dialog action rows stay visible above the keyboard.
- Money, references, long organization names, officer names, and checksums do not overflow.
- Touch targets are at least 48dp on Android.
- Important states use visible text, not color alone.
- TalkBack can identify icon buttons such as settings, export actions, backup actions, and file selectors.

## Verification Commands

Run from the repository root:

```powershell
flutter pub get
dart format lib test
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

For Play Store packaging, also run:

```powershell
flutter build appbundle --release
```

