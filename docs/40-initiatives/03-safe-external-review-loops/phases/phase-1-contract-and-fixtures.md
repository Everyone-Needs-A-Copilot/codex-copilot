# Phase 1: Contract And Fixtures

> Authoritative follow-up task: TASK-8 under PRD-6 `Safe External Review Loops`

## Objective

Ratify the provider-neutral state, authority, budget, failure, and fixture
contracts so implementation can proceed without unresolved safety boundaries.

## Inputs And Dependencies

- [research and source audit](../research.md)
- [architecture recommendation](../architecture.md)
- [security and trust-boundary review](../security.md)
- [ADR-001](../decisions/ADR-001-bounded-provider-neutral-review-core.md)
- current `SOUL.md`, QA gate, pack/plugin conventions, and Agent Skills specification
- revalidated Greptile repository, issue, CLI, API, billing, and rate-limit behavior

## Work Definition

1. Revalidate all time-sensitive upstream claims and record changed assumptions.
2. Define the normalized review snapshot and finding schemas.
3. Define state transitions and terminal reasons.
4. Ratify the three authority profiles, atomic grants, and what user language authorizes each grant.
5. Ratify independent wait, attempt, fix-iteration, and external-trigger budgets.
6. Define dirty-worktree, file-scope, revision-change, and stale-finding refusal rules.
7. Choose whether implementation lives in a dormant `code-review` pack or a separate plugin.
8. Create fixtures for missing checks, edited comments, pagination, stale revisions, dirty files, provider failures, and exhausted budgets.
9. Create adversarial fixtures for prompt-injecting comments, unsafe paths, untrusted patches, and secret-bearing diagnostics.
10. Store the resulting architecture and security work products in `tc` and create Phase 2 implementation tasks with test expectations.

## Exit Criteria

- ADR-001 is accepted or superseded by a recorded decision
- schemas and terminal states are explicit and fixture-backed
- authority wording is testable and no mode has ambiguous publication rights
- external comments, paths, patches, credentials, and diagnostics have concrete trust-boundary controls
- budget precedence and conservative defaults are documented
- packaging and ownership boundaries are settled
- implementation tasks identify exact file scopes and carry `metadata.requiresQa=true`
- no critical provider API, billing, authentication, or host-compatibility assumption remains unverified

## Closure Audit

Store an `architecture` work product under TASK-8 summarizing the ratified
contract, evidence, alternatives, and implementation boundaries. Phase 1 is a
planning phase; if it changes executable validation or fixtures, add a task-bound
`test` work product and pass the QA gate before marking it complete.
