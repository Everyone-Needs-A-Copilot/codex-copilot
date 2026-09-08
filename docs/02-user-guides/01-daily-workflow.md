# Daily Workflow

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

## Load Relevant Guidance

Specialists are instructed to retrieve the knowledge needed for the task; this
is agent-driven selection, not guaranteed runtime injection. For additional
context, the agent uses `cc skill select`, preserves required skills and stores
one selection receipt per task. Reuse unchanged content instead of loading it
again. Missing tools or skills must be reported explicitly.

For product work, design specialists select focused `cc design` playbooks and
carry a surface contract through implementation and QA. See [Design Quality](design-quality.md)
for the 21-action catalog and examples. Describe the work in your prompt; you do
not normally need to name each playbook yourself.

Optional edit feedback runs only after project/runtime enablement and native hook
trust. Approved personal rules are selected by project and specialist scope;
reflection proposes new rules with evidence and owner approval. Neither feature
silently mines history or promotes preferences. Existing projects need their
normal update and activation workflow before receiving new capabilities.

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

## Use Initiatives For Multi-Phase Work

Formal initiatives live in `docs/40-initiatives/NN-slug/` with `README.md`, `phases/`, `decisions/`, and `retrospectives/`.

Use initiative Markdown for durable goals, phase design, decisions, validation evidence, and outcomes. Keep live task state, dependencies, assignments, work products, and QA status in `tc`, then link the two surfaces.

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

Implementation work that needs verification follows the [Quality Gates](04-quality-gates.md)
contract:

1. Set `metadata.requiresQa=true` and register the task's acceptance criteria and source scopes before implementation.
2. Store the implementation work product and route to `$qa`.
3. Capture `tc task evidence-identity` before verification and compare another capture afterwards.
4. Store observed results and artifacts for every registered criterion, the exact identity, a baseline and one supported verdict in a task-bound `test` work product.
5. Inspect the gate, then complete through `tc`; unfinished dependencies also prevent completion.

```bash
tc task check-qa 123 --json
scripts/copilot-gate.sh --task 123
```

Use the actual task ID in place of `123`. An artifact marker and approval token
alone are insufficient. Product-facing work also needs relevant rendered,
interaction and accessibility evidence; a ready design report does not grant QA.

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
