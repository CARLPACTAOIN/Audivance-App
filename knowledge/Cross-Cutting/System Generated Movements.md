---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# System Generated Movements

## Purpose

Workflow-created ledger rows are visible to users but protected from manual edit/delete.

## Applies To

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Persistence]]

## Important Implementation

- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)
- `lib/features/audit/data/drift_audit_repository.dart` (Graphify, source)
- `lib/features/treasury/treasury_service.dart` (Graphify, source)
- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

## Important Rules

- Repository update/delete rejects protected fund movements.

## Change Impact

- [[Audit Logging]]
- [[Export Center]]

<!-- END GENERATED ARCHITECTURE -->
