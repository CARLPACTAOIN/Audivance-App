"""Generate the human-facing Audivance Obsidian architecture vault.

The vault is intentionally curated. Graphify remains the machine-readable graph;
these notes summarize major domains, concepts, workflows, and impact areas for
human navigation.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
VAULT = ROOT / "knowledge"
GRAPH_JSON = ROOT / "graphify-out" / "graph.json"
GRAPH_REPORT = ROOT / "graphify-out" / "GRAPH_REPORT.md"
BEGIN = "<!-- BEGIN GENERATED ARCHITECTURE -->"
END = "<!-- END GENERATED ARCHITECTURE -->"


@dataclass(frozen=True)
class Note:
    folder: str
    title: str
    note_type: str
    body: str
    aliases: tuple[str, ...] = ()

    @property
    def path(self) -> Path:
        return VAULT / self.folder / f"{self.title}.md" if self.folder else VAULT / f"{self.title}.md"


@dataclass(frozen=True)
class Domain:
    title: str
    purpose: str
    related: tuple[str, ...]
    concepts: tuple[str, ...]
    workflows: tuple[str, ...]
    implementation: dict[str, tuple[str, ...]]
    rules: tuple[str, ...]
    impact: tuple[str, ...]


@dataclass(frozen=True)
class Concept:
    title: str
    meaning: str
    belongs_to: tuple[str, ...]
    relationships: tuple[str, ...]
    implementation: tuple[str, ...]
    constraints: tuple[str, ...] = ()


@dataclass(frozen=True)
class Workflow:
    title: str
    purpose: str
    flow: tuple[str, ...]
    domains: tuple[str, ...]
    implementation: tuple[str, ...]
    rules: tuple[str, ...]
    impact: tuple[str, ...]


@dataclass(frozen=True)
class CrossCutting:
    title: str
    purpose: str
    applies_to: tuple[str, ...]
    implementation: tuple[str, ...]
    rules: tuple[str, ...]
    impact: tuple[str, ...]


DOMAINS: tuple[Domain, ...] = (
    Domain(
        title="Application Shell",
        purpose="Bootstraps the Flutter app, decides setup or unlock routing, opens the local database, and hosts the ready-state workspace navigation.",
        related=("Local Setup and Unlock", "Persistence", "Dashboard", "Treasury", "Event Management", "Export Center", "Backup and Restore"),
        concepts=("Local Account", "Organization Workspace", "Audit Repository"),
        workflows=("First Launch and Unlock",),
        implementation={
            "App Shell": ("lib/main.dart", "lib/app/audivance_app.dart", "lib/app/workspace_shell.dart"),
            "Startup": ("lib/app/app_startup_service.dart", "lib/app/credential_upgrade_screen.dart", "lib/app/unlock_screen.dart"),
            "Shared UI": ("lib/app/ui/app_ui.dart", "lib/app/ui/app_date_picker_form_field.dart", "lib/app/brand_logo.dart"),
            "Tests": ("test/widget_test.dart", "test/app/app_startup_service_test.dart", "test/app/app_date_picker_form_field_test.dart"),
        },
        rules=(
            "Startup is complete only after a local account and organization profile exist.",
            "Existing unsecured workspaces route through credential upgrade before the dashboard.",
            "The shell wires feature services together without embedding financial domain rules in widgets.",
        ),
        impact=("Local Setup and Unlock", "Persistence", "Dashboard", "Backup and Restore"),
    ),
    Domain(
        title="Local Setup and Unlock",
        purpose="Creates the one-device organization workspace and protects access with a local PIN-backed secure credential boundary.",
        related=("Application Shell", "Persistence", "Database Encryption"),
        concepts=("Local Account", "Organization Workspace", "Audit Database"),
        workflows=("First Launch and Unlock",),
        implementation={
            "Setup UI": ("lib/features/setup/setup_screen.dart",),
            "Unlock Boundary": ("lib/app/local_unlock_service.dart", "lib/app/unlock_screen.dart", "lib/app/credential_upgrade_screen.dart"),
            "Startup State": ("lib/app/app_startup_service.dart",),
            "Tests": ("test/app/local_unlock_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "The MVP preserves one organization account per device.",
            "PINs are not stored directly; the app stores a PBKDF2-HMAC-SHA256 credential envelope.",
            "The unlock service also provides the database key boundary used by encrypted database opening.",
        ),
        impact=("Application Shell", "Persistence", "Database Encryption", "Backup and Restore"),
    ),
    Domain(
        title="Persistence",
        purpose="Stores audit records in Drift/SQLite while exposing domain models through the repository boundary.",
        related=("Application Shell", "Treasury", "Event Management", "Liquidation and Reimbursements", "Export Center", "Backup and Restore"),
        concepts=("Audit Database", "Audit Repository", "Stable Local ID", "Attachment Reference"),
        workflows=("First Launch and Unlock", "Create Event and Allocate Budget", "Generate COA Export"),
        implementation={
            "Database": ("lib/features/audit/data/audit_database.dart", "lib/features/audit/data/audit_database.g.dart"),
            "Repository": ("lib/features/audit/data/audit_repository.dart", "lib/features/audit/data/drift_audit_repository.dart"),
            "Mapping": ("lib/features/audit/data/audit_mappers.dart",),
            "Opening and Encryption": ("lib/features/audit/data/audit_database_opener.dart", "lib/features/audit/data/audit_database_encryption_service.dart"),
            "Tests": ("test/data/drift_audit_repository_test.dart", "test/data/audit_database_encryption_service_test.dart"),
        },
        rules=(
            "Money is persisted as integer centavos.",
            "Stable IDs persist as text primary keys.",
            "System-generated fund movements are protected from repository update/delete.",
            "Audit logs are append-only through the public repository API.",
        ),
        impact=("Financial Validation", "Audit Logging", "Export Center", "Backup and Restore"),
    ),
    Domain(
        title="Treasury",
        purpose="Tracks source fund balances, Add Fund entries, manual fund movements, and ledger rows for the organization workspace.",
        related=("Event Management", "Liquidation and Reimbursements", "Dashboard", "Audit Logging", "Attachment Integrity"),
        concepts=("Treasury Source Fund", "Fund Movement", "Attachment Reference", "Officer"),
        workflows=("Add Treasury Funds", "Create Event and Allocate Budget", "Adjust Event Budget"),
        implementation={
            "Service": ("lib/features/treasury/treasury_service.dart",),
            "UI": ("lib/features/treasury/treasury_screen.dart", "lib/features/treasury/treasury_formatters.dart"),
            "Rules": ("lib/features/audit/domain/audit_rules.dart",),
            "Tests": ("test/features/treasury/treasury_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "Treasury Add Fund requires a supporting document attachment.",
            "Manual movements are limited to Fund Release, Transfer, and Return / Refund.",
            "Balance validation blocks movements when the available balance is insufficient.",
            "Fund movement references follow FM-YYYYMMDD-XXXXXXXX.",
        ),
        impact=("Event Management", "Dashboard", "Export Center", "Audit Logging"),
    ),
    Domain(
        title="Event Management",
        purpose="Creates auditable events with resolution metadata, split funding, status calculation, budget adjustments, and budget-vs-actual review snapshots.",
        related=("Treasury", "Liquidation and Reimbursements", "Budget Review", "Dashboard", "Export Center"),
        concepts=("Audit Event", "Event Funding Allocation", "Fund Movement", "Auditor Review Snapshot", "Budget Health"),
        workflows=("Create Event and Allocate Budget", "Adjust Event Budget", "Budget Review Snapshot", "Record Liquidation"),
        implementation={
            "Service": ("lib/features/events/event_service.dart",),
            "UI": ("lib/features/events/event_screen.dart",),
            "Rules": ("lib/features/audit/domain/audit_rules.dart",),
            "Tests": ("test/features/events/event_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "Event creation requires a resolution attachment.",
            "Split funding allocations must equal the event budget.",
            "Budget increases are blocked when source treasury balance is insufficient.",
            "Budget decreases are blocked when event Approved Budget balance is insufficient.",
            "Liquidated events cannot be adjusted.",
        ),
        impact=("Treasury", "Liquidation and Reimbursements", "Budget Review", "Export Center", "Audit Logging"),
    ),
    Domain(
        title="Liquidation and Reimbursements",
        purpose="Records liquidation receipts and line items, reduces accountability for released funds, and creates/payments claims for out-of-pocket spending.",
        related=("Event Management", "Treasury", "Budget Review", "Export Center", "Attachment Integrity"),
        concepts=("Liquidation Receipt", "Liquidation Line", "Reimbursement Claim", "Fund Movement", "Officer"),
        workflows=("Record Liquidation", "Pay Reimbursement", "Budget Review Snapshot"),
        implementation={
            "Service": ("lib/features/liquidation/liquidation_service.dart",),
            "UI": ("lib/features/events/event_screen.dart",),
            "Rules": ("lib/features/audit/domain/audit_rules.dart",),
            "Tests": ("test/features/liquidation/liquidation_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "Liquidation requires receipt metadata, line items, accountable officer, and receipt attachment.",
            "Released Funds entries create Liquidation Submitted fund movements.",
            "Out-of-Pocket entries create pending reimbursement claims.",
            "Reimbursement payment is blocked when the Approved Budget balance is insufficient.",
        ),
        impact=("Event Management", "Budget Review", "Export Center", "Audit Logging"),
    ),
    Domain(
        title="Budget Review",
        purpose="Computes budget-vs-actual summaries, health labels, variance, utilization, and immutable auditor review snapshots.",
        related=("Event Management", "Liquidation and Reimbursements", "Export Center", "Dashboard"),
        concepts=("Budget Health", "Auditor Review Snapshot", "Audit Event", "Liquidation Line", "Reimbursement Claim"),
        workflows=("Budget Review Snapshot", "Generate COA Export"),
        implementation={
            "Event Service": ("lib/features/events/event_service.dart",),
            "Export Service": ("lib/features/export/export_service.dart", "lib/features/export/pdf_report_service.dart"),
            "Tests": ("test/features/events/event_service_test.dart", "test/features/export/export_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "Budget health values are No Budget, Healthy, Watch, Over Budget, and Critical.",
            "Utilization is stored/exported as integer basis points.",
            "Auditor review snapshots do not mutate when later liquidation or budget changes occur.",
        ),
        impact=("Event Management", "Liquidation and Reimbursements", "Export Center"),
    ),
    Domain(
        title="Dashboard",
        purpose="Provides the offline workspace summary for treasury balance, approved budget, event statuses, pending reimbursements, and recent ledger activity.",
        related=("Treasury", "Event Management", "Liquidation and Reimbursements", "Export Center"),
        concepts=("Audit Event", "Fund Movement", "Reimbursement Claim", "Budget Health"),
        workflows=("Create Event and Allocate Budget", "Record Liquidation", "Pay Reimbursement"),
        implementation={
            "Service": ("lib/features/dashboard/dashboard_service.dart",),
            "Models": ("lib/features/dashboard/dashboard_models.dart",),
            "UI": ("lib/features/dashboard/dashboard_screen.dart",),
            "Tests": ("test/features/dashboard/dashboard_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "Dashboard values are computed from persisted repository records.",
            "Event status counts use EventRules.calculateStatus.",
            "Fresh setup shows zero-value metrics and readiness tasks instead of demo data.",
        ),
        impact=("Treasury", "Event Management", "Liquidation and Reimbursements"),
    ),
    Domain(
        title="Export Center",
        purpose="Builds the COA-facing audit package with manifest, JSON, CSV, PDF reports, readiness checks, checksums, and attachments.",
        related=("Treasury", "Event Management", "Liquidation and Reimbursements", "Budget Review", "Attachments and Local Files"),
        concepts=("COA Export Package", "Attachment Reference", "Audit Log Entry", "Auditor Review Snapshot"),
        workflows=("Generate COA Export", "Budget Review Snapshot"),
        implementation={
            "Service": ("lib/features/export/export_service.dart",),
            "Reports": ("lib/features/export/pdf_report_service.dart", "lib/features/export/pdf_report_actions.dart"),
            "Writers": ("lib/features/export/export_package_writer.dart",),
            "UI": ("lib/features/export/export_screen.dart",),
            "Tests": ("test/features/export/export_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "ZIP generation is blocked by readiness blockers.",
            "Warnings remain visible but do not prevent package generation.",
            "Reports and package entries include SHA-256 checksums.",
            "The package includes structured data, CSVs, PDFs, and app-private attachments.",
        ),
        impact=("COA Export Package", "Attachment Integrity", "Audit Logging", "Budget Review"),
    ),
    Domain(
        title="Backup and Restore",
        purpose="Builds and validates local backup ZIPs that preserve the encrypted database files and app-private attachments.",
        related=("Persistence", "Attachments and Local Files", "Database Encryption", "Application Shell"),
        concepts=("Backup Package", "Audit Database", "Attachment Reference"),
        workflows=("Generate and Validate Backup",),
        implementation={
            "Service": ("lib/features/backup/backup_service.dart",),
            "IO Boundary": ("lib/features/backup/backup_package_io.dart",),
            "UI": ("lib/features/backup/backup_screen.dart",),
            "Storage": ("lib/core/storage/audit_storage_paths.dart",),
            "Tests": ("test/features/backup/backup_service_test.dart",),
        },
        rules=(
            "Backups include encrypted SQLite database files and app-private attachments.",
            "Backup validation checks manifest type, required database entry, byte lengths, and SHA-256 checksums.",
            "Current backup labeling is same-device/key-context; cross-device recovery remains future work.",
        ),
        impact=("Persistence", "Database Encryption", "Attachments and Local Files"),
    ),
    Domain(
        title="Attachments and Local Files",
        purpose="Imports selected files into app-private storage, records attachment metadata, verifies integrity, and resolves files for export/backup.",
        related=("Treasury", "Event Management", "Liquidation and Reimbursements", "Export Center", "Backup and Restore"),
        concepts=("Attachment Reference", "COA Export Package", "Backup Package"),
        workflows=("Add Treasury Funds", "Create Event and Allocate Budget", "Record Liquidation", "Generate COA Export", "Generate and Validate Backup"),
        implementation={
            "Storage": ("lib/core/attachments/attachment_storage_service.dart", "lib/core/storage/audit_storage_paths.dart"),
            "Picker and UI": ("lib/core/attachments/attachment_picker.dart", "lib/core/attachments/attachment_selector.dart"),
            "Domain": ("lib/core/domain/attachment_ref.dart",),
            "Tests": ("test/core/attachment_storage_service_test.dart", "test/widget_test.dart"),
        },
        rules=(
            "Attachments are copied into app-private storage.",
            "AttachmentRef stores local path, original file name, size, and optional checksum.",
            "Export readiness blocks missing or corrupted required attachments.",
        ),
        impact=("Export Center", "Backup and Restore", "Attachment Integrity"),
    ),
)


CONCEPTS: tuple[Concept, ...] = (
    Concept("Organization Workspace", "The local single-organization audit workspace created during first launch.", ("Local Setup and Unlock",), ("contains [[Local Account]]", "owns [[Audit Event]] records", "exports a [[COA Export Package]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/setup/setup_screen.dart"), ("MVP scope is one organization account per device.",)),
    Concept("Local Account", "The local profile and credential state used to unlock the workspace.", ("Local Setup and Unlock",), ("unlocks [[Organization Workspace]]", "feeds [[Application Shell]] startup routing"), ("lib/features/audit/domain/audit_models.dart", "lib/app/local_unlock_service.dart", "lib/app/app_startup_service.dart"), ("PINs are represented by secure credential envelopes, not stored directly.",)),
    Concept("Officer", "An organization officer who can belong to Finance or Audit Committee and serve as an accountable holder.", ("Event Management", "Treasury", "Liquidation and Reimbursements"), ("can be holder for [[Fund Movement]]", "can be accountable officer for [[Liquidation Receipt]]", "can own [[Reimbursement Claim]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/audit/domain/audit_rules.dart"), ("Only one active head is allowed per committee.", "Committee heads must be assigned to a committee.")),
    Concept("Treasury Source Fund", "A source-specific fund balance available for allocation, release, transfer, or return.", ("Treasury",), ("funds [[Audit Event]] through [[Event Funding Allocation]]", "requires [[Attachment Reference]] for Add Fund"), ("lib/features/audit/domain/audit_models.dart", "lib/features/treasury/treasury_service.dart"), ("Add Fund amount must be positive.", "Add Fund requires a supporting attachment.")),
    Concept("Audit Event", "An auditable organization event with approved budget, dates, resolution metadata, and liquidation state.", ("Event Management",), ("funded by [[Event Funding Allocation]]", "produces [[Liquidation Receipt]]", "summarized by [[Budget Health]]", "included in [[COA Export Package]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/events/event_service.dart"), ("Event resolution attachment is required.", "Status is date-driven unless liquidated.")),
    Concept("Event Funding Allocation", "The split funding record connecting an event budget to one or more treasury sources.", ("Event Management", "Treasury"), ("allocates [[Treasury Source Fund]] to [[Audit Event]]", "generates protected [[Fund Movement]] rows"), ("lib/features/audit/domain/audit_models.dart", "lib/features/events/event_service.dart"), ("Allocation total must equal the event budget.",)),
    Concept("Fund Movement", "The ledger record for Add Fund, budget allocations, budget adjustments, manual movements, liquidation submissions, and reimbursement payments.", ("Treasury", "Event Management", "Liquidation and Reimbursements"), ("updates [[Treasury Source Fund]] balances", "references [[Audit Event]] when event-scoped", "is protected by [[System Generated Movements]] when generated by workflows"), ("lib/features/audit/domain/audit_models.dart", "lib/features/treasury/treasury_service.dart", "lib/features/liquidation/liquidation_service.dart"), ("System-generated rows are readable but protected from manual edit/delete.",)),
    Concept("Liquidation Receipt", "Receipt-level liquidation metadata for one event, including payee, evidence number, funding mode, accountable officer, and attachment.", ("Liquidation and Reimbursements",), ("contains [[Liquidation Line]]", "requires [[Attachment Reference]]", "may create [[Reimbursement Claim]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/liquidation/liquidation_service.dart"), ("Receipt attachment is required.",)),
    Concept("Liquidation Line", "A product/item row under a liquidation receipt with quantity and unit cost.", ("Liquidation and Reimbursements", "Budget Review"), ("belongs to [[Liquidation Receipt]]", "contributes to actual spending for [[Budget Health]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/liquidation/liquidation_service.dart"), ("Line description, quantity, and unit cost must be valid.",)),
    Concept("Reimbursement Claim", "A pending or paid claim created from out-of-pocket liquidation spending.", ("Liquidation and Reimbursements",), ("created by [[Liquidation Line]]", "paid through protected [[Fund Movement]]", "affects [[Budget Health]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/liquidation/liquidation_service.dart"), ("Only pending claims can be paid.", "Payment is blocked when Approved Budget balance is insufficient.")),
    Concept("Budget Health", "The budget status derived from event budget and actual liquidation/reimbursement totals.", ("Budget Review",), ("summarizes [[Audit Event]]", "uses [[Liquidation Line]] and [[Reimbursement Claim]] actuals", "captured by [[Auditor Review Snapshot]]"), ("lib/features/events/event_service.dart", "lib/features/export/export_service.dart", "lib/features/export/pdf_report_service.dart"), ("Uses noBudget, healthy, watch, overBudget, and critical values.",)),
    Concept("Auditor Review Snapshot", "An immutable saved review of event findings, cause, recommendation, budget, actual, variance, utilization, and health.", ("Budget Review", "Event Management"), ("captures [[Budget Health]]", "is exported in [[COA Export Package]]", "appends [[Audit Log Entry]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/events/event_service.dart", "lib/features/export/export_service.dart"), ("Findings, cause, and recommendation are required.", "Snapshots do not change when later numbers change.")),
    Concept("Attachment Reference", "Stable metadata for a file imported into app-private storage.", ("Attachments and Local Files",), ("used by [[Treasury Source Fund]]", "used by [[Audit Event]]", "used by [[Liquidation Receipt]]", "included in [[COA Export Package]] and [[Backup Package]]"), ("lib/core/domain/attachment_ref.dart", "lib/core/attachments/attachment_storage_service.dart", "lib/features/audit/data/audit_mappers.dart"), ("Integrity verification checks existence, size, and checksum when available.",)),
    Concept("Stable Local ID", "A local identifier used so exported records remain consistently referenceable.", ("Persistence",), ("identifies [[Audit Event]]", "identifies [[Fund Movement]]", "identifies [[Attachment Reference]]"), ("lib/core/domain/identity.dart", "lib/core/domain/stable_id_generator.dart"), ("Favor stable UUID/ULID-style IDs for exportable records.",)),
    Concept("Audit Repository", "The application boundary that exposes domain models while hiding Drift rows and persistence details.", ("Persistence",), ("implemented by [[Audit Database]] adapter", "used by service domains", "enforces repository-level protections"), ("lib/features/audit/data/audit_repository.dart", "lib/features/audit/data/drift_audit_repository.dart"), ("System-generated fund movements cannot be modified or deleted through the repository.",)),
    Concept("Audit Database", "The Drift SQLite schema for local accounts, organizations, events, funds, liquidation, reimbursement, reviews, and logs.", ("Persistence",), ("opened by [[Application Shell]]", "backed up in [[Backup Package]]", "exported through [[Audit Repository]] reads"), ("lib/features/audit/data/audit_database.dart", "lib/features/audit/data/audit_database_opener.dart", "lib/features/audit/data/audit_database_encryption_service.dart"), ("Schema version is currently 3.", "Database-at-rest encryption is enabled when a secure key is available.")),
    Concept("Audit Log Entry", "Append-only record of financial and administrative changes.", ("Audit Logging", "Persistence"), ("created by mutating workflows", "included in [[COA Export Package]]"), ("lib/features/audit/domain/audit_models.dart", "lib/features/audit/data/audit_repository.dart"), ("Audit logs are append-only from normal app workflows.",)),
    Concept("COA Export Package", "The ZIP audit package submitted for COA review outside the live app.", ("Export Center",), ("contains [[Audit Event]]", "contains [[Fund Movement]]", "contains [[Audit Log Entry]]", "contains [[Attachment Reference]] files"), ("lib/features/export/export_service.dart", "lib/features/export/export_package_writer.dart", "lib/features/export/pdf_report_service.dart"), ("Readiness blockers prevent ZIP generation.", "Manifest and package entries carry checksums.")),
    Concept("Backup Package", "A local backup ZIP containing database files and app-private attachments.", ("Backup and Restore",), ("contains [[Audit Database]] files", "contains [[Attachment Reference]] files", "validated before restore"), ("lib/features/backup/backup_service.dart", "lib/features/backup/backup_package_io.dart"), ("Current encrypted backups are same-device/key-context backups.",)),
)


WORKFLOWS: tuple[Workflow, ...] = (
    Workflow("First Launch and Unlock", "Routes a new or returning user into setup, credential upgrade, unlock, or the ready dashboard.", ("Open app", "Resolve setup state", "Create local account and organization if needed", "Configure PIN credential", "Open encrypted workspace", "Show workspace shell"), ("Application Shell", "Local Setup and Unlock", "Persistence"), ("lib/app/audivance_app.dart", "lib/app/app_startup_service.dart", "lib/features/setup/setup_screen.dart", "lib/app/local_unlock_service.dart"), ("Setup complete requires both local account and organization.", "Existing uncredentialed workspaces route through credential upgrade."), ("Database Encryption", "Backup and Restore")),
    Workflow("Add Treasury Funds", "Adds money to a source-specific treasury balance while preserving attachment evidence and a protected ledger row.", ("Select source type", "Attach supporting document", "Validate positive amount", "Create or update source fund", "Create protected Add Fund movement", "Append audit log"), ("Treasury", "Attachments and Local Files", "Audit Logging"), ("lib/features/treasury/treasury_service.dart", "lib/features/treasury/treasury_screen.dart", "lib/core/attachments/attachment_selector.dart"), ("Supporting attachment is required.", "Amount must be greater than zero."), ("Export Center", "Dashboard")),
    Workflow("Create Event and Allocate Budget", "Creates an event, allocates its budget from treasury sources, and records protected budget allocation movements.", ("Enter event metadata", "Attach resolution", "Add split funding rows", "Validate allocation total", "Persist event and allocations", "Decrease source balances", "Create budget allocation movements", "Append audit log"), ("Event Management", "Treasury", "Attachments and Local Files", "Audit Logging"), ("lib/features/events/event_service.dart", "lib/features/events/event_screen.dart", "lib/features/audit/domain/audit_rules.dart"), ("Resolution attachment is required.", "Split funding allocations must equal budget.", "Each source must have sufficient balance."), ("Dashboard", "Export Center", "Budget Review")),
    Workflow("Adjust Event Budget", "Adjusts event budget through ledger-only changes while preserving original split-funding allocations.", ("Choose increase or decrease", "Select source for increase if needed", "Enter amount and remarks", "Validate source or approved budget balance", "Update event budget/balance", "Create protected budget adjustment movement", "Append audit log"), ("Event Management", "Treasury", "Audit Logging"), ("lib/features/events/event_service.dart", "lib/features/events/event_screen.dart"), ("Remarks are required.", "Budget decreases cannot overdraw Approved Budget balance.", "Liquidated events cannot be adjusted."), ("Budget Review", "Dashboard", "Export Center")),
    Workflow("Record Liquidation", "Records receipt metadata and line items for a completed event and routes released-funds versus out-of-pocket behavior.", ("Select event", "Enter receipt metadata", "Attach receipt", "Add line items", "Validate event status and budget", "Persist receipt and lines", "Released Funds: create liquidation movement", "Out-of-Pocket: create reimbursement claim", "Append audit log"), ("Liquidation and Reimbursements", "Event Management", "Attachments and Local Files", "Audit Logging"), ("lib/features/liquidation/liquidation_service.dart", "lib/features/events/event_screen.dart"), ("Only completed events can be liquidated.", "Receipt attachment and at least one valid line are required.", "Released-funds liquidation requires sufficient Approved Budget balance."), ("Budget Review", "Export Center", "Dashboard")),
    Workflow("Pay Reimbursement", "Pays a pending out-of-pocket claim from event Approved Budget and records a protected reimbursement payment movement.", ("Select pending claim", "Review amount and available event balance", "Validate claim state and balance", "Create reimbursement payment movement", "Mark claim paid", "Append audit log"), ("Liquidation and Reimbursements", "Event Management", "Treasury", "Audit Logging"), ("lib/features/liquidation/liquidation_service.dart", "lib/features/events/event_screen.dart"), ("Only pending claims can be paid.", "Payment is blocked when Approved Budget balance is insufficient."), ("Budget Review", "Dashboard", "Export Center")),
    Workflow("Budget Review Snapshot", "Captures a point-in-time auditor review of budget-vs-actual health for an event.", ("Open budget review", "Compute actuals, variance, utilization, health", "Enter findings, cause, recommendation", "Persist immutable snapshot", "Append audit log", "Export snapshot in JSON/CSV"), ("Budget Review", "Event Management", "Export Center", "Audit Logging"), ("lib/features/events/event_service.dart", "lib/features/events/event_screen.dart", "lib/features/export/export_service.dart"), ("Findings, cause, and recommendation are required.", "Saved snapshots remain unchanged after later event changes."), ("COA Export Package",)),
    Workflow("Generate COA Export", "Builds the review package that replaces live COA access in the offline MVP.", ("Load export data", "Run readiness checks", "Verify required attachments", "Build JSON and CSV data", "Generate PDF reports", "Copy attachments", "Build manifest and checksums", "Write ZIP"), ("Export Center", "Treasury", "Event Management", "Liquidation and Reimbursements", "Budget Review", "Attachments and Local Files"), ("lib/features/export/export_service.dart", "lib/features/export/pdf_report_service.dart", "lib/features/export/export_package_writer.dart"), ("Readiness blockers prevent ZIP generation.", "Missing or corrupted stored attachments block generation.", "Warnings remain visible but do not block export."), ("Audit Logging", "Attachment Integrity")),
    Workflow("Generate and Validate Backup", "Creates and validates a same-device backup containing database files and app-private attachments.", ("Choose Generate Backup", "Collect database and sidecar files", "Collect attachment files", "Write backup manifest", "Generate backup ZIP", "Validate manifest, sizes, and checksums"), ("Backup and Restore", "Persistence", "Attachments and Local Files"), ("lib/features/backup/backup_service.dart", "lib/features/backup/backup_screen.dart", "lib/core/storage/audit_storage_paths.dart"), ("Backup validation requires a manifest and database entry.", "Checksums and byte lengths must match manifest entries."), ("Database Encryption", "Application Shell")),
)


CROSS_CUTTING: tuple[CrossCutting, ...] = (
    CrossCutting("Offline Local First", "The MVP works without hosted services, OAuth, live COA access, or realtime sync.", ("Application Shell", "Persistence", "Export Center", "Backup and Restore"), ("OFFLINE_APPLICATION_PRD.md", "MEMORY.md", "lib/features/audit/data/audit_database.dart"), ("Do not add cloud services unless explicitly requested.", "COA review happens through exported packages."), ("Application Shell", "Persistence", "Treasury", "Event Management", "Export Center", "Backup and Restore")),
    CrossCutting("Financial Validation", "Financial mutations must validate balances and required evidence before saving.", ("Treasury", "Event Management", "Liquidation and Reimbursements", "Budget Review"), ("lib/features/audit/domain/audit_rules.dart", "lib/features/treasury/treasury_service.dart", "lib/features/events/event_service.dart", "lib/features/liquidation/liquidation_service.dart"), ("Never bypass balance validation.", "Required attachment rules belong in domain/application logic, not only UI."), ("Audit Logging", "Export Center")),
    CrossCutting("Audit Logging", "Financial and administrative mutations append readable audit records for later review and export.", ("Treasury", "Event Management", "Liquidation and Reimbursements", "Budget Review", "Export Center"), ("lib/features/audit/domain/audit_models.dart", "lib/features/audit/data/audit_repository.dart", "lib/features/treasury/treasury_service.dart", "lib/features/events/event_service.dart", "lib/features/liquidation/liquidation_service.dart"), ("Audit logs are append-only from normal app workflows.", "Logs are included in COA exports."), ("Persistence", "COA Export Package")),
    CrossCutting("System Generated Movements", "Workflow-created ledger rows are visible to users but protected from manual edit/delete.", ("Treasury", "Event Management", "Liquidation and Reimbursements", "Persistence"), ("lib/features/audit/domain/audit_rules.dart", "lib/features/audit/data/drift_audit_repository.dart", "lib/features/treasury/treasury_service.dart", "lib/features/events/event_service.dart", "lib/features/liquidation/liquidation_service.dart"), ("Repository update/delete rejects protected fund movements.",), ("Audit Logging", "Export Center")),
    CrossCutting("Attachment Integrity", "Required files are copied locally and verified by existence, size, and checksum before export or backup use.", ("Attachments and Local Files", "Treasury", "Event Management", "Liquidation and Reimbursements", "Export Center", "Backup and Restore"), ("lib/core/attachments/attachment_storage_service.dart", "lib/core/domain/attachment_ref.dart", "lib/features/export/export_service.dart", "lib/features/backup/backup_service.dart"), ("Export blocks missing or corrupted required attachments.", "Backups include attachments and validate checksums."), ("COA Export Package", "Backup Package")),
    CrossCutting("Database Encryption", "The app opens local SQLite storage with a secure session key and supports plaintext-to-encrypted migration.", ("Application Shell", "Local Setup and Unlock", "Persistence", "Backup and Restore"), ("lib/app/local_unlock_service.dart", "lib/features/audit/data/audit_database_opener.dart", "lib/features/audit/data/audit_database_encryption_service.dart"), ("Encrypted database opening is tied to the local secure credential/key context.", "Cross-device encrypted backup recovery remains future work."), ("Backup and Restore", "First Launch and Unlock")),
    CrossCutting("Export Checksums", "COA package files and PDF reports carry SHA-256 checksums in package metadata.", ("Export Center", "Budget Review", "Attachments and Local Files"), ("lib/features/export/export_service.dart", "lib/features/export/pdf_report_service.dart"), ("Manifest checksums support accidental tampering detection.",), ("COA Export Package",)),
)


def read_graph_sources() -> set[str]:
    if not GRAPH_JSON.exists():
        return set()
    graph = json.loads(GRAPH_JSON.read_text(encoding="utf-8"))
    sources = set()
    for node in graph.get("nodes", []):
        source = node.get("source_file")
        if source:
            sources.add(source.replace("\\", "/"))
    for link in graph.get("links", []):
        source = link.get("source_file")
        if source:
            sources.add(source.replace("\\", "/"))
    return sources


def graph_summary() -> str:
    if not GRAPH_JSON.exists():
        return "Graphify graph.json is not present."
    graph = json.loads(GRAPH_JSON.read_text(encoding="utf-8"))
    return (
        f"Graphify currently reports {len(graph.get('nodes', []))} nodes, "
        f"{len(graph.get('links', []))} links, and "
        f"{len({n.get('community') for n in graph.get('nodes', []) if n.get('community') is not None})} communities."
    )


def wiki(name: str) -> str:
    return f"[[{name}]]"


def bullet_links(items: Iterable[str]) -> str:
    return "\n".join(f"- {wiki(item)}" for item in items) if items else "- None identified."


def bullet_code(items: Iterable[str], graph_sources: set[str]) -> str:
    rows = []
    for item in items:
        normalized = item.replace("\\", "/")
        exists = (ROOT / item).exists()
        in_graph = normalized in graph_sources
        suffix = []
        if in_graph:
            suffix.append("Graphify")
        if exists:
            suffix.append("source")
        label = f" ({', '.join(suffix)})" if suffix else ""
        rows.append(f"- `{item}`{label}")
    return "\n".join(rows) if rows else "- None identified."


def bullets(items: Iterable[str]) -> str:
    return "\n".join(f"- {item}" for item in items) if items else "- None identified."


def domain_body(domain: Domain, graph_sources: set[str]) -> str:
    impl = []
    for group, files in domain.implementation.items():
        impl.append(f"### {group}\n{bullet_code(files, graph_sources)}")
    return f"""# {domain.title}

