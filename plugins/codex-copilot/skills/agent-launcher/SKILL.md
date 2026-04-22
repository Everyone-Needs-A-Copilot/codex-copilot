---
name: agent-launcher
description: Use when you want to invoke codex-copilot specialist agents natively in Codex, either by selecting the right specialist skill for the main session or by mapping specialists onto real Codex spawned-agent roles for delegated work.
---

# Agent Launcher

Use this skill to launch codex-copilot specialists in a Codex-native way.

## Native modes

### Main session

If the user did not explicitly ask for subagents, load the requested specialist skill directly:

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

### Delegated subagent

If the user explicitly asked for delegation or parallel work, map the specialist to a real Codex subagent type:

- `explorer`: `ta`, `qa`, `sec`
- `worker`: `me`, `uid`, `do`
- `default`: `sd`, `uxd`, `uids`, `doc`, `cw`

## Required behavior

1. choose the workflow
2. ensure `tc` task context exists for substantial work
3. keep the immediate blocking step local when that is faster
4. if spawning, give the subagent one specialist identity and one bounded task
5. route implementation work through `qa` before closing

Read `references/workflows.md` for the standard sequences.
