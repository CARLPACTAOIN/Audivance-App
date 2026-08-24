# Audivance Offline Application PRD

Status: Draft for review  
Date: August 18, 2026  
Product: Audivance - Student Organization Audit Platform  
Target release: Offline/local-only version

## 1. Summary

Audivance Offline is a local-only version of the existing Audivance audit system for student organizations that cannot reliably use the deployed web application. The offline app should keep nearly the same financial logic as the current Laravel app, but remove the dependency on a hosted server, cloud database, Google login, and live COA review access.

Each organization uses one account on one device. The organization records its treasury, events, fund movements, liquidation reports, reimbursements, and supporting documents locally. When COA needs to audit the organization, the app exports a complete audit package that COA can review outside the app or import into a separate COA review tool later.

## 2. Problem Statement

The current system is difficult to deploy and maintain as a hosted application. Student organizations still need a structured audit workflow, but they may not have stable internet access, server administration capacity, or a reliable central deployment environment.

The offline version solves this by moving daily encoding, validation, document attachment, and report generation onto the organization's own device. COA review happens through exported records instead of live access to the organization's online workspace.

## 3. Goals

- Preserve the current audit logic as much as possible: organization profile, officers, treasury, events and resolutions, fund movements, liquidation reports, reimbursements, budget-vs-actual, and audit logs.
- Work fully offline after installation and first setup.
- Support one organization account per device for the MVP.
- Export all COA-auditable records in a predictable package.
- Produce human-readable reports for fund movements, liquidation, budget-vs-actual, and organization summaries.
- Store attachments locally, including event resolutions, fund source supporting documents, and receipt attachments.
- Prevent common accounting mistakes through the same validation rules used in the web app.
- Keep a durable local audit trail of financial changes.

## 4. Non-Goals

- No live multi-organization COA dashboard in the MVP.
- No Google OAuth, email verification, commissioner invitations, or cloud-based onboarding.
- No real-time sync between devices.
- No multi-user role hierarchy inside one organization for the MVP unless explicitly added later.
- No automatic submission to COA unless a future import portal or sync server is approved.
- No replacement for official COA judgment; the app prepares records, but COA still reviews them.

## 5. Recommended Product Direction

The recommended MVP is a local-first mobile/tablet app with SQLite storage and local file storage. Flutter is a strong option because it supports Android, iOS, Windows, and desktop expansion from one codebase. If the team needs the fastest reuse of current Laravel business logic, a local desktop build using Laravel with SQLite can be considered, but it is less ideal if the target users primarily use phones.

Recommendation:

- MVP platform: Android-first mobile app, tablet-friendly layout.
- Data store: encrypted SQLite database.
- File storage: encrypted or app-private local document storage.
- Export format: ZIP audit package containing JSON, CSV, PDF reports, attachments, and a manifest with checksum.
- Future COA tooling: optional COA desktop/web import viewer that can read exported ZIP packages.

## 6. Users and Personas

### Organization Auditor

The primary user. Encodes organization profile, officers, funds, event budgets, fund releases, liquidation receipts, reimbursements, and audit review remarks.

### Organization Treasurer or Finance Officer

May assist in preparing records and attachments. In the MVP, this can be handled by the same local account unless the team decides to support multiple local PINs later.

### COA Reviewer

Does not need access to the organization's device. Reviews exported records, PDF reports, and supporting attachments submitted by the organization.

## 7. MVP Scope

### 7.1 Local Setup

- Create local account with name, email or student ID, password/PIN, and optional biometric unlock.
- Create one organization profile on first launch.
- Capture organization name, type, adviser, semester, school year, and signatory names.
- Auto-create the fixed committees:
  - Finance Committee
  - Audit Committee
- Allow backup and restore of the local organization workspace.

### 7.2 Dashboard

- Show current treasury balance.
- Show total approved budget.
- Show event count by status.
- Show liquidation due or for liquidation events.
- Show pending reimbursements.
- Show recent fund movements and recent liquidation entries.
- Work without internet.

### 7.3 Organization Profile

- Edit organization metadata.
- Maintain semester and school year.
- Maintain adviser and signatory information needed for reports.
- Display export readiness status, such as missing profile fields or missing required attachments.

### 7.4 Officers

- Add, edit, and archive officers.
- Assign officers to Finance Committee, Audit Committee, or no committee.
- Restrict officer position to Head or Member.
- Require a committee for Head.
- Allow only one Head per committee.
- Use officers as accountable holders for fund releases, transfers, liquidation, and reimbursements.

### 7.5 Treasury

- Add funds by source:
  - Fund from previous admin
  - Voluntary contributions / Student Collections
  - DONATION/SPONSOR
  - Income generating profit
  - PPMP
