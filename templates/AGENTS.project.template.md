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

## Output Contract

For every user-facing reply, checkpoint, progress update, blocker, command report, and completion report:

- Lead with what is now true: the answer, decision, result, or blocker—not the investigation chronology.
- Include only what the reader needs to trust the result, make the decision, or take the next action. Preserve required findings, real uncertainty, citations, QA evidence, safety warnings, blockers, and next actions.
- Default to at most 6 sentences or 5 bullets. Use more only when the user asks for depth or when risk, complexity, or completeness requires it.
- For a real decision, give an outcome headline, 2–3 numbered options stated as outcomes, and a question of at most 4 words—normally “Which one?” Do not print generic standing options. If there is no real decision, do not manufacture options or ask for approval.
- Keep progress updates to one short sentence: material result plus next active step. Lead completion reports with the outcome, followed only by changed scope, verification, and any remaining caveat or action.
- Omit preambles, generic closers, self-narration, repeated findings, evidence inventories, command traces, and chronology unless the reader asked for them or needs them to trust the result.

Detailed technical records belong in `tc` work products. Content always outranks form: never omit a required finding, caveat, citation, safety warning, QA artifact, verdict, Task/WP identifier, or genuine blocker to satisfy a length target.

## `cc` CLI

Use the `cc` CLI for persistent memory, skill discovery, Live Docs, onboarding, and Copilot config. The retired `copilot-memory`, `skills-copilot`, and `task-copilot` MCP servers and their `initiative_*`, `memory_*`, and `skill_*` tool calls do not exist.

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
Use `tc` PRDs/tasks for live initiative execution state; use `cc memory` for durable decisions and lessons.

## Live Docs

Before planning or implementing against an installed third-party package API, use Live Docs through `cc`:

```bash
$HOME/.local/bin/cc docs get <package> --topic <area> --json
```

If `cc docs` is unavailable, say so and verify against local package files or official docs before coding.

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

For three or more related `tc` operations, prefer one `python3` block using `tc.api`. For three or more related `cc` memory/skill operations, use a separate `cc.api` block. Keep `tc` and `cc` API blocks separate.

### Initiative Documentation

Formal multi-phase initiatives live in `docs/40-initiatives/NN-slug/`.

- each initiative includes `README.md`, `phases/`, `decisions/`, and `retrospectives/`
- initiative Markdown stores durable goals, phase design, decisions, validation evidence, and outcomes
- `tc` remains authoritative for live tasks, dependencies, assignments, work products, and QA status
- link initiative documents to their `tc` PRD/tasks instead of maintaining a second task board
- add every initiative to `docs/40-initiatives/README.md`
- never create `docs/initiatives/`

### QA Gate Convention

Codex Copilot ships Codex-native routing, debug-circuit-breaker, and subagent-context hooks. These are separate implementations from Claude Code hooks and do not replace explicit `tc` QA state or the design-led product creation protocol.

- implementation tasks that need verification should carry `metadata.requiresQa=true`
- `$me` stores an implementation work product and routes to `$qa`
- `$qa` stores a `test` work product with an `ARTIFACT:` marker and a `VERDICT: APPROVED`, `VERDICT: APPROVED-WITH-MINOR-FIXES`, or `VERDICT: REJECTED` token
- `scripts/copilot-gate.sh` can inspect QA-required tasks before closure; setup installs a project-local framework-owned copy

Passing QA verdicts must be evidence-bound. Valid artifact markers include
`test-run`, `file-check`, `diff-check`, `screenshot-check`, `a11y-check`, and
`design-fidelity-check`.

## Framework Rules

- Start new work with `$protocol` unless the correct specialist path is already obvious.
- Use `$launcher` when the correct specialist flow is unclear.
- Read `SOUL.md` before substantial product-facing work and use it to decide whether the direction should be built, reshaped, deferred, or rejected.
- Read `docs/01-architecture/12-architecture-guiding-principles.md` before durable architecture, migration, data, security, performance, AI pipeline, or productized implementation work.
- Use `$ta` before implementation for architecture, refactors, or non-trivial features.
- Use `$me` for implementation once the work is framed.
- Use `$qa` to verify implementation work.
- Use `$do -> $me -> $qa` for infrastructure, CI, deployment, and environment changes that require implementation.
- Use `spawn_agent` only when the user explicitly asks for delegation or parallel subagents.
- Keep plans free of time estimates.

### Delegating to Subagents

- Do not end a subagent prompt with an enumerated reporting checklist.
- The standing return contract is at most three sentences: outcome, root cause if known, and anything anomalous or requiring a decision. Put full evidence in a file and return its path.
- Surface every safety-relevant anomaly in those three sentences; never bury it only in the evidence file.
- Request more depth only when the decision genuinely depends on it.

## Debugging Discipline

When an explanation conflicts with a measurement, follow the measurement and narrow the investigation.

1. Confirm a mechanism exists in the relevant environment, plan, or account before naming it as the cause.
2. State what every diagnostic exercised, including the selected key, config, binary, branch, interpreter, and working directory when relevant.
3. Count failures through one shared dependency as one observation unless that dependency is varied.
4. After two hypotheses are falsified, stop hypothesizing. Read the code that enforces the behavior and cite `file:line`.

## Decision Instruments

- `SOUL.md` is the product taste and purpose lens. It answers whether a product-facing direction belongs here.
- `docs/01-architecture/12-architecture-guiding-principles.md` is the technical lens. It answers how accepted direction should be built.
- When either file changes the route, state that explicitly before continuing.

## Project-Specific Rules

{{PROJECT_RULES}}
