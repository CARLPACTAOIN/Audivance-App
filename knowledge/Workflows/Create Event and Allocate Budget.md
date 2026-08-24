---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Create Event and Allocate Budget

## Purpose

Creates an event, allocates its budget from treasury sources, and records protected budget allocation movements.

## Flow

```text
Enter event metadata
  -> Attach resolution
  -> Add split funding rows
  -> Validate allocation total
  -> Persist event and allocations
  -> Decrease source balances
  -> Create budget allocation movements
  -> Append audit log
```

## Participating Domains

- [[Event Management]]
- [[Treasury]]
- [[Attachments and Local Files]]
- [[Audit Logging]]

## Important Implementation

- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/events/event_screen.dart` (Graphify, source)
- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)

## Rules And Failure Cases

- Resolution attachment is required.
- Split funding allocations must equal budget.
- Each source must have sufficient balance.

## Change Impact

- [[Dashboard]]
- [[Export Center]]
- [[Budget Review]]

<!-- END GENERATED ARCHITECTURE -->