- Require supporting document attachment for each Treasury Add Fund entry.
- Generate fund movement references automatically using the existing pattern: `FM-YYYYMMDD-XXXXXXXX`.
- Show unallocated treasury balance.
- Show source-specific balances.
- Show liquidated event excess funds.
- Export source fund history and supporting document metadata.

### 7.6 Events and Resolutions

- Create events with name, type, semester, school year, date range, permit approval date, resolution number, and budget.
- Require an event resolution attachment.
- Support split funding across multiple fund sources.
- On event creation, generate budget allocation movements from source funds to Approved Budget.
- On budget edits, require budget adjustment remarks and generate budget adjustment movements.
- Block budget increases when source treasury balance is insufficient.
- Block budget decreases when event Approved Budget balance is insufficient.
- Keep event statuses date-driven:
  - Ongoing by default
  - For Liquidation after end date
  - Due seven days after end date
  - Liquidated only from the liquidation workflow

### 7.7 Fund Movements

- Allow manual movements only for:
  - Fund Release
  - Transfer
  - Return / Refund
- Support movement filters by event, type, holder, date range, and search.
- Validate balances before saving.
- Block transfers from zero or insufficient balances.
- Show system-generated rows but prevent manual edit/delete of system-generated movements.
- Export the complete ledger with references, dates, holders, amounts, purpose, remarks, and system-generated flags.

### 7.8 Liquidation Reports

- Select an event for liquidation.
- Add receipt entries with shared metadata:
  - Payee or merchant
  - Date
  - Evidence number
  - Receipt type
  - Funding mode
  - Accountable officer
  - Receipt attachment
- Support repeatable product/item rows under one receipt entry.
- Save each product row as a separate liquidation line.
- Receipt types:
  - Official Receipt
  - Reimbursement Expense Receipt
  - Payment Agreement
  - Acknowledgement Receipt
  - Sales Invoice
- Funding modes:
  - Released Funds
  - Out-of-Pocket
- Released Funds entries generate Liquidation Submitted movements that reduce officer accountability.
- Out-of-Pocket entries create reimbursement claims.
- Print or export the liquidation report using the USM-OSA-F46 layout.
- Mark event as Liquidated only when event status is For Liquidation.

### 7.9 Reimbursement Claims

- Create pending claims from Out-of-Pocket liquidation entries.
- Show claim amount, event, accountable officer, and current status.
- Before payment, show a review screen with:
  - Claim amount
  - Available event Approved Budget
  - Projected remaining event fund
  - Insufficient fund warning when applicable
- On payment, create a system-generated Reimbursement Payment movement from Approved Budget.
- Mark claim as paid without adding officer custody balance.

### 7.10 Budget vs Actual

- Show event budget, actual liquidation total, variance, utilization, and budget health.
- Budget health should use current app logic:
  - No Budget
  - Healthy
  - Watch
  - Over Budget
  - Critical
- Store auditor review snapshots for findings, cause, recommendation, budget, actual, variance, and utilization.
- Export budget-vs-actual summary as PDF and CSV.

### 7.11 Audit Logs

- Record append-only audit logs for financial and administrative actions.
- Capture action, actor, target record, amount/reference, before/after snapshots, metadata, date/time, and device identifier.
- Keep audit logs readable in the app.
- Include audit logs in the COA export package.

### 7.12 Export Center

The Export Center is the most important difference from the online app. It replaces live COA access.

The app must support exporting:

- Organization profile
- Officers and committees
- Treasury source funds
- Fund movements
- Events and resolutions
- Event funding sources
- Liquidation report lines
- Receipt attachment metadata
- Reimbursement claims
- Budget-vs-actual summaries
- Auditor reviews/recommendations
- Audit logs
- Attached files, including resolutions, fund source documents, and receipts

Recommended export package:

- One ZIP file per organization, semester, and school year.
- `manifest.json` with organization name, semester, school year, export timestamp, app version, record counts, and file checksums.
- `data/*.json` for full structured machine-readable data.
- `csv/*.csv` for spreadsheet review.
- `reports/*.pdf` for printable summaries and liquidation reports.
- `attachments/` for supporting documents grouped by module.
- Optional `README.txt` explaining folder contents for COA reviewers.

Suggested file name:

`Audivance-{OrganizationSlug}-{SchoolYear}-{Semester}-{ExportDate}.zip`

Example:

`Audivance-JPIA-2026-2027-1st-Semester-2026-08-18.zip`

Export safeguards:

