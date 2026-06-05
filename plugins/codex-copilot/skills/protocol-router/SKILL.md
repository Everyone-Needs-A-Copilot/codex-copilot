---
name: protocol-router
description: Use when a request needs specialist routing before implementation, including bugs, feature work, architecture changes, UX work, security-sensitive changes, or tc-backed delivery planning.
---

# Protocol Router

Use this skill to classify the request and choose the right specialist flow before coding.

## Classification

| Request type | Start with |
|--------------|------------|
| bug, regression, test failure | `qa` |
| backend feature, refactor, architecture, performance | `ta` |
| user-facing feature, workflow, product experience | `sd` or `uxd` |
| visual polish, design system, component styling | `uids` or `uid` |
| auth, permissions, secrets, trust boundaries | `sec` in addition to primary flow |
| docs, onboarding, references | `doc` |
| deploy, CI, env, infrastructure | `do` |
| memory, shared docs, known references, knowledge setup | `kc` |
| brand strategy, campaign direction, concept territory | `cco` |
| sales, customer success, support escalation | `cs` |
| finance, tax, pricing economics, CPA prep | `cpa` |

## Codex rule

If the user did not explicitly ask for subagents, apply the specialist lens in the main session.

If the user explicitly asked for delegation or parallel work, you may spawn subagents after deciding:

1. what the immediate local step is
2. which work can safely run in parallel

## Standard flow

1. classify the request
2. identify the specialist sequence
3. check whether a `tc` PRD or task exists
4. create missing task records if the work is substantial
5. execute the specialist flow
6. verify with `qa` before closing implementation work

## Routing patterns

- bug: `qa -> me -> qa`
- backend feature: `ta -> me -> qa`
- experience feature: `sd -> uxd -> uids -> uid` as needed, then `ta -> me -> qa`
- infrastructure: `do -> me -> qa`
- security-sensitive feature: primary flow plus `sec` before completion
- creative branch: `cco -> cw`, then return to the primary build flow when implementation is needed
- knowledge setup: `kc`, then return to the primary flow

## References

Read `references/routing-matrix.md` when you need the full mapping.
