# codex-copilot

Codex Copilot is a Codex-native instruction layer that gives Codex a disciplined specialist workflow instead of a single undifferentiated assistant loop.

It ports the core operating model from `claude-copilot` into primitives Codex can actually use today:

- `AGENTS.md` for repo-level operating rules
- native skills for protocol and specialist playbooks
- command-equivalent skills for Claude Copilot workflows such as continue, pause, map, memory, extensions, orchestrate, setup, and update
- optional delegation through `spawn_agent` when the user explicitly asks for subagents
- `tc` as the durable record for PRDs, tasks, and work products

## What You Get

| Capability | What It Does |
| ---------- | ------------ |
| Protocol-first routing | Routes work before coding so requests follow the right workflow |
| 16 specialist playbooks | Mirrors Claude Copilot's `cco`, `cpa`, `cs`, `cw`, `do`, `doc`, `ind`, `kc`, `me`, `qa`, `sd`, `sec`, `ta`, `uid`, `uids`, and `uxd` roster |
| Codex-native command layer | Mirrors Claude command workflows as native skills instead of slash-command syntax |
| Task discipline | Uses `tc` for task state, work products, and substantial execution records |
| Reusable project bootstrap | Wires any project to the shared framework without copying the framework repo |
| Honest delegation boundary | Uses native Codex subagents only when the user explicitly wants delegated or parallel work |

## Why This Exists

Generic AI coding sessions tend to skip straight from an ambiguous request to code. That works for small edits, but it breaks down on defects, non-trivial features, user-facing flows, security-sensitive work, and multi-step implementation.

Codex Copilot adds an operating model around Codex so it can:

- classify the task before acting
- apply the right specialist lens at the right stage
- keep substantial work grounded in `tc`
- stay native to Codex instead of pretending Claude features exist

## How It Works

```text
You
  |
  v
$protocol
  |
  +--> defect              -> qa -> me -> qa
  +--> technical           -> ta -> me -> qa
  +--> infrastructure      -> do -> me -> qa
  +--> experience          -> sd -> uxd -> uids -> uid -> ta -> me -> qa
  +--> ui polish           -> uids -> uid -> qa
  +--> security-sensitive  -> ta -> sec -> me -> qa
  +--> knowledge           -> kc
  +--> creative branch     -> cco -> cw
  +--> business advisory   -> cs or cpa
  |
  v
tc-backed execution for substantial work
```

When the user explicitly asks for delegation or parallel work, Codex Copilot maps those specialist roles onto Codex’s built-in spawned agent types.

## Quick Start

### 1. Clone the framework

```bash
git clone https://github.com/Everyone-Needs-A-Copilot/codex-copilot.git
cd codex-copilot
```

### 2. Wire a project to the framework

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

### 3. Open the target project in Codex

Start with:

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

## Included Skills

Primary entrypoint:

- `$protocol`

Specialist skills:

- `$agent-launcher`
- `$agent-ta`
- `$agent-me`
- `$agent-qa`
- `$agent-sec`
- `$agent-doc`
- `$agent-do`
- `$agent-sd`
- `$agent-ind`
- `$agent-uxd`
- `$agent-uids`
- `$agent-uid`
- `$agent-cw`
- `$agent-cco`
- `$agent-kc`
- `$agent-cs`
- `$agent-cpa`

Support skills:

- `protocol-router`
- `task-copilot`
- `specialist-agents`
- `continue`
- `pause`
- `map`
- `memory`
- `extensions`
- `orchestrate`
- `update-project`
- `update-copilot`
- `knowledge-copilot`
- `config`
- `reflect`
- `skills-approve`
- `setup-copilot`
- `setup-project`

## Repo Layout

- `AGENTS.md` - operating instructions for this repo
- `plugins/codex-copilot/` - installable plugin bundle and skills
- `scripts/setup-project.sh` - project bootstrap installer
- `templates/AGENTS.project.template.md` - generated project instructions
- `docs/` - public documentation

## Documentation

- [Install Guide](./docs/install.md)
- [Project Setup Guide](./docs/setup-project.md)
- [Protocol Guide](./docs/protocol.md)
- [Native Agents](./docs/native-agents.md)
- [Architecture](./docs/architecture.md)
- [Getting Started](./docs/getting-started.md)
- [Usage Guide](./docs/usage.md)
- [Capability Matrix](./docs/capabilities.md)
- [Publishing Notes](./docs/publishing.md)

## Mirror Boundary

This repo mirrors Claude Copilot through Codex-native primitives. See the [Capability Matrix](./docs/capabilities.md) for the exact status of each mirrored feature.

- Claude slash commands become Codex skills.
- Claude `@agent-*` invocations become local specialist skills or explicit `spawn_agent` delegation.
- Claude hooks become documented guardrails and tests where Codex has no hook equivalent.
- Claude auto-spawn orchestration becomes explicit, user-approved Codex delegation.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Security

See [SECURITY.md](./SECURITY.md).

## License

MIT. See [LICENSE](./LICENSE).
