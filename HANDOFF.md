# Audivance Handoff

Last updated: August 24, 2026

## Current Status

This repository is a Flutter project for the Audivance offline audit app. The default counter scaffold has been replaced with an Audivance app shell, first-launch setup, persistent secure local unlock, encrypted local SQLite storage, a repository-backed offline audit dashboard, Treasury and Events workspaces, persisted export/backup history, a pure Dart domain foundation, and a Drift + SQLite persistence foundation.

Completed setup work:

- Added project memory in `MEMORY.md`.
- Added agent/contributor rules in `AGENTS.md`.
- Added this handoff document.
- Installed the requested UI/UX skill locally at `.codex/skills/ui-ux-pro-max`.
- Replaced the default app with an Audivance dashboard shell.
- Added core domain primitives and audit rule services.
- Added Drift database schema, mappers, repository interface, repository implementation, database opener, and stable ID generator.
- Added local account persistence, setup-state checks, first-launch setup UI, app startup service, persistent secure PIN verification, credential-upgrade handling for older workspaces, and one-time plaintext-to-encrypted database migration.
- Added a dashboard application service that computes dashboard snapshots from persisted repository data.
- Added ready-state workspace navigation and the first Treasury workflow for source balances, Add Fund, manual movements, ledger rows, and audit logs.
- Added the first Events workflow for event records, resolution attachment metadata, split funding, budget-allocation movements, and audit logs.
- Added ledger-only Event budget adjustments with required remarks, source/event balance validation, protected Budget Adjustment movements, and audit logs.
- Added Event budget-vs-actual summaries, immutable auditor review snapshots, review history UI, and Export Center JSON/CSV entries for budget review data.
- Added app-private attachment import with file picking, SHA-256 checksums, reusable attachment selector UI, and Export Center attachment integrity readiness checks.
- Added real COA ZIP generation with manifest, README, JSON data files, CSV review tables, stored attachments, SHA-256 package checksums, and a save-file writer boundary.
- Added A4 PDF report generation for organization summary, Treasury ledger, budget-vs-actual, and per-event liquidation reports; liquidation reports now use a template-driven USM-OSA-F46 layout with the official USM logo asset and all PDF entries are packaged under `reports/` in COA ZIP exports.
- Added Backup & Restore foundation with app-support storage path sharing, local backup ZIP generation for encrypted SQLite database files plus app-private attachments, hardened backup manifest validation, staged same-device restore, active encrypted database close/reopen orchestration, typed restore confirmation, same-device/key-context backup labeling, and a Settings panel entry point.
- Added export/backup history persistence and application services; Export Center now reminds users to create a same-day backup before COA ZIP generation, records successful/canceled/failed export attempts, and Backup & Restore records backup save/cancel/failure attempts.
- Added Organization Profile and Officer Management workspace with editable organization metadata, active/archived officer roster management, committee-head validation, liquidation officer filtering, export readiness alignment, and audit logs for profile/officer mutations.
- Added the Audivance logo asset, padded icon/splash sources, launcher icon and native splash configs, platform icon/splash resources, and in-app `BrandLogo` usage.
- Added Android release-hardening configuration: package identity `com.audivance.app`, key-properties based release signing, git ignores for signing secrets, disabled Android Auto Backup policy confirmation, controlled startup storage/encryption failure UI, and `docs/ANDROID_QA_CHECKLIST.md`.
- Added a final MVP UX/edge-case polish pass for existing setup, unlock, dashboard, Treasury, Events/Liquidation, Export, Backup, and attachment flows, including shared state/dialog/status primitives, direct dashboard navigation actions, visible protected/system-generated labels, top form error summaries, and tighter phone-width wrapping.
- Added widget and domain unit tests.
- Added in-memory Drift repository tests.

## Important Files

