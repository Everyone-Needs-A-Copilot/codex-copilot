# Codex Copilot

Codex Copilot is a Codex-native operating layer for developers who want specialist reasoning, durable task context, and evidence-bound verification before work is called complete.

It mirrors [Claude Copilot](https://github.com/Everyone-Needs-A-Copilot/claude-copilot)'s capability intent through real Codex primitives: `AGENTS.md`, skills, plugin-bundled lifecycle hooks, `tc`, `cc`, scripts, tests, and explicitly approved `spawn_agent` delegation. It does not pretend Claude hook registration, slash commands, or named-agent syntax work unchanged in Codex.

Current release: **0.14.0**, which mirrors Claude Copilot 5.30.0 and requires shared **cc 2.16.0** and **tc 2.10.0** (see [`VERSION.json`](./VERSION.json) and the [parity contract](./docs/05-reference/03-parity-contract.md)).

## What You Get

- `$protocol` routing for defects, technical work, product experience, security, and infrastructure
- a done block before substantial work (Done means / Proven by / Not in scope / Assumptions / First example) that becomes the `tc` task contract, and a four-line completion report (Works / Unverified / Parked / Decision needed)
- specialist skills for architecture (`$ta`), engineering (`$me`), QA (`$qa`), security (`$sec`), documentation (`$doc`), DevOps (`$do`), service design (`$sd`), industrial design (`$ind`), UX (`$uxd`), UI design (`$uids`) and UI implementation (`$uid`)
- `$new-product`: facilitated zero-to-one product definition from an empty folder, through six phases to a prototype, with a root `SOUL.md` decision instrument that can't be ratified until the user has answered what would make them stop using the product
- workflow skills: `$continue`, `$pause`, `$reflect`, `$cleanup`, `$map`, `$memory`, `$orchestrate`, `$extensions`, `$config`, `$skills-approve`, `$knowledge-copilot`, and setup and update skills
- native hooks for conditional protocol routing, failed-command circuit breaking, concise subagent returns, and optional design feedback on edits
- `tc` PRDs, tasks, streams, handoffs, work products, execution limits and test maps
- `cc` memory, skill discovery, configuration, Live Docs, design quality and rules
- task/source-bound QA through shared `tc` and `scripts/copilot-gate.sh`
- optional capability packs that stay dormant until a project activates them: `business-creative` (`kc`, `cco`, `cw`, `cs`, `cpa`) and `writing-legal` (proposal, slide and case-study copy, contract, IP, privacy, employment and government-contracting review)
- `docs/40-initiatives/` for durable multi-phase initiative knowledge linked to `tc` execution state

## Quick Start

### 1. Clone And Verify

```bash
git clone https://github.com/Everyone-Needs-A-Copilot/codex-copilot.git
cd codex-copilot

tc --help
$HOME/.local/bin/cc --help
scripts/check-versions.sh
scripts/smoke-test.sh
```

`cc` and `tc` come from Claude Copilot. The command name `cc` can also mean a system C compiler, so framework instructions use `$HOME/.local/bin/cc`.

### 2. Wire A Project

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

Setup writes `AGENTS.md`, the project plugin and its hooks, `.codex-copilot.json`, `cc` config and memory, an executable copy of the QA gate, `docs/40-initiatives/`, a `SOUL.md` and an architecture principles doc (skip both with `--no-decision-instruments`), and `.copilot/tasks.db` when `tc init` succeeds. Re-running it repairs framework-owned plugin, skill and QA-gate files in place; `AGENTS.md` and project-owned files are never replaced.

Keep a configured project current with `scripts/update-project.sh --project /absolute/path/to/project` (`--dry-run` reports changes first). Activate an optional pack with `scripts/activate-pack.py --project /absolute/path/to/project --pack business-creative`.

Start a new Codex session after installing or updating the plugin. Review and trust newly introduced hook definitions with `/hooks`; Codex skips non-managed hooks until their current hash is trusted.

### 3. Start In Codex

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

For a new product, open an empty folder and use `$new-product`.

## Operating Model

```text
request
  -> done block (one word from the owner)
  -> $protocol
  -> specialist workflow
  -> tc-backed work products
  -> evidence-bound QA when implementation is involved
  -> four-line completion report
```

Most work runs in the main Codex session. Subagents are used only when the user explicitly asks for delegation or parallel work, at most three at a time unless the done block says otherwise.

Formal multi-phase initiatives live in `docs/40-initiatives/NN-slug/`. Their briefs, phase plans, decisions, closure evidence, and retrospectives are durable documentation; live tasks, dependencies, assignments, and QA status remain authoritative in `tc`.

## Work Lifecycle

`$cleanup` preserves useful history, applies scoped lessons and retires unnecessary artifacts with exact approval and verified recovery. Protocol, direct specialists (including optional packs when the project lifecycle instruction is installed), resume, pause, reflection and task closure use the same [packaged contract](plugins/codex-copilot/skills/cleanup/references/work-lifecycle.md), with worktree checks and visible cleanup approval at start, resume, new PRD or initiative, merge, finish, pause and handoff. Registered lifecycle criteria are checked by existing `tc` QA, not a new runtime hook or task engine. Recorded lessons and cleaner files are not evidence of improved product outcomes until later work measures the effect.

Setup preserves an existing project `AGENTS.md`: when adopting into an existing project, add the lifecycle pointer from the project template. Standalone pack activation does not install the base lifecycle contract.

## Documentation

- [Documentation Index](./docs/README.md)
- [Install](./docs/01-setup/01-install.md) and [Getting Started](./docs/01-setup/03-getting-started.md)
- [Daily Workflow](./docs/02-user-guides/01-daily-workflow.md)
- [Protocol](./docs/02-user-guides/02-protocol.md), [Quality Gates](./docs/02-user-guides/04-quality-gates.md), [Parallel Work](./docs/02-user-guides/05-parallel-work.md) and [Capability Packs](./docs/02-user-guides/06-capability-packs.md)
- [Design Quality And Activation](./docs/02-user-guides/design-quality.md)
- [Architecture](./docs/04-architecture/00-overview.md)
- [Capability Matrix](./docs/05-reference/01-capability-matrix.md) and [Specialist Catalog](./docs/05-reference/02-specialist-catalog.md)
- [Release And Publishing](./docs/03-developer-guides/02-release-and-publishing.md)
- [Initiatives](./docs/40-initiatives/README.md)
- [Troubleshooting](./docs/07-troubleshooting/00-overview.md)

## Honest Boundaries

- Selected Claude hook intent is ported to Codex-native plugin hooks; QA closure remains explicit `tc` metadata, work products, and tests.
- Current QA-required tasks need a registered acceptance contract, captured source identity, observed criterion results and evidence-bound artifacts; a bare approval token cannot complete a task.
- The framework is degraded without the shared `cc` and `tc` CLIs.
- Parallel work is user-approved and scope-validated; there are no hidden background workers.
- Claude-only features with no Codex event, such as the PreCompact handoff hook, are not ported; each adoption records what was and wasn't ported in `parity/`.
- Publishing a release does not update installed consumers; each project updates through `scripts/update-project.sh`.
- Codex Copilot owns no memory engine, task engine, database, hosted service, or model provider.

That honesty is intentional.

## Maintainers

Claude parity is checked with `python3 scripts/check-upstream-parity.py --content` against a Claude Copilot checkout (`CLAUDE_COPILOT_ROOT`). `$new-product` is vendored byte-for-byte from Claude Copilot and pinned by `parity/skill-folder-hashes.json`; the work-lifecycle contract is synchronized with:

```bash
python3 scripts/sync-work-lifecycle.py --claude-root /path/to/claude-copilot
python3 scripts/sync-work-lifecycle.py --claude-root /path/to/claude-copilot --check
```

## Project Information

- [Contributing](./CONTRIBUTING.md)
- [Security](./SECURITY.md)
- [Changelog](./CHANGELOG.md)
- [License](./LICENSE)

<!-- cse-design-quality:start -->
Design quality: 21 focused actions through shared `cc design`, native specialist guidance, optional edit feedback and task-bound review. See [the operating guide](docs/02-user-guides/design-quality.md).
<!-- cse-design-quality:end -->
