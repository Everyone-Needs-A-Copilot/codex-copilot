# Phase 2: Core Safety And Validation

## Objective

Implement the provider-neutral safeguards and standards validation that belong
in the global framework, without adding a global provider dependency.

## Inputs And Dependencies

- completed Phase 1 contract and architecture work product
- ratified packaging decision and schemas
- existing specialist shared behaviors, QA gate, smoke test, and agent eval harness

## Work Definition

1. Add bounded-wait and external-mutation guidance to the correct shared specialist surfaces.
2. Make clear that external reviewer scores cannot replace accepted QA artifacts.
3. Add Agent Skills reference validation to release fitness with a reproducible invocation or pinned dependency strategy.
4. Add golden cases for authority classification, timeout handling, budget exhaustion, and dirty-worktree refusal.
5. Add golden cases proving external review text cannot grant authority or cause direct command execution.
6. Implement only the provider-neutral schemas or helper primitives ratified in Phase 1.
7. Document degradation when the validator or required external CLIs are unavailable.

## Exit Criteria

- global skills remain provider-neutral
- release fitness rejects invalid skill structure
- evals distinguish inspect, fix-only, and publish authority correctly
- wait and budget guidance has explicit terminal behavior
- tests prove no provider score can satisfy the existing QA gate by itself
- implementation and QA work products pass `scripts/copilot-gate.sh`

## Closure Audit

Record test-run and diff-check evidence, the corresponding QA work product, and
the accepted verdict before Phase 3 begins.
