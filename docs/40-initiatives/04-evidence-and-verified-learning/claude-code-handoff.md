# Claude Code handoff: complete CSE adoption and rollout

Prepared 7 September 2026. Audience: Claude Code working in
the sibling `claude-copilot` checkout.
Handoff record: **codex-copilot PRD-9 / TASK-16**.
This is the original implementation specification. For subsequent verified outcomes,
see [shared gap closure](../05-design-quality/phases/03-shared-gap-closure.md);
read current `tc` state before treating any historical gap below as still open.

## Start here

Implement the remaining Claude Copilot enablement for CSE delivery evidence,
verified personal learning, selective context loading, runtime verification and
controlled effectiveness evaluation. Preserve the mechanisms already implemented;
close the integration and rollout gaps below instead of repeating the repository
research. Start with architecture and QA framing, then implementation, security
review, verification and release preparation under the applicable local protocol.

Read this whole handoff, then `CLAUDE.md`, `AGENTS.md`, `SOUL.md`, and
`docs/01-architecture/12-architecture-guiding-principles.md` in Claude Copilot.
Revalidate the source and installation inventory before editing: the workspaces
contain unrelated user changes, and installed binaries do not all match source.
Proceed with routine authorized work; do not interpret this document as new
authority for blanket staging, destructive Git operations, provider uploads,
messages, private-data publication, or automatic preference promotion.
Use the active session's authorization for release and experiment execution;
prepare the exact candidate and verification evidence before raising any actual
remaining approval requirement.

Create or reuse a rollout PRD in **Claude Copilot's own `tc` database**, with
QA-required implementation tasks for the work packages below and explicit
dependencies. Link back to codex-copilot PRD-9 / TASK-16; task and WP numbers are
database-local. Completed TASK-11–15 cover bounded mechanisms and local activation,
not this rollout. Keep live status, dependencies, work products and verdicts in
`tc`; this handoff is the durable specification, not another task board.

Dependency order: establish A, implement B and C, prepare the immutable candidate
and disposable installation from E, verify D against that candidate, then finish
E's release and project rollout. Keep runtime readiness and the pilot's adoption
decision as separate gates with separate evidence.

## What exists and what remains

| Capability | Observed baseline | Remaining gap |
|---|---|---|
| Delivery evidence | Native Claude and Codex `ta/me/qa` playbooks describe criteria, observations, tested identity and baselines | Mechanically validate the task-bound evidence contract and reconcile Claude session gating with task completion |
| Personal learning | Private `scripts/taste` validates selected receipts, independent observations, owner approval, conflicts and retirement | Prove configured Claude discovery, applicability and reflection behavior; no real rules have been promoted |
| Context selection | Shared `cc skill select` returns selected content, source hashes, reasons, deduplication and character-budget receipts | Put bounded selection into the normal optional-context workflow and prove consumption; it is not automatic startup injection |
| Runtime reporting | `cc doctor --runtime-details` separates installation from unknown trust/dispatch; explicit probes exercise Codex hook contracts directly | Collect Claude-origin lifecycle evidence, including negative cases, and avoid promoting direct probes into enforcement claims |
| Outcome evaluation | Shared freeze/check commands and a Copilot Benchmark pilot skeleton exist | Run frozen baseline/candidate Claude trials with real review and a genuine clarification case |
| Distribution | Active local `cc` is 2.12.15; global Claude `ta/me/qa/reflect` received additive sections | Build a reproducible committed candidate, verify installation, and update consuming projects through the canonical transaction |

The local activation is an editable development installation, not a published
release. Claude's framework manifest still says **5.14.16**, Codex's **0.7.0**;
the `cc` component says **2.12.15**, with an explicit unpublished-adoption note.
Do not treat those version strings as proof of identical installed content.
Global `~/.claude/CLAUDE.md` and all consuming project snapshots were not refreshed.

## Ownership and source map

Paths in this table are relative to the parent CSE workspace directory.