- `OFFLINE_APPLICATION_PRD.md`: Product requirements and domain rules.
- `MEMORY.md`: Persistent project context and product invariants.
- `AGENTS.md`: Rules for future agents and contributors.
- `docs/ANDROID_QA_CHECKLIST.md`: Repeatable Android release and device QA checklist.
- `pubspec.yaml`: Flutter package manifest.
- `lib/main.dart`: App entry point.
- `lib/app/audivance_app.dart`: Material app shell and theme.
- `lib/app/app_startup_service.dart`: Startup routing state between setup, unlock, and dashboard.
- `lib/app/local_unlock_service.dart`: Secure credential storage, PIN verification, unlock session state, test fake, and database-key provider boundary.
- `lib/app/credential_upgrade_screen.dart`: PIN setup screen for existing pre-secure local workspaces.
- `lib/app/workspace_shell.dart`: Ready-state navigation shell for Dashboard, Treasury, Events, Export, and Profile.
- `lib/app/brand_logo.dart`: Reusable in-app Audivance logo widget.
- `lib/app/ui/app_ui.dart`: Shared responsive scaffold, loading/error state, inline status, dialog frame, metadata chip, and status badge primitives.
- `lib/core/storage/audit_storage_paths.dart`: Shared app-support storage paths for the SQLite database and attachments.
- `lib/features/backup/`: Backup service, backup history service, restore coordinator, backup package file picker boundaries, and Backup & Restore UI panel.
- `lib/features/dashboard/`: Repository-backed dashboard UI, snapshot models, demo fixture, and application service.
- `lib/features/treasury/`: Treasury service, formatting helpers, source-balance UI, Add Fund form, manual movement form, and ledger view.
- `lib/features/events/`: Events service, event list UI, create-event form, split-funding allocation UI, budget adjustments, liquidation actions, and budget-vs-actual review UI.
- `lib/features/organization/`: Organization profile service/UI and officer create/edit/archive/restore workflow.
- `lib/features/export/`: Export Center service, export history service, package preview, PDF report generation, real ZIP generation, save-file writer boundary, backup-before-export reminder UI, and Export Center UI.
- `lib/features/setup/`: First-launch local account and organization setup UI.
- `lib/core/attachments/`: File picker boundary, app-private attachment storage service, and reusable attachment selector UI.
- `lib/core/domain/`: Pure Dart primitives such as `Money`, `ValidationResult`, `StableId`, and `AttachmentRef`.
- `lib/features/audit/domain/`: Shared audit models and validation rule services.
- `lib/features/audit/data/`: Drift database, generated schema, mappers, repository, encrypted database opener, and plaintext-to-encrypted migration service.
- `assets/templates/usm_osa_f46/`: Expected location for official USM-OSA-F46 visual reference files used during local PDF QA.
- `test/widget_test.dart`: Setup, unlock, and dashboard lifecycle widget tests.
- `test/app/`: Startup service tests.
- `test/domain/`: Domain unit tests for audit rules.
- `test/data/`: In-memory Drift persistence tests.
- `.codex/skills/ui-ux-pro-max/SKILL.md`: Repo-local UI/UX skill instructions.

## Development Commands

Run from the repository root:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

If Git reports a dubious ownership error in this sandbox, avoid changing repository safety settings unless the user asks. The workspace appears nested under `C:\Users\cjcar`, which has a parent `.git` owned by a different Windows user than the sandbox account.

## Recommended Next Implementation Sequence

1. Plan Cross-Device Encrypted Backup Recovery V1, including recovery-key UX and cryptographic backup-key handling.
2. Add cross-device encrypted backup recovery only after that recovery-key design is approved.
3. Add focused widget and unit tests as each workflow is introduced.

## Likely Package Decisions To Evaluate

- Local database: Drift + SQLite is implemented.
- Encryption: secure credential storage, key-provider boundary, encrypted database opening, and plaintext database migration are implemented with SQLite3MultipleCiphers.
- File picking and storage: implemented with `file_picker`, app-private support storage, relative attachment paths, and SHA-256 checksums.
- Export ZIP: archive package plus manifest checksums.
- PDF generation: implemented with the Dart `pdf` package; liquidation reports use a template-driven USM-OSA-F46 layout, while summary reports remain Audivance-branded printable reports until official templates are provided.
- IDs: UUID or ULID package for stable exported references.
- Backup recovery: same-device encrypted database backup generation, validation, staged restore, active database close/reopen, restore confirmation, and backup/export history are implemented; cross-device encrypted recovery still needs a recovery-key design.

## UI/UX Skill Usage

For UI work, use the installed repo-local skill:

```powershell
python .codex\skills\ui-ux-pro-max\scripts\search.py "student organization audit finance dashboard" --design-system -p "Audivance"
python .codex\skills\ui-ux-pro-max\scripts\search.py "Form validation" --stack flutter
```

Before delivering user-facing UI, read:

- `.codex/skills/ui-ux-pro-max/references/pro-rules.md`
- `.codex/skills/ui-ux-pro-max/data/stacks/flutter.csv`

## Handoff Notes

- Treat `OFFLINE_APPLICATION_PRD.md` as the authoritative scope document until stakeholders update it.
- Keep implementation local-first and offline by default.
- Do not add cloud services, OAuth, live COA review, or sync unless the user explicitly changes MVP scope.
- Build around financial correctness and auditability before visual polish.
- Preserve generated/system ledger rows and append-only audit logs as first-class concepts.
- Next best sprint: Cross-Device Encrypted Backup Recovery V1.
