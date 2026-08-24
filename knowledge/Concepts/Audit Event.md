---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Audit Event

## Meaning

An auditable organization event with approved budget, dates, resolution metadata, and liquidation state.

## Belongs To

- [[Event Management]]

## Relationships

- funded by [[Event Funding Allocation]]
- produces [[Liquidation Receipt]]
- summarized by [[Budget Health]]
- included in [[COA Export Package]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/events/event_service.dart` (Graphify, source)

## Important Constraints

- Event resolution attachment is required.
- Status is date-driven unless liquidated.

<!-- END GENERATED ARCHITECTURE -->