| Owner | Primary files and responsibility |
|---|---|
| `claude-copilot` | `.claude/agents/{ta,me,qa}.md`, `.claude/commands/{protocol,reflect,update-copilot,update-project}.md`, `CLAUDE.md`, `.claude/hooks/{subagent-stop,pretool-check}.sh`: native behavior and lifecycle adapters |
| Shared `cc`, in `claude-copilot` | `tools/cc/src/cc/core/skill_store.py`, `core/runtime_evidence.py`, `core/evaluation/adoption.py`, corresponding `commands/skill.py`, `commands/eval.py`, `main.py`, `api.py`: retrieval and observation mechanics |
| Shared `tc`, in `claude-copilot` | `tools/tc/`: task state and authoritative completion predicate; reconcile installed/source divergence before extending it |
| Installation, in `claude-copilot` | `scripts/install-framework-snapshot.py`, `tools/cc/install.sh`, `tools/cc/src/cc/core/ecosystem/{canonical_transaction,project_integration}.py`, `VERSION.json`: snapshot provenance and canonical project reconciliation |
| `knowledge-copilot-private` | `scripts/taste`, `08-taste/README.md`, generated `08-taste/INDEX.md`: personal evidence and rules, kept private |
| `copilot-bench` | `docs/pilots/cse-effectiveness/README.md`, `cse-adoption.plan.example.json`, existing `./bench` runner: frozen experiments and run artifacts |
| `codex-copilot` | Native skills, `scripts/copilot-gate.sh`, parity manifests and this initiative: consume shared behavior through Codex-native adapters |

Do not edit materialized `plugins/codex-copilot/` copies inside other projects as
the authoritative Codex source. Do not introduce another memory store, task engine,
model runner, daemon, development MCP server or universal framework layer.

## A. Reconcile CLI provenance and establish the candidate baseline

**Confirmed prerequisite:** the active `~/.local/bin/tc` uses
`~/.copilot/enforcement-runtime-20260907/bin/python` and imports `tc`
from that environment's site-packages. It supports `tc task check-qa`.
The checked-out `claude-copilot/tools/tc/src/tc` does not expose that command.
Python API imports in the default `python3` currently resolve to the checkout,
so even CLI/API operations can exercise different implementations.

Read-only reproduction from Claude Copilot on the preparation date:

```bash
$HOME/.local/bin/tc task check-qa --help
# Supported by the installed CLI.

PYTHONPATH=tools/tc/src \
  ~/.copilot/enforcement-runtime-20260907/bin/python \
  -m tc.main task check-qa --help
# Exit 2: No such command 'check-qa'.
```

Claude's current `scripts/copilot-gate.sh` calls this command. Locate the reviewed
source that produced the installed capability and reconcile it into the correct
source/release lineage, preserving unrelated changes. Do not copy an entire
site-packages tree into the repository or assume the installed build is the
authoritative implementation. Ensure CLI and importable API completion paths use
the same QA predicate; a Python batch must not bypass what the CLI enforces.

Record HEAD, dirty-file hashes, executable/interpreter/module paths, effective
config, framework source, global/project override paths and test-file integrity
before modifying anything. Use isolated checkouts when dirty state would collide;
also isolate databases, ports and processes used by verification.

**Acceptance:** a fresh candidate install has the required `tc` API/CLI gate,
`cc` commands and matching source identities without borrowing the pre-existing
enforcement environment; installation/reinstallation cannot silently discard them.
If source provenance cannot be established, record a release blocker rather than
certifying the current machine as a reproducible distribution.

## B. Enforce delivery evidence through one task authority

The Claude QA playbook (`claude-copilot/.claude/agents/qa.md` in the sibling workspace)
already defines this compact packet for each required criterion:

```text
CRITERION: <required behavior and input/state>
EXPECTED: <observable outcome>
OBSERVED: <actual outcome>
IDENTITY: <checkout/revision + dirty fingerprint; runtime/config/server/data>
BASELINE: <before evidence, or unavailable + reason>
ARTIFACT: <accepted type>|<local evidence or failable command + result>
UNTESTED: <required cases not exercised, or none>
VERDICT: <supported verdict>
```

Specify a versioned, machine-readable representation or validated envelope linked
to the existing task-bound `test` work product; preserve a readable rendering.
Use shared `tc` completion authority, with thin native Claude and Codex adapters,
rather than separate permissive regex decisions in each caller. Read the actual
completion implementation identified in A before choosing the module boundary.
Handle older work products explicitly: preserve history and existing contracts;
do not silently treat legacy evidence as satisfying the stronger contract or
retroactively invalidate every completed task without a migration design.

The current Claude hook (`claude-copilot/.claude/hooks/subagent-stop.sh` in the sibling workspace)
has relevant behavior that must be reconciled:

