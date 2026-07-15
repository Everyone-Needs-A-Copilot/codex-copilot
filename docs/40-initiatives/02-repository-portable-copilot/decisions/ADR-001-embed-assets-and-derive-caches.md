# ADR-001: Embed Prompt Assets And Derive Local State Caches

> Status: Proposed

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

## Alternatives Rejected

- **Out-of-repository symlinks:** rejected because they depend on local clone topology and are fragile across platforms.
- **Git submodules:** rejected as the default because recursive initialization, authentication, and detached state preserve much of the setup friction.
- **Global-only framework installation:** rejected because project behavior remains machine-dependent and may drift silently.
- **Committed SQLite, WAL, or SHM files:** rejected because they are binary, conflict-prone, and may be inconsistent.
- **Vendored `cc` and `tc` engines:** rejected because Codex Copilot is a leaf layer and must not duplicate shared engine ownership.
- **Hosted task storage:** rejected because it adds a service dependency and weakens repository-local and offline operation.

