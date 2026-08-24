---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Treasury Source Fund

## Meaning

A source-specific fund balance available for allocation, release, transfer, or return.

## Belongs To

- [[Treasury]]

## Relationships

- funds [[Audit Event]] through [[Event Funding Allocation]]
- requires [[Attachment Reference]] for Add Fund

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/treasury/treasury_service.dart` (Graphify, source)

## Important Constraints

- Add Fund amount must be positive.
- Add Fund requires a supporting attachment.

<!-- END GENERATED ARCHITECTURE -->
