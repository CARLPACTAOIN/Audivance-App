---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Attachments and Local Files

## Purpose

Imports selected files into app-private storage, records attachment metadata, verifies integrity, and resolves files for export/backup.

## Related Domains

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Export Center]]
- [[Backup and Restore]]

## Key Concepts

- [[Attachment Reference]]
- [[COA Export Package]]
- [[Backup Package]]

## Main Workflows

- [[Add Treasury Funds]]
- [[Create Event and Allocate Budget]]
- [[Record Liquidation]]
- [[Generate COA Export]]
- [[Generate and Validate Backup]]

## Important Implementation

### Storage
- `lib/core/attachments/attachment_storage_service.dart` (Graphify, source)
- `lib/core/storage/audit_storage_paths.dart` (Graphify, source)

### Picker and UI
- `lib/core/attachments/attachment_picker.dart` (Graphify, source)
- `lib/core/attachments/attachment_selector.dart` (Graphify, source)

### Domain
- `lib/core/domain/attachment_ref.dart` (Graphify, source)

### Tests
- `test/core/attachment_storage_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- Attachments are copied into app-private storage.
- AttachmentRef stores local path, original file name, size, and optional checksum.
- Export readiness blocks missing or corrupted required attachments.

## Change Impact

Changes in this domain may affect:

- [[Export Center]]
- [[Backup and Restore]]
- [[Attachment Integrity]]

<!-- END GENERATED ARCHITECTURE -->
