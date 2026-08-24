---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Treasury

## Purpose

Tracks source fund balances, Add Fund entries, manual fund movements, and ledger rows for the organization workspace.

## Related Domains

- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Dashboard]]
- [[Audit Logging]]
- [[Attachment Integrity]]

## Key Concepts

- [[Treasury Source Fund]]
- [[Fund Movement]]
- [[Attachment Reference]]
- [[Officer]]

## Main Workflows

- [[Add Treasury Funds]]
- [[Create Event and Allocate Budget]]
- [[Adjust Event Budget]]

## Important Implementation

### Service
- `lib/features/treasury/treasury_service.dart` (Graphify, source)

### UI
- `lib/features/treasury/treasury_screen.dart` (Graphify, source)
- `lib/features/treasury/treasury_formatters.dart` (Graphify, source)

### Rules
- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)

### Tests
- `test/features/treasury/treasury_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- Treasury Add Fund requires a supporting document attachment.
- Manual movements are limited to Fund Release, Transfer, and Return / Refund.
- Balance validation blocks movements when the available balance is insufficient.
- Fund movement references follow FM-YYYYMMDD-XXXXXXXX.

## Change Impact

Changes in this domain may affect:

- [[Event Management]]
- [[Dashboard]]
- [[Export Center]]
- [[Audit Logging]]

<!-- END GENERATED ARCHITECTURE -->
