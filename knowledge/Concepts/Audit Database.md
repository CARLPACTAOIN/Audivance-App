---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Audit Database

## Meaning

The Drift SQLite schema for local accounts, organizations, events, funds, liquidation, reimbursement, reviews, and logs.

## Belongs To

- [[Persistence]]

## Relationships

- opened by [[Application Shell]]
- backed up in [[Backup Package]]
- exported through [[Audit Repository]] reads

## Implementation

- `lib/features/audit/data/audit_database.dart` (Graphify, source)
- `lib/features/audit/data/audit_database_opener.dart` (Graphify, source)
- `lib/features/audit/data/audit_database_encryption_service.dart` (Graphify, source)

## Important Constraints

- Schema version is currently 3.
- Database-at-rest encryption is enabled when a secure key is available.

<!-- END GENERATED ARCHITECTURE -->
