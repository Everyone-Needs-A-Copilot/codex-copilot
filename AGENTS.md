# Agent Instructions

## Overview

- Project: `codex-copilot`
- Purpose: Codex-native specialist-agent framework with `tc` task management
- Source inspiration: `claude-copilot`

## Core Principle

Codex should behave like a disciplined lead engineer with access to specialist playbooks.

Use specialist reasoning before implementation. Do not jump from vague requests straight into code when the work needs architecture, QA framing, service design, UX, UI, documentation, security, or operations thinking first.

## Codex-Native Translation

This project does not assume Claude-style named-agent syntax.

Use these Codex-native equivalents:

- `AGENTS.md` for repo-level operating instructions
- local skills from `plugins/codex-copilot/skills/`
- `spawn_agent` only when the user explicitly asks for subagents, delegation, or parallel agent work

When the user does not explicitly ask for subagents, apply the specialist playbook locally in the main session.

## Output Contract

For every user-facing reply, checkpoint, progress update, blocker, command report, and completion report:

- Lead with what is now true: the answer, decision, result, or blocker—not the investigation chronology.
- Include only what the reader needs to trust the result, make the decision, or take the next action. Preserve required findings, real uncertainty, citations, QA evidence, safety warnings, blockers, and next actions.
- Default to at most 6 sentences or 5 bullets. Use more only when the user asks for depth or when risk, complexity, or completeness requires it.
- For a real decision, give an outcome headline, 2–3 numbered options stated as outcomes, and a question of at most 4 words—normally “Which one?” Do not print generic standing options. If there is no real decision, do not manufacture options or ask for approval.
- Keep progress updates to one short sentence: material result plus next active step. Lead completion reports with the outcome, followed only by changed scope, verification, and any remaining caveat or action.
- Omit preambles, generic closers, self-narration, repeated findings, evidence inventories, command traces, and chronology unless the reader asked for them or needs them to trust the result.

Detailed technical records belong in `tc` work products. Content always outranks form: never omit a required finding, caveat, citation, safety warning, QA artifact, verdict, Task/WP identifier, or genuine blocker to satisfy a length target.

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

Use `cc memory ...` for durable project/global memory and `cc skill ...` to list, search, inspect, and retrieve reusable skills.

## Live Docs

Before planning or implementing against an installed third-party package API, use Live Docs through `cc` instead of relying on remembered API shapes:

```bash
$HOME/.local/bin/cc docs get <package> --topic <area> --json
```

Use `cc docs resolve <package>` when version detection itself is unclear. If `cc docs` is unavailable, state that limitation and verify against local package files or official docs before coding.

## Task Copilot

Use `tc` for task tracking and work-product storage.

- Preferred command: `tc`
- Fallback if needed: `./.venv-tc/bin/tc`
- Pass `--json` on commands that support it.

Standard pattern:

1. `tc task get <taskId> --json`
2. do the work
3. `tc wp store --task <taskId> --type <type> --title "..." --content "..." --json`
4. `tc task update <taskId> --status completed --json`

If no PRD/task exists for framework work, create them instead of writing planning state into markdown:

- `tc prd create --title "..." --content "..." --json`
- `tc task create --prd <id> --title "..." --description "..." --json`

For three or more related `tc` operations, prefer a single `python3` block using `tc.api` and print only a compact summary. For three or more related `cc` memory/skill operations, use a separate `cc.api` block. Do not mix `tc.api` and `cc.api` in the same Python process.

### Initiative Documentation

Formal multi-phase initiatives live in `docs/40-initiatives/NN-slug/`.

- each initiative includes `README.md`, `phases/`, `decisions/`, and `retrospectives/`
- initiative Markdown stores durable goals, phase design, decisions, validation evidence, and outcomes
- `tc` remains authoritative for live tasks, dependencies, assignments, work products, and QA status
- link initiative documents to their `tc` PRD/tasks instead of maintaining a second task board
- add every initiative to `docs/40-initiatives/README.md`
- never create `docs/initiatives/`

### QA Gate Convention

Codex Copilot cannot rely on Claude runtime lifecycle hooks such as SessionStart,
PreToolUse, or SubagentStop, so implementation work uses explicit `tc` state.
This does not change the design-led product creation protocol:

- implementation tasks that need verification should carry `metadata.requiresQa=true`
- `$me` stores an implementation work product and routes to `$qa`
- `$qa` stores a `test` work product with an `ARTIFACT:` marker and records a `VERDICT: APPROVED`, `VERDICT: APPROVED-WITH-MINOR-FIXES`, or `VERDICT: REJECTED` token
- use `scripts/copilot-gate.sh` to inspect QA-required tasks before closure

Passing QA verdicts must be evidence-bound. Valid artifact markers include
`test-run`, `file-check`, `diff-check`, `screenshot-check`, `a11y-check`, and
`design-fidelity-check`.

## Native Specialist Skills

Primary protocol entrypoint:

- `$protocol`

These specialists are available as native Codex skills:

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

Optional parity specialists are available through dormant packs rather than loaded globally:

- `kc`, `cco`, `cw`, `cs`, and `cpa` live in `packs/business-creative/`
- activate a pack in a project with `scripts/activate-pack.py`

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

## Routing Rules

- New work should start with `$protocol` unless the correct specialist is already obvious.
- Bugs start with `qa`, then `me`, then `qa` again.
- Experience work starts with `sd` or `uxd` before implementation.
- Technical features start with `ta` before implementation.
- Security-sensitive work pulls in `sec` before completion.
- Infrastructure work starts with `do`, then routes through `me` and `qa` when code or scripts change.
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

## Test Integrity

Tests define the contract. Changing them changes what "passing" means, so they are
never collateral in a fix.

- **Never edit a test to make it pass.** If a test fails, the implementation is wrong
  until proven otherwise. Editing an assertion, renaming a test to match new behaviour,
  or deleting a case is prohibited unless the user asked for a test change specifically.
- **A test file is read-only** during bug-fix, refactor and feature work. It is
  editable only when writing tests is the stated task.
- **If a test looks wrong, stop and say so.** Report the disagreement between test and
  implementation and let the user decide. Do not resolve it unilaterally.
- **"The tests pass" is only evidence if the tests are unchanged.** Before reporting a
  pass, confirm no test file differs from HEAD. If one does, say so explicitly and treat
  the run as unverified.

### When the reported problem does not exist

A bug report can be wrong. If investigation shows the code is already correct and its
tests already pass, the correct answer is to **say so and change nothing**.

Do not invent a defect to justify a change. Do not adjust behaviour at a boundary to
match a mistaken description. Reporting "no defect found, here is why" is a complete and
successful outcome, and is strongly preferred over a change that makes the report appear
true.

## Required Reading

Before substantial work, read the relevant skill:

- `plugins/codex-copilot/skills/protocol/SKILL.md`
- `plugins/codex-copilot/skills/launcher/SKILL.md`
- `plugins/codex-copilot/skills/protocol-router/SKILL.md`
- `plugins/codex-copilot/skills/task-copilot/SKILL.md`
- `plugins/codex-copilot/skills/specialist-agents/SKILL.md`
