---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Adjust Event Budget

## Purpose

Adjusts event budget through ledger-only changes while preserving original split-funding allocations.

## Flow

```text
Choose increase or decrease
  -> Select source for increase if needed
  -> Enter amount and remarks
  -> Validate source or approved budget balance
  -> Update event budget/balance
  -> Create protected budget adjustment movement
  -> Append audit log
```

## Participating Domains

- [[Event Management]]
- [[Treasury]]
- [[Audit Logging]]

## Important Implementation

- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/events/event_screen.dart` (Graphify, source)

## Rules And Failure Cases

- Remarks are required.
- Budget decreases cannot overdraw Approved Budget balance.
- Liquidated events cannot be adjusted.

## Change Impact

- [[Budget Review]]
- [[Dashboard]]
- [[Export Center]]

<!-- END GENERATED ARCHITECTURE -->
