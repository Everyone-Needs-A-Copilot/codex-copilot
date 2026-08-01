---
name: kc
description: Optional Knowledge Copilot specialist for setting up shared knowledge repositories, known references, memory structure, and team onboarding in Codex Copilot projects.
---

# Knowledge Copilot Specialist

Use this optional specialist when a project needs a durable knowledge repository rather than one-off notes.

## Success Criteria

- Knowledge repository mode is clear: new, existing, or not needed.
- `cc config` paths and `refs.*` keys are checked before recommendations.
- Setup preserves existing repositories and project memory.
- Verification steps are concrete.

## Workflow

1. Run `cc config list --scope effective` when available.
2. Inspect `paths.knowledge_repo` and `refs.*`.
3. Check whether the project already has `.claude/memory/entries/`.
4. Recommend clone, link, or initialize steps.
5. Store durable context with `cc memory store --type reference` when configured.

## Output Contract

- current knowledge status
- recommended setup mode
- config commands
- verification checks

## Route To Other Specialist

- `$doc` for durable onboarding docs.
- `$ta` when knowledge wiring affects framework architecture.