- `parse_qa_verdict` checks an APPROVED token before REJECTED, and scans the whole
  returned message; conflicting tokens or quoted examples can influence parsing.
- `handle_qa_completion` clears all session-pending tasks when a passing response
  mentions no matching task; approval is therefore not reliably task-specific.
- After three failures, the hook removes the task from its pending list and
  reports advisory unblocking; `COPILOT_QA_GATE=off` is another documented bypass.

Bind acceptance to the exact task, current implementation identity, criterion set
and QA work product. Only its matching pending task may clear. Missing fields,
unavailable artifacts, stale identity, wrong-task evidence, conflicting verdicts
and untested required behavior must prevent a passing completion decision.
Never execute a command merely because an artifact string contains it; QA invokes
known checks deliberately, and the validator inspects their recorded evidence.
Field presence and hashes cannot prove behavioral truth: QA must still verify the
expected result and the artifact's relevance.

Keep a documented recovery/escape path as the product requires, but distinguish
**session unblocked** from **task verified**: retries, disabled hooks, corrupt
state or missing `tc` may surface recovery instructions, never manufacture
approval or let unverified work satisfy the completion predicate. Preserve
`APPROVED-WITH-MINOR-FIXES` only for non-blocking issues with all required criteria
met. Keep external adversarial review optional; explicitly reconcile artifact-type
compatibility between Claude, Codex and the shared validator.

**Acceptance:** isolated checks demonstrate valid evidence passes; bare markers,
wrong/missing task IDs, mixed verdicts, quoted approval examples, stale evidence,
missing criteria, changed implementation after QA and metadata-only approval fail;
one task's pass leaves another pending; concurrent updates preserve both records;
retry exhaustion and disabled hooks cannot create a verified task. Verify both
CLI/API completion and the native hook adapter, not just a parser helper.

## C. Connect selective context and verified learning to ordinary work

Use the existing protocol/task-entry and specialist-loading paths to call
`cc skill select` when additional optional knowledge is needed. Store the receipt
once in the task WP, actually consume the selected content, and avoid loading the
same source hash repeatedly. Prefer task-specific loading over a growing global
startup prompt. Preserve mandatory repository/system instructions independently
of relevance filtering, and retain explicitly required skills even when they
exceed the optional character budget; report the overage.

Update the source templates and framework-owned installation surfaces that deliver
these instructions, not only the repository-root `CLAUDE.md`. Define visible
fallbacks for unavailable `cc`, missing required skills, no relevant optional
skills and changed sources. Keep existing `skill get/search` behavior compatible;
character receipts are not measured model tokens or proof of consumption.

Resolve `paths.knowledge_repo` through `cc` configuration, including tier and owner;
do not hardcode the private repository into framework defaults. Verify Claude's
specialists read only applicable active rules from the generated taste index and
do not elevate personal preferences above project constraints. Reflection must
select a real correction/outcome, preserve a minimized source receipt, and keep
unverified observations in existing `cc memory` when the corpus is unavailable.

Use the existing private script for independent-session evidence, source rechecks,
contrary evidence, concrete owner approval, promotion and retirement. Approval
flags record an operator attestation, not authenticated identity. Never mine
entire histories, count silence, invent feedback, automatically approve a rule,
or copy private quotes into public framework artifacts. Exercise promotion with
synthetic data only in a disposable corpus; no real rule is required for rollout.

**Acceptance:** a Claude task records selected and excluded sources, uses relevant
content and retains required constraints under budget pressure; repeat loading is
bounded; changed sources invalidate reuse; absent configuration degrades visibly;
cross-project rules do not leak applicability; unverified/conflicting candidates
remain inactive; retirement removes a rule from the next active load without
destroying its history. Keep the private corpus's changes in its own release path.

## D. Prove Claude lifecycle behavior and evaluate outcomes separately

First install the candidate into an isolated consumer project and exercise a real
Claude task through architecture, implementation and QA using its installed native
workflow. Verify source precedence for global/project playbooks and commands,
effective hook registration, actual hook events, the armed gate, a rejected QA
attempt, a valid task-bound approval and the resulting `tc` state. Capture local
event/session identity, model/runtime version, executable and config hashes,
candidate content hash, commands/results and artifacts. Do not infer event origin
from a self-authored JSON file or a direct shell invocation of a hook.

