# Setup Project

Install the Codex Copilot project surface into a selected repository so the setup travels with the project.

## What the installer does

The bootstrap script:

1. copies the small project plugin into `plugins/codex-copilot`
2. writes `.agents/plugins/marketplace.json`
3. writes `.claude/cc/config.json` for the new `cc` CLI
4. creates `.claude/memory/entries/` and ignores the local memory index
5. links `.claude/skills/codex-copilot` to the copied project plugin's skills
6. writes a thin project `AGENTS.md`
7. copies `scripts/copilot-gate.sh` into the project
8. scaffolds `docs/40-initiatives/` with an index and reusable initiative structure
9. writes design-led decision instruments: `SOUL.md` and `docs/01-architecture/12-architecture-guiding-principles.md`
10. writes `.codex-copilot.json` with install metadata
11. optionally runs `tc init --json`

This keeps the project setup portable. Control Tower can refresh the framework-owned copy later without depending on a machine-specific checkout path.

Use a git repository as the target project when you want `cc skill list --scope project` to discover project skills immediately.

After setup, verify Live Docs and task tooling when available:

```bash
cc docs sources
cc memory check --json
tc progress --json
```

## Command

Run:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

Run the script from the `codex-copilot` repo root, or invoke it via the path to your local `codex-copilot` clone.

## Optional project rules

If you want to pre-fill project-specific rules, pass a file:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js" \
  --rules-file /absolute/path/to/project-rules.md
```

## Decision instruments

By default, setup creates:

- `SOUL.md` for product purpose, taste constraints, anti-patterns, and product-facing go/no-go decisions
- `docs/01-architecture/12-architecture-guiding-principles.md` for durable technical decisions after the product direction is accepted

`$protocol` reads these files before substantial work when they apply.

To skip these files for a lightweight install:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --no-decision-instruments
```

## Existing Project Wiring

The installer does not override an existing `AGENTS.md`. If a project already has Codex Copilot wiring (a plugin link, skill link, or QA-gate link already present), running the installer again delegates to `scripts/update-project.sh` and repairs those paths in place -- content-compared against the framework source (sha256, not the declared version), never a wholesale replace -- instead of refusing.

`--force` is accepted for compatibility with older scripts, but it changes nothing: there is no longer a refusal for it to bypass.

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --force
```

## Updating an Existing Install

To refresh an existing install directly, without first-install scaffolding, run the updater on its own:

```bash
./scripts/update-project.sh --project /absolute/path/to/project
```

It only ever touches the 62 framework-owned paths (61 files under `plugins/codex-copilot/` plus `scripts/copilot-gate.sh`). A file is skipped -- never overwritten -- if it is marked `ownership: project`, either via `owner: project` YAML frontmatter in the file itself or a `copilot.lock.json` entry for that path with `"ownership": "project"`. `AGENTS.md`, `SOUL.md`, `docs/40-initiatives/`, and `.agents/plugins/marketplace.json` are never touched by the updater; `.codex-copilot.json` only has its framework-tracking fields merged in (`projectName`/`pluginPath` are preserved). Running it twice in a row makes no further changes on the second run. Add `--dry-run` to preview without writing.

## Result

The target repo will contain:

- `AGENTS.md`
- `SOUL.md`
- `.agents/plugins/marketplace.json`
- `.codex-copilot.json`
- `.claude/cc/config.json`
- `.claude/memory/entries/`
- `.claude/skills/codex-copilot` -> relative symlink to `plugins/codex-copilot/skills` inside the same project
- `scripts/copilot-gate.sh` -> project-local executable copy
- `docs/40-initiatives/README.md`
- `docs/40-initiatives/_template/`
- `docs/01-architecture/12-architecture-guiding-principles.md`
- `plugins/codex-copilot` -> portable project-local plugin copy

## First prompt in Codex

After opening the target project in Codex, start with:

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

## Notes

- The installer copies only the project plugin, not the entire framework repository.
- The skills bridge stays relative entirely within the project, so a clone does not depend on the original machine's directory layout.
- Framework refresh is explicit and collision-safe; changing a machine checkout never silently changes a project.
- The installer prefers `$HOME/.local/bin/cc` because bare `cc` may resolve to the system C compiler.
- If a project already has a hand-written `AGENTS.md`, review it manually before changing it.
- Existing `SOUL.md` and architecture-principles files are preserved.
- Existing `docs/40-initiatives/` is preserved as-is once it exists (only scaffolded the first time).
- An existing QA-gate path (`scripts/copilot-gate.sh`) is repaired in place by `update-project.sh`, not silently replaced and not refused.
- Optional packs can be activated later with `scripts/activate-pack.py`.
