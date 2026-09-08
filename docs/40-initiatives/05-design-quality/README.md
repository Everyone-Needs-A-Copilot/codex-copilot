# Complete CSE design quality

> Authorized implementation · 2026-09-07 · PRD-11 in the **codex-copilot** task database

CSE now has a shared design-quality capability through `cc design`, with native
specialist guidance for Claude Copilot and Codex Copilot. It covers the full
design chain: surface intent, explicit authority, focused visual and interaction
work, critique, pinned detection, rendered comparison and evidence-bound QA.

The goal is better product work with fewer missed states and less arbitrary
styling. A detector score cannot establish that outcome. Real work and owner
feedback remain the measure of effectiveness.

## Scope and ownership

| Responsibility | Owner and implementation |
| --- | --- |
| Reusable operations, contracts, receipts, tool registry | Shared `claude-copilot/tools/cc/src/cc/core/design/` and `commands/design.py` |
| Service and interaction intent | Native `sd` and `uxd` specialists; existing required walkthroughs retained |
| Visual direction and implementation | Native `uids` and `uid`; existing design authority retained |
| Task decomposition and delivery | Native `ta` and `me`; `tc` owns execution state |
| Behavioral truth and approval | Native `qa`; existing task-bound ARTIFACT/VERDICT gate |
| Edit feedback | Runtime-specific optional adapters; no implicit install or task closure |
| Visual iteration | Existing browser tooling, offline `cc design compare`, optional external live workflow |

The 21 focused actions are available through `cc design guide`: shape, system,
typeset, layout, colorize, bolder, quieter, distill, animate, delight, onboard,
clarify, harden, adapt, optimize, extract, critique, audit, polish, compare and live.
Guides are loaded on demand; they are not 21 new globally loaded agents.

## Durable records

- [Operating guide](../../02-user-guides/design-quality.md): commands, input contracts, verification and recovery.
- [Phase design](phases/01-capability-and-activation.md): scope, exit criteria and task links.
- [Architecture decision](decisions/001-shared-design-authority.md): shared ownership, trust boundaries and source provenance.
- [Validation and trial](phases/02-validation.md): observed results and limits.
- [Shared gap closure](phases/03-shared-gap-closure.md): migration, verification and remaining owner actions.
- [Lessons](retrospectives/01-initial-trial.md): what the first real artifact taught us.

Live task and QA state is authoritative in PRD-11, TASK-18–25. TASK-22 retains
owner outcome review; TASK-23 tracks fresh native-session dispatch evidence. This document is
not a second task board. The implementation is local and unpublished; existing
release candidates must be revalidated against the resulting source before release.

## Outcome standard

Count required states actually exercised, design/behavior defects found before
handoff, repeated owner corrections, accepted exceptions and unnecessary changes
caused by false positives. Preserve initial judgment before scan output. Compare
like-for-like work using frozen criteria, source/runtime identity and real review;
do not infer causation from one repaired prototype or mechanical test passes.