Include negative runs with a missing/disabled hook, different project override,
wrong task evidence and a changed configuration after a successful run. Keep
declared, installed, exercised, trusted and enforced claims distinct. Extend the
existing reporting boundary only when necessary to represent independently
verifiable runtime observations; preserve default `cc doctor --json` compatibility.
Missing runtime-origin evidence means enforcement remains unverified, even if
direct hook tests pass. Do not build another runtime verifier/runner if an existing
one provides the required evidence.

Then follow the benchmark handoff (`copilot-bench/docs/pilots/cse-effectiveness/README.md` in the sibling workspace)
and shared observation contract (`claude-copilot/docs/30-operations/08-evidence-and-adoption.md` in the sibling workspace).
Adapt the existing example from its Codex arm to **Claude Copilot baseline versus
Claude Copilot candidate**, not vanilla versus Copilot. Inspect the existing runner
and freeze exact model, effort, runtime/version, configuration and content identities
before execution. Preserve task fixtures and rubrics; record all invalid runs and
baseline failures rather than silently replacing them.

Start with the six documented task families and two repetitions per variant
(twelve complete pairs). Add a genuine necessary-clarification holdout before
claiming judgment coverage, increasing the frozen case/pair count accordingly.
Keep learning sources disjoint from evaluation inputs; never train rules on pilot
cases. Run each variant against the same inputs and review contract. Genuine
human-rework and judgment measurements require real review, not synthesized scores.

The predeclared policy requires no correctness, required-clarification, abstention
or unauthorized-effect regression; no increase in misapplied rules; at least 10%
less reviewed corrective work; and no more than 10% growth in context characters
or calls. Use `cc eval adoption-freeze` and `adoption-check` on complete observations.
They validate observations; they do not run models, authenticate reviewers or
establish statistical significance. Preserve a baseline/hold decision on missing
or unfavorable evidence; report mechanical readiness separately from effectiveness.

**Acceptance:** Claude-origin positive and negative lifecycle artifacts prove the
claimed gate behavior, and a separately stored pilot report links frozen inputs,
every planned trial, real reviews and the retain/adopt result. A dry run or
synthetic validator check does not satisfy either live-evidence requirement.
If runtime/account/reviewer access is unavailable, finish the independent work
and leave this specific empirical gap open with a replayable handoff.

## E. Package, release and propagate without losing project ownership

Prepare a scoped candidate containing only reviewed changes, including any source
reconciliation from A. Use the repository's release procedure to choose coherent
framework/component versions, dependency requirements, release notes and Codex
parity updates; do not merely stamp the current version as released. Keep private
knowledge content separate. Final candidate contents must be immutable for install
and runtime/pilot verification; changes afterward require rerunning affected checks.

The current `/update-copilot` (`claude-copilot/.claude/commands/update-copilot.md` in the sibling workspace)
pulls its source and selects committed `HEAD`/`HEAD^{tree}` for
`install-framework-snapshot.py`. It cannot distribute the present uncommitted
adoption edits. Do not run it as a shortcut before the intended candidate is in
the source revision it will install. Verify **both cc and tc**, the global command
roster, actual agent/reflect resolution, source-commit/tree receipts and dependency
provenance after installation; a `--version` match alone is insufficient.

Exercise clean installation, upgrade, repeat no-op and recovery first in disposable
locations using the canonical installer/reconciliation paths. Verify current source
rosters actually distribute `reflect` and the new optional-context guidance; file
presence in the framework does not imply inclusion in a consuming project.

After the candidate is released through the authorized route, use `/update-copilot`
for the machine and `/update-project` (`claude-copilot/.claude/commands/update-project.md` in the sibling workspace)
for each in-scope project. Inspect the exact canonical reconcile plan, use its
fresh plan ID for apply, and run independent verify. Respect existing authorization
for the concrete action and any real remaining command-plan confirmation; do not
invent an extra approval stage. If a project is dirty, customized or ownership is
uncertain, preserve it and report the exact held path instead of overwriting it.
Inventory the in-scope projects; do not claim ecosystem-wide propagation after one.

Record the resulting lock, installed source identities, framework-owned hook
checksum/executable/registration and fresh-session behavior. Stage and verify the
supported recovery path before activating a candidate; never restore an old backup
over later user edits. Preserve activation receipts and pending QA state during
recovery. An interrupted install must remain recoverable and cannot report success
for mismatched disk and lock state.

