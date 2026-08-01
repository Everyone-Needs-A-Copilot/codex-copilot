# Codex Copilot

Codex Copilot is a Codex-native operating layer for developers who want specialist reasoning, durable task context, and evidence-bound verification before work is called complete.

It mirrors Claude Copilot's capability intent through real Codex primitives: `AGENTS.md`, skills, plugins, `tc`, `cc`, scripts, tests, and explicitly approved `spawn_agent` delegation. It does not pretend Codex has Claude-only slash commands, named-agent syntax, or lifecycle hooks.

## What You Get

- `$protocol` routing for defects, technical work, product experience, security, and infrastructure
- specialist skills for design, architecture, engineering, QA, security, documentation, and operations
- `tc` PRDs, tasks, streams, handoffs, and work products
- `cc` memory, skill discovery, configuration, and Live Docs
- artifact-bound QA through `scripts/copilot-gate.sh`
- optional capability packs that stay dormant until a project activates them
- `docs/40-initiatives/` for durable multi-phase initiative knowledge linked to `tc` execution state

## Quick Start

### 1. Clone And Verify

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

The installer refuses to replace existing `AGENTS.md`, plugin links, skill links, or QA-gate wiring. New projects receive decision instruments, `docs/40-initiatives/`, and an executable link to the shared QA gate.

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
- [Architecture](./docs/04-architecture/00-overview.md)
- [Capability Matrix](./docs/05-reference/01-capability-matrix.md)
- [Initiatives](./docs/40-initiatives/README.md)
- [Troubleshooting](./docs/07-troubleshooting/00-overview.md)

## Honest Boundaries

- Claude runtime hooks become explicit `tc` metadata, scripts, work products, and tests.
- A bare `VERDICT: APPROVED` does not pass the QA gate; passing verdicts require an `ARTIFACT:` marker.
- The framework is degraded without the shared `cc` and `tc` CLIs.
- Parallel work is user-approved and scope-validated; there are no hidden background workers.
- Codex Copilot owns no memory engine, task engine, database, hosted service, or model provider.

That honesty is intentional.

## Project Information

- [Contributing](./CONTRIBUTING.md)
- [Security](./SECURITY.md)
- [Changelog](./CHANGELOG.md)
- [License](./LICENSE)
