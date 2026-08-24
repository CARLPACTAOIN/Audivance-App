---
type: concept
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# COA Export Package

## Meaning

The ZIP audit package submitted for COA review outside the live app.

## Belongs To

- [[Export Center]]

## Relationships

- contains [[Audit Event]]
- contains [[Fund Movement]]
- contains [[Audit Log Entry]]
- contains [[Attachment Reference]] files

## Implementation

- `lib/features/export/export_service.dart` (Graphify, source)
- `lib/features/export/export_package_writer.dart` (Graphify, source)
- `lib/features/export/pdf_report_service.dart` (Graphify, source)

## Important Constraints

- Readiness blockers prevent ZIP generation.
- Manifest and package entries carry checksums.

<!-- END GENERATED ARCHITECTURE -->
