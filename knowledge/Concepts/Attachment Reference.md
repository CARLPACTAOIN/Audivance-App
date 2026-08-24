---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Attachment Reference

## Meaning

Stable metadata for a file imported into app-private storage.

## Belongs To

- [[Attachments and Local Files]]

## Relationships

- used by [[Treasury Source Fund]]
- used by [[Audit Event]]
- used by [[Liquidation Receipt]]
- included in [[COA Export Package]] and [[Backup Package]]

## Implementation

- `lib/core/domain/attachment_ref.dart` (Graphify, source)
- `lib/core/attachments/attachment_storage_service.dart` (Graphify, source)
- `lib/features/audit/data/audit_mappers.dart` (Graphify, source)

## Important Constraints

- Integrity verification checks existence, size, and checksum when available.

<!-- END GENERATED ARCHITECTURE -->
