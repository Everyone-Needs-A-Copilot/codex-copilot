# Architecture

## Goal

Port the `claude-copilot` framework into Codex-native constructs without faking Claude-only features.

## Mapping

| Claude Copilot concept | Codex equivalent |
|------------------------|------------------|
| `CLAUDE.md` | `AGENTS.md` |
| named-agent invocation | specialist playbook applied locally or via `spawn_agent` when explicitly authorized |
| slash commands | documented workflows and reusable skills |
| `.claude/skills/` | `cc` skill discovery bridge to plugin-delivered Codex skills |
| Memory Copilot / Skills Copilot MCP servers | `cc` CLI |
| Task Copilot via `tc` | unchanged |
| selected Claude hook intent | Codex-native plugin hooks using Codex payload/output contracts |
| knowledge/extensions | dormant capability packs plus project-local plugin activation |
| orchestration worktrees | user-approved `spawn_agent` delegation plus stream validation and explicit git worktree handling |

## Design Choices

### 1. Honest Port, Not Syntax Emulation

This framework does not depend on Claude's named-agent invocation syntax.

This port therefore uses:

- explicit specialist role definitions
- skill-driven operating procedures
- optional subagent spawning only when user-authorized

### 2. Keep `tc` as the System of Record

The most valuable non-model-specific part of the original framework is its task/work-product discipline. Live tasks, dependencies, assignments, work products, and QA status remain in `tc`.

Formal multi-phase initiative knowledge lives in `docs/40-initiatives/NN-slug/`. Initiative documents hold goals, phase designs, decisions, closure evidence, and retrospectives while linking back to authoritative `tc` execution state.

### 3. Use `cc` For Memory And Skill Discovery

Memory and reusable skill discovery now live behind the Claude Copilot `cc` CLI. Codex Copilot projects link the shared plugin skills into `.claude/skills/codex-copilot` so `cc skill ...` can discover them, and keep durable memory entries under `.claude/memory/entries/`. An opt-in organization plugin (see [Setup Project](../01-setup/02-setup-project.md#organization-plugin)) gets the same bridge at `.claude/skills/<org-plugin-name>`, alongside the base plugin's rather than instead of it.

### 4. Installable as a Codex Plugin

The plugin bundle gives Codex a native entry point:

- `.codex-plugin/plugin.json`
- marketplace registration
- bundled skills
- bundled routing, debugging, subagent-context and opt-in design-feedback hooks

### 5. Project Overlays Through Packs

The global plugin should stay focused on software creation. Domain capabilities live under `packs/<category>/` and stay dormant until a project activates them through a project-local plugin.

This gives Codex Copilot the same practical inheritance shape as Claude Copilot:

- shared global behavior for every project
- reusable dormant capability source
- project-specific activation and overrides

### 6. Design-Led Decision Instruments

Projects can define two local decision instruments:

- `SOUL.md` for product purpose, taste, anti-patterns, and whether product-facing work belongs in the product
- `docs/01-architecture/12-architecture-guiding-principles.md` for how accepted product direction should be built

`$protocol` reads these before substantial work when they apply. The setup script scaffolds both files by default so design judgment is not hidden in chat history.

### 7. Live Docs For API Correctness

Codex Copilot requires specialists to verify installed third-party package APIs through `cc docs` before planning or coding against them. This mirrors Claude Copilot's Live Docs feature while keeping the tool dependency explicit.

### 8. Native Hooks Plus An Explicit QA Gate

Codex Copilot ships native adapters for conditional prompt routing, per-command-shape
debug warnings and denial, subagent return context and opt-in design feedback.
Claude Code hook registration and payloads do not carry over. Shared tc 2.0.0
owns QA completion: it binds registered criteria and tested source identity to
the task/database and checks the recorded observations, artifacts and verdict.
Completion also rejects unfinished dependencies. `scripts/copilot-gate.sh`
inspects this authority; neither native feedback nor metadata grants approval.

This boundary does not change the design-led product protocol.

### 9. Optional Parity Packs

Claude's `kc`, `cco`, `cw`, `cs`, and `cpa` specialists are useful but not always appropriate for software projects. Codex Copilot ships them as the `business-creative` dormant pack, activated per project.

## Capability Status

### Implemented now

- Codex-native repo instructions
- plugin packaging
- protocol-first entrypoint
- native specialist skills
- machine-readable agent catalog
- routing skill
- `tc` workflow skill
- `cc` CLI bridge for memory and skills
- specialist playbooks
- dormant capability pack convention
- direct software specialist skill names
- design-led project decision-instrument scaffolding
- design-fidelity QA expectations
- adopted Claude 5.15.0 source baseline, requiring cc 2.13.0 / tc 2.0.0, with version and content freshness checks
- Codex-native plugin hooks for conditional routing, debug circuit breaking, subagent return context and opt-in edit feedback
- shared design guidance, task-bound review, pinned detection and rendered comparison
- optional skill selection with required-instruction retention and inspectable receipts
- Live Docs guidance
- QA gate inspection script
- optional business/creative specialist pack
- stream validation utility

### Deliberately deferred

- Claude hook behaviors that do not yet have a tested Codex-native equivalent

### Non-goals

- hidden or autonomous background worker loops
- delegation without explicit user approval
- a second task or memory engine inside this repository

These boundaries are intentional. Hidden workers are not a roadmap item; approved delegation remains explicit and scope-validated.

## System Context

```mermaid
flowchart LR
    U[Developer] --> C[Codex]
    C --> A[AGENTS.md]
    C --> P[Codex Copilot plugin and skills]
    P --> TC[tc task state and work products]
    P --> CC[cc memory, config, skills, Live Docs, design]
    P --> S[Codex-native hooks, explicit scripts, and tests]
    P --> I[docs/40-initiatives]
    I -. links durable initiative context .-> TC
    C -. user-approved delegation only .-> SA[spawn_agent]
```

## Ownership Boundaries

| Surface | Owner |
| --- | --- |
| specialist behavior and routing | Codex Copilot plugin skills and catalog |
| live execution state, acceptance contracts and QA completion | `tc` |
| memory, config, skill selection, Live Docs and shared design operations | `cc` |
| initiative briefs, phases, decisions, and retrospectives | `docs/40-initiatives/` in the consuming project |
| domain-specific optional skills | dormant packs activated by a project |
| Codex-native routing/debug/subagent hooks and optional design-feedback adapter | Codex Copilot plugin; shared `cc` executes design feedback |
| Claude hook registration and payloads | Claude Code; never consumed by Codex |
