---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Local Account

## Meaning

The local profile and credential state used to unlock the workspace.

## Belongs To

- [[Local Setup and Unlock]]

## Relationships

- unlocks [[Organization Workspace]]
- feeds [[Application Shell]] startup routing

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/app/local_unlock_service.dart` (Graphify, source)
- `lib/app/app_startup_service.dart` (Graphify, source)

## Important Constraints

- PINs are represented by secure credential envelopes, not stored directly.

<!-- END GENERATED ARCHITECTURE -->
