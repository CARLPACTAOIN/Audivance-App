---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Backup and Restore

## Purpose

Builds and validates local backup ZIPs that preserve the encrypted database files and app-private attachments.

## Related Domains

- [[Persistence]]
- [[Attachments and Local Files]]
- [[Database Encryption]]
- [[Application Shell]]

## Key Concepts

- [[Backup Package]]
- [[Audit Database]]
- [[Attachment Reference]]

## Main Workflows

- [[Generate and Validate Backup]]

## Important Implementation

### Service
- `lib/features/backup/backup_service.dart` (Graphify, source)

### IO Boundary
- `lib/features/backup/backup_package_io.dart` (Graphify, source)

### UI
- `lib/features/backup/backup_screen.dart` (Graphify, source)

### Storage
- `lib/core/storage/audit_storage_paths.dart` (Graphify, source)

### Tests
- `test/features/backup/backup_service_test.dart` (Graphify, source)

## Important Rules

- Backups include encrypted SQLite database files and app-private attachments.
- Backup validation checks manifest type, required database entry, byte lengths, and SHA-256 checksums.
- Current backup labeling is same-device/key-context; cross-device recovery remains future work.

## Change Impact

Changes in this domain may affect:

- [[Persistence]]
- [[Database Encryption]]
- [[Attachments and Local Files]]

<!-- END GENERATED ARCHITECTURE -->
