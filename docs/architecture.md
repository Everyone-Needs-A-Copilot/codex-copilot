# Architecture

## Goal

Port the `claude-copilot` framework into Codex-native constructs without faking Claude-only features.

## Mapping

| Claude Copilot concept | Codex equivalent |
|------------------------|------------------|
| `CLAUDE.md` | `AGENTS.md` |
| `@agent-x` invocation | specialist playbook applied locally or via `spawn_agent` when explicitly authorized |
| slash commands | documented workflows and reusable skills |
| `.claude/skills/` | `cc` skill discovery bridge to plugin-delivered Codex skills |
| Memory Copilot / Skills Copilot MCP servers | `cc` CLI |
| Task Copilot via `tc` | unchanged |
| knowledge/extensions | future plugin or repo conventions |
| orchestration worktrees | future Codex workflow built on `spawn_agent` + git worktrees |

## Design Choices

### 1. Honest Port, Not Syntax Emulation

Codex does not expose a native named-agent registry like Claude's `@agent-qa`.

This port therefore uses:

- explicit specialist role definitions
- skill-driven operating procedures
- optional subagent spawning only when user-authorized

### 2. Keep `tc` as the System of Record

The most valuable non-model-specific part of the original framework is its task/work-product discipline. That remains unchanged.

### 3. Use `cc` For Memory And Skill Discovery

Memory and reusable skill discovery now live behind the Claude Copilot `cc` CLI. Codex Copilot projects link the shared plugin skills into `.claude/skills/codex-copilot` so `cc skill ...` can discover them, and keep durable memory entries under `.claude/memory/entries/`.

### 4. Installable as a Codex Plugin

The plugin bundle gives Codex a native entry point:

- `.codex-plugin/plugin.json`
- marketplace registration
- bundled skills

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

### Deliberately deferred

- automated orchestration scripts
- full extension-resolution system

Those can be added in later phases once the core Codex workflow is validated.
