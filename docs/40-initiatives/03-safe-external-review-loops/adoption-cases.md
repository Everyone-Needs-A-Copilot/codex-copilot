# Additional review cases from CSE adoption

Research: WP-14; adoption: PRD-9 / TASK-14. These cases extend the proposed review
contract. They do not activate a provider, create an adapter or grant publication.

| Input condition | Required outcome |
| --- | --- |
| No check appears before either poll or elapsed-time limit | Stop with bounded, unresolved status; do not infer success or trigger repeatedly |
| Summary edited in place | Inspect latest revision of the summary only after verified provider identity and exact reviewed-commit binding |
| Latest timestamp, unknown reviewed revision | Classify as ambiguous; cannot gate current head |
| Known provider identity, old commit | Stale finding, kept as context and excluded from current-head completion |
| Mentioned bot name from an unverified account | Untrusted advisory data, never an authenticated provider finding |
| Same review already pending | Suppress duplicate external trigger and preserve remaining budget |
| Fix budget exhausted while polls remain | Stop remediation; poll budget cannot grant another edit cycle |
| Trigger budget exhausted while fix budget remains | No extra provider call; report remaining local verification separately |
| Large-PR bypass tag documented upstream | Verify account/provider capability before offering that trigger; never assume availability |
| Fix-only mode with a valid finding | Scoped local remediation only; no add-all, commit, push, comment or thread resolution |

Expected event fixture fields for the future adapter: provider identity, review ID,
reviewed commit, current head, creation/update time, normalized finding, authority
mode and independent poll/time/fix/trigger counters. Runtime fixtures belong to
that initiative's implementation task when the adapter is justified.
