---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Financial Validation

## Purpose

Financial mutations must validate balances and required evidence before saving.

## Applies To

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]

## Important Implementation

- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)
- `lib/features/treasury/treasury_service.dart` (Graphify, source)
- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

## Important Rules

- Never bypass balance validation.
- Required attachment rules belong in domain/application logic, not only UI.

## Change Impact

- [[Audit Logging]]
- [[Export Center]]

<!-- END GENERATED ARCHITECTURE -->
