---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Database Encryption

## Purpose

The app opens local SQLite storage with a secure session key and supports plaintext-to-encrypted migration.

## Applies To

- [[Application Shell]]
- [[Local Setup and Unlock]]
- [[Persistence]]
- [[Backup and Restore]]

## Important Implementation

- `lib/app/local_unlock_service.dart` (Graphify, source)
- `lib/features/audit/data/audit_database_opener.dart` (Graphify, source)
- `lib/features/audit/data/audit_database_encryption_service.dart` (Graphify, source)

## Important Rules

- Encrypted database opening is tied to the local secure credential/key context.
- Cross-device encrypted backup recovery remains future work.

## Change Impact

- [[Backup and Restore]]
- [[First Launch and Unlock]]

<!-- END GENERATED ARCHITECTURE -->
