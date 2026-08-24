---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Record Liquidation

## Purpose

Records receipt metadata and line items for a completed event and routes released-funds versus out-of-pocket behavior.

## Flow

```text
Select event
  -> Enter receipt metadata
  -> Attach receipt
  -> Add line items
  -> Validate event status and budget
  -> Persist receipt and lines
  -> Released Funds: create liquidation movement
  -> Out-of-Pocket: create reimbursement claim
  -> Append audit log
```

## Participating Domains

- [[Liquidation and Reimbursements]]
- [[Event Management]]
- [[Attachments and Local Files]]
- [[Audit Logging]]

## Important Implementation

- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)
- `lib/features/events/event_screen.dart` (Graphify, source)

## Rules And Failure Cases

- Only completed events can be liquidated.
- Receipt attachment and at least one valid line are required.
- Released-funds liquidation requires sufficient Approved Budget balance.

## Change Impact

- [[Budget Review]]
- [[Export Center]]
- [[Dashboard]]

<!-- END GENERATED ARCHITECTURE -->
