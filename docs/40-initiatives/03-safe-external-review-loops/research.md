# Safe External Review Loops: Research And Source Audit

## Research Question

What should Codex Copilot learn from `greptileai/skills`, and which ideas should
be adopted, reshaped, or rejected under Codex Copilot's product and QA rules?

## Inspection Snapshot

- Inspected: 2026-07-15
- Upstream: <https://github.com/greptileai/skills>
- `main` commit: `7a34572951f296d7f2a05e69e8494136cb00c85e`
- Commit date: 2026-06-23
- Commit subject: `Merge pull request #19 from ravern/ravern/add-cli-review-skill`
- Project memory search: no prior project entry for Greptile or external review loops

Because the repository and its issues can change, this snapshot is evidence for
the initiative's starting point, not a permanent statement about upstream.

## Repository Shape

The inspected repository contains three Agent Skills:

| Skill | Responsibility | Important behavior |
| --- | --- | --- |
| [`check-pr`](https://github.com/greptileai/skills/blob/main/check-pr/SKILL.md) | Inspect and optionally remediate a hosted change | Detects GitHub, GitLab, or Perforce; waits for checks; classifies comments; can fix and resolve |
| [`cli-review`](https://github.com/greptileai/skills/blob/main/cli-review/SKILL.md) | Run a local Greptile CLI review | Checks repository context, installation, authentication, JSON fallback, and concise output |
| [`greploop`](https://github.com/greptileai/skills/blob/main/greploop/SKILL.md) | Repeatedly review and remediate | Caps the outer fix cycle at five iterations and targets 5/5 confidence with no unresolved comments |

`check-pr` and `greploop` keep GitHub GraphQL and GitLab API details in
`references/`. The repository README explains multi-skill discovery and
symlink installation for Claude Code.

## Transferable Strengths

### Operational skills, not generic personas

Each skill defines a bounded job with inputs, prerequisite discovery, concrete
steps, failure behavior, and an output contract. This complements Codex
Copilot's specialist roles: specialists decide how to reason, while operational
skills can encode a repeatable interaction with a real external system.

### Progressive disclosure

Core procedure stays in `SKILL.md`; platform-specific API material is loaded
from focused references when required. This aligns with the
[Agent Skills specification](https://agentskills.io/specification) and its
[skill-creation guidance](https://agentskills.io/skill-creation/best-practices).

### Multi-source reconciliation

Hosted review state may appear in checks, reviews, inline threads, descriptions,
or general comments. Greptile can edit one existing comment rather than create
a new one. The merged change in
[PR #15](https://github.com/greptileai/skills/pull/15) therefore selects the
latest Greptile comment by `updated_at`. The general lesson is broader: review
state is eventually consistent and must be reconciled by revision and update
time, not assumed to be append-only.

### Finding taxonomy and explicit output

The distinction among actionable, informational, and already-addressed findings
is useful. A structured summary makes the next action legible and prevents every
review comment from being treated as a code defect.

### Packaging is part of portability

[PR #20](https://github.com/greptileai/skills/pull/20) observes that the
instruction bodies are mostly agent-agnostic while installation, discovery,
activation, and tool metadata remain host-specific. Codex Copilot should keep
using its actual plugin and pack primitives and validate the portable Agent
Skills layer without pretending host packaging is universal.

## Failure Evidence And Design Corrections

### The outer iteration cap does not bound inner waits

[Issue #14](https://github.com/greptileai/skills/issues/14) identifies
unbounded `while true` loops while waiting for GitHub or GitLab review state.
If a check never appears, the five-iteration remediation cap does nothing.

**Correction:** every wait needs elapsed-time and attempt limits, terminal error
states, and periodic user-visible progress. The whole operation also needs a
total deadline.

### Iteration has a monetary and rate-limit cost

[Issue #12](https://github.com/greptileai/skills/issues/12) reports roughly a
dozen reviews during a forty-minute run and an associated usage spike.

**Correction:** distinguish fix iterations from external triggers. Declare and
enforce `maxExternalTriggers`, suppress duplicate reviews, expose consumption,
and stop before the budget is exceeded.

### Remediation and publication are different authorities

[Issue #17](https://github.com/greptileai/skills/issues/17) objects to
`git add -A`, autonomous commits, and pushes. Those actions can capture secrets,
generated output, debug files, or unrelated user changes.

**Correction:** define three modes:

- `inspect`: read-only repository and external state
- `fix-only`: scoped working-tree edits, no staging or external mutation
- `publish`: explicitly authorized staging/commit/push/comment/resolution actions

Publication must never be an incidental substep of inspection or remediation.

### A provider metric is not QA evidence

The `greploop` target of 5/5 confidence and zero unresolved comments is a useful
provider-specific stop signal, but it cannot prove runtime behavior, preserve
product intent, or replace tests.

**Correction:** store provider output as review context. Codex Copilot's normal
`$qa` flow still requires a task-bound, accepted `ARTIFACT:` marker and verdict.

### Long shell snippets are difficult to verify

The provider skills contain substantial polling, pagination, GraphQL, parsing,
and mutation logic as instructions. This makes behavior dependent on each
agent's shell composition and leaves duplicated provider references exposed to
drift.

**Correction:** retain concise workflow guidance in skills, but move fragile
operations into non-interactive, tested scripts with `--help`, structured JSON,
helpful errors, and explicit exit codes. This follows the Agent Skills
[script guidance](https://agentskills.io/skill-creation/using-scripts).

## Local Codex Copilot Assessment

Codex Copilot already has several stronger foundations:

- [`SOUL.md`](../../../SOUL.md) requires native primitives and evidence-bound QA.
- [`qa/SKILL.md`](../../../plugins/codex-copilot/skills/qa/SKILL.md) refuses approval without an accepted external artifact.
- [`scripts/copilot-gate.sh`](../../../scripts/copilot-gate.sh) checks task-bound evidence and verdict tokens.
- [capability packs](../../02-user-guides/06-capability-packs.md) provide an explicit dormant surface for optional skills.
- the core [plugin manifest](../../../plugins/codex-copilot/.codex-plugin/plugin.json) already provides Codex-native multi-skill packaging.

One immediate gap is that [`scripts/smoke-test.sh`](../../../scripts/smoke-test.sh)
does not run the Agent Skills reference validator. During this research:

- all three inspected Greptile skills passed `agentskills validate`
- all current `plugins/codex-copilot/skills/*` skills passed the same validation

The command used was:

```bash
uvx --from skills-ref agentskills validate <skill-directory>
```

This result is point-in-time evidence; Phase 2 should make validation part of
release fitness if Phase 1 confirms the dependency and invocation strategy.

## Recommendation

Adopt the workflow engineering lessons, not the current automation boundary:

1. Ratify a provider-neutral state, authority, budget, and error contract.
2. Add standards validation and shared safety guidance to the core framework.
3. Put reusable external review behavior in a dormant `code-review` capability pack or separate integration plugin.
4. Implement Greptile only as the first adapter and initially expose `inspect` and `fix-only` modes.
5. Defer publish-mode automation until fixtures and task-bound QA prove dirty-worktree safety, explicit authority, and external-state correctness.

Do not copy `allowed-tools` as enforcement. The Agent Skills specification marks
that field experimental and notes that support varies by client. It may describe
intent, but Codex Copilot must enforce safety through actual permissions,
explicit instructions, scripts, refusal conditions, and verification.

## Source Index

- Greptile skills repository: <https://github.com/greptileai/skills>
- `check-pr`: <https://github.com/greptileai/skills/blob/main/check-pr/SKILL.md>
- `cli-review`: <https://github.com/greptileai/skills/blob/main/cli-review/SKILL.md>
- `greploop`: <https://github.com/greptileai/skills/blob/main/greploop/SKILL.md>
- Edited comment handling: <https://github.com/greptileai/skills/pull/15>
- Unbounded polling: <https://github.com/greptileai/skills/issues/14>
- Review usage/cost report: <https://github.com/greptileai/skills/issues/12>
- Fix-only mode and Git safety: <https://github.com/greptileai/skills/issues/17>
- Open-skills portability proposal: <https://github.com/greptileai/skills/pull/20>
- Agent Skills specification: <https://agentskills.io/specification>
- Agent Skills best practices: <https://agentskills.io/skill-creation/best-practices>
- Agent Skills script guidance: <https://agentskills.io/skill-creation/using-scripts>

## Revalidation Checklist

Before implementation, the next developer should verify:

- upstream `main` and whether issues #12, #14, and #17 remain unresolved
- whether PR #20 or another packaging model was merged
- current Greptile output surfaces, trigger semantics, rate limits, and billing behavior
- current GitHub/GitLab CLI and API shapes using authoritative documentation
- current Agent Skills validator package and invocation
- whether Codex plugin or pack discovery semantics changed
- whether a provider-neutral implementation already exists upstream in Codex Copilot or `cc`
