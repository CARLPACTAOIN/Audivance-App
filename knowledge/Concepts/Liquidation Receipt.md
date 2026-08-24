---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Liquidation Receipt

## Meaning

Receipt-level liquidation metadata for one event, including payee, evidence number, funding mode, accountable officer, and attachment.

## Belongs To

- [[Liquidation and Reimbursements]]

## Relationships

- contains [[Liquidation Line]]
- requires [[Attachment Reference]]
- may create [[Reimbursement Claim]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

## Important Constraints

- Receipt attachment is required.

<!-- END GENERATED ARCHITECTURE -->