## Purpose

{domain.purpose}

## Related Domains

{bullet_links(domain.related)}

## Key Concepts

{bullet_links(domain.concepts)}

## Main Workflows

{bullet_links(domain.workflows)}

## Important Implementation

{'\n\n'.join(impl)}

## Important Rules

{bullets(domain.rules)}

## Change Impact

Changes in this domain may affect:

{bullet_links(domain.impact)}
"""


def concept_body(concept: Concept, graph_sources: set[str]) -> str:
    return f"""# {concept.title}

## Meaning

{concept.meaning}

## Belongs To

{bullet_links(concept.belongs_to)}

## Relationships

{bullets(concept.relationships)}

## Implementation

{bullet_code(concept.implementation, graph_sources)}

## Important Constraints

{bullets(concept.constraints)}
"""


def workflow_body(workflow: Workflow, graph_sources: set[str]) -> str:
    flow = "\n  -> ".join(workflow.flow)
    return f"""# {workflow.title}

## Purpose

{workflow.purpose}

## Flow

```text
{flow}
```

## Participating Domains

{bullet_links(workflow.domains)}

## Important Implementation

{bullet_code(workflow.implementation, graph_sources)}

## Rules And Failure Cases

{bullets(workflow.rules)}

## Change Impact

{bullet_links(workflow.impact)}
"""


def cross_body(item: CrossCutting, graph_sources: set[str]) -> str:
    return f"""# {item.title}

