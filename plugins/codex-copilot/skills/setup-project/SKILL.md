---
name: setup-project
description: Use when you need the Codex Copilot equivalent of Claude Copilot /setup-project: wire a target repository to the shared Codex Copilot framework.
---

# Setup Project

Wire a project to Codex Copilot.

## Workflow

1. Use `scripts/setup-project.sh --project <path>` from the framework repo.
2. Confirm whether existing `AGENTS.md`, plugin links, or skill links would be replaced.
3. Treat `--force` as compatibility-only; the installer still refuses replacement of existing project wiring.
4. Verify generated `AGENTS.md`, `.agents/plugins/marketplace.json`, `.claude/cc/config.json`, memory dirs, and plugin links.
5. Run `cc skill list`, `cc docs sources`, `cc memory check --json`, and `tc progress --json` from the target project when available.

## Output

- generated files
- plugin and skill link targets
- verification results
