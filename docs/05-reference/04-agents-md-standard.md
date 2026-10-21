# Project AGENTS.md Standard

This is the Codex Copilot authoring and maintenance contract for [the project template](../../templates/AGENTS.project.template.md). It separates Codex loading behavior from framework conventions. It applies to generated files and reviewed migrations; setup scaffolding alone does not establish that a project is ready.

## Codex loading behavior

Codex builds its instruction chain at startup. In `CODEX_HOME` (normally `~/.codex`), it selects the first non-empty `AGENTS.override.md` or `AGENTS.md`. Within a project, it walks from the project root (usually the Git root) down to the starting working directory, selecting at most one instruction file per directory: `AGENTS.override.md`, then `AGENTS.md`, then configured fallback names. Without a project root, discovery checks the current directory. Later, more specific guidance takes precedence within the instruction chain; repository text does not override higher-priority runtime instructions or the user's explicit task boundaries.

Discovery stops at the starting directory, rather than recursively loading every subtree. Before working elsewhere, inspect applicable nested instructions and preserve their scope. A same-directory override replaces that directory's regular file; it is not an additive supplement. Audit overrides instead of assuming a root edit becomes active.

The documented default `project_doc_max_bytes` is 32 KiB for combined project instructions. Check the effective configuration and leave room for nested guidance; line count is not the loading budget. Use a fresh session to verify changed guidance. An ordinary Markdown link, `@file`, `.claude/rules/` path, or Claude `paths:` frontmatter is not a Codex automatic import. Explicitly state when to read referenced guidance.

These behaviors come from [OpenAI's AGENTS.md guide](https://learn.chatgpt.com/docs/agent-configuration/agents-md). Headings, section order, and size targets below are Copilot conventions, not a required Codex schema. Guidance is instruction context; enforcement claims require actual runtime or task-gate evidence.

## Content and order

1. **Project Overview:** verified name, purpose, and stack. Do not infer product purpose from an unfilled template.
2. **Project-Specific Rules:** standing project invariants near the top. Keep this established heading for continuity; reconcile shared requirements with Claude's `Project Rules` by meaning, not spelling.
3. **Project Commands:** verified setup, development, build, lint, and test commands or precise pointers to maintained instructions. Include working directories, runtimes, prerequisites, focused checks, and relevant external effects. Record non-applicable categories. Generic discovery guidance is acceptable scaffolding, not migration completion.
4. **Instruction Scope:** nested guidance, conditional references, and shared-rule parity boundaries.
5. **Codex Copilot and framework obligations:** concise routing, output, `cc`, Live Docs, knowledge/context, `tc`, QA, debugging, delegation, and decision-instrument guidance. Procedures belong in the installed skills and are read when their task condition applies.

The template deliberately retains its existing four substitution keys: `PROJECT_NAME`, `PROJECT_DESCRIPTION`, `TECH_STACK`, and `PROJECT_RULES`. The installer does not populate command details. A maintainer completes those during adoption; do not introduce new unresolved template keys without changing and validating rendering support.

Target roughly 100 lines for the base template and fewer than 200 for a completed root file, but also measure UTF-8 bytes and preserve important rules. Shorter line counts alone are not an improvement. Move substantial task-specific procedures to referenced documents and area-specific instructions to the appropriate subtree; do not move repository-wide obligations to a directory that may never enter the instruction chain. Avoid duplicating skill catalogs and whole manuals. [OpenAI recommends conditional references and removing unnecessary always-loaded guidance](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).

## Preserve the Copilot contract

- Use available native skills. The template's `$protocol` and specialist names are shorthand; resolve the actual skill exposed by the session, including plugin-qualified names. Applying a skill locally is distinct from launching a subagent. Delegation requires the user's explicit request.
- Keep outcome-first communication, diagnostic discipline, and the concise subagent return contract. Existing authorization remains valid; ordinary reversible work does not need repeated approval.
- Use `cc` for memory, configuration, skills, and Live Docs; `tc` for live tasks and work products. Shared `.claude/cc/` paths are valid Copilot storage, not evidence that Codex implements Claude hooks or rule discovery.
- Resolve task-relevant knowledge through configured `CC_KNOWLEDGE_REPOS`, nearest tier first. Projects supply their consumption-contract and domain pointers; never ship organization-specific facts in the public framework or invent missing knowledge.
- Optional context uses the installed shared-behaviors contract, including receipts and visible fallbacks. Mandatory instructions remain outside relevance filtering.
- QA-required work registers criteria and source scope, captures tested identity, records observed evidence on the task, and passes the task gate before completion. See [Quality Gates](../02-user-guides/04-quality-gates.md); the rendered template points to installed skills because the plugin does not ship this framework docs tree.
- Use `SOUL.md` and architecture principles for their stated decision types. Report missing or unfilled authority rather than silently inventing it.

Machine preferences belong in global configuration/instructions unless genuinely required by the repository. Keep shared repository obligations portable for other contributors and environments; do not remove them solely because one maintainer has a global copy.

## Reconcile with Claude Code

Compare shared requirements across both entrypoints and any referenced rule files. Preserve invariants, commands, applicability, and exceptions. Translate routing only when the corresponding Codex capability exists. A rule about maintaining Claude assets may still be relevant to Codex editing those assets; a rule about executing a Claude-only runtime procedure must not be presented as a native Codex procedure.

Retain a `.claude/rules/` pointer when its content is usable and its read condition is explicit. If only part applies, state that boundary or reference a neutral document. Do not flatten path-scoped rules into global requirements. Missing or contradictory authority is a finding to resolve, not permission to delete a rule.

Keep shared project requirements synchronized in both entrypoints when both exist; tool-specific instructions need not match. Do not use either entrypoint as a wholesale import of the other. The parity review must account for effective nested and referenced instructions, not just equal bullet counts at the root.

## Ownership and maintenance

`AGENTS.md` is project-owned after generation. [Setup and update](../01-setup/02-setup-project.md) preserve existing files, including when repairing framework assets. Absence from `managed_outputs` is intentional; do not add whole-file replacement to solve instruction drift.

When this standard or its template changes, record the semantic changes and validate a disposable render first. Apply them as a reviewed patch to a representative project's effective instructions; preserve its commands, scoped rules, and customizations. A fleet migration follows pilot evidence and explicit rollout scope. Detect and report drift during these reviews; automatic drift detection or block regeneration is not currently implemented by this standard.

## Acceptance checks

- Verify identity, commands, references, installed capabilities, shared-rule parity, and preservation of project customizations; no unresolved template tokens or generic setup placeholders remain in an adopted file.
- Inventory global/project/nested instructions, overrides, fallback names, starting directories, and the effective byte limit. Measure the selected instruction chain, including overrides; do not treat the 200-line convention as proof against truncation.
- In fresh Codex sessions from the root and a representative nested directory, ask which instruction sources are active and what rules govern the chosen task. Corroborate with session logs when available. Explicitly check referenced-rule loading for a relevant task; a self-report alone does not prove enforcement or obedience.
- Validate rendering and project-file preservation with the existing framework tests; confirm test files remain unchanged. Run relevant documentation/link checks and review the diff.
- Record the tested checkout, runtime/configuration, working directories, observations, and limits. A disposable render verifies generation; it does not substitute for a live pilot or fleet audit.
