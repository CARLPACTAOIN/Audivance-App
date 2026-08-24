---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Attachment Integrity

## Purpose

Required files are copied locally and verified by existence, size, and checksum before export or backup use.

## Applies To

- [[Attachments and Local Files]]
- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Export Center]]
- [[Backup and Restore]]

## Important Implementation

- `lib/core/attachments/attachment_storage_service.dart` (Graphify, source)
- `lib/core/domain/attachment_ref.dart` (Graphify, source)
- `lib/features/export/export_service.dart` (Graphify, source)
- `lib/features/backup/backup_service.dart` (Graphify, source)

## Important Rules

- Export blocks missing or corrupted required attachments.
- Backups include attachments and validate checksums.

## Change Impact

- [[COA Export Package]]
- [[Backup Package]]

<!-- END GENERATED ARCHITECTURE -->
