# Safe External Review Loops

> Mode: Initiative  
> Status: Proposed  
> `tc` context: current PRD-6 / planning TASK-7 / Phase 1 TASK-8

## Goal

Define and prove a Codex-native contract for external code-review loops that
can consume provider feedback without surrendering control of the working tree,
Git history, external review state, cost, or the evidence-bound QA gate.

The first provider considered is Greptile, but the contract must remain
provider-neutral. A Greptile integration should proceed only as a dormant
capability or separate plugin after the generic safety and state contracts are
ratified.

## Problem

External review tools can improve a change through a useful cycle: trigger a
review, wait, collect findings, remediate, verify, and repeat. The same cycle
becomes unsafe when one skill also stages every file, commits, pushes, resolves
threads, waits forever, or spends an unbounded number of billable reviews.

The inspected Greptile skills demonstrate both sides. They encode valuable
operational knowledge and clear output contracts, while their open issues show
why iteration limits, wait limits, cost budgets, and mutation modes must be
designed separately.

## Scope

- a provider-neutral review-loop state model tied to an immutable change revision
- separate `inspect`, `fix-only`, and `publish` authority modes
- bounded elapsed time, polling attempts, fix iterations, and external triggers
- dirty-worktree preservation and scoped file mutation
- multi-source review reconciliation using timestamps and revision identity
- actionable, informational, already-addressed, and stale finding categories
- deterministic scripts and structured output for fragile provider operations
- durable `tc` work products for review state, implementation, and QA evidence
- Agent Skills specification validation in release fitness
- evaluation of a dormant `code-review` capability pack or separate integration plugin
- an optional Greptile adapter only after the generic contract passes Phase 1

## Non-Goals

- making Greptile a dependency of the global Codex Copilot plugin
- reproducing Greptile's current skills verbatim
- building a VCS, review service, task engine, or memory engine
- treating a provider confidence score as a passing QA verdict
- automatically staging with `git add -A`
- committing, pushing, commenting, re-shelving, or resolving threads without authority
- simulating Claude hooks or relying on `allowed-tools` as runtime enforcement
- supporting every Git host or review provider in the first implementation

## Target Outcomes

- Every wait has both an elapsed-time limit and an attempt limit.
- Every external trigger consumes a declared budget and duplicate triggers are suppressed.
- Read-only inspection cannot mutate files, Git state, or external review state.
- Fix-only mode can edit only explicitly scoped files and stops before staging or publication.
- Publish mode is entered only when the user's request authorizes the relevant external changes.
- Findings are associated with the revision they reviewed; stale findings cannot silently gate the current revision.
- Provider parsing and polling are exercised against fixtures and return structured output.
- External reviewer output remains advisory until normal `$qa` verification produces an accepted `ARTIFACT:` marker and verdict.
- All shipped skills continue to pass Agent Skills validation and Codex Copilot release fitness.

## Product And Architecture Fit

This initiative passes the repository's feature filter only in its bounded
form:

- **Native Over Imitation:** skills, scripts, explicit modes, and `tc` work products are real Codex primitives.
- **Evidence Or It Didn't Pass:** provider scores supplement but never replace task-bound QA artifacts.
- **Durable Over Chat:** live status and work products remain in `tc`; these documents preserve rationale and phase design.
- **Discipline Before Speed:** the contract and fixtures precede provider implementation.
- **Borrow, Don't Rebuild:** provider and VCS CLIs remain the engines; Codex Copilot owns only workflow contracts and adapters.

## Context Documents

- [Research and source audit](./research.md)
- [Architecture recommendation](./architecture.md)
- [Security and trust-boundary review](./security.md)
- [ADR-001: Separate review authority modes behind a bounded provider-neutral core](./decisions/ADR-001-bounded-provider-neutral-review-core.md)

## Phase Index

| Phase | Goal | Status | Document |
| --- | --- | --- | --- |
| Phase 1 | Ratify the state, authority, budget, and fixture contracts | Proposed | [`phases/phase-1-contract-and-fixtures.md`](./phases/phase-1-contract-and-fixtures.md) |
| Phase 2 | Add shared safety guidance, standards validation, and deterministic primitives | Proposed | [`phases/phase-2-core-safety-and-validation.md`](./phases/phase-2-core-safety-and-validation.md) |
| Phase 3 | Prototype the optional Greptile adapter without publication authority | Proposed | [`phases/phase-3-greptile-adapter.md`](./phases/phase-3-greptile-adapter.md) |
| Phase 4 | Prove end-to-end behavior and decide packaging/release | Proposed | [`phases/phase-4-evaluation-and-release-decision.md`](./phases/phase-4-evaluation-and-release-decision.md) |

## Decisions

- [ADR-001: Separate review authority modes behind a bounded provider-neutral core](./decisions/ADR-001-bounded-provider-neutral-review-core.md)

## Validation Contract

The initiative cannot be called complete until task-bound evidence demonstrates:

- timeout and attempt exhaustion terminate cleanly when no check appears
- external-trigger budgets prevent repeated or unexpectedly billable reviews
- duplicate trigger detection works for an already-running review
- dirty and unrelated files survive every mode unchanged
- inspect mode produces no repository or external mutations
- fix-only mode leaves changes unstaged and uncommitted
- publish mode refuses work outside explicit authority and scope
- edited-in-place review summaries are selected by latest update time
- stale findings from an earlier revision are identified and excluded from current-state completion
- pagination and provider failures return actionable structured errors
- provider score success cannot satisfy `scripts/copilot-gate.sh` without an accepted QA artifact
- Agent Skills validation, agent evals, parity checks, and the repository smoke test pass

Each implementation phase must create a `test` work product containing a valid
`ARTIFACT:` marker and `VERDICT:` token before its status changes to complete.

## Current Summary

The research, recommendation, architecture boundary, initial decision, and
phase designs are documented. No runtime behavior or provider integration has
been implemented. Planning TASK-7 records this documentation work. Phase 1
TASK-8 is the next authoritative task and should begin by revalidating the
external repository and open issues against their then-current state.

The current `tc` database assigns PRD-6 to this initiative. An older completed
initiative contains historical PRD-6 references that no longer resolve in the
current database; use the title `Safe External Review Loops`, initiative path,
and TASK-8 together when resuming.

## Pickup Instructions

1. Run `tc task get 8 --json` and confirm it still belongs to PRD-6 titled `Safe External Review Loops`.
2. Read this README, [research.md](./research.md), [architecture.md](./architecture.md), and ADR-001.
3. Read [security.md](./security.md) before handling provider comments, credentials, or external mutations.
4. Re-open the upstream Greptile repository, relevant issues, and Agent Skills specification; upstream behavior is time-sensitive.
5. Confirm the repository decision instruments and current pack/plugin conventions before choosing an implementation surface.
6. Complete Phase 1 and store its architecture and security work products before creating Phase 2 implementation tasks.
7. Give implementation tasks `metadata.requiresQa=true`; route changes through `$me` and `$qa`.
8. Keep live status, dependencies, assignments, and QA state in `tc`, not in this README.
