# ADR 002 — Adopt task authority without breaking legacy inspection

This records the initial tc 1.4 compatibility decision. [Shared gap closure](../phases/03-shared-gap-closure.md)
supersedes its version baseline: current source requires tc 2.0.0 and registered
task/source-bound acceptance evidence. The legacy inspection boundary remains.

Claude's prior handoff landed as commit `483c695`, framework 5.15.0 / tc 1.4.0,
while design integration was in progress. Its new shared completion predicate is
the correct authority for design QA. Codex's installed gate still inspected WPs
itself, and its protected tests explicitly preserved that older CLI contract.

**Decision:** the native Codex gate discovers `check-qa` in `tc task --help` and
uses its task-bound structured response when present. A rejected, malformed or
failed authoritative response blocks; it never falls back to older WPs. When the
capability is absent, the existing artifact-inspection behavior remains available
with an explicit legacy notice. At that stage, installations required tc 1.4.0; legacy
inspection is not described as current completion validation. No tests were changed.

This differs deliberately from Claude's strict capability-unavailable exit path,
because Codex retains its established compatibility contract. Neither hook nor
helper can override tc 1.4's own completion predicate.

The content-parity review covered eleven changed upstream instruction files:
cco/cw/ind gained project/lens-scoped taste precedence; sd/uxd/uids/ta carry that
precedence and design guidance; me/qa carry design/evidence guidance; uid gained
design guidance; protocol and shared behaviors carry optional-context selection.
Native role syntax and the existing design-led chain remain intact. The reflect
command already matched its source hash. The baseline records reviewed source,
including unpublished design additions; it is not a signed-release claim.
