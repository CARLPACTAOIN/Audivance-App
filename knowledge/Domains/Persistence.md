---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Persistence

## Purpose

Stores audit records in Drift/SQLite while exposing domain models through the repository boundary.

## Related Domains

- [[Application Shell]]
- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Export Center]]
- [[Backup and Restore]]

## Key Concepts

- [[Audit Database]]
- [[Audit Repository]]
- [[Stable Local ID]]
- [[Attachment Reference]]

## Main Workflows

- [[First Launch and Unlock]]
- [[Create Event and Allocate Budget]]
- [[Generate COA Export]]

## Important Implementation

### Database
- `lib/features/audit/data/audit_database.dart` (Graphify, source)
- `lib/features/audit/data/audit_database.g.dart` (source)

### Repository
- `lib/features/audit/data/audit_repository.dart` (Graphify, source)
- `lib/features/audit/data/drift_audit_repository.dart` (Graphify, source)

### Mapping
- `lib/features/audit/data/audit_mappers.dart` (Graphify, source)

### Opening and Encryption
- `lib/features/audit/data/audit_database_opener.dart` (Graphify, source)
- `lib/features/audit/data/audit_database_encryption_service.dart` (Graphify, source)

### Tests
- `test/data/drift_audit_repository_test.dart` (Graphify, source)
- `test/data/audit_database_encryption_service_test.dart` (Graphify, source)

## Important Rules

- Money is persisted as integer centavos.
- Stable IDs persist as text primary keys.
- System-generated fund movements are protected from repository update/delete.
- Audit logs are append-only through the public repository API.

## Change Impact

Changes in this domain may affect:

- [[Financial Validation]]
- [[Audit Logging]]
- [[Export Center]]
- [[Backup and Restore]]

<!-- END GENERATED ARCHITECTURE -->
