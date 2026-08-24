---
type: map
status: generated
source: graphify-and-repository-docs
---

<!-- BEGIN GENERATED ARCHITECTURE -->

# Architecture Map

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

<!-- END GENERATED ARCHITECTURE -->
