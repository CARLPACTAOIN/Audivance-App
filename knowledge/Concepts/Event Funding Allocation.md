---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Event Funding Allocation

## Meaning

The split funding record connecting an event budget to one or more treasury sources.

## Belongs To

- [[Event Management]]
- [[Treasury]]

## Relationships

- allocates [[Treasury Source Fund]] to [[Audit Event]]
- generates protected [[Fund Movement]] rows

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/events/event_service.dart` (Graphify, source)

## Important Constraints

- Allocation total must equal the event budget.

<!-- END GENERATED ARCHITECTURE -->
