# Phase 3: Greptile Adapter

## Objective

Prototype Greptile as the first provider adapter using the ratified contract,
initially limited to inspect and fix-only behavior.

## Inputs And Dependencies

- completed Phase 2 safety and validation work
- current official Greptile CLI and hosting-platform documentation
- fixtures for GitHub and one additional supported platform chosen in Phase 1
- a settled dormant pack or separate-plugin layout

## Work Definition

1. Implement provider detection and explicit override behavior.
2. Normalize change identity, immutable revision, provider status, score, and findings.
3. Reconcile current data across checks, reviews, inline threads, descriptions, and edited comments where applicable.
4. Implement bounded monitoring with duplicate-trigger suppression and external-trigger accounting.
5. Implement inspect mode with zero mutation.
6. Implement fix-only mode with dirty-tree inventory, explicit file scope, post-edit diff checks, and no staging.
7. Provide non-interactive scripts, structured JSON, `--help`, helpful errors, and fixture tests.
8. Document authentication and installation without performing silent global installation or login.
9. Treat provider comments and suggested patches as untrusted data; reject command injection, unsafe paths, secret exposure, and out-of-scope edits.

## Exit Criteria

- inspect-mode fixtures prove zero repository and external mutations
- fix-only fixtures preserve unrelated and pre-existing changes
- no command uses `git add -A`
- missing checks, stale revisions, edited comments, pagination, rate limits, malformed output, and timeout paths are covered
- external triggers never exceed the configured budget
- provider output remains advisory to task-bound QA
- adversarial provider content cannot execute commands, widen file scope, or expose credentials
- implementation and QA work products pass the gate

## Closure Audit

Record fixture test runs, dirty-tree diff checks, adapter compatibility evidence,
remaining platform gaps, and the QA verdict. Do not enable publish mode merely
because inspect and fix-only pass.
