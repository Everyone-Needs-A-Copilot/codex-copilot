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
| experience | `sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| physical-digital | `ind -> sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive | `ta -> sec -> me -> qa` |
| infrastructure | `do -> me -> qa` |

## Specialist Use Without Delegation

Codex Copilot is designed to work in the main session by default.

Examples:

```text
Use $ta to break this refactor into tc-backed tasks.
Use $qa to reproduce and verify this defect.
Use $sd to frame the service journey before UX.
Use $uxd to design the interaction states.
Use $uids to define the visual system.
Use $uid to implement the UI.
Use $ind to shape a physical-digital product touchpoint.
Use $doc to write onboarding docs for this repo.
Use $do to update CI or deployment automation.
```

## Live Docs

Before planning or coding against an installed third-party package API, use:

```bash
cc docs get <package> --topic <area> --json
```

If `cc docs` is unavailable, verify through local package files or official docs before coding.

## Project Capability Packs

Domain-specific work should be activated by the project, not added to the global software layer.

The shared repo can store dormant packs under `packs/<category>/`. A project activates a pack by exposing selected pack skills through its own local plugin and marketplace entry.

This keeps global Codex Copilot focused on making software while allowing a project to opt into capabilities such as writing, legal advisory, sales workflows, or other domain work.

## Delegated Work

Delegation is intentionally narrow.

Use `spawn_agent` only when the user explicitly asks for:

- subagents
- delegation
- parallel work

When that happens, `$launcher` maps specialist intent onto Codex’s built-in spawned agent types.

## Task Discipline

For substantial work, use `tc` as the system of record:

1. get or create the task context
2. do the work through the right specialist flow
3. store meaningful work products
4. update task status

For implementation tasks that require verification, set `metadata.requiresQa=true`, store a `code` work product, route to `$qa`, and store a `test` work product with a verdict. `scripts/copilot-gate.sh` checks the convention.
