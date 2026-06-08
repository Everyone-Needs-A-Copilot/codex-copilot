# Getting Started

## Recommended Flow

1. Clone `codex-copilot`.
2. Use `scripts/setup-project.sh` to wire a target repo to the framework.
3. Open the target repo in Codex.
4. Start with `$protocol`.

## What Gets Added to a Project

The bootstrap script writes:

- `AGENTS.md`
- `.agents/plugins/marketplace.json`
- `.codex-copilot.json`
- `.claude/cc/config.json`
- `.claude/memory/entries/`
- `.claude/skills/codex-copilot` as a relative symlink to the shared framework skills
- `plugins/codex-copilot` as a relative symlink to the shared framework plugin

This keeps the framework centralized while giving each project a stable local plugin path.

Use a git repository as the target project when you want `cc skill list --scope project` to discover project skills immediately.

## First Prompt

Use:

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

## Recommended Validation

1. Create or identify a `tc` task for a meaningful change.
2. Ask Codex to use `$protocol`.
3. Confirm the request is routed through the correct specialist workflow.
4. Confirm the work product or task state is recorded with `tc` for substantial work.
5. Run `cc skill list --scope project` and confirm the direct software specialist skills plus command-equivalent support skills are discoverable.
