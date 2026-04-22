# Install

## Local Repo Use

Open the repo in Codex and let Codex read:

- `AGENTS.md`
- `plugins/codex-copilot/skills/`

The repo is already structured so the instructions are local and versioned.

## Local Plugin Registration

This repo includes a local marketplace entry:

- `.agents/plugins/marketplace.json`

The plugin lives at:

- `plugins/codex-copilot`

## Project Bootstrap

To wire another project to this shared framework, use:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

Run that command from the `codex-copilot` repo root, or replace it with the path to your local clone.

Full details:

- [setup-project.md](./setup-project.md)

## Task Copilot Requirement

This framework expects `tc` to be available.

Use:

```bash
tc --help
```

If `tc` is not installed globally, use the repo-local fallback pattern:

```bash
./.venv-tc/bin/tc --help
```

## Recommended First Prompt In Codex

Use a prompt like:

```text
Read AGENTS.md and the codex-copilot skills, then use $protocol to route this task through the right workflow with tc-backed task tracking.
```

## Suggested Validation

1. Create a PRD with `tc prd create`
2. Create a task with `tc task create`
3. Ask Codex to route the work using the protocol skill
4. Have Codex store a work product with `tc wp store`

That verifies the core framework loop end to end.
