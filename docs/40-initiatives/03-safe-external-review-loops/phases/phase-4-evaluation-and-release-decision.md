# Phase 4: Evaluation And Release Decision

## Objective

Evaluate the end-to-end workflow, decide whether publish mode is justified, and
choose the supported packaging and release status.

## Inputs And Dependencies

- completed Greptile inspect and fix-only adapter
- task-bound QA evidence from earlier phases
- current user feedback, provider costs/rate limits, and host compatibility

## Work Definition

1. Run representative cases: clean PR, dirty tree, edited summary, stale revision, missing check, failing review, exhausted budget, and provider outage.
2. Compare the adapter with manual guarded review and shipping workflows.
3. Measure trigger count, elapsed time, false completion, stale finding rate, and unintended mutation rate.
4. Decide whether publish mode has sufficient value and safety evidence.
5. If publish mode proceeds, create a separate QA-required implementation task with explicit stage/commit/push/comment/resolve acceptance cases.
6. Finalize compatibility, installation, usage, degradation, and removal documentation.
7. Update catalogs, pack/plugin manifests, parity records, versions, and release notes only for capabilities actually shipped.

## Exit Criteria

- all target scenarios have reproducible evidence
- no unintended repository, Git, or external mutation is observed
- costs and rate-limit behavior are visible and bounded
- supported providers, modes, and limitations are stated precisely
- publish mode is either independently approved or explicitly deferred
- release fitness and `scripts/copilot-gate.sh` pass
- the initiative retrospective records lessons and remaining work

## Closure Audit

Store the final evaluation as a task-bound `test` work product with accepted
artifacts and verdict. Update the initiative README only with durable outcomes;
keep task completion and QA status authoritative in `tc`.
