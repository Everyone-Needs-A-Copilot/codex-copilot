# Install

Codex Copilot can be used directly in this framework repo or linked into other projects.

## Requirements

| Requirement | Why |
| --- | --- |
| Codex | Reads `AGENTS.md`, plugin skills, and project instructions. |
| `tc` | Stores PRDs, tasks, streams, handoffs, and work products. |
| `cc` | Provides memory, memory drift checks, skill discovery, config, env hydration, known references, and Live Docs. |
| Python 3 | Runs setup and verification scripts. |
| Git | Supports project detection, safe updates, and optional worktree workflows. |

Check the tools:

```bash
tc --help
$HOME/.local/bin/cc --help
$HOME/.local/bin/cc docs sources
$HOME/.local/bin/cc memory check --json
python3 --version
git --version
```

The command name `cc` can also mean a system C compiler, so framework instructions prefer `$HOME/.local/bin/cc`.

## Framework Verification

From the `codex-copilot` repo:

```bash
scripts/check-versions.sh
scripts/smoke-test.sh
```

These verify:

- version alignment
- plugin manifest alignment
- parity manifest alignment
- pack manifest alignment
- test suite behavior
- stream validation behavior
- artifact-bound QA gate behavior

## Using The Framework Repo Directly

Open this repo in Codex. Codex will read:

- `AGENTS.md`
- `plugins/codex-copilot/skills/`

Start with:

```text
Use $protocol to route this task through the right workflow.
```

## Linking A Target Project

Run:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

The setup script creates relative symlinks so generated project files do not embed machine-specific framework paths.

## What Gets Installed In A Project

- `AGENTS.md`
- `.agents/plugins/marketplace.json`
- `.codex-copilot.json`
- `.claude/cc/config.json`
- `.claude/memory/entries/`
- `.claude/skills/codex-copilot`
- `plugins/codex-copilot`
- `SOUL.md` unless skipped
- `docs/01-architecture/12-architecture-guiding-principles.md` unless skipped
- `.copilot/tasks.db` when `tc init` succeeds

## Safe Update Behavior

The setup script refuses to replace existing project wiring. For an already configured project, update only the exact framework block that needs changing and preserve project-specific rules.

Optional packs are activated separately:

```bash
scripts/activate-pack.py --project /absolute/path/to/project --pack business-creative
```

## Troubleshooting

### `cc` opens a compiler

Use the absolute shim:

```bash
$HOME/.local/bin/cc --help
```

### Skills are not discoverable

Run from a git repository and check:

```bash
ls -ld .claude/skills/codex-copilot
cc skill list --scope project
```

### Live Docs is unavailable

Check:

```bash
cc docs sources
cc memory check --json
```

If unavailable, inspect local package files or official docs before coding against third-party APIs.

### `tc` cannot find a database

Initialize in the target project:

```bash
tc init --json
```
