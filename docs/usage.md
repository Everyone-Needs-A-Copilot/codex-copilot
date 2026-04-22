# Usage Guide

## Starting Work

Use `$protocol` unless the correct specialist path is already obvious.

Examples:

```text
Use $protocol to fix the login regression.
Use $protocol to add a new onboarding flow.
Use $protocol to refactor the background job system.
```

## Workflow Types

| Request Type | Workflow |
| ------------ | -------- |
| defect | `qa -> me -> qa` |
| technical | `ta -> me -> qa` |
| experience | `sd -> uxd -> uids -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive | `ta -> sec -> me -> qa` |

## Specialist Use Without Delegation

Codex Copilot is designed to work in the main session by default.

Examples:

```text
Use $agent-ta to break this refactor into tc-backed tasks.
Use $agent-qa to reproduce and verify this defect.
Use $agent-doc to write onboarding docs for this repo.
```

## Delegated Work

Delegation is intentionally narrow.

Use `spawn_agent` only when the user explicitly asks for:

- subagents
- delegation
- parallel work

When that happens, `$agent-launcher` maps specialist intent onto Codex’s built-in spawned agent types.

## Task Discipline

For substantial work, use `tc` as the system of record:

1. get or create the task context
2. do the work through the right specialist flow
3. store meaningful work products
4. update task status
