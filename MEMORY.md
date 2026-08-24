# Audivance Memory

Last updated: August 24, 2026

## Project Identity

Audivance is a Flutter application for an offline/local-first student organization audit workflow. The product direction is defined in `OFFLINE_APPLICATION_PRD.md`.

The MVP is Android-first and tablet-friendly, with future desktop support possible through Flutter's multi-platform targets.

## Current Codebase State

- Framework: Flutter / Dart.
- Package name: `audivance`.
- Dart SDK constraint: `^3.13.0`.
- Current dependencies: Flutter SDK, `cupertino_icons`, Drift, SQLite, `path`, `path_provider`, `file_picker`, `crypto`, `archive`, `pdf`, `flutter_secure_storage`, and `cryptography`.
- Current dev tooling includes Drift code generation plus launcher icon and native splash generation configuration.
- Current app implementation: Audivance app shell with first-launch setup, persistent secure local unlock, encrypted local SQLite storage, repository-backed dashboard, Treasury workspace, Events workspace with budget adjustments and budget-vs-actual review snapshots, Export Center preview, PDF report generation, ZIP generation, hardened Backup & Restore foundation, app-private attachment import, and a final MVP UX/edge-case polish pass across existing workflows.
- Current domain implementation: pure Dart primitives and audit rule services under `lib/core/domain/` and `lib/features/audit/domain/`.
- Current persistence implementation: Drift database schema version 3, mappers, repository interface, repository implementation, encrypted app database opener, plaintext-to-encrypted migration service, and secure key-provider boundary under `lib/features/audit/data/`.
- Current test implementation: setup/unlock/dashboard widget tests plus app startup, domain, and in-memory Drift repository tests.
- Product spec: `OFFLINE_APPLICATION_PRD.md`.
- Repo-local UI/UX skill installed at `.codex/skills/ui-ux-pro-max`.

## Product Commitments

- The app must work fully offline after install and first setup.
- MVP scope is one organization account on one device.
- No Google OAuth, cloud database, live COA dashboard, or real-time sync in the MVP.
- COA review is handled through exported audit packages, not live app access.
- The app should preserve the financial logic of the current Audivance Laravel app wherever practical.
- All financial changes require durable audit logs.
- Attachments are local and must be included in backups and COA exports.

## Core Domain Areas

- Local account and organization setup.
- Organization profile, semester, school year, adviser, and signatories.
- Officers and fixed committees: Finance Committee and Audit Committee.
- Treasury source funds with required supporting documents.
- Events and resolutions with split funding.
- Fund movements with validation and generated references.
- Liquidation reports with receipt lines and attachments.
- Reimbursement claims for out-of-pocket liquidation entries.
- Budget-vs-actual summaries and auditor review snapshots.
- Append-only audit logs.
- Backup, restore, and COA export ZIP package.

## Implemented Domain Foundation

- `Money` stores PHP amounts as integer centavos and avoids floating-point arithmetic.
- `ValidationResult` represents expected business-rule failures with readable messages.
- `AttachmentRef` and `StableId` provide package-free references for local files and exportable records.
- Audit models cover organization profile, officers, treasury sources, events, funding allocations, fund movements, liquidation records, reimbursement claims, audit logs, and export readiness issues.
- Rule services cover officer constraints, Treasury Add Fund attachment/amount checks, event budget allocation checks, budget increase/decrease checks, event status calculation, manual fund movement checks, liquidation funding-mode behavior, and reimbursement payment checks.

## Implemented Persistence Foundation

- Drift + SQLite is the selected local storage foundation.
- `AuditDatabase` schema version is `3`.
- `Money` persists as integer centavos.
- Stable IDs persist as text primary keys.
- Enum values persist as stable strings using Dart enum names.
- Attachment references persist as flattened id, file name, local path, optional size, and optional checksum columns.
- `AuditRepository` returns domain models rather than Drift row types.
- `DriftAuditRepository` validates existing domain rules before writes where rules exist.
- System-generated fund movements are protected from repository update/delete.
- Audit logs are append-only through the public repository API.
- Auditor review snapshots persist as immutable event-level records with captured budget, actual, variance, utilization, and health values.
- `AuditDatabaseOpener` opens `audivance.sqlite` in application support storage with SQLite3MultipleCiphers when a secure session database key is available.
- `AuditDatabaseEncryptionService` detects missing, plaintext, encrypted, and invalid-key databases and performs one-time plaintext-to-encrypted migration without changing the Drift schema version.

## Implemented First-Launch And Unlock Foundation

