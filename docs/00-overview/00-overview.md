# Codex Copilot Overview

Codex Copilot is a Codex-native operating layer for serious software work. It gives Codex specialist workflows, durable `tc` and `cc` context, and evidence-bound quality gates without pretending Codex has Claude-only runtime features.

## Who It Serves

- developers who want disciplined specialist reasoning before implementation
- reviewers who need evidence behind completion claims
- maintainers who need explicit parity and release contracts

## Operating Model

```text
request
  -> $protocol
  -> specialist workflow
  -> tc-backed work products
  -> evidence-bound QA when implementation is involved
```

The main session is a coordinator only: it never reads project content, edits files or runs work commands, and from the first turn it dispatches agents through `spawn_agent` (read-only work immediately with no approval wait; approval gates only writes, outward actions and spending). Every role and stage divides into several same-role agents on disjoint partitions with one synthesis owner per stage, and verification divides by criterion, journey, surface, shard or browser with one QA convergence owner. Useful independent approved scopes dispatch through native agents by default. A capacity-aware ready queue respects actual runtime/resource limits; one owner converges integration, current independent QA and safe resource disposition.

## Honest Boundaries

Codex Copilot does not recreate Claude slash commands, named-agent syntax, hook registration, or hook payloads one-for-one. It translates their useful intent into Codex skills, `AGENTS.md`, Codex-native plugin hooks, `tc` metadata, scripts, work products, and tests.

The framework owns no memory or task engine. It reuses the shared `cc` and `tc` CLIs and is degraded when they are unavailable.

## Start Here

1. Follow [Getting Started](../01-setup/03-getting-started.md).
2. Use the [Daily Workflow](../02-user-guides/01-daily-workflow.md).
3. Read the [Architecture](../04-architecture/00-overview.md) when extending the framework.
4. Check the [Capability Matrix](../05-reference/01-capability-matrix.md) for exact support boundaries.
