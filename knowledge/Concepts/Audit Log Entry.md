---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Audit Log Entry

## Meaning

Append-only record of financial and administrative changes.

## Belongs To

- [[Audit Logging]]
- [[Persistence]]

## Relationships

- created by mutating workflows
- included in [[COA Export Package]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/audit/data/audit_repository.dart` (Graphify, source)

## Important Constraints

- Audit logs are append-only from normal app workflows.

<!-- END GENERATED ARCHITECTURE -->
