# Agent Instructions

## Project Overview

- Project: `{{PROJECT_NAME}}`
- Description: {{PROJECT_DESCRIPTION}}
- Stack: {{TECH_STACK}}

## Codex Copilot

This project uses the shared `codex-copilot` framework through the project-local plugin link:

- `./plugins/codex-copilot`

Use these native specialist skills when appropriate:

- `$protocol`
- `$launcher`
- `$sd`
- `$uxd`
- `$uids`
- `$uid`
- `$ta`
- `$me`
- `$qa`
- `$ind`
- `$sec`
- `$doc`
- `$do`

## Memory And Skills Copilot

Use the new `cc` CLI for persistent memory, skill discovery, and Copilot config. It replaces the old Skills Copilot and Memory Copilot MCP servers.

- Preferred command: `$HOME/.local/bin/cc`
- Fallback if needed: `cc`, after confirming it resolves to the Claude Copilot CLI and not the system C compiler
- Source: Claude Copilot `tools/cc/`
- Project config: `.claude/cc/config.json`
- Project memory: `.claude/memory/entries/`
- Project skills bridge: `.claude/skills/codex-copilot` -> `plugins/codex-copilot/skills`

When a task needs Copilot config values, run:

```bash
eval "$($HOME/.local/bin/cc env)"
```

Use `cc memory ...` for durable project/global memory and `cc skill ...` to list, search, inspect, and evaluate reusable skills.

## Task Management

Use `tc` for task tracking and work-product storage in this repository.

- Preferred command: `tc`
- Fallback if unavailable: `./.venv-tc/bin/tc`
- Use `--json` on commands that support it.

### Core Pattern

1. `tc task get <taskId> --json`
2. do the work
3. `tc wp store --task <taskId> --type <type> --title "..." --content "..." --json`
4. `tc task update <id> --status completed --json`

## Framework Rules

- Start new work with `$protocol` unless the correct specialist path is already obvious.
- Use `$launcher` when the correct specialist flow is unclear.
- Read `SOUL.md` before substantial product-facing work and use it to decide whether the direction should be built, reshaped, deferred, or rejected.
- Read `docs/01-architecture/12-architecture-guiding-principles.md` before durable architecture, migration, data, security, performance, AI pipeline, or productized implementation work.
- Use `$ta` before implementation for architecture, refactors, or non-trivial features.
- Use `$me` for implementation once the work is framed.
- Use `$qa` to verify implementation work.
- Use `spawn_agent` only when the user explicitly asks for delegation or parallel subagents.
- Keep plans free of time estimates.

## Decision Instruments

- `SOUL.md` is the product taste and purpose lens. It answers whether a product-facing direction belongs here.
- `docs/01-architecture/12-architecture-guiding-principles.md` is the technical lens. It answers how accepted direction should be built.
- When either file changes the route, state that explicitly before continuing.

## Project-Specific Rules

{{PROJECT_RULES}}
