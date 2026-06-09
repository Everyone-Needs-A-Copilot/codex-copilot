# Orchestration And Worktrees

Codex Copilot supports approval-based parallel work. It does not silently auto-spawn workers.

## Stream Metadata

Each stream should declare:

```json
{
  "streamId": "Stream-A",
  "streamName": "Foundation",
  "files": ["src/auth.ts"],
  "streamDependencies": [],
  "streamPaths": ["src/auth/**"],
  "streamTokenBudget": 2500
}
```

Required fields:

- `streamId`
- `files`
- `streamDependencies`

## Validate Streams

Before parallel work:

```bash
scripts/orchestrate-validate.py stream-plan.json
```

The validator checks required fields, duplicate stream ids, unknown dependencies, dependency cycles, and overlapping file ownership.

## Worktree Safety

Use git worktrees only after the user approves the branch and merge plan.

Recommended lifecycle:

1. validate stream metadata
2. create one worktree per approved stream
3. run stream work in disjoint scopes
4. route each stream through QA
5. merge only after approval
6. clean up only after merge status is clear

## Spawn-Agent Boundary

Use `spawn_agent` only when the user explicitly asks for delegation or parallel execution. Each launch prompt should include the specialist role, task id, owned paths, forbidden paths, and required work product.
