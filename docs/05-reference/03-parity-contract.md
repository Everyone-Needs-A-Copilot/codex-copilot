# Claude Parity Contract

Codex Copilot mirrors Claude Copilot capability intent, not Claude-only syntax.

The current baseline is recorded in `parity/claude-baseline.json`:

- Claude Copilot framework: `5.13.0`
- `cc`: `1.7.0`
- `tc`: `1.3.0`
- Codex Copilot parity release: `0.6.0`

## Implemented

- `AGENTS.md` project instructions
- direct Codex skills for the software/product specialist roster
- `$protocol`, command-equivalent skills, and `tc` work products
- Live Docs guidance through `cc docs`
- memory drift checks through `cc memory check`
- artifact-bound QA-gate state convention through `tc` metadata, QA work products, and `scripts/copilot-gate.sh`
- optional specialist packs for `kc`, `cco`, `cw`, `cs`, and `cpa`
- stream validation through `scripts/orchestrate-validate.py`
- deterministic specialist contract evals through `cc eval`
- `cc memory export`, layered knowledge repositories, and `cc config add/remove`
- `tc wp render`, `tc worker`, and per-task `--max-budget-usd` metadata

## Substituted

Claude lifecycle hooks are substituted with explicit Codex mechanisms:

- preflight and routing instructions
- `tc` task metadata
- QA work products with `ARTIFACT:` markers and verdicts
- inspection scripts and tests

Here, "Claude lifecycle hooks" means Claude Code runtime events such as
SessionStart, PreToolUse, and SubagentStop. It does not mean the design-led
product creation protocol; the Codex protocol remains design-led.

Claude named-agent syntax is substituted with direct skill names and `agent-catalog.json`.

Headless worker orchestration is substituted with explicit user-approved `spawn_agent` launch templates and worktree safety checks.

## Deferred

Automatic runtime hook enforcement remains platform-dependent. Codex Copilot should not describe hook enforcement as implemented until Codex provides a matching lifecycle surface.

Claude's hook-backed `/careful` and `/freeze` safety primitives are therefore
deferred rather than imitated. Codex host safety policy and explicit project
instructions remain the honest substitute, not equivalent mechanical enforcement.

## Content-Level Parity

Claude Copilot versions its agents (`.claude/agents`) and commands
(`.claude/commands`) independently of the top-level `framework` string in
`VERSION.json`. That means a content change to an agent or command file that
doesn't bump the framework version passes the version-only check above while
Claude Copilot and Codex Copilot still diverge in substance. Content-level
parity closes that gap by hashing the files instead of trusting a version
number to move when they change.

`scripts/check-upstream-parity.py --content` sha256-hashes every upstream file
that defines shared, mirrored behavior:

- `.claude/agents/*.md`
- `.claude/commands/*.md`
- `.claude/skills/**/SKILL.md`

and compares those hashes, plus the upstream `framework`/`agents`/`commands`
version fields, against the committed manifest
`parity/upstream-content-hashes.json` (`{generated_at, upstream_commit,
files: {relpath: sha256}, versions: {framework, agents, commands}}`). The
`--content` result is nested under a `content` key in the existing JSON
output (`status: pass|drift`, `changed`/`added`/`removed` file lists, and
`version_diffs`) so the original version-only contract (`status`,
`upstream`, `mismatches`) is unchanged for callers that don't pass
`--content`. The script exits nonzero on drift when `--content` is used.
`scripts/smoke-test.sh` runs both the version-only check and
`--content` as separate steps, so content drift is visible on every smoke
run against a local Claude Copilot checkout, not just when someone remembers
to ask for it.

### Sweep Workflow

1. **Drift**: `python3 scripts/check-upstream-parity.py --content --json`
   reports `content.status: "drift"` with the specific agent/command/skill
   files that changed (or were added/removed) and any `agents`/`commands`/
   `framework` version-field diffs.
