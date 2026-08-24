---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Add Treasury Funds

## Purpose

Adds money to a source-specific treasury balance while preserving attachment evidence and a protected ledger row.

## Flow

```text
Select source type
  -> Attach supporting document
  -> Validate positive amount
  -> Create or update source fund
  -> Create protected Add Fund movement
  -> Append audit log
```

## Participating Domains

- [[Treasury]]
- [[Attachments and Local Files]]
- [[Audit Logging]]

## Important Implementation

- `lib/features/treasury/treasury_service.dart` (Graphify, source)
- `lib/features/treasury/treasury_screen.dart` (Graphify, source)
- `lib/core/attachments/attachment_selector.dart` (Graphify, source)

## Rules And Failure Cases

- Supporting attachment is required.
- Amount must be greater than zero.

## Change Impact

- [[Export Center]]
- [[Dashboard]]

<!-- END GENERATED ARCHITECTURE -->
