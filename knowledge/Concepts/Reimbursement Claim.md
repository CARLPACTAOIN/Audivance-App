---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Reimbursement Claim

## Meaning

A pending or paid claim created from out-of-pocket liquidation spending.

## Belongs To

- [[Liquidation and Reimbursements]]

## Relationships

- created by [[Liquidation Line]]
- paid through protected [[Fund Movement]]
- affects [[Budget Health]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

## Important Constraints

- Only pending claims can be paid.
- Payment is blocked when Approved Budget balance is insufficient.

<!-- END GENERATED ARCHITECTURE -->