## Purpose

{item.purpose}

## Applies To

{bullet_links(item.applies_to)}

## Important Implementation

{bullet_code(item.implementation, graph_sources)}

## Important Rules

{bullets(item.rules)}

## Change Impact

{bullet_links(item.impact)}
"""


def frontmatter(note_type: str, aliases: Iterable[str]) -> str:
    alias_lines = "".join(f"\n  - {alias}" for alias in aliases)
    aliases_block = f"\naliases:{alias_lines}" if alias_lines else ""
    return f"""---
type: {note_type}
status: generated
source: graphify-and-repository-docs{aliases_block}
---
"""


def render_note(note: Note) -> str:
    generated = f"{BEGIN}\n\n{note.body.rstrip()}\n\n{END}\n"
    return f"{frontmatter(note.note_type, note.aliases)}\n{generated}"


def write_note(note: Note) -> bool:
    rendered = render_note(note)
    path = note.path
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        existing = path.read_text(encoding="utf-8")
        pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.DOTALL)
        if pattern.search(existing):
            replacement = f"{BEGIN}\n\n{note.body.rstrip()}\n\n{END}"
            updated = pattern.sub(lambda _: replacement, existing)
        else:
            updated = existing.rstrip() + "\n\n" + f"{BEGIN}\n\n{note.body.rstrip()}\n\n{END}\n"
    else:
        updated = rendered
    if path.exists() and path.read_text(encoding="utf-8") == updated:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def overview_body() -> str:
    domains = "\n".join(f"- {wiki(domain.title)} - {domain.purpose}" for domain in DOMAINS)
    workflows = "\n".join(f"- {wiki(workflow.title)}" for workflow in WORKFLOWS)
    concerns = "\n".join(f"- {wiki(item.title)}" for item in CROSS_CUTTING)
    return f"""# Audivance System Overview

