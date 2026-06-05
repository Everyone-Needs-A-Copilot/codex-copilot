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
| infrastructure | `do -> me -> qa` |
| experience | `sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive | `ta -> sec -> me -> qa` |
| knowledge | `kc` |
| creative branch | `cco -> cw` |
| business advisory | `cs` or `cpa` |

## Specialist Use Without Delegation

Codex Copilot is designed to work in the main session by default.

Examples:

```text
Use $agent-ta to break this refactor into tc-backed tasks.
Use $agent-qa to reproduce and verify this defect.
Use $agent-doc to write onboarding docs for this repo.
Use $continue to resume previous Codex Copilot work.
Use $orchestrate to plan explicit user-approved parallel streams.
```

## Command-Equivalent Skills

Claude Copilot slash-command workflows are available as Codex skills:

| Skill | Capability Boundary |
| ----- | ------------------- |
| `$continue` | Resume from `tc` tasks, work products, and `cc` memory when available. |
| `$pause` | Preserve current work state through `tc`/`cc`; no Claude checkpoint runtime. |
| `$map` | Produce or store a codebase map; writing `PROJECT_MAP.md` requires explicit request. |
| `$memory` | Inspect `cc memory`, known references, and `tc` progress. |
| `$extensions` | Inspect knowledge and extension status; no automatic prompt assembly. |
| `$orchestrate` | Plan streams and explicit delegation; no automatic background workers. |
| `$setup-project` | Guide project wiring; replacement still requires exact approval. |
| `$update-project` | Inspect project drift and suggest safe updates. |
| `$update-copilot` | Inspect/update framework state without destructive git operations. |
| `$knowledge-copilot` | Create, link, or inspect shared knowledge safely. |

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
