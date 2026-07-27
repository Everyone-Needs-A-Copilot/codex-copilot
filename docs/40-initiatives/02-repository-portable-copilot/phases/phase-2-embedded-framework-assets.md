# Phase 2: Embedded Framework Assets

## Objective

Make Claude Copilot and Codex Copilot prompt-layer assets self-contained, versioned, and discoverable from a cloned repository.

## Inputs And Dependencies

- completed Phase 1 portability and ownership contracts
- current setup, update, plugin, and QA-gate implementations
- Codex repository marketplace and plugin discovery behavior

## Work Definition

1. Change portable setup to materialize regular tracked files instead of out-of-repository links.
2. Keep symlink mode explicit and limited to framework development.
3. Generate the lock manifest and ownership checksums during setup.
4. Use repository-relative paths for safe Claude hooks and project configuration.
5. Implement update behavior that replaces framework-owned assets while preserving project-owned content.
6. Add generated-project fixtures for both frameworks and for existing-file refusal paths.

## Exit Criteria

- a generated project contains no out-of-repository framework links
- Claude and Codex prompt assets are present as regular tracked files
- the repository marketplace resolves the embedded Codex plugin
- update detects drift and preserves project-owned instructions and overrides
- setup and update fixtures pass on clean and preconfigured projects

## Closure Audit

Create a phase closure audit before marking this phase complete. Cite generated-project file checks, update-preservation tests, and the corresponding task-bound QA work product.