Audivance is an offline/local-first Flutter audit workspace for student organizations. It records treasury funds, event budgets, fund movements, liquidation receipts, reimbursements, audit review snapshots, local attachments, backups, and COA export packages without depending on a hosted service.

Graphify remains the machine-readable structural source. This Obsidian vault is a curated human-facing architecture map.

## Major Domains

{domains}

## Important Workflows

{workflows}

## Cross-Cutting Concerns

{concerns}

## How To Explore

Start with the domain notes above or open [[Architecture Map]], [[Domain Index]], and [[Change Impact Map]].

Use Obsidian's Local Graph when inspecting a domain or concept. The full global graph should stay small enough to show architectural relationships, not every class or method.

For raw implementation-level relationships, inspect:

`graphify-out/graph.html`

For machine-readable graph data:

`graphify-out/graph.json`

## Graphify Snapshot

{graph_summary()}
"""


def architecture_map_body() -> str:
    return """# Architecture Map

```text
Audivance Offline App
  -> Application Shell
      -> Local Setup and Unlock
      -> Dashboard
      -> Treasury
      -> Event Management
      -> Export Center
      -> Backup and Restore
  -> Persistence
      -> Audit Repository
      -> Audit Database
      -> Database Encryption
  -> Audit Workflows
      -> Treasury
      -> Event Management
      -> Liquidation and Reimbursements
      -> Budget Review
  -> Evidence and Handoff
      -> Attachments and Local Files
      -> COA Export Package
      -> Backup Package
```

