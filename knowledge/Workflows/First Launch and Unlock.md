---
type: workflow
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# First Launch and Unlock

## Purpose

Routes a new or returning user into setup, credential upgrade, unlock, or the ready dashboard.

## Flow

```text
Open app
  -> Resolve setup state
  -> Create local account and organization if needed
  -> Configure PIN credential
  -> Open encrypted workspace
  -> Show workspace shell
```

## Participating Domains

- [[Application Shell]]
- [[Local Setup and Unlock]]
- [[Persistence]]

## Important Implementation

- `lib/app/audivance_app.dart` (Graphify, source)
- `lib/app/app_startup_service.dart` (Graphify, source)
- `lib/features/setup/setup_screen.dart` (Graphify, source)
- `lib/app/local_unlock_service.dart` (Graphify, source)

## Rules And Failure Cases

- Setup complete requires both local account and organization.
- Existing uncredentialed workspaces route through credential upgrade.

## Change Impact

- [[Database Encryption]]
- [[Backup and Restore]]

<!-- END GENERATED ARCHITECTURE -->
