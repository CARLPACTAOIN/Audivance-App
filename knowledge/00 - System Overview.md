---
type: overview
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Audivance System Overview

Audivance is an offline/local-first Flutter audit workspace for student organizations. It records treasury funds, event budgets, fund movements, liquidation receipts, reimbursements, audit review snapshots, local attachments, backups, and COA export packages without depending on a hosted service.

Graphify remains the machine-readable structural source. This Obsidian vault is a curated human-facing architecture map.

## Major Domains

- [[Application Shell]] - Bootstraps the Flutter app, decides setup or unlock routing, opens the local database, and hosts the ready-state workspace navigation.
- [[Local Setup and Unlock]] - Creates the one-device organization workspace and protects access with a local PIN-backed secure credential boundary.
- [[Persistence]] - Stores audit records in Drift/SQLite while exposing domain models through the repository boundary.
- [[Treasury]] - Tracks source fund balances, Add Fund entries, manual fund movements, and ledger rows for the organization workspace.
- [[Event Management]] - Creates auditable events with resolution metadata, split funding, status calculation, budget adjustments, and budget-vs-actual review snapshots.
- [[Liquidation and Reimbursements]] - Records liquidation receipts and line items, reduces accountability for released funds, and creates/payments claims for out-of-pocket spending.
- [[Budget Review]] - Computes budget-vs-actual summaries, health labels, variance, utilization, and immutable auditor review snapshots.
- [[Dashboard]] - Provides the offline workspace summary for treasury balance, approved budget, event statuses, pending reimbursements, and recent ledger activity.
- [[Export Center]] - Builds the COA-facing audit package with manifest, JSON, CSV, PDF reports, readiness checks, checksums, and attachments.
- [[Backup and Restore]] - Builds and validates local backup ZIPs that preserve the encrypted database files and app-private attachments.
- [[Attachments and Local Files]] - Imports selected files into app-private storage, records attachment metadata, verifies integrity, and resolves files for export/backup.

## Important Workflows

- [[First Launch and Unlock]]
- [[Add Treasury Funds]]
- [[Create Event and Allocate Budget]]
- [[Adjust Event Budget]]
- [[Record Liquidation]]
- [[Pay Reimbursement]]
- [[Budget Review Snapshot]]
- [[Generate COA Export]]
- [[Generate and Validate Backup]]

## Cross-Cutting Concerns

- [[Offline Local First]]
- [[Financial Validation]]
- [[Audit Logging]]
- [[System Generated Movements]]
- [[Attachment Integrity]]
- [[Database Encryption]]
- [[Export Checksums]]

## How To Explore

Start with the domain notes above or open [[Architecture Map]], [[Domain Index]], and [[Change Impact Map]].

Use Obsidian's Local Graph when inspecting a domain or concept. The full global graph should stay small enough to show architectural relationships, not every class or method.

For raw implementation-level relationships, inspect:

`graphify-out/graph.html`

For machine-readable graph data:

`graphify-out/graph.json`

## Graphify Snapshot

Graphify currently reports 2188 nodes, 2868 links, and 81 communities.

<!-- END GENERATED ARCHITECTURE -->
