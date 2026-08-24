---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Generate and Validate Backup

## Purpose

Creates and validates a same-device backup containing database files and app-private attachments.

## Flow

```text
Choose Generate Backup
  -> Collect database and sidecar files
  -> Collect attachment files
  -> Write backup manifest
  -> Generate backup ZIP
  -> Validate manifest, sizes, and checksums
```

## Participating Domains

- [[Backup and Restore]]
- [[Persistence]]
- [[Attachments and Local Files]]

## Important Implementation

- `lib/features/backup/backup_service.dart` (Graphify, source)
- `lib/features/backup/backup_screen.dart` (Graphify, source)
- `lib/core/storage/audit_storage_paths.dart` (Graphify, source)

## Rules And Failure Cases

- Backup validation requires a manifest and database entry.
- Checksums and byte lengths must match manifest entries.

## Change Impact

- [[Database Encryption]]
- [[Application Shell]]

<!-- END GENERATED ARCHITECTURE -->