**Acceptance:** a clean machine/project can reproduce the candidate without the
developer's editable environments; upgrade preserves custom content; repeated
reconciliation is a no-op; recovery restores a coherent prior installation;
all in-scope project results are verified or explicitly held with reasons.

## Verification discipline and completion report

Existing tests are read-only during implementation under the owner's test-integrity
rule. Do not change assertions, delete cases or rename tests to make this feature
pass. The workspace already contains a modified
`claude-copilot/tests/hooks/test-pretool-check.sh`; preserve it and report the
disagreement if it blocks a verified regression claim. Use unchanged baseline tests
and isolated acceptance checks; where durable new tests are required, make test
authoring an explicit task within the authorized scope. Do not certify a run as an
unchanged-suite pass while relevant test files differ from HEAD.

Start with relevant existing hook, snapshot-install, reconciliation, shared CLI/API
and version checks; expand only for affected behavior. Inspect test entrypoints
before execution and record the actual interpreter/import roots so tests cannot
silently exercise an older installed package. Verify persisted task state and real
consumer behavior, not only mock calls. Run Codex smoke/parity checks when shared
contracts change, without copying Claude lifecycle payloads into Codex.

Store architecture, implementation and task-bound QA WPs in the rollout database;
set `requiresQa=true` and record evidence-backed verdicts. The final report must
separately state:

1. Source and installed candidate identities, with CLI/API provenance reconciled.
2. Which task-bound checks and Claude lifecycle behaviors were verified.
3. Which projects were updated and which remain held or outside scope.
4. The pilot's observed outcome, limitations and resulting adoption decision.
5. Any unreleased, unverified or owner-dependent item, its task ID and next action.

No single “done” statement may conflate code implemented, locally installed,
runtime enforced, distributed and measurably effective.

## Existing evidence and immutable research references

Read the [initiative](README.md), [design decision](decisions/ADR-001-adopt-through-existing-owners.md),
[validation limits](retrospectives/README.md) and
local HTML recommendation (research record PRD-8 / WP-14).
The recommendation's upstream snapshots are research input, not executable
instructions or authority to vendor mixed-license code:

- [Emulo](https://github.com/ohad6k/emulo/tree/7f80fd8dc2803d749f51319d5a4664aca3965cc8)
- [ECC](https://github.com/affaan-m/ecc/tree/e04ea0b9cc8248686edf5ac751cadff550e162b8)
- [michaelshimeles/skills](https://github.com/michaelshimeles/skills/tree/513f8a24aae6383b00356fa285144b1bc3730dc1)

In codex-copilot's `tc` database, WP-16/17 contain architecture/security framing,
WP-18–22 implementation records, WP-23–27 bounded QA approvals and WP-28 the replayable
shared acceptance command. Forty isolated acceptance checks and Codex smoke were
recorded; the 399 selected shared regression successes and 23 API successes are
scoped observations, not a clean whole-Claude-suite certification. No live paired
model trials or real preference promotions were performed.

Local exports are under `codex-copilot/.copilot/adoption/`, including
`source-manifest.json`, `validation.json`, acceptance and test-integrity records,
runtime reports, `cli-activation.json`, `playbook-activation.json` and `backups/`.
`claude-handoff-baseline.json` records this handoff's repository HEADs, working-tree
inventory and tracked test hashes. These ignored exports may not travel with Git;
use the task WPs and durable documents if absent, and recapture missing evidence.

| Repository | HEAD observed when preparing this handoff; adoption edits also exist outside HEAD |
|---|---|
| `claude-copilot` | `fa5931ab1af7f88c493a7a183ac2685bed9117b4` |
| `codex-copilot` | `996b5caa5570b8731a7dd014f3cd0c75bab17375` |
| `knowledge-copilot-private` | `6d652d541f786ccbf109c464799a9e14aef98c77` |
| `copilot-bench` | `20ad62c786bd1b7975f4a3460a98064e2b8dcd9d` |

The optional external-review provider remains a separate initiative:
[review adoption cases](../03-safe-external-review-loops/adoption-cases.md).
A provider adapter, mandatory video capture, automatic publication and automatic
personal-policy promotion are not missing prerequisites for this rollout.

unknowns: the provenance and final canonical merge of the installed-only `tc` gate;
actual Claude lifecycle enforcement; the complete in-scope project inventory and
their current ownership holds; and net benefit on held-out work remain to be resolved
by the implementation and empirical steps above.
