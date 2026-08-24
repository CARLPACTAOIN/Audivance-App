---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Event Management

## Purpose

Creates auditable events with resolution metadata, split funding, status calculation, budget adjustments, and budget-vs-actual review snapshots.

## Related Domains

- [[Treasury]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]
- [[Dashboard]]
- [[Export Center]]

## Key Concepts

- [[Audit Event]]
- [[Event Funding Allocation]]
- [[Fund Movement]]
- [[Auditor Review Snapshot]]
- [[Budget Health]]

## Main Workflows

- [[Create Event and Allocate Budget]]
- [[Adjust Event Budget]]
- [[Budget Review Snapshot]]
- [[Record Liquidation]]

## Important Implementation

### Service
- `lib/features/events/event_service.dart` (Graphify, source)

### UI
- `lib/features/events/event_screen.dart` (Graphify, source)

### Rules
- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)

### Tests
- `test/features/events/event_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- Event creation requires a resolution attachment.
- Split funding allocations must equal the event budget.
- Budget increases are blocked when source treasury balance is insufficient.
- Budget decreases are blocked when event Approved Budget balance is insufficient.
- Liquidated events cannot be adjusted.

## Change Impact

Changes in this domain may affect:

- [[Treasury]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]
- [[Export Center]]
- [[Audit Logging]]

<!-- END GENERATED ARCHITECTURE -->
