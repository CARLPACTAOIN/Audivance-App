# Agent Rules

## Project Context

Audivance is a Flutter offline audit app for student organizations. Read `OFFLINE_APPLICATION_PRD.md`, `MEMORY.md`, and `HANDOFF.md` before making product or architecture changes.

## Scope Rules

- Keep the MVP offline/local-first.
- Do not add cloud services, OAuth, hosted databases, email flows, or sync unless explicitly requested.
- Preserve one organization account per device for MVP unless the scope changes.
- Treat COA review as an exported package workflow, not a live dashboard workflow.
- Favor stable local IDs such as UUIDs or ULIDs for exportable records.

## Financial Correctness Rules

- Never bypass balance validation for treasury, event budgets, fund releases, transfers, returns, liquidation, or reimbursements.
- Keep system-generated fund movements readable but protected from manual edit/delete.
- Add audit logs for financial and administrative mutations.
- Audit logs must be append-only from normal app workflows.
- Required attachment rules in the PRD must be enforced in domain/application logic, not only in UI.
- Export and backup logic must include both structured data and local attachments.

## Flutter Engineering Rules

- Follow existing Dart and Flutter lint rules in `analysis_options.yaml`.
- Keep UI, application/domain logic, persistence, and export/reporting code separated.
- Prefer feature-based organization under `lib/` once implementation begins.
- Keep widgets small enough to test and review.
- Add focused unit tests for domain rules and widget tests for critical workflows.
- Run `flutter analyze` and `flutter test` after non-trivial code changes when the local Flutter toolchain is available.

## UI/UX Rules

- Use the repo-local UI/UX skill at `.codex/skills/ui-ux-pro-max` for interface design, review, or UI fixes.
- For new app screens or design direction, generate or consult a design system before implementation.
- For Flutter UI guidance, query the installed skill with `--stack flutter`.
- Use dense, audit-workflow-friendly layouts for dashboards and ledger screens.
- Prioritize readable financial tables, clear form validation, strong empty/error/loading states, and accessible touch targets.
- Do not rely on color alone to communicate financial status.

## Repository Hygiene

- Keep edits scoped to the task.
- Do not overwrite user changes.
- Do not commit generated build output.
- Do not modify platform folders unless the task requires platform-specific behavior.
- Do not change dependency versions casually; explain why a new dependency is needed.
- Prefer documented, testable domain services over financial logic embedded directly in widgets.

## Verification

Before handing off implementation work, report:

- Files changed.
- Commands run and their results.
- Any tests that could not be run.
- Known risks or follow-up tasks.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
