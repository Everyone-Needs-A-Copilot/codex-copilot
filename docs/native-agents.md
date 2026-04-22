# Native Agents

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
- `$agent-ta`
- `$agent-me`
- `$agent-qa`
- `$agent-sec`
- `$agent-doc`
- `$agent-do`
- `$agent-sd`
- `$agent-uxd`
- `$agent-uids`
- `$agent-uid`
- `$agent-cw`
- `$agent-launcher`

## Invocation model

### Local specialist mode

Invoke a specialist skill directly in the main Codex session:

```text
Use $protocol to route this task through the right workflow.
Use $agent-ta to break this feature into tc-backed tasks.
Use $agent-qa to reproduce this regression and define verification.
```

### Delegated mode

If the user explicitly asks for subagents or parallel execution, use `$agent-launcher` to map the requested specialist onto a real Codex spawned agent type:

- `explorer`: analysis-heavy specialists such as `ta`, `qa`, `sec`
- `worker`: implementation-heavy specialists such as `me`, `uid`, `do`
- `default`: mixed or design-oriented specialists such as `sd`, `uxd`, `uids`, `doc`, `cw`

## Why this is the correct boundary

This keeps the system genuinely native to Codex:

- specialist units are native Codex skills
- delegation uses native Codex subagents
- no fake `@agent-name` syntax is required

## Machine-readable source

See [agent-catalog.json](../plugins/codex-copilot/agent-catalog.json).
