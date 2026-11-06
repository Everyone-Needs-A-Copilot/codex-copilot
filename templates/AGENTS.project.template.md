# Agent Instructions

## Project Overview

- Project: `{{PROJECT_NAME}}`
- Description: {{PROJECT_DESCRIPTION}}
- Stack: {{TECH_STACK}}

## Project-Specific Rules

{{PROJECT_RULES}}

## Project Commands

- Before running project commands, verify them against the README and checked-in build/package/CI configuration; never guess.
- Maintainers: replace this scaffolding with setup, development, build, lint, and focused test commands or precise documentation pointers. Include working directories, runtimes, prerequisites, external effects, and non-applicable categories.

## Instruction Scope

- Check applicable nested `AGENTS.md` / `AGENTS.override.md` before working in a subtree. Preserve scoped rules; references and Claude `paths:` frontmatter are not automatic Codex imports.
- Keep shared project requirements consistent with `CLAUDE.md` when present; preserve scope and keep tool-specific routing separate. Do not import either whole entrypoint into the other.
