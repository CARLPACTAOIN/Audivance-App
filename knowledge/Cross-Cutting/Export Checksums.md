---
type: cross-cutting
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Export Checksums

## Purpose

COA package files and PDF reports carry SHA-256 checksums in package metadata.

## Applies To

- [[Export Center]]
- [[Budget Review]]
- [[Attachments and Local Files]]

## Important Implementation

- `lib/features/export/export_service.dart` (Graphify, source)
- `lib/features/export/pdf_report_service.dart` (Graphify, source)

## Important Rules

- Manifest checksums support accidental tampering detection.

## Change Impact

- [[COA Export Package]]

<!-- END GENERATED ARCHITECTURE -->
