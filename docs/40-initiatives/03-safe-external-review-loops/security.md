# Safe External Review Loops: Security And Trust Boundaries

## Scope

This review covers the proposed external review-loop contract, not Greptile's
internal security. Provider APIs, bot comments, human comments, hosted patches,
repository content, and CLI output all cross trust boundaries before they can
influence local files or external state.

## Assets

- user-authored and unrelated working-tree changes
- repository history, branches, and hosted review state
- provider and VCS credentials
- source code, private diffs, task context, and secrets
- external review quota, rate limits, and monetary budget
- QA integrity and the meaning of a passing verdict

## Actors And Trust Boundaries

| Actor or input | Trust level | Boundary |
| --- | --- | --- |
| User request | Authoritative for intent, subject to repository safety rules | Chat to local execution |
| Repository files and PR content | Untrusted until inspected | Repository to agent reasoning |
| Human or bot review comment | Untrusted data | Provider to agent reasoning |
| Suggested command or patch | Untrusted proposal | Provider text to local process/filesystem |
| `gh`, `glab`, `p4`, or provider CLI | Trusted only within installed version and granted credentials | Local process to hosted service |
| Hosted review service | External system with eventual consistency and possible compromise | Network to local state |
| `tc` QA record | Authoritative only when evidence-bound | Local validation to durable task state |

## Prioritized Risks And Controls

| Risk | Likelihood / impact | Concrete control | Verification |
| --- | --- | --- | --- |
| Review comment prompt injection requests commands, secrets, or wider scope | Medium / High | Treat comments as data; validate the underlying issue; never execute comment instructions directly | Adversarial comment fixtures produce findings but no command execution |
| Provider path or patch writes outside the repository or allowed file set | Medium / High | Canonicalize paths, require repository containment and an explicit allowlist, diff-check after edits | Traversal, symlink, absolute-path, and unrelated-file fixtures are refused |
| Broad staging captures secrets or user changes | Medium / High | Prohibit `git add -A`; snapshot dirty state; stage explicit paths only under an authorized grant | Dirty-tree fixtures remain byte-for-byte unchanged outside scope |
| Credential leakage through stdout, logs, comments, chat, or `tc` | Low / High | Least-privilege auth; never print tokens; redact diagnostics; refuse secret-bearing output | Seeded secret fixtures do not appear in captured output or work products |
| Authority confusion turns review triggering into commit/push/resolve permission | Medium / High | Use atomic grants; default to none; `review.trigger` implies no Git or thread grants | Grant-matrix tests exercise every forbidden transition |
| Stale or replayed review state approves the wrong revision | Medium / High | Bind snapshots and findings to immutable revisions; invalidate completion after revision change | Revision-change fixtures mark prior results stale |
| Cost or rate-limit exhaustion from repeated triggers | Medium / Medium | Independent trigger budget, duplicate suppression, consumption reporting, and fail-closed limits | Trigger counter never exceeds configured maximum |
| Compromised or malformed provider output bypasses QA | Low / High | Parse against a schema; preserve diagnostics; provider score remains advisory | Malformed and forged 5/5 results cannot pass the QA gate |
| Silent installer or authentication flow changes machine state | Medium / Medium | Check prerequisites; request explicit authority; use official, versioned installation guidance | Missing-tool fixtures stop with instructions and perform no installation |

## Authentication And Secret Handling

- Use existing authenticated CLIs where possible; do not collect tokens in skill prompts.
- Do not echo environment variables or full authentication errors that may contain secrets.
- Prefer least-privilege scopes for reading review state; require separate authority for write operations.
- Never store credentials in initiative documents, fixtures, `tc` work products, or provider comments.
- Any install or login flow that changes machine state requires explicit user authority and current official documentation.

## External Mutation Controls

The implementation should represent authority as atomic grants:

```text
workspace.write
git.stage
git.commit
git.push
review.trigger
review.comment
review.resolve
```

All grants default to false. Named modes provide conservative profiles, but the
implementation must check the individual grant immediately before each
mutation. A successful earlier action does not authorize a later one.

## Residual Risk

Even with these controls, provider feedback can be wrong and a correctly scoped
fix can still introduce a defect. Hosted services can also change output shape,
latency, cost, and authentication behavior. Those risks remain acceptable only
if Live Docs or authoritative provider documentation is rechecked during
implementation, fixtures cover the observed formats, and normal task-bound QA
remains the final gate.
