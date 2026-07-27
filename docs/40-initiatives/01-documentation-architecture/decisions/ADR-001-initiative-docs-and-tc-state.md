# ADR-001: Separate Initiative Knowledge From Execution State

## Context

Convoco demonstrates that multi-phase work benefits from a durable initiative folder containing phase plans, decisions, closure audits, and retrospectives. Codex Copilot also requires substantial task state to remain in `tc`, where dependencies, assignments, work products, and QA status are queryable.

## Decision

Every project uses `docs/40-initiatives/NN-slug/` for durable initiative knowledge. Each initiative contains `README.md`, `phases/`, `decisions/`, and `retrospectives/`.

`tc` remains authoritative for live execution state. Initiative documents summarize status and link to PRDs, tasks, work products, and QA evidence instead of duplicating a task board in Markdown.

## Consequences

- Initiative context remains readable to humans and agents across sessions.
- Execution state remains structured and inspectable.
- Documentation and task state can drift if links are not maintained, so closure checks must verify both surfaces.

## Alternatives Rejected

- Markdown-only initiative tracking: rejected because it duplicates and weakens `tc` state.
- `tc`-only initiatives: rejected because long-form rationale, phase design, and retrospectives become difficult to navigate as a coherent program.
- Unnumbered `docs/initiatives/`: rejected because it breaks the established ordered documentation architecture.
