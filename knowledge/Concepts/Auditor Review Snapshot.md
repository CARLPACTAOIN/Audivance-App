---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Auditor Review Snapshot

## Meaning

An immutable saved review of event findings, cause, recommendation, budget, actual, variance, utilization, and health.

## Belongs To

- [[Budget Review]]
- [[Event Management]]

## Relationships

- captures [[Budget Health]]
- is exported in [[COA Export Package]]
- appends [[Audit Log Entry]]

## Implementation

- `lib/features/audit/domain/audit_models.dart` (Graphify, source)
- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/export/export_service.dart` (Graphify, source)

## Important Constraints

- Findings, cause, and recommendation are required.
- Snapshots do not change when later numbers change.

<!-- END GENERATED ARCHITECTURE -->
