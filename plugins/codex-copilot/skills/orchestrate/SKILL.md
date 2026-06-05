---
name: orchestrate
description: Use when you need the Codex Copilot equivalent of Claude Copilot /orchestrate: plan stream-based work, validate dependencies, and coordinate explicit user-approved Codex subagent execution.
---

# Orchestrate

Coordinate parallel work in a Codex-native way.

## Boundary

Codex Copilot does not auto-spawn workers unless the user explicitly asks for delegation or parallel execution.

## Workflow

1. Use `ta` to create a PRD, task breakdown, streams, dependencies, and file ownership.
2. Validate stream dependencies and file overlap before any parallel work begins.
3. Use git worktrees only after confirming the branch/worktree plan with the user.
4. Spawn Codex subagents only when explicitly requested.
5. Keep write scopes disjoint and route each implementation stream through `qa`.
6. Treat merge, cleanup, and removal operations as separate actions requiring explicit current approval when destructive.

## Output

- stream plan
- dependency graph
- file ownership map
- launch instructions or local execution plan

