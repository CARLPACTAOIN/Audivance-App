---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Officer

## Meaning

An organization officer who can belong to Finance or Audit Committee and serve as an accountable holder.

## Belongs To

- [[Event Management]]
- [[Treasury]]
- [[Liquidation and Reimbursements]]

## Relationships

- can be holder for [[Fund Movement]]
- can be accountable officer for [[Liquidation Receipt]]
- can own [[Reimbursement Claim]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/audit/domain/audit_rules.dart` (Graphify, source)

## Important Constraints

- Only one active head is allowed per committee.
- Committee heads must be assigned to a committee.

<!-- END GENERATED ARCHITECTURE -->