- Startup routing now checks persisted setup state.
- Setup is complete only when a local account profile and organization profile exist.
- First launch collects local account, local PIN, organization profile, semester, school year, adviser, and signatories.
- First launch and credential-upgrade flows configure a persistent secure local PIN verifier.
- PINs are not stored directly; the app stores a PBKDF2-HMAC-SHA256 credential envelope in platform secure storage.
- The secure unlock service also stores a random future database key for the encrypted database migration sprint.
- Existing setup without secure credential data routes to a "Secure workspace" upgrade screen.
- Existing setup with secure credential data routes to the unlock boundary before dashboard.
- Biometric unlock and encrypted database opening remain future work.

## Implemented Dashboard Foundation

- `DashboardService` loads dashboard snapshots from `AuditRepository`.
- Dashboard organization, term, treasury balance, approved event budget, event liquidation counts, pending reimbursement totals, and recent fund movements are computed from persisted records.
- Event status counts use `EventRules.calculateStatus`.
- Recent fund movements are sorted newest first and preserve the system-generated/protected flag in the dashboard preview.
- Fresh setup shows zero-value metrics and readiness tasks instead of the old demo data.
- `demoDashboardSnapshot` remains available only as a widget/test fixture fallback.

## Implemented Treasury Workspace

- `WorkspaceShell` owns ready-state navigation for Dashboard, Treasury, Events, and Export.
- `TreasuryService` loads source balances and ledger rows from `AuditRepository`.
- Treasury Add Fund validates positive amount and selected app-private attachment metadata, updates or creates the source balance, creates a protected system-generated Add Fund movement, and appends an audit log.
- Manual Treasury movements support Fund Release, Transfer, and Return / Refund with source-balance validation and audit logging.
- Treasury UI shows total unallocated balance, source-specific balances, ledger rows newest first, and modal forms for Add Fund and manual movements.
- Treasury, Events, and Liquidation forms use a reusable attachment selector that imports files into app-private storage and produces `AttachmentRef` metadata.

## Implemented Branding Foundation

- The uploaded Audivance logo is normalized under `assets/images/logo/` for Flutter runtime use and generated platform assets.
- Padded icon and splash source PNGs are available to avoid clipping on iOS rounded icons, Android adaptive icons, and Android 12 splash masking.
- Launcher icon and native splash generator configs are present at the repository root.
- The app startup, setup, unlock, workspace chrome, and dashboard header use a reusable Flutter `BrandLogo` widget.

## Implemented Events Workspace

- `EventService` loads event cards and Treasury allocation options from `AuditRepository`.
- Event creation validates required event metadata, date range, positive budget, selected resolution attachment metadata, split funding totals, existing source IDs, and source balances.
- Valid event creation persists the event and allocations, decrements unallocated Treasury source balances, creates protected system-generated Budget Allocation movements, and appends an audit log.
- Event budget adjustments are ledger-only: original split-funding allocations remain immutable, while budget increases/decreases update event budget/balance, update the selected Treasury source balance, create protected Budget Adjustment movements, and append audit logs.
- Events UI shows summary cards, event records with status/budget/resolution metadata, and a Create Event form with repeatable allocation rows.
- Events UI includes a Budget Review action that shows budget-vs-actual metrics, utilization, health, and immutable auditor review history.
- Auditor review creation requires findings, cause, and recommendation; saved snapshots append an audit log and do not change when later liquidation or budget changes occur.
- Encrypted database opening and one-time plaintext migration are implemented.

## Implemented Budget vs Actual Foundation

- Event budget-vs-actual summaries are computed from persisted event budgets, approved budget balances, liquidation lines, and reimbursement claims.
- Utilization is stored and exported as integer basis points to avoid floating-point money arithmetic.
- Budget health values are `noBudget`, `healthy`, `watch`, `overBudget`, and `critical`.
- Export Center preview and ZIP generation include `data/budget_vs_actual.json`, `data/auditor_reviews.json`, `csv/budget_vs_actual.csv`, and `csv/auditor_reviews.csv`.

## Implemented PDF Reports Foundation

- `PdfReportService` generates deterministic A4 PDF bytes for COA-facing export reports.
- Export reports include `reports/organization_summary.pdf`, `reports/treasury_ledger.pdf`, `reports/budget_vs_actual.pdf`, and one `reports/liquidation/{eventSlug}-{eventId}.pdf` file per event with liquidation receipts.
- PDF report checksums use SHA-256 and are included in the real ZIP manifest with `sourceType: report`.
- The Export Center package structure shows report paths, and generated ZIP packages include report files under `reports/`.
- V1 PDF layouts are Audivance-branded printable summaries, not exact official COA/USM-OSA-F46 replicas.

## Financial Rules To Preserve

