---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Organization Workspace

## Meaning

The local single-organization audit workspace created during first launch.

## Belongs To

- [[Local Setup and Unlock]]

## Relationships

- contains [[Local Account]]
- owns [[Audit Event]] records
- exports a [[COA Export Package]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/setup/setup_screen.dart` (Graphify, source)

## Important Constraints

- MVP scope is one organization account per device.

<!-- END GENERATED ARCHITECTURE -->
