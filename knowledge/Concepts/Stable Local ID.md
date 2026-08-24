---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Stable Local ID

## Meaning

A local identifier used so exported records remain consistently referenceable.

## Belongs To

- [[Persistence]]

## Relationships

- identifies [[Audit Event]]
- identifies [[Fund Movement]]
- identifies [[Attachment Reference]]

## Implementation

- `lib/core/domain/identity.dart` (Graphify, source)
- `lib/core/domain/stable_id_generator.dart` (Graphify, source)

## Important Constraints

- Favor stable UUID/ULID-style IDs for exportable records.

<!-- END GENERATED ARCHITECTURE -->