- Fund movement references follow `FM-YYYYMMDD-XXXXXXXX`.
- Treasury Add Fund requires a supporting document attachment.
- Event creation generates budget allocation movements from source funds to Approved Budget.
- Budget edits require adjustment remarks and system-generated adjustment movements.
- Budget increases are blocked when source treasury balance is insufficient.
- Budget decreases are blocked when event Approved Budget balance is insufficient.
- Manual movements are limited to Fund Release, Transfer, and Return / Refund.
- System-generated fund movements must be visible but not manually editable or deletable.
- Released Funds liquidation entries reduce officer accountability.
- Out-of-Pocket liquidation entries create reimbursement claims.
- Reimbursement payment creates a system-generated Reimbursement Payment movement from Approved Budget.
- Audit logs are append-only and should capture before/after snapshots and metadata.

## Export Package Contract

The COA export ZIP should contain:

- `manifest.json` with organization, semester, school year, export timestamp, app version, record counts, and checksums.
- `data/*.json` for complete structured records.
- `csv/*.csv` for spreadsheet review.
- `reports/*.pdf` for printable summaries and liquidation reports.
- `attachments/` grouped by module.
- Optional `README.txt` for COA reviewers.

Suggested export filename:

`Audivance-{OrganizationSlug}-{SchoolYear}-{Semester}-{ExportDate}.zip`

The Export Center now generates a real local ZIP package containing the manifest, README, JSON data files, CSV review tables, PDF reports, and app-private attachments grouped under `attachments/{module}/{recordId}/{fileName}`. ZIP generation is blocked by readiness blockers such as missing required workspace records or missing/corrupted stored attachment files; warnings remain visible but do not prevent generation.

## Implemented Backup Foundation

- `AuditStoragePaths` centralizes the app-support database and attachment paths used by Drift, attachment storage, and backup generation.
- `BackupService` builds a local backup ZIP with `backup_manifest.json`, encrypted SQLite database files, SQLite sidecar files when present, and app-private attachments.
- Backup manifests now identify database backups as encrypted same-device/key-context backups; cross-device encrypted recovery is still future work.
- Backup validation verifies readable ZIP structure, manifest type, safe archive paths, required database entry, source/path consistency, listed entry byte lengths, and SHA-256 checksums.
- Restore uses a staged write-then-verify flow before replacing active encrypted database files and app-private attachments.
- `BackupRestoreCoordinator` closes the active workspace database, restores the validated backup, reopens the encrypted workspace, and reports controlled restore or reopen failures.
- The Settings action opens a Backup & Restore panel with Generate Backup, Validate Backup, typed RESTORE confirmation, and active same-device restore actions.

## Implemented Final UX Polish

- Shared UI primitives now cover responsive page/dialog framing, loading/empty/error/retry states, inline status panels, metadata chips, and text status badges.
- Dashboard quick actions route directly to Treasury ledger and Export Center instead of showing build-sequence snackbars.
- Setup, unlock, credential-upgrade, Treasury, Events, Export, Backup, and attachment flows use clearer inline errors, safer loading/error states, guarded submits, and small-screen-friendly wrapping/truncation.
- Protected/system-generated ledger rows are labeled with visible text rather than relying on lock icons or color alone.
- Attachment selection shows selected-file metadata with long names/checksums constrained for phone-width layouts and import failures surfaced inline with retry affordances.

## Security And Storage Direction

- Use Drift + SQLite for structured local data. Database-at-rest encryption is enabled through SQLite3MultipleCiphers and the secure stored database key.
- Attachment import copies selected files into app-private support storage under `attachments/`, stores relative paths in `AttachmentRef.localPath`, and records size plus SHA-256 checksum metadata.
- Prefer encrypted or otherwise protected attachment storage once the secure unlock/encryption slice is added.
- Use stable UUIDs or ULIDs for records that may appear in exports.
- Require local unlock through a persisted secure PIN verifier.
- Add biometric unlock only when platform support is available.
- Backup and restore must include database, attachments, app version, and schema version.
- Restore must validate the backup, require explicit confirmation, stage files before replacement, and reopen the encrypted workspace after replacement.
- Cross-device encrypted backup recovery still needs a separate key/recovery design.

## Open Decisions

- Confirm Android-only MVP versus Android plus desktop.
- Confirm exact COA export package acceptance criteria.
- Confirm required PDF form layouts beyond USM-OSA-F46 liquidation.
- Decide whether backups are mandatory before every COA export.
- Decide whether importing existing Laravel data is in scope.
- Decide whether a COA import/viewer utility is needed for MVP or later.
- Next best sprint: Organization Profile + Officer Management V1.
