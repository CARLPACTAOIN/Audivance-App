---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Liquidation Line

## Meaning

A product/item row under a liquidation receipt with quantity and unit cost.

## Belongs To

- [[Liquidation and Reimbursements]]
- [[Budget Review]]

## Relationships

- belongs to [[Liquidation Receipt]]
- contributes to actual spending for [[Budget Health]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/liquidation/liquidation_service.dart` (Graphify, source)

## Important Constraints

- Line description, quantity, and unit cost must be valid.

<!-- END GENERATED ARCHITECTURE -->
