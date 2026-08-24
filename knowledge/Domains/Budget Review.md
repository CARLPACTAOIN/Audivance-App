---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Budget Review

## Purpose

Computes budget-vs-actual summaries, health labels, variance, utilization, and immutable auditor review snapshots.

## Related Domains

- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Export Center]]
- [[Dashboard]]

## Key Concepts

- [[Budget Health]]
- [[Auditor Review Snapshot]]
- [[Audit Event]]
- [[Liquidation Line]]
- [[Reimbursement Claim]]

## Main Workflows

- [[Budget Review Snapshot]]
- [[Generate COA Export]]

## Important Implementation

### Event Service
- `lib/features/events/event_service.dart` (Graphify, source)

### Export Service
- `lib/features/export/export_service.dart` (Graphify, source)
- `lib/features/export/pdf_report_service.dart` (Graphify, source)

### Tests
- `test/features/events/event_service_test.dart` (Graphify, source)
- `test/features/export/export_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- Budget health values are No Budget, Healthy, Watch, Over Budget, and Critical.
- Utilization is stored/exported as integer basis points.
- Auditor review snapshots do not mutate when later liquidation or budget changes occur.

## Change Impact

Changes in this domain may affect:

- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Export Center]]

<!-- END GENERATED ARCHITECTURE -->
