# Routing Matrix

## Role responsibilities

| Role | Focus | Output |
|------|-------|--------|
| `ta` | architecture, trade-offs, task breakdown | plan, ADR-style reasoning, task shape |
| `me` | implementation | code changes |
| `qa` | validation and regressions | reproduction notes, tests, verification |
| `sec` | threats and controls | security review |
| `doc` | explanation and docs | concise documentation |
| `do` | infra and delivery | scripts, CI, deployment updates |
| `sd` | service blueprint | journey framing and system touchpoints |
| `ind` | industrial design | object-level essentialism, affordances, constraints |
| `uxd` | interaction design | flows, states, usability choices |
| `uids` | visual direction | hierarchy, tokens, layout language |
| `uid` | interface implementation | components and styling |
| `cw` | product language | concise, intentional copy |
| `cco` | creative direction | brand strategy, concept territory, positioning |
| `kc` | knowledge setup | shared docs, memory, refs, knowledge repository status |
| `cs` | customer success | support, discovery, retention, sales strategy |
| `cpa` | financial advisory prep | cash flow, tax-aware modeling, CPA questions |

## Request matrix

| Request | Primary route | Optional additions |
|---------|---------------|-------------------|
| fix failing tests | `qa -> me -> qa` | `ta` if architecture is implicated |
| add API endpoint | `ta -> me -> qa` | `sec`, `doc` |
| redesign onboarding | `sd -> uxd -> uids -> uid -> ta -> me -> qa` | `ind`, `cco -> cw` |
| update dashboard visuals | `uids -> uid -> qa` | `uxd` |
| write migration plan | `ta` | `do`, `sec` |
| ship deployment fix | `do -> me -> qa` | `ta`, `sec` |
| set up knowledge repo | `kc` | `doc` |
| prepare sales discovery | `cs` | `cpa` |
| model pricing tax impact | `cpa` | `cs` |
