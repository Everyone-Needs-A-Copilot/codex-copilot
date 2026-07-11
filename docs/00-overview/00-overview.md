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

Most specialist work happens in the main Codex session. Delegation is available only when the user explicitly asks for subagents or parallel work.

## Honest Boundaries

Codex Copilot does not recreate Claude slash commands, named-agent syntax, or lifecycle hooks one-for-one. It translates their useful intent into Codex skills, `AGENTS.md`, `tc` metadata, scripts, work products, and tests.

The framework owns no memory or task engine. It reuses the shared `cc` and `tc` CLIs and is degraded when they are unavailable.

## Start Here

1. Follow [Getting Started](../01-setup/03-getting-started.md).
2. Use the [Daily Workflow](../02-user-guides/01-daily-workflow.md).
3. Read the [Architecture](../04-architecture/00-overview.md) when extending the framework.
4. Check the [Capability Matrix](../05-reference/01-capability-matrix.md) for exact support boundaries.
