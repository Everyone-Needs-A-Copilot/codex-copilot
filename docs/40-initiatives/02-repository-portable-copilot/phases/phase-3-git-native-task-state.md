# Phase 3: Git-Native Task State

## Objective

Make Git-friendly project files the canonical `tc` record while retaining SQLite only as a disposable local query cache.

## Inputs And Dependencies

- completed Phase 1 task schema and identity contracts
- `tc` engine ownership and migration APIs
- representative databases containing PRDs, streams, tasks, dependencies, handoffs, logs, and work products

## Work Definition

1. Implement deterministic file-per-entity persistence with stable UUIDs.
2. Hydrate a new local cache from canonical files after clone.
3. Update canonical files transactionally when `tc` mutates state.
4. Migrate existing databases and externally stored work products without data loss.
5. Detect and warn about Git-tracked database, WAL, SHM, and cache files.
6. Add branch-merge, interrupted-write, stale-cache, and round-trip equivalence tests.

## Exit Criteria

- canonical task files round-trip without semantic loss
- cache deletion and rebuild preserve query results
- independent entity edits are reviewable and mergeable in Git
- interrupted writes do not leave partially committed canonical state
- migration retains all supported entities and work-product content
- `tc doctor` identifies tracked or stale generated state

## Closure Audit

Create a phase closure audit before marking this phase complete. Cite round-trip tests, migration fixtures, merge checks, and the corresponding task-bound QA work product.

