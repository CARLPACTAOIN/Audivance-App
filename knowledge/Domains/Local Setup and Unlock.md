---
type: domain
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Local Setup and Unlock

## Purpose

Creates the one-device organization workspace and protects access with a local PIN-backed secure credential boundary.

## Related Domains

- [[Application Shell]]
- [[Persistence]]
- [[Database Encryption]]

## Key Concepts

- [[Local Account]]
- [[Organization Workspace]]
- [[Audit Database]]

## Main Workflows

- [[First Launch and Unlock]]

## Important Implementation

### Setup UI
- `lib/features/setup/setup_screen.dart` (Graphify, source)

### Unlock Boundary
- `lib/app/local_unlock_service.dart` (Graphify, source)
- `lib/app/unlock_screen.dart` (Graphify, source)
- `lib/app/credential_upgrade_screen.dart` (Graphify, source)

### Startup State
- `lib/app/app_startup_service.dart` (Graphify, source)

### Tests
- `test/app/local_unlock_service_test.dart` (Graphify, source)
- `test/widget_test.dart` (Graphify, source)

## Important Rules

- The MVP preserves one organization account per device.
- PINs are not stored directly; the app stores a PBKDF2-HMAC-SHA256 credential envelope.
- The unlock service also provides the database key boundary used by encrypted database opening.

## Change Impact

Changes in this domain may affect:

- [[Application Shell]]
- [[Persistence]]
- [[Database Encryption]]
- [[Backup and Restore]]

<!-- END GENERATED ARCHITECTURE -->