## Primary Navigation

- [[Application Shell]]
- [[Local Setup and Unlock]]
- [[Persistence]]
- [[Treasury]]
- [[Event Management]]
- [[Liquidation and Reimbursements]]
- [[Budget Review]]
- [[Export Center]]
- [[Backup and Restore]]
- [[Attachments and Local Files]]

## Important Bridges

- [[Audit Repository]] connects feature services to Drift persistence.
- [[Fund Movement]] connects [[Treasury]], [[Event Management]], and [[Liquidation and Reimbursements]].
- [[Attachment Reference]] connects evidence-bearing workflows to [[Export Center]] and [[Backup and Restore]].
- [[Audit Log Entry]] connects mutating workflows to COA review.
"""


def domain_index_body() -> str:
    rows = []
    for domain in DOMAINS:
        rows.append(
            f"| [[{domain.title}]] | {', '.join(wiki(c) for c in domain.concepts[:4])} | {', '.join(wiki(w) for w in domain.workflows[:3])} |"
        )
    return """# Domain Index

| Domain | Key Concepts | Main Workflows |
| --- | --- | --- |
""" + "\n".join(rows) + "\n"


def change_impact_body() -> str:
    sections = []
    for domain in DOMAINS:
        sections.append(
            f"## {domain.title}\n\nChanges here may affect:\n\n{bullet_links(domain.impact)}"
        )
    return "# Change Impact Map\n\n" + "\n\n".join(sections) + "\n"


def readme_body() -> str:
    return """# Knowledge Vault README

