# Phase 4: Machine Bootstrap And Updates

## Objective

Reduce new-computer setup to one safe, idempotent bootstrap while keeping executable tooling and credentials machine-owned.

## Inputs And Dependencies

- completed lock manifest and embedded asset implementation
- completed Git-native `tc` state and hydration behavior
- versioned standalone distribution paths for `cc` and `tc`

## Work Definition

1. Publish or select versioned standalone installation paths for `cc` and `tc`.
2. Implement a repository bootstrap that verifies pinned versions and diagnoses degradation.
3. Rebuild memory and task caches from tracked sources.
4. Verify Claude assets, Codex marketplace/plugin visibility, trust boundaries, and host restart requirements.
5. Implement project doctor checks for links, paths, credentials, caches, ownership drift, and version mismatch.
6. Make repeated bootstrap and doctor runs non-destructive and working-tree clean.

## Exit Criteria

- a new machine needs no separate framework source checkout
- bootstrap installs or precisely reports missing machine prerequisites
- repeated bootstrap runs are idempotent
- cache rebuilds recover committed project context
- doctor reports degraded host activation honestly without rewriting project state
- bootstrap and doctor leave no machine paths or secrets in tracked files

## Closure Audit

Create a phase closure audit before marking this phase complete. Cite package installation checks, idempotency tests, cache rebuild evidence, and the corresponding task-bound QA work product.

