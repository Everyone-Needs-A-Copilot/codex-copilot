---
name: protocol
description: Use as the primary Codex Copilot entrypoint for new work. It classifies the request, chooses the right specialist workflow, creates tc-backed planning context when needed, and routes execution through codex-copilot agents similarly to Claude Copilot's /protocol command.
---

# Protocol

`$protocol` is the primary Codex Copilot entrypoint for new work.

Use it at the start of a task to decide how the work should proceed.

## Purpose

It should behave like the Claude Copilot `/protocol` command in intent:

- classify the request
- choose the correct specialist workflow
- require the right kind of thinking before implementation
- route the work through the correct agents

In Codex, that means:

- invoke specialist skills in the main session by default
- use `spawn_agent` only when the user explicitly asks for subagents or parallel execution
- use `tc` as the durable record for substantial work

## Request Classification

| Request type | Signals | Workflow |
|--------------|---------|----------|
| defect | broken behavior, regression, failing tests, bug fix | `qa -> me -> qa` |
| technical | architecture, refactor, backend, migration, optimization | `ta -> me -> qa` |
| experience | user-facing feature, workflow, screen, UI, UX | `sd -> uxd -> uids -> ta -> me -> qa` |
| UI polish | visual refinement, component styling, layout polish | `uids -> uid -> qa` |
| security-sensitive | auth, permissions, secrets, trust boundaries | `ta -> sec -> me -> qa` |
| ambiguous | improve, update, change, enhance without clear direction | ask for clarification before routing |

## Required behavior

1. classify the task
2. state the workflow
3. ensure `tc` context exists for substantial work
4. perform the next appropriate specialist step
5. do not jump straight to implementation when earlier specialist work is warranted
6. do not use `spawn_agent` unless the user explicitly asked for delegation or parallel work

## Checkpoints

For design-heavy flows, stop after major design stages unless the user clearly asked for uninterrupted execution.

Checkpoint stages:

- after `sd`
- after `uxd`
- after `uids`
- after `ta` when the plan materially shapes implementation

Each checkpoint should summarize:

- what was decided
- what happens next
- what the user can correct before continuing

## Main-session pattern

Use these native skills directly:

- `$agent-sd`
- `$agent-uxd`
- `$agent-uids`
- `$agent-ta`
- `$agent-me`
- `$agent-qa`
- `$agent-sec`

## Delegated pattern

If the user explicitly asks for delegation or parallel work, use `$agent-launcher` to map the needed specialists onto native Codex spawned-agent roles.

## Task Copilot

For substantial work:

- create or use a PRD/task in `tc`
- store long outputs as work products
- keep the main response concise

## References

Read `references/flows.md` for workflow details and `references/checkpoints.md` for checkpoint behavior.
