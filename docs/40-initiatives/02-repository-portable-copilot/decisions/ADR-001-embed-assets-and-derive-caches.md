# ADR-001: Embed Prompt Assets And Derive Local State Caches

> Status: Superseded by [central-resolution ADR-001](../../../../../claude-copilot/docs/40-initiatives/06-central-resolution/decisions/ADR-001-central-release-pointer.md) (claude-copilot `docs/40-initiatives/06-central-resolution/`)

## Supersession note

This record is kept as history; do not implement it. The embedded-assets and lock-manifest copy model it proposes is replaced by central resolution.

**Why:** per-project copies plus checksum locks made every release stale across roughly 71 projects, so each release forced a per-project sync. Codex user-level `AGENTS.md`, skills, the user-enabled plugin and hook trust are machine-level, so a copy inside each repository never removed the machine-level setup and only added drift.

**What replaces it:**

- One release pointer that all projects resolve against, with no per-project asset copies or checksum locks.
- A user-scope Codex plugin installed under one marketplace name.
- A per-project trust entry written by `cc project init`.

Host applications, credentials, trust decisions and personal state stay machine-owned, as this record already stated. See the central-resolution ADR for the full decision, consequences and alternatives.

## Context

Claude Copilot and Codex Copilot projects need to retain their operating instructions and durable project context across computers. The current system mixes repository-owned files with links and executable installations that exist only on one machine. Project memory is already file-based, while task state remains in a local SQLite database.

A portable design must survive a fresh clone, remain inspectable in Git, preserve project-owned overrides, avoid committing credentials or mutable databases, and respect the boundary that `cc` and `tc` own memory and task behavior.

## Decision

Portable project setup will embed version-pinned prompt-layer assets as regular repository files. A lock manifest will record source versions, checksums, ownership, and required shared tool versions.

Project memory and task state will use Git-friendly canonical files. Memory and task SQLite databases will be treated as disposable local caches rebuilt by `cc` and `tc`.

Host applications, credentials, trust decisions, personal state, and standalone `cc`/`tc` executables will remain machine-owned. A repository bootstrap will install or diagnose those prerequisites without recreating project configuration.

## Consequences

- A clone contains the project-specific Copilot operating layer and durable context.
- Framework versions become reproducible and updates become reviewable.
- Project repositories grow by the size of their embedded prompt assets and canonical task history.
- Updating requires ownership-aware synchronization instead of changing one shared checkout.
- `tc` requires an engine-level persistence and migration change.
- Codex plugin activation and project trust remain explicit host operations.
- Generated caches can be deleted safely because canonical files remain authoritative.

## Interim Decision (2026-10-09)

Until Git-mergeable task files exist, projects commit the `tc` SQLite database itself: `.copilot/tasks.db`, its archive `.copilot/tasks.db-history` and the `.copilot/wp/` work-product files. WAL, SHM and journal files stay ignored. This is the owner's decision, so tasks travel with each project between machines now, and it is enforced by `tc` 2.4 (`tc init` and `tc db track`, Claude Copilot 5.19.0).

Public repositories are excluded: their work products hold internal notes and machine paths, so they keep task state out of Git with the `.gitignore` line `# tc: task state stays local`, which `tc` never changes. This repository is one of them.

The rejection below still describes the long-term design. The interim accepts its cost: a committed database cannot be merged, so work happens on one machine at a time and starts with a pull. The inconsistency risk is limited because every `tc` command closes its connection, which folds the WAL into `tasks.db` before it can be committed. Migrating to canonical task files (Phase 3) replaces this, and the committed database becomes the migration's input.

## Alternatives Rejected

- **Out-of-repository symlinks:** rejected because they depend on local clone topology and are fragile across platforms.
- **Git submodules:** rejected as the default because recursive initialization, authentication, and detached state preserve much of the setup friction.
- **Global-only framework installation:** rejected because project behavior remains machine-dependent and may drift silently.
- **Committed SQLite, WAL, or SHM files:** rejected as the long-term design because they are binary, conflict-prone, and may be inconsistent. Committing `tasks.db` (never WAL or SHM) is the accepted interim; see above.
- **Vendored `cc` and `tc` engines:** rejected because Codex Copilot is a leaf layer and must not duplicate shared engine ownership.
- **Hosted task storage:** rejected because it adds a service dependency and weakens repository-local and offline operation.

