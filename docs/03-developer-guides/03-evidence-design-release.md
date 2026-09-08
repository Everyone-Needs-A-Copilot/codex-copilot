# Evidence and design release preparation

The next intended release is **0.8.0**. Source preparation and publication are
tracked separately in Codex PRD-11 TASK-26 and TASK-27. The current source changes
are unreleased until a new foundation-signed tag exists; a development commit,
review branch or successful local installation does not replace that tag.

## What the candidate delivers

The native specialist chain consumes shared `cc 2.13.0` and `tc 2.0.0`:
task/database/criterion/source-bound QA, required-skill retention with content
deduplication, 21 focused design actions, task-bound review and optional native
edit feedback. The shared operations live in Claude Copilot; Codex does not ship
another task, memory, detector or model-runner implementation.

The compatibility change is explicit: pending QA-required tasks need a registered
acceptance contract and a source identity captured before verification. Completed
historical evidence remains historical. See the [design operating guide](../02-user-guides/design-quality.md)
and native `ta`/`me`/`qa` instructions for the current contract.

Both native runtimes have dispatched the feedback command in fresh sessions.
Project trust, exact-hook review, detector availability and canonical source paths
still apply. Feedback can report unavailable evidence; it never completes QA.

## Release fitness

Run these from the reviewed source, and repeat bootstrap from a clean clone that
has no sibling checkout, private memory or ignored report artifacts:

```bash
scripts/check-versions.sh
scripts/smoke-test.sh
python3 -m unittest discover -s tests -v
```

Use `scripts/setup-project.sh` with a disposable project, then inspect the installed
plugin version, executable hook files, generated instructions, task database and
QA-gate wiring. Re-run `scripts/update-project.sh` to verify idempotence and
preservation of project-owned content. Keep reports in `tc` work products.

Version, plugin, agent catalog, capability pack and parity manifests must agree.
The existing test pins the release version explicitly; any release-related test
edit must have the authorization required by `AGENTS.md`. Never change an
assertion simply to conceal a runtime or behavior failure.

## Publish through the existing foundation trust

Release publication requires the approved ENAC foundation signing key:
`SHA256:FIfppOkzwXZUAamELQzYoSUQXiEAmTYiVewHe1ACMZo`. A personal GitHub
authentication/signing key is not a replacement. Keep private key material outside
repositories and logs. The release custodian uses the existing Control Tower
`scripts/foundation-snapshot-release.py` procedure with product `codex`, the exact
reviewed source, branch `main`, and a new immutable semantic-version tag.

Land the reviewed source through the normal branch route; sign the resulting
release commit with the approved key, preserving development history. Verify the
release commit signature independently, then dry-run the existing tag publisher.
Require exact source/tag identity, branch ancestry, approved signer and executable
tree checks before publication. Independently fetch and verify the published tag.
No trust override or replacement tag is part of this procedure.

Compatible shared `cc`/`tc` releases must also be available and verified before
general consumer rollout. The combined shared candidate is
`a2227ca8195dd00fe69cc38e39c1ad110eb657b0`, with installation validation recorded
in Claude TASK-46 / WP-76; this source identity does not certify its publication.
Claude TASK-47 tracks the actual shared foundation release.

After both release boundaries pass, use the canonical project update workflow:
inspect a fresh plan, apply that exact plan within the authorized scope, then
independently verify disk truth. Preserve customized or dirty projects and record
their exact holds. Publishing source alone does not update every consumer.

## Effectiveness remains empirical

TASK-22 needs paired real product work, frozen controls and genuine reviewer
corrections. TASK-23 / WP-49 proves runtime dispatch, not improved productivity.
Choose the product/workflow and reviewer, then preserve baseline/candidate inputs,
rubrics and actual observations before evaluating adoption. Retain the baseline
on missing or unfavorable evidence. Do not synthesize review scores or promote
personal preferences from benchmark inputs.
