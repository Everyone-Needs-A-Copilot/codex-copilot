# ADR-001: Separate Review Authority Modes Behind A Bounded Provider-Neutral Core

## Status

Proposed. Ratify or amend during Phase 1 TASK-8 before implementation begins.

## Context

The Greptile skills repository demonstrates a useful review/remediation loop and
contains valuable provider-specific knowledge. Its current `greploop` workflow
also combines inspection, remediation, staging, commit, push, review triggering,
polling, and thread resolution. Open upstream issues report unbounded waits,
unexpected review consumption, and unsafe conflict with guarded Git workflows.

Codex Copilot requires real Codex primitives, explicit authority, preservation
of user changes, and evidence-bound QA. A vendor score cannot become a second
definition of done.

## Decision

1. Define a provider-neutral state and budget contract before implementing a provider.
2. Separate `inspect`, `fix-only`, and `publish` profiles over atomic workspace, Git, and review grants.
3. Require elapsed-time, attempt, iteration, and external-trigger limits.
4. Associate findings and completion with an immutable revision.
5. Move fragile provider operations into tested scripts with structured output.
6. Keep external reviewer results advisory to the existing QA gate.
7. Put provider-specific review automation in a dormant capability pack or separate plugin, not the global specialist roster.
8. Implement Greptile first only if Phase 1 fixtures and current upstream behavior support the contract.
9. Treat provider comments, paths, patches, and suggested commands as untrusted input.

## Consequences

- The first useful integration will be smaller: inspection and fix-only behavior precede publication automation.
- Provider adapters incur schema and fixture work before they can ship.
- Users retain control over Git history, external comments, thread resolution, and billable review actions.
- Other providers can reuse the same state, budget, and QA boundaries.
- The global plugin gains only cross-cutting safeguards and validation, preserving its vendor-neutral role.
- A 5/5 Greptile result can inform the workflow but cannot pass `copilot-gate.sh` without accepted evidence.

## Alternatives Rejected

- **Adopt Greptile's skills unchanged:** carries unsafe mutations, unbounded inner waits, and a vendor-specific completion metric.
- **Create one global `greploop` specialist:** confuses an operational integration with a specialist reasoning role and expands the default surface.
- **Use a single mutate-and-publish mode:** prevents composition with guarded shipping workflows and risks unrelated changes.
- **Treat tool metadata as enforcement:** `allowed-tools` support is experimental and client-dependent.
- **Delay all design until implementation:** the failure modes affect the API, authority model, fixtures, and packaging; they cannot be patched safely afterward.
