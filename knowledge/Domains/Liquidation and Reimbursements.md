---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Liquidation and Reimbursements

## Purpose

Records liquidation receipts and line items, reduces accountability for released funds, and creates/payments claims for out-of-pocket spending.

## Related Domains

- [[Event Management]]
- [[Treasury]]
- [[Budget Review]]
- [[Export Center]]
- [[Attachment Integrity]]

## Key Concepts

- [[Liquidation Receipt]]
- [[Liquidation Line]]
- [[Reimbursement Claim]]
- [[Fund Movement]]
- [[Officer]]

## Main Workflows

- [[Record Liquidation]]
- [[Pay Reimbursement]]
- [[Budget Review Snapshot]]

## Important Implementation

### Service
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

### UI
- `lib/features/events/event_screen.dart` (Graphify, source)

### Rules
- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)

### Tests
- `test/features/liquidation/liquidation_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- Liquidation requires receipt metadata, line items, accountable officer, and receipt attachment.
- Released Funds entries create Liquidation Submitted fund movements.
- Out-of-Pocket entries create pending reimbursement claims.
- Reimbursement payment is blocked when the Approved Budget balance is insufficient.

## Change Impact

Changes in this domain may affect:

- [[Event Management]]
- [[Budget Review]]
- [[Export Center]]
- [[Audit Logging]]

<!-- END GENERATED ARCHITECTURE -->
