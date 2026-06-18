# Codex Copilot Documentation

Codex Copilot is a Codex-native specialist workflow framework. It helps Codex route work, apply expert playbooks, preserve durable context, verify implementation, and stay honest about Codex runtime boundaries.

This documentation is organized by the job you are trying to do.

## New To Codex Copilot

Read these first:

1. [Getting Started](./getting-started.md)
2. [Install](./install.md)
3. [Usage Guide](./usage.md)
4. [Protocol](./protocol.md)

You will learn what the framework is, how to wire it into a project, and how to start work with `$protocol`.

## Understanding The Framework

Use these when you want the operating model:

- [Architecture](./architecture.md): how Codex Copilot maps Claude Copilot ideas into Codex-native primitives
- [Capabilities](./capabilities.md): what is implemented, substituted, limited, or intentionally deferred
- [Native Agents](./native-agents.md): how specialist skills work locally and with explicit delegation
- [Parity Contract](./parity.md): the Claude Copilot baseline this project mirrors

## Running Work

Use these during day-to-day project work:

- [Protocol](./protocol.md): routing new work
- [Usage Guide](./usage.md): common workflows and examples
- [Live Docs](./live-docs.md): verifying installed third-party APIs before coding
- [Quality Gates](./quality-gates.md): implementation verification through `tc` metadata and QA work products
- [Orchestration](./orchestration.md): stream planning, file ownership, and approved parallel work

## Setting Up Projects And Capabilities

Use these when installing or extending the framework:

- [Project Setup](./setup-project.md): generated files and safe setup behavior
- [Extensions And Packs](./extensions.md): how optional capabilities are activated
- [Capability Packs](./packs.md): included dormant packs and activation pattern

## Maintaining The Framework

Use these when publishing, updating, or verifying releases:

- [Release Fitness](./release-fitness.md)
- [Publishing Notes](./publishing.md)

## Core Concepts

| Concept | Meaning |
| --- | --- |
| `$protocol` | Primary entrypoint that classifies work and selects the specialist workflow. |
| Specialist skill | A Codex skill that applies a focused role such as `$ta`, `$me`, `$qa`, `$sd`, or `$do`. |
| `tc` | Task Copilot CLI for PRDs, tasks, streams, handoffs, and work products. |
| `cc` | Claude Copilot CLI for memory, skill discovery, config, env hydration, known references, and Live Docs. |
| Live Docs | `cc docs` lookup that verifies installed package APIs before planning or coding. |
| QA gate | Explicit Codex substitute for Claude runtime hooks, using `tc` metadata, artifact-bound QA work products, verdict tokens, and `scripts/copilot-gate.sh`. |
| Pack | Dormant set of optional skills that a project can activate without making the global plugin noisy. |

## The Main Workflow

```text
User request
  |
  v
$protocol
  |
  +--> choose specialist sequence
  +--> create or use tc task context
  +--> store durable work products
  +--> verify through qa when implementation is involved
  |
  v
clear summary plus durable task record
```

## Benefits

- less ambiguous work intake
- better architecture and UX sequencing
- fewer unverified implementation changes
- lower risk from stale third-party API knowledge
- more durable planning and handoff records
- safer explicit parallelization
- project-level customization without global clutter
