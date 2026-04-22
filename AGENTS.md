# Agent Instructions

## Overview

- Project: `codex-copilot`
- Purpose: Codex-native specialist-agent framework with `tc` task management
- Source inspiration: `claude-copilot`

## Core Principle

Codex should behave like a disciplined lead engineer with access to specialist playbooks.

Use specialist reasoning before implementation. Do not jump from vague requests straight into code when the work needs architecture, QA framing, service design, UX, UI, documentation, security, or operations thinking first.

## Codex-Native Translation

This project does not assume Claude-style `@agent-x` syntax.

Use these Codex-native equivalents:

- `AGENTS.md` for repo-level operating instructions
- local skills from `plugins/codex-copilot/skills/`
- `spawn_agent` only when the user explicitly asks for subagents, delegation, or parallel agent work

When the user does not explicitly ask for subagents, apply the specialist playbook locally in the main session.

## Task Copilot

Use `tc` for task tracking and work-product storage.

- Preferred command: `tc`
- Fallback if needed: `./.venv-tc/bin/tc`
- Always pass `--json`

Standard pattern:

1. `tc task get <taskId> --json`
2. do the work
3. `tc wp store --task <taskId> --type <type> --title "..." --content "..." --json`
4. `tc task update <taskId> --status completed --json`

If no PRD/task exists for framework work, create them instead of writing planning state into markdown:

- `tc prd create --title "..." --content "..." --json`
- `tc task create --prd <id> --title "..." --description "..." --json`

## Native Specialist Skills

Primary protocol entrypoint:

- `$protocol`

These specialists are available as native Codex skills:

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

## Specialist Matrix

Use these specialist roles as decision lenses:

| Role | Purpose | Trigger |
|------|---------|---------|
| `ta` | architecture and task breakdown | backend, refactors, systems, trade-offs |
| `me` | implementation | code changes |
| `qa` | verification and edge cases | bugs, tests, regressions |
| `sec` | security review | auth, secrets, permissions, trust boundaries |
| `doc` | documentation | READMEs, onboarding, API docs |
| `do` | devops | CI, deploy, infra, observability |
| `sd` | service design | end-to-end user journey |
| `uxd` | interaction design | workflows, states, usability |
| `uids` | visual design | look and feel, design systems |
| `uid` | UI implementation | component construction, styling |
| `cw` | copywriting | microcopy, content, tone |

## Routing Rules

- New work should start with `$protocol` unless the correct specialist is already obvious.
- Bugs start with `qa`, then `me`, then `qa` again.
- Experience work starts with `sd` or `uxd` before implementation.
- Technical features start with `ta` before implementation.
- Security-sensitive work pulls in `sec` before completion.
- `me` is not the final gate on implementation work when tests are relevant.

## Delegation Rules

`spawn_agent` is allowed only when the user explicitly asks for delegation, subagents, or parallel work.

If delegation is authorized:

- use `explorer` for bounded codebase analysis questions
- use `worker` for isolated implementation slices
- give the subagent a single clear responsibility
- keep write scopes disjoint
- do not delegate the immediate blocking step if doing it locally is faster

## Working Style

- keep changes focused and minimal
- prefer root-cause fixes
- preserve user changes
- never use destructive git or database commands without explicit user approval
- do not include time estimates in plans or docs

## Required Reading

Before substantial work, read the relevant skill:

- `plugins/codex-copilot/skills/protocol/SKILL.md`
- `plugins/codex-copilot/skills/agent-launcher/SKILL.md`
- `plugins/codex-copilot/skills/protocol-router/SKILL.md`
- `plugins/codex-copilot/skills/task-copilot/SKILL.md`
- `plugins/codex-copilot/skills/specialist-agents/SKILL.md`
