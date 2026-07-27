# Phase 1: Portability Contract

## Objective

Ratify the repository-versus-machine ownership boundary and define the manifest and schema contracts required by later phases.

## Inputs And Dependencies

- [architecture brief](../architecture.md)
- [ADR-001](../decisions/ADR-001-embed-assets-and-derive-caches.md)
- existing Claude Copilot and Codex Copilot setup/update behavior
- current `cc` memory entry and `tc` database contracts

## Work Definition

1. Specify the lock manifest, framework ownership metadata, and version fields.
2. Define which Claude, Codex, memory, and task paths are tracked or ignored.
3. Define project-owned override rules and non-destructive update behavior.
4. Define Git-friendly task entity identities and serialization invariants with the `tc` owner.
5. Define bootstrap, migration, degradation, and recovery contracts.
6. Add schema fixtures and validation cases before implementation begins.

## Exit Criteria

- one reviewed ownership matrix covers every installed path
- manifest and task-state schemas have deterministic fixtures
- update and migration refusal conditions are explicit
- credentials, personal state, and host activation remain outside repository ownership
- later implementation tasks can be created without unresolved critical architecture choices

## Closure Audit

Create a phase closure audit before marking this phase complete. Cite schema validation, fixture checks, architecture review, and the corresponding task-bound QA work product.

