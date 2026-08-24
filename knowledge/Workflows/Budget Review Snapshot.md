---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Budget Review Snapshot

## Purpose

Captures a point-in-time auditor review of budget-vs-actual health for an event.

## Flow

```text
Open budget review
  -> Compute actuals, variance, utilization, health
  -> Enter findings, cause, recommendation
  -> Persist immutable snapshot
  -> Append audit log
  -> Export snapshot in JSON/CSV
```

## Participating Domains

- [[Budget Review]]
- [[Event Management]]
- [[Export Center]]
- [[Audit Logging]]

## Important Implementation

- `lib/features/events/event_service.dart` (Graphify, source)
- `lib/features/events/event_screen.dart` (Graphify, source)
- `lib/features/export/export_service.dart` (Graphify, source)

## Rules And Failure Cases

- Findings, cause, and recommendation are required.
- Saved snapshots remain unchanged after later event changes.

## Change Impact

- [[COA Export Package]]

<!-- END GENERATED ARCHITECTURE -->
