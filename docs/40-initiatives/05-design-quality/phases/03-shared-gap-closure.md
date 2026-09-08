# Shared rollout gap closure

Recorded 2026-09-08 under Codex PRD-11 TASK-24/25 and Claude PRD-4
TASK-37/40/41/42/45/46/47. The implementation uses local specialist reasoning;
no work was delegated to subagents.

The shared development runtime is cc 2.13.0 / tc 2.0.0. Current QA binds the
project database, task definition, registered criteria and explicit content
manifest. Native specialist instructions register that contract before QA, retain
the pre-verification identity and use tc's completion authority. Required skill
aliases retain their names without duplicating content. Design receipts also bind
to the actual task's acceptance criteria and cover all targets and authority.

Claude's remaining command roster consumers now follow the canonical roster;
workspace finish no longer silently skips a missing-only `reflect`. Snapshot
publication verifies and publishes cc/tc together, including dependency and
enforcement provenance. The source CLI installation was activated and the reviewed
upstream instruction baseline recaptured. Complete Codex smoke validation passed;
native graded files were unchanged. Task WPs hold exact artifacts and QA verdicts.

The sibling Claude operations handoff
(`claude-copilot/docs/30-operations/12-cse-gap-closure-and-release-handoff.md`)
explains the pending-task migration, authorized fixture changes, baseline test
limitations, final release checks, project propagation and genuine owner-review
requirements. Claude TASK-34 remains historical preparation; TASK-47 is the actual
release gate, and TASK-36 depends on it. TASK-22 remains the real effectiveness
review; synthetic tests and native hook probes do not satisfy it.

Fresh Claude Code and Codex native dispatch is verified in TASK-23 / WP-49,
including source/pin/session state, duplicate replay and bounded native failure.
The final combined candidate is `a2227ca8195dd00fe69cc38e39c1ad110eb657b0`
(tree `52afb85dc302b29a583adf7492bcf20163ff7b8e`); Claude TASK-46 / WP-76
records its successful isolated installation and combined validation.
Codex TASK-25 / WP-47 records native integration approval.
The Codex adapter now accepts native `tool_input.command`, in addition to older
replay shapes. Registration and hook trust are separate from native dispatch.
The legacy inspection decision in ADR-002 remains historical compatibility;
current deployments require tc 2.0.0 and its authoritative completion check.
