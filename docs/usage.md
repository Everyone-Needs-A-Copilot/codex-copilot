# Usage Guide

This guide covers the daily Codex Copilot workflow.

## Start With Protocol

Use `$protocol` when beginning new work:

```text
Use $protocol to fix the login regression.
Use $protocol to add a new onboarding flow.
Use $protocol to refactor the background job system.
Use $protocol to update staging deployment automation.
```

`$protocol` classifies the request and routes it through the right specialist sequence.

## Workflow Types

| Request Type | Workflow |
| --- | --- |
| defect | `qa -> me -> qa` |
| technical | `ta -> me -> qa` |
| experience | `sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| physical-digital | `ind -> sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive | `ta -> sec -> me -> qa` |
| infrastructure | `do -> me -> qa` |

## Use Specialists Directly

When the correct role is obvious:

```text
Use $ta to break this refactor into tc-backed tasks.
Use $qa to reproduce and verify this defect.
Use $sd to frame the service journey before UX.
Use $uxd to design the interaction states.
Use $uids to define the visual system.
Use $uid to implement the UI.
Use $ind to shape a physical-digital product touchpoint.
Use $sec to review this auth change.
Use $doc to update onboarding docs.
Use $do to update CI or deployment automation.
```

## Use `tc` For Durable Work

For substantial work, keep the durable record in `tc`:

```bash
tc prd create --title "Checkout v2" --content "..."
tc task create --prd 1 --title "Implement checkout flow"
tc wp store --task 1 --type architecture --title "Checkout architecture" --content "..."
```

Useful work product types:

- `architecture`
- `specification`
- `code`
- `test`
- `security`
- `operations`
- `documentation`

## Check Memory Drift

Before relying on durable memory after restructures, renames, setup changes, or
framework updates, run:

```bash
cc memory check --json
```

This checks stored memory for broken paths, unresolved commands, version
conflicts, and stale entries without spending model tokens.

## Use Live Docs Before API Work

Before planning or coding against an installed third-party package API:

```bash
cc docs get <package> --topic <area> --json
```

Examples:

```bash
cc docs get openai --topic responses --json
cc docs get stripe --topic payment-intents --json
cc docs get react-router --topic loaders --json
```

If `cc docs` is unavailable, verify through local package files or official docs before coding.

## Use The QA Gate For Implementation

Implementation work that needs verification should use the QA-gate convention:

1. task metadata includes `requiresQa=true`
2. `$me` stores a `code` work product
3. `$qa` stores a `test` work product
4. the QA work product includes an evidence artifact and a verdict token

Verdict tokens:

```text
ARTIFACT: test-run|pytest tests/ exit=0 "47 passed"
VERDICT: APPROVED
VERDICT: APPROVED-WITH-MINOR-FIXES
VERDICT: REJECTED
```

Passing verdicts require an `ARTIFACT:` marker. For product-facing work, use
evidence such as `screenshot-check`, `a11y-check`, or `design-fidelity-check`
when the meaningful risk is visual, interaction, or product-taste fidelity.

Inspect the gate:

```bash
scripts/copilot-gate.sh
```

## Use Delegation Carefully

Codex Copilot works locally in the main session by default.

Use `spawn_agent` only when the user explicitly asks for:

- subagents
- delegation
- parallel work

When delegation is approved, use `$launcher` to map the specialist role to a Codex spawned-agent type and give the subagent a narrow file scope.

## Use Orchestration For Parallel Streams

For parallel work:

1. have `$ta` define streams and file ownership
2. validate streams
3. get user approval for delegation and worktrees
4. launch scoped subagents only if requested
5. route every implementation stream through QA

Validate stream plans:

```bash
scripts/orchestrate-validate.py stream-plan.json
```

## Activate Optional Packs

The global plugin stays software-focused. Domain capabilities are activated per project:

```bash
scripts/activate-pack.py --project /path/to/project --pack business-creative
```

The included `business-creative` pack provides optional `kc`, `cco`, `cw`, `cs`, and `cpa` specialists.

## Good Prompts

```text
Use $protocol. I want to add SSO, but please route security and QA explicitly.
```

```text
Use $ta to turn this migration into tc-backed tasks with test requirements.
```

```text
Use $qa to reproduce the bug first, then route to $me if implementation is needed.
```

```text
Use $orchestrate to create a stream plan only. Do not spawn agents until I approve.
```