2. **Catch up**: port the upstream content change into Codex Copilot's
   mirrored surface (skills, `agent-catalog.json`, prompts, docs) the same
   way any other parity update is handled.
3. **`--update-baseline`**: once Codex Copilot has caught up, run
   `python3 scripts/check-upstream-parity.py --update-baseline` to
   regenerate `parity/upstream-content-hashes.json` from the current
   upstream checkout. This is the explicit "we caught up" action — it is
   never implicit, so a drifted baseline can't silently start passing again
   without someone deciding it should.

### The port guard (`--update-baseline` cannot resolve drift on trust alone)

Step 3 above used to be trust-based: `--update-baseline` regenerated the
manifest from whatever the upstream checkout looked like, with **no check
that codex-copilot's own mirrored surface had actually been touched** —
running it alone, with nothing ported, silently marked real drift
"resolved." That gap is now closed mechanically. When a prior baseline
already exists and shows real content drift against the freshly-hashed
upstream, `--update-baseline` **refuses** (exits 1, leaves the baseline
file untouched) unless one of two things is true at the moment it runs:

- codex-copilot's own working tree has a **live, uncommitted change**
  outside `parity/` (the normal flow: port the mirrored surface, leave it
  staged/unstaged, run `--update-baseline`, then commit both together in
  one commit — exactly how commit `ce087be1` did it); or
- the caller passes `--attest-no-port-needed "<reason>"`, which unblocks
  the update and records the reason in `parity/baseline-update-log.json`
  instead of resolving the drift silently (for genuine no-mirror-to-touch
  cases, e.g. a pure renumbering/comment-only upstream change).

A candidate third signal — "codex-copilot's HEAD moved since the last
recorded update" — was tried and **rejected**: it let a prior, unrelated
port commit silently unlock resolving a later, different drift that was
never actually ported for. Only a live diff at the moment of the update
counts; see `scripts/check-upstream-parity.py`'s `run_update_baseline()`
and `tests/test_mirror_parity.py`'s
`test_update_baseline_port_guard_*` tests for the exact mechanics and the
regression coverage for that rejected signal.

`parity/baseline-update-log.json` records the provenance of the most
recent successful update (`codex_head_commit`,
`codex_working_tree_dirty_at_update`, `port_attestation`) for audit —
separate from `parity/upstream-content-hashes.json` so the baseline
manifest's own schema is unchanged.

### Recurrence prevention: the parity-warn hook

Drift has previously recurred not because the sweep steps above don't work,
but because nothing prompted anyone to re-run them after a later Claude
Copilot commit landed. `scripts/warn-parity-drift.sh` closes that gap:
`scripts/install-parity-warn-hook.sh` installs it as a managed block in
Claude Copilot's own `pre-commit` hook (chained onto whatever hooks are
already there, following the same idempotent managed-block convention as
`copilot-control-tower/tools/cse-bench/install-claim-sweep-hook.sh`). It
fires only when a commit stages a file under the tracked glob
(`.claude/agents/*.md`, `.claude/commands/*.md`, `.claude/skills/**/SKILL.md`)
and the content baseline is not confirmed in sync, and it prints the exact
Sweep Workflow commands to run. It is a WARNING, not a gate — it always
exits 0, because a downstream mirror's sync lag should never block work in
the upstream repo. Install/refresh it with:

```bash
cd codex-copilot && scripts/install-parity-warn-hook.sh
```

## Updating The Baseline

When Claude Copilot changes, update:

1. `parity/claude-baseline.json`
2. `VERSION.json`
3. `plugins/codex-copilot/agent-catalog.json`
4. `plugins/codex-copilot/agent-catalog.schema.json`
5. docs and tests that assert the parity surface

Then run:

```bash
scripts/smoke-test.sh
```

When a Claude Copilot checkout is available at `../claude-copilot` or through
`CLAUDE_COPILOT_ROOT`, smoke testing also requires exact upstream component
version agreement. This prevents an internally consistent but stale snapshot
from being reported as current.
