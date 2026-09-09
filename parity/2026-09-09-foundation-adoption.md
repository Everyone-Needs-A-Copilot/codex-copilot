# Reviewed foundation source adoption

Scope: Claude PRD-6 / TASK-68 and Codex PRD-15 / TASK-32. Source compatibility
advances from framework `5.15.0` / `cc 2.13.0` to `5.15.1` / `2.13.1`; `tc 2.0.0`
and the Codex `0.7.0` version field do not change. This is not a signed foundation
release, tag, global install, consumer rollout or promotion to the intended 0.8.0.

## Exact review

Before adoption, the normal version/content check reported three changed files,
zero added/removed files, and a framework version delta across 70 tracked upstream
instruction files. The former recorded upstream commit was
`2a1734f08338067c4420d8b55a62ab5cf8f7b1e4`; the reviewed upstream checkout is
`328ec6a1e06d6ddb10578145bbdd33cacf3464f3` plus its explicitly reviewed dirty policy
and protocol changes. The generated manifest records actual content hashes, not
a claim that the dirty content already belongs to that commit.

| Upstream delta | Native counterpart / disposition |
|---|---|
| `.claude/agents/me.md`: proportional coverage, no unconditional new test per edited file, compact role guidance, fixed finish line | Native `skills/me/SKILL.md` already loads the shipped `specialist-agents/references/verification-policy.md`; that policy preserves consumers, fallback, diagnostics, caps and explicit closure. Claude embeds the same essential block because its project roster ships named agent files, not `_shared`. |
| `.claude/agents/qa.md`: behavior lanes, actual stored tc approval instead of stale message-only/three-rejection explanation, persisted write evidence, corrected design binding, fixed finish line | Native `skills/qa/SKILL.md` and shared policy retain equivalent behavior and tc2 task/database/criterion/source binding. Existing `scripts/copilot-gate.sh` remains native QA authority; no Claude hook syntax is imported. Native receipt integrity still requires reviewed authority, assertions and a negative control. |
| `.claude/commands/protocol.md`: fixed deliverable, criteria/consumers/cap/exclusions, stop after required QA, no automatic unrelated improvement | Identical Fixed Delivery Boundary text in native `skills/protocol/SKILL.md`; native routing and user-authorized delegation remain unchanged. |
| Framework/cc patch version delta | Update only compatibility pins in `VERSION.json` and `parity/claude-baseline.json`; catalog/schema contain no changed upstream pin, so no unrelated catalog or release-version rewrite. |

Existing native proportional-rule and test-integrity implementation was already
committed before this adoption. The current fixed-finish-line native policy and
protocol port is a live, reviewed change, not an unrelated dirty file offered as
port evidence. The normal `scripts/check-upstream-parity.py --update-baseline`
workflow records provenance only after reviewing those mappings; no bypass or
false no-port attestation is needed.

## Capability and evidence boundaries

The shared source CLI provides `cc verify plan/run/status` and the new `cc status`
overview. These source-only additions are not proven present in an earlier
published/tagged `cc 2.13.1` snapshot. Probe the selected binary, use the prepared
source environment for source checks, and retain normal signed distribution
requirements before a general rollout. Codex does not vendor a replacement engine.

The focused acceptance uses real, disposable canonical Claude+Codex project
transactions with safe synthetic public sources, native Codex setup from the
explicit reviewed source, preservation checks and shared verification/status.
Machine readiness in the canonical fixture is an explicit fixture fact; host trust,
live model adherence, published compatibility and global deployment are untested.
Task-bound identities and actual check results remain authoritative in `tc`.

Future instruction drift must be reviewed again. A green content check alone does
not establish semantic parity, fixture correctness or a release-ready ecosystem.
