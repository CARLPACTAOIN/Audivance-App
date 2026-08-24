---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Pay Reimbursement

## Purpose

Pays a pending out-of-pocket claim from event Approved Budget and records a protected reimbursement payment movement.

## Flow

```text
Select pending claim
  -> Review amount and available event balance
  -> Validate claim state and balance
  -> Create reimbursement payment movement
  -> Mark claim paid
  -> Append audit log
```

## Participating Domains

- [[Liquidation and Reimbursements]]
- [[Event Management]]
- [[Treasury]]
- [[Audit Logging]]

## Important Implementation

- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)
- `lib/features/events/event_screen.dart` (Graphify, source)

## Rules And Failure Cases

- Only pending claims can be paid.
- Payment is blocked when Approved Budget balance is insufficient.

## Change Impact

- [[Budget Review]]
- [[Dashboard]]
- [[Export Center]]

<!-- END GENERATED ARCHITECTURE -->
