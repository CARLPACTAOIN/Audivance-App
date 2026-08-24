---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Generate COA Export

## Purpose

Builds the review package that replaces live COA access in the offline MVP.

## Flow

```text
Load export data
  -> Run readiness checks
  -> Verify required attachments
  -> Build JSON and CSV data
  -> Generate PDF reports
  -> Copy attachments
  -> Build manifest and checksums
  -> Write ZIP
```

## Participating Domains

- [[Export Center]]
- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]
- [[Attachments and Local Files]]

## Important Implementation

- `lib/features/export/export_service.dart` (Graphify, source)
- `lib/features/export/pdf_report_service.dart` (Graphify, source)
- `lib/features/export/export_package_writer.dart` (Graphify, source)

## Rules And Failure Cases

- Readiness blockers prevent ZIP generation.
- Missing or corrupted stored attachments block generation.
- Warnings remain visible but do not block export.

## Change Impact

- [[Audit Logging]]
- [[Attachment Integrity]]

<!-- END GENERATED ARCHITECTURE -->
