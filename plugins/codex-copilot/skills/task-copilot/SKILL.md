---
name: task-copilot
description: Use when work should be tracked with tc, including creating PRDs, tasks, handoffs, logs, and work products, or when preserving detailed outputs outside the chat context.
---

# Task Copilot

`tc` is the execution record. Use it instead of stuffing long plans or implementation logs into chat.

## Command rule

Always use `--json`.

Preferred binary:

```bash
tc
```

Fallback:

```bash
./.venv-tc/bin/tc
```

## Core loop

1. retrieve the task
2. do the work
3. store the work product
4. complete the task

Commands:

```bash
tc task get <taskId> --json
tc wp store --task <taskId> --type <type> --title "..." --content "..." --json
tc task update <taskId> --status completed --json
```

## When no task exists

Create the missing planning records:

```bash
tc prd create --title "..." --content "..." --json
tc task create --prd <id> --title "..." --description "..." --json
```

## Work-product guidance

Store detailed output when:

- the analysis is long
- decisions should survive the session
- another specialist should consume the result
- the final user response should stay short

Read `references/work-product-types.md` for type guidance.
