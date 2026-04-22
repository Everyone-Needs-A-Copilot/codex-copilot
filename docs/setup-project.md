# Setup Project

Use the shared `codex-copilot` framework in a selected repo without copying the framework into that repo.

## What the installer does

The bootstrap script:

1. creates a project-local `plugins/codex-copilot` symlink to the shared framework
2. writes `.agents/plugins/marketplace.json`
3. writes a thin project `AGENTS.md`
4. writes `.codex-copilot.json` with install metadata
5. optionally runs `tc init --json`

This keeps the framework centralized while giving each project a stable local plugin path.

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

## Force overwrite

If the target project already has wiring you want to replace:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --force
```

## Result

The target repo will contain:

- `AGENTS.md`
- `.agents/plugins/marketplace.json`
- `.codex-copilot.json`
- `plugins/codex-copilot` -> relative symlink to the shared framework plugin

## First prompt in Codex

After opening the target project in Codex, start with:

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

## Notes

- The installer does not copy the framework repo.
- Updating the shared `codex-copilot` repo updates all linked projects automatically.
- The installer creates a relative plugin symlink, so generated project files do not embed a machine-specific absolute framework path.
- If a project already has a hand-written `AGENTS.md`, review before using `--force`.
