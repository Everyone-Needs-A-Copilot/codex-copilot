# Documentation Architecture

> Mode: Initiative  
> Status: Complete  
> `tc` context: PRD-6 / TASK-22

## Goal

Establish a predictable documentation system for Codex Copilot and make `docs/40-initiatives/` the canonical place to document, plan, decide, and validate multi-phase initiatives in every configured project.

## Scope

- numbered repository documentation organized by reader job
- concise root README and documentation hub
- canonical source-of-truth boundaries
- project scaffolding for `docs/40-initiatives/`
- shared Knowledge Copilot documentation standards and templates
- executable target-project QA-gate path
- automated documentation and setup verification

## Non-Goals

- changing the core `cc` or `tc` engines
- modifying Convoco's existing initiative history
- introducing a Markdown task tracker that competes with `tc`

## Target Outcomes

- New readers can move from README to first successful workflow without duplicated setup paths.
- Maintainers can distinguish tutorials, guides, explanations, reference, troubleshooting, and historical research.
- Every new project receives the `docs/40-initiatives/` contract.
- Initiative documentation links to `tc`, while `tc` remains authoritative for execution state.
- Documentation claims and commands pass deterministic verification.

## Phase Index

| Phase | Goal | Status | Document |
| --- | --- | --- | --- |
| Phase 1 | Rebuild repository documentation and initiative conventions | Complete | [`phases/phase-1-documentation-system.md`](./phases/phase-1-documentation-system.md) |

## Decisions

- [ADR-001: Separate initiative knowledge from execution state](./decisions/ADR-001-initiative-docs-and-tc-state.md)

## Validation Contract

Completion requires link validation, setup-project fixture checks, initiative scaffold checks, public-path portability checks, parity tests, smoke tests, and an evidence-bound `tc` QA work product. See the [Phase 1 closure audit](./phases/phase-1-closure-audit.md).

## Current Summary

The numbered information architecture, Convoco-derived initiative convention, shared standards, setup scaffolding, and QA-gate link are implemented. TASK-22 remains the authoritative execution and QA record.
