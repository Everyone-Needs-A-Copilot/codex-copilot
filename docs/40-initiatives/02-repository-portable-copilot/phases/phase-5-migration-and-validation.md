# Phase 5: Migration And Validation

## Objective

Migrate existing projects without losing project-owned context and prove repository portability from clean clones.

## Inputs And Dependencies

- completed embedded asset, task persistence, bootstrap, update, and doctor capabilities
- inventory of existing Claude Copilot and Codex Copilot installation shapes
- migration fixtures covering symlinked, copied, partially configured, and database-tracked projects

## Work Definition

1. Inventory existing framework links, copied assets, overrides, memory entries, and task databases.
2. Preview every migration and refuse ambiguous ownership conflicts.
3. Materialize framework assets and generate lock metadata without replacing project-owned files.
4. Convert task state, verify equivalence, and only then remove generated databases from Git tracking.
5. Test fresh clones at unrelated filesystem paths without sibling framework checkouts.
6. Validate update preservation, cross-platform path behavior, security boundaries, and rollback instructions.
7. Publish migration guidance and phase closure evidence.

## Exit Criteria

- representative existing projects migrate without lost instructions, memory, task state, or work products
- migration is previewable, reversible until verification passes, and safe to rerun
- a clean clone recovers equivalent project context after bootstrap
- no migrated repository tracks generated databases, WAL/SHM files, credentials, or machine paths
- setup, migration, framework, parity, and QA-gate checks pass
- rollback and manual-recovery procedures are documented and exercised

## Closure Audit

Create a phase closure audit before marking this phase complete. Cite migration inventories, clean-clone checks, equivalence tests, security scans, and the corresponding task-bound QA work product.

