# Repository-Portable Copilot

> Mode: Initiative  
> Status: Proposed  
> `tc` context: PRD-5 / architecture TASK-5 and WP-7 / documentation TASK-6

## Goal

Make a project configured once for Claude Copilot and Codex Copilot retain its project instructions, agents, skills, safe settings, memory, tasks, dependencies, and work products when the repository is cloned on another computer.

A new computer may still require a one-time installation of the host applications and shared `cc`/`tc` executables. It must not require recreating project setup or depend on another framework checkout at a matching filesystem path.

## Scope

- repository ownership of Claude Copilot and Codex Copilot prompt-layer assets
- versioned, checksummed framework installation metadata
- safe project configuration without machine-specific paths or credentials
- committed project memory entries with disposable local indexes
- Git-mergeable canonical `tc` state with a disposable local database cache
- idempotent machine bootstrap, project health checks, and update behavior
- migration of existing copied, symlinked, and database-backed installations
- clean-clone and update-preservation validation

## Non-Goals

- vendoring the Claude Code or Codex applications
- committing credentials, authentication state, personal settings, or personal memory
- rebuilding the `cc` or `tc` engines inside Codex Copilot
- eliminating the Codex trust and plugin-activation boundaries imposed by the host
- introducing a remote task service or a second Markdown task board
- silently updating framework-owned files without a reviewable version change

## Target Outcomes

- A fresh clone contains no broken or out-of-repository framework links.
- `AGENTS.md` and `CLAUDE.md` provide project guidance without rerunning project setup.
- Claude agents and commands are regular tracked files, and Codex has a tracked repository marketplace plus an embedded plugin snapshot.
- Project memory entries survive cloning while memory indexes remain disposable.
- `tc` reconstructs the same PRDs, tasks, dependencies, statuses, and work products from Git-tracked canonical state.
- A one-command bootstrap installs or diagnoses only missing machine prerequisites and rebuilds local caches.
- Framework updates change only manifest-owned assets and preserve project-owned rules and overrides.
- No tracked file contains machine-specific absolute paths, credentials, SQLite WAL/SHM files, or generated caches.

## Architecture

The target ownership model, clone journey, persistence design, alternatives, and fitness checks are defined in the [architecture brief](./architecture.md).

## Phase Index

| Phase | Goal | Status | Document |
| --- | --- | --- | --- |
| Phase 1 | Ratify the portability contract and lock-manifest schema | Proposed | [`phases/phase-1-portability-contract.md`](./phases/phase-1-portability-contract.md) |
| Phase 2 | Embed framework-owned prompt assets as tracked project files | Proposed | [`phases/phase-2-embedded-framework-assets.md`](./phases/phase-2-embedded-framework-assets.md) |
| Phase 3 | Make Git-friendly files the canonical source for `tc` state | Proposed | [`phases/phase-3-git-native-task-state.md`](./phases/phase-3-git-native-task-state.md) |
| Phase 4 | Provide standalone tooling, bootstrap, doctor, and safe updates | Proposed | [`phases/phase-4-machine-bootstrap.md`](./phases/phase-4-machine-bootstrap.md) |
| Phase 5 | Migrate existing projects and prove clean-clone portability | Proposed | [`phases/phase-5-migration-and-validation.md`](./phases/phase-5-migration-and-validation.md) |

## Decisions

- [ADR-001: Embed prompt assets and derive local state caches](./decisions/ADR-001-embed-assets-and-derive-caches.md)

## Validation Contract

The initiative cannot be called complete until evidence-bound QA demonstrates:

- a fresh clone at an unrelated path works without a sibling framework checkout
- repository instructions and embedded assets are discoverable by their intended hosts
- memory and task caches rebuild from tracked canonical files with equivalent results
- bootstrap is idempotent and produces no unrequested repository changes
- update preserves project-owned files and changes only manifest-owned framework assets
- tracked content contains no credentials, machine paths, task databases, WAL/SHM files, or generated caches
- framework checks, setup fixtures, migration fixtures, and `scripts/copilot-gate.sh` pass

Each phase must add a closure audit and link its task-bound `test` work product before its status changes to complete.

## Current Summary

The architecture is documented in TASK-5 and WP-7. Implementation has not begun. PRD-5 remains the authoritative record for future tasks, dependencies, assignments, work products, and QA status.

