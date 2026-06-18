# Codex Copilot

Codex Copilot is a Codex-native operating layer for serious software work. It gives Codex a repeatable specialist workflow, durable task memory, and explicit quality gates instead of a single undifferentiated assistant loop.

It is inspired by Claude Copilot, but it does not pretend Codex has Claude-only runtime features. The framework translates the useful parts into Codex primitives:

- `AGENTS.md` for project instructions
- Codex skills for specialist playbooks
- `tc` for PRDs, tasks, streams, handoffs, and work products
- `cc` for memory, memory drift checks, skill discovery, configuration, known references, and Live Docs
- optional `spawn_agent` delegation only when the user explicitly asks for subagents or parallel work
- dormant capability packs that projects can activate when they need domain-specific specialists

## What It Is

Codex Copilot is not a separate application. It is a framework of instructions, skills, scripts, templates, and docs that helps Codex behave like a disciplined lead engineer with access to specialist playbooks.

Use it when you want Codex to:

- classify work before coding
- bring in architecture, QA, security, DevOps, service design, UX, UI, or documentation thinking at the right time
- preserve important plans and outputs in `tc`
- verify third-party package APIs with Live Docs before coding against them
- keep implementation work from being treated as complete before QA
- coordinate explicit, scoped parallel work without hidden background automation

## Why It Exists

AI coding sessions are useful, but they often fail in predictable ways:

- they jump from vague intent straight to code
- they forget prior decisions
- they skip QA or treat build success as verification
- they use stale API knowledge for third-party packages
- they produce long plans that vanish into chat history
- they blur UX, UI, architecture, implementation, and testing into one generic response

Codex Copilot fixes those failure modes with a small operating model:

1. Route the work.
2. Apply the right specialist lens.
3. Store durable planning and work products.
4. Verify before closing.
5. Keep Codex-native boundaries honest.

## Core Values

| Value | What It Means In Practice |
| --- | --- |
| Discipline before speed | Classify, frame, and verify instead of rushing from request to code. |
| Native over imitation | Use Codex skills, `AGENTS.md`, scripts, and `tc` instead of pretending Claude slash commands or hooks exist. |
| Durable context | Important decisions, specs, implementation notes, and test results belong in `tc` and `cc`, not only chat. |
| Specialist judgment | Architecture, QA, design, security, docs, and ops each have a distinct job. |
| Explicit quality | Implementation is not the final gate when tests, review, or design fidelity matter. |
| User-approved delegation | Parallel work uses clear scopes and approval, not silent background workers. |

## What You Get

| Capability | What It Does |
| --- | --- |
| `$protocol` routing | Classifies new work and chooses the right specialist workflow. |
| Specialist skills | Provides direct Codex skills for service design, UX, UI design, UI implementation, architecture, engineering, QA, security, docs, ops, and industrial design. |
| `tc` task discipline | Stores PRDs, tasks, handoffs, stream metadata, and work products. |
| `cc` memory and config | Uses the Claude Copilot `cc` CLI for memory, drift checks, skill discovery, environment hydration, known references, and Live Docs. |
| Live Docs | Requires `cc docs` before planning or coding against installed third-party package APIs. |
| QA gate substitute | Uses `tc` metadata, artifact-bound QA work products, verdict tokens, and `scripts/copilot-gate.sh`. |
| Project setup | Wires projects to the shared framework without copying the framework repo. |
| Optional packs | Lets projects activate dormant domain skills without making them global. |
| Stream validation | Checks stream dependencies and file ownership before approved parallel work. |
| Release fitness | Provides version, manifest, parity, and smoke checks. |

## How It Works

```text
You
  |
  v
$protocol
  |
  +--> defect              -> qa -> me -> qa
  +--> technical           -> ta -> me -> qa
  +--> experience          -> sd -> uxd -> uids -> uid -> ta -> me -> qa
  +--> physical-digital    -> ind -> sd -> uxd -> uids -> uid -> ta -> me -> qa
  +--> UI polish           -> uids -> uid -> qa
  +--> security-sensitive  -> ta -> sec -> me -> qa
  +--> infrastructure      -> do -> me -> qa
  |
  v
tc-backed work products and verification
```

Most specialist work happens in the main Codex session. If the user explicitly asks for delegation, `$launcher` maps specialist intent onto Codex spawned-agent roles with clear scope boundaries.

## Quick Start

### 1. Clone The Framework

```bash
git clone https://github.com/Everyone-Needs-A-Copilot/codex-copilot.git
cd codex-copilot
```

### 2. Verify Tooling

Codex Copilot expects `tc` and `cc` to be installed:

```bash
tc --help
$HOME/.local/bin/cc --help
$HOME/.local/bin/cc docs sources
$HOME/.local/bin/cc memory check --json
```

Run the framework smoke test:

```bash
scripts/smoke-test.sh
```

### 3. Wire A Project

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

The setup script creates local links to the shared framework and writes project instructions. It refuses to overwrite existing `AGENTS.md`, plugin links, or skill links.

### 4. Start In Codex

Open the target project in Codex and start with:

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

## Everyday Usage

Use `$protocol` when starting new work:

```text
Use $protocol to fix the checkout regression.
Use $protocol to add a new onboarding flow.
Use $protocol to refactor the auth service.
Use $protocol to update staging deployment automation.
```

Use a specialist directly when the path is obvious:

```text
Use $ta to break this migration into tc-backed tasks.
Use $qa to reproduce and verify this bug.
Use $sec to review this auth change.
Use $doc to update setup documentation.
```

For substantial work, use `tc`:

```bash
tc prd create --title "Checkout v2" --content "..."
tc task create --prd 1 --title "Implement checkout state machine"
tc wp store --task 1 --type architecture --title "Checkout architecture" --content "..."
```

For third-party package APIs, use Live Docs:

```bash
cc docs get openai --topic responses --json
```

For QA-required implementation work, inspect the gate:

```bash
scripts/copilot-gate.sh
```

Passing QA verdicts must be evidence-bound with an `ARTIFACT:` marker such as
`test-run`, `file-check`, `diff-check`, `screenshot-check`, `a11y-check`, or
`design-fidelity-check`.

## Specialist Roster

Primary entrypoint:

- `$protocol`

Active software and product specialists:

- `$sd`: service design and end-to-end journey framing
- `$uxd`: interaction design, task flows, states, and accessibility flow
- `$uids`: visual design, hierarchy, tokens, and product-language presentation
- `$uid`: UI implementation, responsive behavior, styling, and accessibility attributes
- `$ta`: technical architecture, decomposition, tradeoffs, and task planning
- `$me`: implementation, bug fixes, refactors, and integration work
- `$qa`: reproduction, tests, verification, design fidelity, and verdicts
- `$ind`: physical-digital and connected-product design
- `$sec`: security review, trust boundaries, auth, secrets, and unsafe inputs
- `$doc`: durable documentation, setup guides, API docs, and onboarding material
- `$do`: CI, deployment, infrastructure, observability, and operational safety

Support skills:

- `$launcher`
- `protocol-router`
- `task-copilot`
- `specialist-agents`

Optional parity specialists live in `packs/business-creative/`:

- `kc`
- `cco`
- `cw`
- `cs`
- `cpa`

Activate optional packs per project:

```bash
scripts/activate-pack.py --project /path/to/project --pack business-creative
```

## Project Layout

```text
codex-copilot/
  AGENTS.md
  VERSION.json
  docs/
  parity/
  plugins/codex-copilot/
    .codex-plugin/plugin.json
    agent-catalog.json
    skills/
  packs/
  scripts/
  templates/
  tests/
```

## Documentation

Start here:

- [Documentation Index](./docs/README.md)
- [Getting Started](./docs/getting-started.md)
- [Install](./docs/install.md)
- [Usage Guide](./docs/usage.md)
- [Protocol](./docs/protocol.md)
- [Native Agents](./docs/native-agents.md)
- [Architecture](./docs/architecture.md)
- [Capabilities](./docs/capabilities.md)
- [Project Setup](./docs/setup-project.md)
- [Live Docs](./docs/live-docs.md)
- [Quality Gates](./docs/quality-gates.md)
- [Orchestration](./docs/orchestration.md)
- [Extensions And Packs](./docs/extensions.md)
- [Capability Packs](./docs/packs.md)
- [Parity Contract](./docs/parity.md)
- [Release Fitness](./docs/release-fitness.md)
- [Publishing Notes](./docs/publishing.md)

## Honest Boundaries

Codex Copilot does not recreate Claude slash commands, Claude named-agent syntax, or Claude lifecycle hooks one-for-one.

Instead:

- slash commands become Codex skills
- named agents become direct skill names and launcher mappings
- Claude runtime hooks become explicit task metadata, scripts, work products, and tests
- headless worker orchestration becomes user-approved delegation with stream validation

"Claude lifecycle hooks" means Claude runtime hooks such as SessionStart,
PreToolUse, and SubagentStop. It does not mean the design-led product creation
protocol; `$protocol` remains design-led.

That honesty is intentional. It keeps the framework reliable inside Codex instead of depending on runtime features this project cannot provide.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Security

See [SECURITY.md](./SECURITY.md).

## License

MIT. See [LICENSE](./LICENSE).