Open the `knowledge/` directory directly as an Obsidian vault.

This vault is generated architecture documentation for humans. It does not replace Graphify:

- Graphify raw data: `../graphify-out/graph.json`
- Graphify visual graph: `../graphify-out/graph.html`
- Graphify report: `../graphify-out/GRAPH_REPORT.md`

Generated content is bounded by:

```text
<!-- BEGIN GENERATED ARCHITECTURE -->
<!-- END GENERATED ARCHITECTURE -->
```

Human-maintained notes can be added outside those markers. To regenerate:

```powershell
python dev-orchestrator\\sync_knowledge.py
```

The generator is deterministic and intentionally curates architecture-level notes instead of mirroring every Graphify node.
"""


def obsidian_config() -> dict[Path, str]:
    return {
        VAULT / ".obsidian" / "app.json": json.dumps(
            {
                "alwaysUpdateLinks": True,
                "newFileLocation": "folder",
                "newFileFolderPath": "Inbox",
                "showUnsupportedFiles": False,
            },
            indent=2,
        )
        + "\n",
        VAULT / ".obsidian" / "graph.json": json.dumps(
            {
                "collapse-filter": True,
                "search": "",
                "showTags": True,
                "showAttachments": False,
                "hideUnresolved": False,
                "showOrphans": True,
                "collapse-color-groups": True,
                "colorGroups": [
                    {"query": "path:Domains", "color": {"a": 1, "rgb": 14701138}},
                    {"query": "path:Concepts", "color": {"a": 1, "rgb": 11444633}},
                    {"query": "path:Workflows", "color": {"a": 1, "rgb": 5431637}},
                    {"query": "path:Cross-Cutting", "color": {"a": 1, "rgb": 16755200}},
                ],
            },
            indent=2,
        )
        + "\n",
    }


def write_static_file(path: Path, content: str) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return False
    path.write_text(content, encoding="utf-8")
    return True


def all_notes(graph_sources: set[str]) -> list[Note]:
    notes: list[Note] = [
        Note("", "00 - System Overview", "overview", overview_body()),
        Note("Maps", "Architecture Map", "map", architecture_map_body()),
        Note("Maps", "Domain Index", "map", domain_index_body()),
        Note("Maps", "Change Impact Map", "map", change_impact_body()),
        Note("", "README", "readme", readme_body()),
    ]
    notes.extend(
        Note("Domains", domain.title, "domain", domain_body(domain, graph_sources))
        for domain in DOMAINS
    )
    notes.extend(
        Note("Concepts", concept.title, "concept", concept_body(concept, graph_sources))
        for concept in CONCEPTS
    )
    notes.extend(
        Note("Workflows", workflow.title, "workflow", workflow_body(workflow, graph_sources))
        for workflow in WORKFLOWS
    )
    notes.extend(
        Note("Cross-Cutting", item.title, "cross-cutting", cross_body(item, graph_sources))
        for item in CROSS_CUTTING
    )
    return notes


def collect_defined_titles(notes: Iterable[Note]) -> set[str]:
    return {note.title for note in notes}


def collect_wiki_links(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    return {match.group(1).split("|", 1)[0].split("#", 1)[0] for match in re.finditer(r"\[\[([^\]]+)\]\]", text)}


def validate_links(notes: list[Note]) -> list[str]:
    defined = collect_defined_titles(notes)
    unresolved: set[str] = set()
    for path in VAULT.rglob("*.md"):
        for link in collect_wiki_links(path):
            if link and link not in defined:
                unresolved.add(link)
    return sorted(unresolved)


def main() -> int:
    graph_sources = read_graph_sources()
    notes = all_notes(graph_sources)
    changed = 0
    for note in notes:
        changed += 1 if write_note(note) else 0
    for path, content in obsidian_config().items():
        changed += 1 if write_static_file(path, content) else 0
    unresolved = validate_links(notes)

    counts = {
        "domains": len(DOMAINS),
        "concepts": len(CONCEPTS),
        "workflows": len(WORKFLOWS),
        "cross_cutting": len(CROSS_CUTTING),
        "maps": 3,
        "changed_files": changed,
        "unresolved_links": unresolved,
    }
    print(json.dumps(counts, indent=2))
    return 1 if unresolved else 0


if __name__ == "__main__":
    raise SystemExit(main())
