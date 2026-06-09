# Getting Started

This guide walks you from a clean project to a working Codex Copilot workflow.

## What You Are Installing

Codex Copilot adds a specialist operating layer to a project. After setup, the target project gets:

- `AGENTS.md` with project-specific Codex instructions
- local plugin registration under `.agents/plugins/`
- a symlink to the shared `plugins/codex-copilot` plugin
- a `cc` config file at `.claude/cc/config.json`
- project memory entries under `.claude/memory/entries/`
- a skill discovery bridge under `.claude/skills/codex-copilot`
- optional decision instruments for product and architecture judgment
- optional `tc` initialization

The framework stays centralized in the shared `codex-copilot` repo. Linked projects point back to it.

## Before You Start

Verify the shared tools:

```bash
tc --help
$HOME/.local/bin/cc --help
$HOME/.local/bin/cc docs sources
```

Then verify the framework itself:

```bash
scripts/smoke-test.sh
```

## Step 1: Wire A Project

From the `codex-copilot` repo:

```bash
./scripts/setup-project.sh \
  --project /absolute/path/to/project \
  --name "my-project" \
  --description "Short project description" \
  --stack "React / Next.js"
```

Use a git repository as the target project when you want `cc skill list --scope project` to discover project skills immediately.

The installer is intentionally conservative. It refuses to overwrite existing `AGENTS.md`, plugin links, or skill links.

## Step 2: Open The Project In Codex

Start with:

```text
Read AGENTS.md and use $protocol to route this task through the right codex-copilot specialists.
```

That tells Codex to use the project instructions and route the work before acting.

## Step 3: Run A Small Workflow

Try a low-risk task:

```text
Use $protocol to review this repo's setup and create a short tc-backed verification note.
```

For substantial work, Codex should:

1. classify the request
2. choose a specialist workflow
3. create or use `tc` task context
4. store important output as a work product
5. route implementation through QA when verification matters

## Step 4: Validate Discovery

In the target project:

```bash
cc skill list --scope project
tc progress --json
cc docs sources
```

Expected result:

- `cc skill list` can see Codex Copilot skills through `.claude/skills/codex-copilot`
- `tc progress` can find or initialize task state
- `cc docs sources` reports Live Docs availability

## Step 5: Use Quality Gates

For implementation work that needs verification:

1. mark the task metadata with `requiresQa`
2. store an implementation work product
3. route to `$qa`
4. store a `test` work product with a verdict
5. run the gate when needed

```bash
scripts/copilot-gate.sh
```

## What To Do Next

- Read [Usage Guide](./usage.md) for daily workflows.
- Read [Protocol](./protocol.md) for routing behavior.
- Read [Native Agents](./native-agents.md) for specialist roles.
- Read [Live Docs](./live-docs.md) before API-heavy work.
- Read [Quality Gates](./quality-gates.md) before shipping implementation.
