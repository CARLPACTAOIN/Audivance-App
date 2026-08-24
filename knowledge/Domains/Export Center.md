---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Export Center

## Purpose

Builds the COA-facing audit package with manifest, JSON, CSV, PDF reports, readiness checks, checksums, and attachments.

## Related Domains

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]
- [[Attachments and Local Files]]

## Key Concepts

- [[COA Export Package]]
- [[Attachment Reference]]
- [[Audit Log Entry]]
- [[Auditor Review Snapshot]]

## Main Workflows

- [[Generate COA Export]]
- [[Budget Review Snapshot]]

## Important Implementation

### Service
- `lib/features/export/export_service.dart` (Graphify, source)

### Reports
- `lib/features/export/pdf_report_service.dart` (Graphify, source)
- `lib/features/export/pdf_report_actions.dart` (Graphify, source)

### Writers
- `lib/features/export/export_package_writer.dart` (Graphify, source)

### UI
- `lib/features/export/export_screen.dart` (Graphify, source)

### Tests
- `test/features/export/export_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- ZIP generation is blocked by readiness blockers.
- Warnings remain visible but do not prevent package generation.
- Reports and package entries include SHA-256 checksums.
- The package includes structured data, CSVs, PDFs, and app-private attachments.

## Change Impact

Changes in this domain may affect:

- [[COA Export Package]]
- [[Attachment Integrity]]
- [[Audit Logging]]
- [[Budget Review]]

<!-- END GENERATED ARCHITECTURE -->
