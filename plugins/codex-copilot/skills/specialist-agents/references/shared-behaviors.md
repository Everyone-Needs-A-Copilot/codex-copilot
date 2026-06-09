# Shared Behaviors

Codex Copilot mirrors Claude Copilot's shared agent behaviors through Codex-native skills and repo instructions.

## Session Preamble

When the work is substantial or needs durable context:

1. Check task context with `tc task get <taskId> --json` when a task id exists.
2. Hydrate Copilot config when `cc` is available:

```bash
eval "$($HOME/.local/bin/cc env)"
```

3. Search memory for relevant decisions:

```bash
$HOME/.local/bin/cc memory search "<task topic>"
```

4. Check the working tree before edits:

```bash
git status --short
```

5. For third-party API planning or implementation, verify the installed package API with Live Docs:

```bash
$HOME/.local/bin/cc docs get <package> --topic <area> --json
```

If `cc docs` is unavailable, say so and inspect local package files or official docs before coding against that API.

## Skill Discovery

Codex skills are the primary path in Codex sessions. Use `cc skill search "<topic>"` or `cc skill get <name>` as a fallback when a reusable skill is not already visible in the session.

Optional parity specialists (`kc`, `cco`, `cw`, `cs`, `cpa`) live in dormant packs. Activate them with `scripts/activate-pack.py` when the project needs those capabilities; do not load them globally by default.

## Task Copilot Pattern

For substantial work, use `tc` as the execution record:

```bash
tc task get <taskId> --json
tc wp store --task <taskId> --type <type> --title "..." --content "..." --json
tc task update <taskId> --status completed --json
```

If no task exists, create a PRD and task rather than writing planning state into ad hoc markdown.

For three or more related `tc` operations, prefer a single `python3` block importing `tc.api` and print one compact result. For three or more related `cc` memory or skill operations, use a separate block importing `cc.api`. Do not mix `tc.api` and `cc.api` in one process.

## Specification Workflow

Domain agents (`sd`, `ind`, `uxd`, `uids`, `cco`, `cw`) should create `specification` work products and route to `ta` for task creation. They do not directly create implementation tasks unless the user explicitly asks for a lightweight, single-session result.

## Memory Store

After meaningful decisions or lessons, store durable memory when `cc` is configured:

```bash
$HOME/.local/bin/cc memory store --type decision "<decision and rationale>"
```

Use `decision`, `context`, `lesson`, `reference`, or `person` as appropriate.

## Return Format

Keep chat output compact. Store detailed analysis, specs, and verification records as work products when `tc` context exists.

## Quality Gates

- `me` is not the final gate when tests or verification are relevant.
- `qa` verifies implementation before closure.
- implementation tasks that require verification should carry `metadata.requiresQa=true`
- `qa` stores a `test` work product and a verdict; `scripts/copilot-gate.sh` checks this convention
- `sec` reviews security-sensitive changes before closure.
- `do` owns deployment planning before deploy or CI changes.
- Destructive actions require explicit current user approval.
