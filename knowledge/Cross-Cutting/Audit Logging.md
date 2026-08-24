---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Audit Logging

## Purpose

Financial and administrative mutations append readable audit records for later review and export.

## Applies To

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]
- [[Export Center]]

## Important Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/audit/data/audit_repository.dart` (Graphify, source)
- `lib/features/treasury/treasury_service.dart` (Graphify, source)
- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

## Important Rules

- Audit logs are append-only from normal app workflows.
- Logs are included in COA exports.

## Change Impact

- [[Persistence]]
- [[COA Export Package]]

<!-- END GENERATED ARCHITECTURE -->
