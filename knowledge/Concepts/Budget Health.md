---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Budget Health

## Meaning

The budget status derived from event budget and actual liquidation/reimbursement totals.

## Belongs To

- [[Budget Review]]

## Relationships

- summarizes [[Audit Event]]
- uses [[Liquidation Line]] and [[Reimbursement Claim]] actuals
- captured by [[Auditor Review Snapshot]]

## Implementation

- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/export/export_service.dart` (Graphify, source)
- `lib/features/export/pdf_report_service.dart` (Graphify, source)

## Important Constraints

- Uses noBudget, healthy, watch, overBudget, and critical values.

<!-- END GENERATED ARCHITECTURE -->
