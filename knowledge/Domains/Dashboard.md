---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Dashboard

## Purpose

Provides the offline workspace summary for treasury balance, approved budget, event statuses, pending reimbursements, and recent ledger activity.

## Related Domains

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Export Center]]

## Key Concepts

- [[Audit Event]]
- [[Fund Movement]]
- [[Reimbursement Claim]]
- [[Budget Health]]

## Main Workflows

- [[Create Event and Allocate Budget]]
- [[Record Liquidation]]
- [[Pay Reimbursement]]

## Important Implementation

### Service
- `lib/features/dashboard/dashboard_service.dart` (Graphify, source)

### Models
- `lib/features/dashboard/dashboard_models.dart` (Graphify, source)

### UI
- `lib/features/dashboard/dashboard_screen.dart` (Graphify, source)

### Tests
- `test/features/dashboard/dashboard_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- Dashboard values are computed from persisted repository records.
- Event status counts use EventRules.calculateStatus.
- Fresh setup shows zero-value metrics and readiness tasks instead of demo data.

## Change Impact

Changes in this domain may affect:

- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]

<!-- END GENERATED ARCHITECTURE -->
