# Initiatives

> Mode: Reference  
> Audience: maintainers and agents documenting, planning, and validating multi-phase initiatives

## What Is An Initiative

An initiative is a multi-phase body of work with a defined goal, explicit decisions, and evidence-bound exit criteria. It is larger than a task or a single feature spec and is expected to survive multiple sessions.

Formal initiative documentation lives only in `docs/40-initiatives/NN-slug/`.

## Current Initiatives

| Folder | Initiative | Goal | Status | `tc` context |
| --- | --- | --- | --- | --- |

## Directory Contract

```text
docs/40-initiatives/
  README.md
  _template/
  NN-slug/
    README.md
    # supporting files only when justified by active work
```

## Markdown And `tc` Ownership

Initiative Markdown records durable intent, rationale, phase design, decisions, validation evidence, and outcomes. `tc` remains authoritative for live task state, assignments, dependencies, work products, and QA status.

Do not maintain a second task board in an initiative README. Summarize current status and link to the corresponding PRD or tasks instead.

## How To Add An Initiative

1. Choose the next unused two-digit number; never renumber existing initiatives.
2. Create `NN-slug/README.md` from `_template/README.md`; do not copy the whole template tree.
3. Complete the initiative README before creating implementation tasks.
4. Create or link the matching `tc` PRD and tasks.
5. Add the initiative to the table in this file.
6. Record significant choices in the README; add a supporting decision file only when it earns its separate maintenance cost.
7. Store phase validation in closure audits and in a `tc` test work product.

Do not create `docs/initiatives/`. Keep one maintained README for completed work:
outcome, consequential decisions, failures/corrections, applicable lessons and
unfinished obligations. The optional `_template/` examples are reference assets,
not scaffolding to copy into every initiative.

Follow `$optimize` for checkpoint and retirement. Preserve necessary originals
with a catalog and tested retrieval; remove superseded narratives only after
consumer/recovery checks and exact approval. Archive location follows project
policy, not an automatic copy of every closed initiative. Report net reduction
including newly created proof artifacts, and identify holds with owners/conditions.
Later work records how a lesson affected a decision/check and its observed result;
completion of this README alone is not proof of better product outcomes.
