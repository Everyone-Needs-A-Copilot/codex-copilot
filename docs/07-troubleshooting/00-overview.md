# Troubleshooting

## `cc` Opens A Compiler

Use the Claude Copilot CLI by absolute path:

```bash
$HOME/.local/bin/cc --help
```

## Skills Are Not Discoverable

Run from a git repository and inspect the project skill bridge:

```bash
ls -ld .claude/skills/codex-copilot
$HOME/.local/bin/cc skill list --scope project
```

## Live Docs Is Unavailable

```bash
$HOME/.local/bin/cc docs sources
$HOME/.local/bin/cc memory check --json
```

If Live Docs remains unavailable, inspect local package files or official documentation before relying on a third-party API shape.

## `tc` Cannot Find A Database

Initialize task state in the target project:

```bash
tc init --json
```

## The QA Gate Command Is Missing

New project setup creates `scripts/copilot-gate.sh` as a relative link to the shared framework script. For an older project, rerun the safe update workflow or invoke the framework copy directly after confirming its location.

Do not create an unrelated replacement script in the target project; keep the shared gate authoritative.
