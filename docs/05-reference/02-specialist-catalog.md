# Specialist Catalog

## What "native" means here

This framework exposes specialists as Codex skills. Delegation uses only the
agent types actually available in the current session; it does not assume a
Claude-style named-agent registry.

The native building blocks available in Codex are:

- skills
- plugins
- `spawn_agent`
- catalog launch mappings to `default`, `explorer` and `worker`, subject to the current session tool contract

This project therefore defines each specialist as a native Codex skill and maps it to a real native agent for useful independent approved scopes by default.

## Agent Catalog

Each specialist is a first-class skill in `skills/`:

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

### Direct skill invocation

A skill can be named directly, but the main session only coordinates: the named specialist runs as dispatched agents, not in the main session. Example requests:

```text
Use $protocol to route this task through the right workflow.
Use $ta to break this feature into tc-backed tasks.
Use $qa to reproduce this regression and define verification.
Use $ind to shape the hardware/software touchpoint before UX work.
```

### Delegated mode

For every role, use `$launcher` by default to map each specialist onto a real native agent, using these role hints where supported:

- `explorer`: analysis-heavy specialists such as `ta`, `qa`, `sec`
- `worker`: implementation-heavy specialists such as `me`, `uid`, `do`
- `default`: mixed or design-oriented specialists such as `sd`, `uxd`, `uids`, `ind`, `doc`

## Why this is the correct boundary

This keeps the system genuinely native to Codex:

- specialist units are native Codex skills
- delegation uses native Codex subagents
- no fake named-agent syntax is required

## Machine-readable source

See [agent-catalog.json](../../agent-catalog.json) and its
[schema](../../agent-catalog.schema.json). The catalog is
the source of truth for the active roster, optional pack specialists, routing
edges, and design chain.
