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
- `$agent-launcher`
- `$agent-ta`
- `$agent-me`
- `$agent-qa`
- `$agent-sec`
- `$agent-doc`
- `$agent-do`
- `$agent-sd`
- `$agent-uxd`
- `$agent-uids`
- `$agent-uid`
- `$agent-cw`

## Task Management

Use `tc` for task tracking and work-product storage in this repository.

- Preferred command: `tc`
- Fallback if unavailable: `./.venv-tc/bin/tc`
- Always use `--json`

### Core Pattern

1. `tc task get <taskId> --json`
2. do the work
3. `tc wp store --task <taskId> --type <type> --title "..." --content "..." --json`
4. `tc task update <id> --status completed --json`

## Framework Rules

- Start new work with `$protocol` unless the correct specialist path is already obvious.
- Use `$agent-launcher` when the correct specialist flow is unclear.
- Use `$agent-ta` before implementation for architecture, refactors, or non-trivial features.
- Use `$agent-me` for implementation once the work is framed.
- Use `$agent-qa` to verify implementation work.
- Use `spawn_agent` only when the user explicitly asks for delegation or parallel subagents.
- Keep plans free of time estimates.

## Project-Specific Rules

{{PROJECT_RULES}}
