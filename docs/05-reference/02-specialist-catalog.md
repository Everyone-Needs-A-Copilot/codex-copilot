# Specialist Catalog

## What "native" means here

Codex does not currently expose custom first-class agent types beyond its built-in spawned agent roles.

The native building blocks available in Codex are:

- skills
- plugins
- `spawn_agent`
- built-in spawned agent types: `default`, `explorer`, `worker`

This project therefore defines each specialist as a native Codex skill and maps it to a real Codex subagent type when delegation is explicitly requested.

## Agent Catalog

Each specialist is a first-class skill in `plugins/codex-copilot/skills/`:

- `$protocol`
- `$sd`
- `$uxd`
- `$uids`
- `$uid`
- `$ta`
- `$me`
- `$qa`
- `$ind`
- `$sec`
- `$doc`
- `$do`
- `$launcher`

## Invocation model

### Local specialist mode

Invoke a specialist skill directly in the main Codex session:

```text
Use $protocol to route this task through the right workflow.
Use $ta to break this feature into tc-backed tasks.
Use $qa to reproduce this regression and define verification.
Use $ind to shape the hardware/software touchpoint before UX work.
```

### Delegated mode

If the user explicitly asks for subagents or parallel execution, use `$launcher` to map the requested specialist onto a real Codex spawned agent type:

- `explorer`: analysis-heavy specialists such as `ta`, `qa`, `sec`
- `worker`: implementation-heavy specialists such as `me`, `uid`, `do`
- `default`: mixed or design-oriented specialists such as `sd`, `uxd`, `uids`, `ind`, `doc`

## Why this is the correct boundary

This keeps the system genuinely native to Codex:

- specialist units are native Codex skills
- delegation uses native Codex subagents
- no fake named-agent syntax is required

## Machine-readable source

See [agent-catalog.json](../../plugins/codex-copilot/agent-catalog.json) and its
[schema](../../plugins/codex-copilot/agent-catalog.schema.json). The catalog is
the source of truth for the active roster, optional pack specialists, routing
edges, and design chain.
