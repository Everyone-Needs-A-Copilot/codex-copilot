# Protocol Flows

## Default workflows

| Request type | Workflow |
|--------------|----------|
| defect | `qa -> me -> qa` |
| technical | `ta -> me -> qa` |
| experience | `sd -> uxd -> uids -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive | `ta -> sec -> me -> qa` |

## Routing notes

- prefer `experience` when the work changes how users experience the product
- prefer `technical` when the change is mostly internal or architectural
- prefer `defect` when the task is about broken behavior or verification
- use `security-sensitive` when trust boundaries or privilege decisions are central

## Ambiguous requests

If the user says something like:

- improve the dashboard
- make onboarding better
- clean this up

and the correct flow is not obvious, stop and ask a short clarifying question before continuing.
