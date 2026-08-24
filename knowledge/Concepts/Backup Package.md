---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Backup Package

## Meaning

A local backup ZIP containing database files and app-private attachments.

## Belongs To

- [[Backup and Restore]]

## Relationships

- contains [[Audit Database]] files
- contains [[Attachment Reference]] files
- validated before restore

## Implementation

- `lib/features/backup/backup_service.dart` (Graphify, source)
- `lib/features/backup/backup_package_io.dart` (Graphify, source)

## Important Constraints

- Current encrypted backups are same-device/key-context backups.

<!-- END GENERATED ARCHITECTURE -->
