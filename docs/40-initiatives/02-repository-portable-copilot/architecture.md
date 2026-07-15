# Repository-Portable Copilot Architecture

## Problem

Projects configured for Claude Copilot or Codex Copilot currently preserve only part of their operating context when cloned elsewhere.

Codex Copilot creates repository-local configuration, but [the current setup script](../../../scripts/setup-project.sh) links the plugin and QA gate to a separate framework checkout. The link may be relative, but a fresh clone does not contain its target. Claude Copilot copies more of its prompt layer into each project, while its machine tooling and some clone-mode configuration still depend on a separate installation.

Project memory entries already use a portable Markdown representation. Task state does not: `tc` uses `.copilot/tasks.db`, and [this repository ignores `.copilot/`](../../../.gitignore). Committing SQLite databases, WAL files, or SHM files is not a safe substitute because they are binary, difficult to merge, and may not represent a consistent snapshot.

## Design Principle

Project behavior and durable project context belong in the repository. Executable runtimes, credentials, trust decisions, personal state, and rebuildable indexes belong to the machine.

The target is a repository-embedded, version-pinned framework snapshot plus a small, idempotent machine bootstrap. Codex Copilot remains a leaf layer: shared memory and task behavior stays owned by `cc` and `tc`.

## Ownership Model

| Repository-owned and tracked | Machine-owned and untracked |
| --- | --- |
| `AGENTS.md` and `CLAUDE.md` | Claude Code and Codex applications |
| safe project `.codex/` and `.claude/` configuration | authentication, tokens, credentials, and trust decisions |
| `.agents/plugins/marketplace.json` | Codex plugin installed/enabled state |
| embedded Codex plugin files | standalone `cc` and `tc` executables |
| Claude agents, commands, skills, and hook scripts | personal settings and personal memory |
| `.claude/memory/entries/*.md` | memory FTS index |
| framework lock manifest and ownership checksums | local `tc` SQLite query cache |
| canonical PRD, task, dependency, and work-product files | transient locks, logs, WAL/SHM files, and generated caches |
| bootstrap and project health-check scripts | host-specific paths and notification configuration |

Project memory must be intentionally shareable. Personal observations, credentials, and secrets remain in personal or global memory outside the repository.

## Embedded Framework Assets

Codex Copilot setup should copy `plugins/codex-copilot/` into the project as regular tracked files and keep `.agents/plugins/marketplace.json` pointed at that in-repository path. This follows the current [Codex plugin guidance](https://learn.chatgpt.com/docs/build-plugins), which supports repository marketplaces and repository-local plugin directories.

Claude Copilot should continue materializing its project agents and commands as regular files. Shared hook scripts and safe project configuration must use paths relative to the repository rather than absolute paths into a machine checkout.

Symlink installation may remain available as an explicit framework-development mode. It must not be the default for portable project setup.

## Lock And Ownership Manifest

A tracked lock manifest should record:

- Claude Copilot and Codex Copilot source repositories
- pinned versions and source commits
- required `cc` and `tc` versions
- installation mode
- framework-owned paths and checksums
- schema versions for project configuration, memory entries, and task state
- the last successful migration or update version

Setup writes the first lock. Update compares the installed snapshot with it, reports drift, and replaces only known framework-owned files. Project-specific rules and overrides remain outside the vendored asset tree or carry explicit project ownership metadata.

## Memory Persistence

Project memory entries remain file-per-entry Markdown under `.claude/memory/entries/`. The SQLite FTS index remains an ignored cache and is rebuilt after cloning or when drift is detected.

Memory commands must preserve the distinction between project memory, which is suitable for repository sharing, and personal memory, which remains machine-local.

## Task Persistence

The `tc` engine should make Git-friendly files authoritative and treat SQLite as a derived local cache. A representative layout is:

```text
.copilot/
  prds/<uuid>.json
  tasks/<uuid>.json
  dependencies/<uuid>.json
  work-products/<uuid>.json
  work-products/<uuid>.md
  cache/tasks.db
```

The exact schema belongs to `tc`, but it must provide:

- stable UUID identity rather than machine-local integer identity alone
- deterministic serialization and ordering
- one mergeable file per independently edited entity
- transactional updates of canonical files
- cache hydration after clone
- migration from existing databases
- warnings when Git tracks task databases, WAL files, or SHM files
- equivalence checks between canonical files and rebuilt query results

Adding task persistence logic to Codex Copilot is rejected because it would duplicate the shared engine and violate the framework ownership boundary.

## Machine Bootstrap

A tracked, idempotent bootstrap should:

1. read the lock manifest
2. verify required host applications and project trust boundaries
3. install or diagnose pinned standalone `cc` and `tc` packages
4. rebuild the memory index
5. hydrate the `tc` cache from tracked canonical files
6. verify the repository Codex marketplace and embedded plugin
7. verify Claude project assets and relative hook/configuration paths
8. report broken links, machine paths, credentials, or tracked generated state

On a previously prepared computer, cloning and opening the repository should be enough. On a new computer, the bootstrap is the only project command required. Codex may still require explicit plugin installation or activation and a new task or application restart; the repository cannot bypass that host boundary honestly.

## Migration

Migration must be conservative and reversible:

1. inventory existing symlinks, copied assets, project overrides, memory entries, and task databases
2. materialize framework assets into the repository without overwriting project-owned files
3. convert task rows and work products into canonical tracked files
4. verify equivalence before removing databases from Git tracking
5. retain the local database until rebuilt state passes validation
6. generate the lock manifest and bootstrap entrypoint
7. verify the project from a fresh clone at an unrelated path

Migration must never delete an existing database, replace project instructions, or rewrite memory merely because the framework detects drift.

## Alternatives Rejected

- **Relative symlinks:** they still depend on clone topology and are fragile on Windows and in containers.
- **Git submodules:** they provide pinning but retain recursive initialization, authentication, and missing-submodule failure modes.
- **Global-only installation:** it leaves project behavior dependent on machine state and permits silent drift between computers.
- **Committed SQLite/WAL/SHM files:** they are binary, conflict-prone, and may be inconsistent.
- **Vendored `cc` and `tc` engines:** this duplicates shared engine ownership and creates platform-specific update and security burdens.
- **Hosted task state:** it weakens offline and repository-local behavior and introduces an unnecessary service dependency.

## Clone Journey

On a prepared computer:

```text
git clone
open project
work
```

On a new computer:

```text
git clone
run repository bootstrap
trust/open project
activate the local Codex plugin when required by the host
work with restored project context
```

Codex automatically reads repository `AGENTS.md` according to its [project instruction discovery contract](https://learn.chatgpt.com/docs/agent-configuration/agents-md). Safe project `.codex/config.toml` values also travel with a trusted repository; credentials and prohibited machine-owned values do not.

## Architecture Fitness Checks

- no broken or out-of-repository links in a fresh clone
- repository instructions load without rerunning setup
- embedded Claude and Codex assets match the lock manifest
- memory search returns committed project entries after index rebuild
- task queries return equivalent PRDs, tasks, dependencies, statuses, and work products after cache hydration
- bootstrap is idempotent and leaves a clean working tree
- update preserves project-owned overrides
- no tracked absolute machine paths, credentials, databases, WAL/SHM files, or generated caches

