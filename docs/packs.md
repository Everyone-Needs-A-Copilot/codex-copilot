# Capability Packs

Capability packs are dormant collections of Codex-native skills stored in the shared `codex-copilot` repo but not loaded globally.

Use packs for reusable domain capabilities that should not appear in every project.

## Layout

```text
packs/
  writing-legal/
    skills/
      pipeline/
        SKILL.md
      legal-gc/
        SKILL.md
```

The active global plugin remains `plugins/codex-copilot/skills/`. Anything under `packs/` is inactive until a project exposes it.

## Activation Pattern

To activate a pack in a project:

1. Create a project-local plugin under `plugins/<project-plugin>/`.
2. Symlink selected pack skill directories into `plugins/<project-plugin>/skills/`.
3. Register that plugin in `.agents/plugins/marketplace.json`.
4. Optionally link `.claude/skills/<project-plugin>` to the project plugin skills so `cc skill ...` can discover them.

This gives each project an explicit override layer while preserving one reusable source for the pack.

## Current Packs

| Pack | Purpose | Active Globally |
| ---- | ------- | --------------- |
| `writing-legal` | Creative writing, proposal/SOW copy, contract review, IP, privacy, employment, government contracts, and AI governance | No |

## Naming

Name packs by capability, not by project. Prefer category names such as `writing-legal`, `research`, `sales`, or `operations`.
