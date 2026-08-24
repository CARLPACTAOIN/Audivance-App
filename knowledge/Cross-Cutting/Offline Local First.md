---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Offline Local First

## Purpose

The MVP works without hosted services, OAuth, live COA access, or realtime sync.

## Applies To

- [[Application Shell]]
- [[Persistence]]
- [[Export Center]]
- [[Backup and Restore]]

## Important Implementation

- `OFFLINE_APPLICATION_PRD.md` (Graphify, source)
- `MEMORY.md` (Graphify, source)
- `lib/features/audit/data/audit_database.dart` (Graphify, source)

## Important Rules

- Do not add cloud services unless explicitly requested.
- COA review happens through exported packages.

## Change Impact

- [[Application Shell]]
- [[Persistence]]
- [[Treasury]]
- [[Event Management]]
- [[Export Center]]
- [[Backup and Restore]]

<!-- END GENERATED ARCHITECTURE -->
