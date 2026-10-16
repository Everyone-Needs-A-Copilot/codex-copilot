# Codex Copilot

Codex Copilot is a Codex-native operating layer for developers who want specialist reasoning, durable task context, and evidence-bound verification before work is called complete.

It mirrors Claude Copilot's capability intent through real Codex primitives: `AGENTS.md`, skills, plugin-bundled lifecycle hooks, `tc`, `cc`, scripts, tests, and explicitly approved `spawn_agent` delegation. It does not pretend Claude hook registration, slash commands, or named-agent syntax work unchanged in Codex.

## What You Get

- `$protocol` routing for defects, technical work, product experience, security, and infrastructure
- specialist skills for design, architecture, engineering, QA, security, documentation, and operations
- native hooks for conditional routing, failed-command circuit breaking, and concise subagent returns
- `tc` PRDs, tasks, streams, handoffs, and work products
- `cc` memory, skill discovery, configuration, and Live Docs
- task/source-bound QA through shared `tc` and `scripts/copilot-gate.sh`
- optional capability packs that stay dormant until a project activates them
- `docs/40-initiatives/` for durable multi-phase initiative knowledge linked to `tc` execution state

## Quick Start

### 1. Clone And Verify

Current source requires shared **cc 2.13.0** and **tc 2.0.0**; see
[`VERSION.json`](./VERSION.json). The evidence/design source is merged on `main`
and remains under `Unreleased`; installing it is a development-source choice,
not proof of a foundation release. See [release preparation](./docs/03-developer-guides/03-evidence-design-release.md).

```bash
git clone https://github.com/Everyone-Needs-A-Copilot/codex-copilot.git
cd codex-copilot

tc --help
$HOME/.local/bin/cc --help
scripts/smoke-test.sh
```

### 2. Wire A Project

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

Re-running the installer repairs framework-owned plugin and QA-gate files while preserving existing `AGENTS.md` and project-owned customization. New projects receive decision instruments, `docs/40-initiatives/`, and an executable copy of the shared QA gate.

Start a new Codex session after installing or updating the plugin. Review and trust newly introduced hook definitions with `/hooks`; Codex skips non-managed hooks until their current hash is trusted.

### 3. Start In Codex

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

## Operating Model

```text
request
  -> $protocol
  -> specialist workflow
  -> tc-backed work products
  -> evidence-bound QA when implementation is involved
```

Most work runs in the main Codex session. Subagents are used only when the user explicitly asks for delegation or parallel work.

Formal multi-phase initiatives live in `docs/40-initiatives/NN-slug/`. Their briefs, phase plans, decisions, closure evidence, and retrospectives are durable documentation; live tasks, dependencies, assignments, and QA status remain authoritative in `tc`.

## Documentation

- [Documentation Index](./docs/README.md)
- [Getting Started](./docs/01-setup/03-getting-started.md)
- [Daily Workflow](./docs/02-user-guides/01-daily-workflow.md)
- [Design Quality And Activation](./docs/02-user-guides/design-quality.md)
- [Architecture](./docs/04-architecture/00-overview.md)
- [Capability Matrix](./docs/05-reference/01-capability-matrix.md)
- [Initiatives](./docs/40-initiatives/README.md)
- [Troubleshooting](./docs/07-troubleshooting/00-overview.md)

## Honest Boundaries

- Selected Claude hook intent is ported to Codex-native plugin hooks; QA closure remains explicit `tc` metadata, work products, and tests.
- Current QA-required tasks need a registered acceptance contract, captured source identity, observed criterion results and evidence-bound artifacts; a bare approval token cannot complete a task.
- The framework is degraded without the shared `cc` and `tc` CLIs.
- Parallel work is user-approved and scope-validated; there are no hidden background workers.
- Codex Copilot owns no memory engine, task engine, database, hosted service, or model provider.

That honesty is intentional.

## Project Information

- [Contributing](./CONTRIBUTING.md)
- [Security](./SECURITY.md)
- [Changelog](./CHANGELOG.md)
- [License](./LICENSE)

<!-- cse-design-quality:start -->
Design quality: 21 focused actions through shared `cc design`, native specialist guidance, optional edit feedback and task-bound review. See [the operating guide](docs/02-user-guides/design-quality.md).
<!-- cse-design-quality:end -->

## Work lifecycle and optimization

`$cleanup` preserves useful history, applies scoped lessons and retires unnecessary
artifacts with exact approval and verified recovery. Protocol, direct specialists
(including optional packs when the project lifecycle instruction is installed), resume, pause, reflection and task closure use the same
[packaged contract](plugins/codex-copilot/skills/cleanup/references/work-lifecycle.md).
Small tasks use their existing record; a completed body has one maintained
narrative. Registered lifecycle criteria are checked by existing tc v2 QA, not a
new runtime hook or task engine. Recorded/applied lessons and cleaner files are
not evidence of improved product outcomes until later work measures the effect.

Maintainers synchronize only this canonical contract from an explicit Claude
foundation checkout:

```bash
python3 scripts/sync-work-lifecycle.py --claude-root /path/to/claude-copilot
python3 scripts/sync-work-lifecycle.py --claude-root /path/to/claude-copilot --check
```

Check mode detects drift without writing. The lifecycle was introduced in 0.9.0;
0.9.1 makes worktree checks and visible cleanup approval requests explicit at
start/resume, new PRD/initiative, merge, finish, pause and handoff. Publishing a
release does not update installed consumers. Setup preserves an existing
project `AGENTS.md`: review and add the lifecycle pointer from the project template
when adopting into an existing project, including direct optional pack work.
Standalone pack activation does not install the base lifecycle contract.
