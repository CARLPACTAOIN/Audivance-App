---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Audit Repository

## Meaning

The application boundary that exposes domain models while hiding Drift rows and persistence details.

## Belongs To

- [[Persistence]]

## Relationships

- implemented by [[Audit Database]] adapter
- used by service domains
- enforces repository-level protections

## Implementation

- `lib/features/audit/data/audit_repository.dart` (Graphify, source)
- `lib/features/audit/data/drift_audit_repository.dart` (Graphify, source)

## Important Constraints

- System-generated fund movements cannot be modified or deleted through the repository.

<!-- END GENERATED ARCHITECTURE -->
