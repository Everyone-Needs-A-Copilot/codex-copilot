# Protocol Flows

## Default workflows

| Request type | Workflow |
|--------------|----------|
| defect | `qa -> me -> qa` |
| technical | `ta -> me -> qa` |
| infrastructure | `do -> me -> qa` |
| experience | `sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive | `ta -> sec -> me -> qa` |
| knowledge | `kc` |
| creative branch | `cco -> cw` |
| business advisory | `cs` or `cpa` |

## Routing notes

- prefer `experience` when the work changes how users experience the product
- prefer `technical` when the change is mostly internal or architectural
- prefer `infrastructure` when deployment, CI, env, containers, releases, or observability dominate
- prefer `defect` when the task is about broken behavior or verification
- use `security-sensitive` when trust boundaries or privilege decisions are central
- insert `ind` before `uxd` when object-level essentialism would materially simplify the feature
- insert `cco -> cw` after `sd` when brand direction, messaging, or creative concept materially shapes the experience

## Ambiguous requests

If the user says something like:

- improve the dashboard
- make onboarding better
- clean this up

and the correct flow is not obvious, stop and ask a short clarifying question before continuing.
