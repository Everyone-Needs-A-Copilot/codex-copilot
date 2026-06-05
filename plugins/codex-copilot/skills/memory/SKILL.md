---
name: memory
description: Use when you need the Codex Copilot equivalent of Claude Copilot /memory: inspect recent cc memory entries, known references, and task progress.
---

# Memory

Show memory and task state for transparency.

## Workflow

1. Run `cc memory list --limit 10` when `cc` is configured.
2. Run `cc config list --scope effective` to show relevant paths and `refs.*`.
3. Run `tc progress --json` when `tc` is initialized.
4. Present a compact dashboard.

## Output

- recent decisions
- recent context or lessons
- known references
- task progress

