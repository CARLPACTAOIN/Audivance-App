---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Application Shell

## Purpose

Bootstraps the Flutter app, decides setup or unlock routing, opens the local database, and hosts the ready-state workspace navigation.

## Related Domains

- [[Local Setup and Unlock]]
- [[Persistence]]
- [[Dashboard]]
- [[Treasury]]
- [[Event Management]]
- [[Export Center]]
- [[Backup and Restore]]

## Key Concepts

- [[Local Account]]
- [[Organization Workspace]]
- [[Audit Repository]]

## Main Workflows

- [[First Launch and Unlock]]

## Important Implementation

### App Shell
- `lib/main.dart` (Graphify, source)
- `lib/app/audivance_app.dart` (Graphify, source)
- `lib/app/workspace_shell.dart` (Graphify, source)

### Startup
- `lib/app/app_startup_service.dart` (Graphify, source)
- `lib/app/credential_upgrade_screen.dart` (Graphify, source)
- `lib/app/unlock_screen.dart` (Graphify, source)

### Shared UI
- `lib/app/ui/app_ui.dart` (Graphify, source)
- `lib/app/ui/app_date_picker_form_field.dart` (Graphify, source)
- `lib/app/brand_logo.dart` (Graphify, source)

### Tests
- `test/widget_test.dart` (Graphify, source)
- `test/app/app_startup_service_test.dart` (Graphify, source)
- `test/app/app_date_picker_form_field_test.dart` (Graphify, source)

## Important Rules

- Startup is complete only after a local account and organization profile exist.
- Existing unsecured workspaces route through credential upgrade before the dashboard.
- The shell wires feature services together without embedding financial domain rules in widgets.

## Change Impact

Changes in this domain may affect:

- [[Local Setup and Unlock]]
- [[Persistence]]
- [[Dashboard]]
- [[Backup and Restore]]

<!-- END GENERATED ARCHITECTURE -->