- Run export readiness checks before generating the package.
- Warn about missing required attachments.
- Warn about unliquidated due events.
- Warn about unpaid reimbursement claims.
- Include checksum/signature metadata so COA can detect accidental file tampering.
- Keep export history inside the app.

## 8. Data Requirements

The offline data model should mirror the current app where practical:

- Local user/account
- Organization
- Officers
- Committees
- Audit events
- Event funding sources
- Fund movements
- Liquidation items
- Reimbursement claims
- Audit reviews
- Financial audit logs
- Local files/attachments
- Export history
- App settings

Records should use stable local UUIDs or ULIDs, not only auto-increment IDs, so exported records can be referenced consistently by COA tools later.

## 9. Security Requirements

- Require app unlock through PIN/password.
- Support optional biometric unlock when available.
- Encrypt local database at rest if platform support allows.
- Store attachments in app-private storage.
- Do not upload records automatically.
- Require confirmation before export.
- Require confirmation before restore, because restore can overwrite local data.
- Protect audit logs from normal edit/delete actions.
- Include app version and device identifier in exports.
- Support local backup password or recovery key if encrypted backups are implemented.

## 10. Backup and Restore

Backup is required because one account/device per organization creates device-loss risk.

MVP requirements:

- Manual encrypted backup to local file.
- Manual restore from backup file.
- Backup includes database and attachments.
- Backup includes app version and schema version.
- App validates backup before restore.

Recommended later:

- Optional export to USB/SD card.
- Optional local network transfer.
- Optional COA-verified archive receipt.

## 11. Functional Priorities

### P0 - Must Have

- Local account and organization setup
- Officers and committees
- Treasury Add Fund with source and attachment
- Events with resolution attachment and split funding
- Fund movements with balance validation
- Liquidation reports with receipt lines and attachments
- Reimbursement claims and payment flow
- Budget-vs-actual summary
- Audit logs
- COA export ZIP package
- Backup and restore

### P1 - Should Have

- PDF report generation for all major reports
- Export readiness checklist
- Export history
- Search and filters across ledger tables
- Biometric unlock
- Import/viewer utility for COA reviewers

### P2 - Nice to Have

- Multi-local-user PINs on the same organization device
- QR code on reports linking to export manifest/checksum
- Offline help screens
- Optional desktop companion app
- Optional future sync to a COA server

## 12. Success Metrics

- An organization can complete a full semester audit workflow without internet.
- COA can review exported records without asking for screenshots or manual spreadsheet reconstruction.
- Export package contains all required reports and attachments.
- The app prevents negative balances caused by invalid manual entries.
- Users can recover from device replacement using a backup file.
- Exported records are consistent with printed liquidation reports.

## 13. Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Device loss | Organization loses records | Require manual encrypted backups and reminders |
| COA rejects export format | Rework export/reporting | Confirm export package structure with COA before development |
| Users edit exported files | Audit trust issues | Add manifest checksums and optional QR/checksum page |
| No cloud sync | Harder COA monitoring | Make export history and readiness checks strong |
| File attachments consume storage | Device storage pressure | Compress exports and show storage usage |
| One device per org is too restrictive | Workflow bottleneck | Keep multi-device sync out of MVP but design IDs for future sync |

## 14. Open Questions for Stakeholders

1. Is the target app definitely mobile, or is a Windows desktop app acceptable for the first offline release?
2. Which devices do most organizations have: Android phones, tablets, laptops, or shared office PCs?
3. Should COA receive a ZIP package, printed reports, Excel files, PDFs, or all of them?
4. Will COA require an import tool, or is folder-based review enough for MVP?
5. Is one account/device per organization strict, or should the app allow multiple local users with separate PINs?
6. Who is allowed to reset the local account if the auditor forgets the PIN?
7. Should organizations submit exports per event, per semester, per school year, or on demand?
8. What exact COA forms must be generated besides the liquidation report?
9. Are digital signatures required for signatories, or are printed wet signatures acceptable?
10. Should exported attachments preserve original filenames or use normalized audit-safe filenames?
11. What is the required retention period for local records?
12. Should backups be mandatory before every export?
13. Should the app support importing existing data from the current Laravel web app?
14. Should COA be able to verify that an export came from an unchanged app build?

## 15. Recommended Next Steps

1. Confirm the target platform: Android-first mobile, desktop-first local app, or both.
2. Confirm the COA export format and required report list.
3. Create sample COA export ZIP from current Audivance data to validate the package structure.
4. Decide whether the offline app should be a new Flutter app or a packaged local Laravel/SQLite app.
5. Freeze MVP rules for one device, one organization, and one local account.
6. Prototype the Export Center first, because it defines the audit handoff between organizations and COA.

