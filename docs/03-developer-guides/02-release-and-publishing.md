# Release And Publishing

Run release fitness before publishing or declaring parity.

The [evidence and design release preparation](03-evidence-design-release.md)
records the next candidate's dependency migration, foundation-signing boundary,
clean-clone checks and remaining empirical review.

## Release Fitness

```bash
scripts/check-versions.sh
scripts/smoke-test.sh
python3 tests/test_mirror_parity.py
```

`scripts/check-versions.sh` verifies:

- `VERSION.json`
- plugin manifest version
- agent catalog version and schema
- Claude parity baseline version
- required `cc` and `tc` component versions
- capability pack manifests
- packaged QA-gate conventions; use `tc task check-qa` for actual task/source-bound completion evidence

`scripts/smoke-test.sh` runs parity tests, native hook checks, version/content
parity, generated-routing checks, agent evals, project-update scenarios and stream
validation. Upstream-dependent checks need the intended Claude checkout; set
`CLAUDE_COPILOT_ROOT` explicitly when several candidates are present. A standalone
unit run may skip upstream-dependent cases, so report skips separately.

### Parity Rules

- Describe hook behavior as implemented only when a Codex-native hook and a failable verification artifact support the claim; never cite Claude registration as Codex enforcement.
- Do not confuse Claude lifecycle hooks with the design-led product protocol.
- Do not add optional specialists globally unless the product decision changes.
- Inspect tests affected by catalog changes; edit tests only with the explicit authorization required by `AGENTS.md`.
- Do not update the mirrored Claude version without updating the baseline manifest.

## Public Release Checklist

- remove machine-specific absolute paths from shipped docs and templates
- remove personal names and emails from plugin metadata unless intentionally public
- confirm repository URLs point to the organization-owned repo
- review generated files from `setup-project.sh`
- validate the bootstrap flow from a clean clone
- run `python3 -m unittest discover -s tests -v`
- confirm the [Capability Matrix](../05-reference/01-capability-matrix.md) matches implemented skills and workflow boundaries

## Repo Ownership

This repository is intended to live under:

- `Everyone-Needs-A-Copilot/codex-copilot`

## Pre-Publish Verification

Recommended searches:

```bash
rg -n '/Users/|/Volumes/|@[A-Za-z0-9._%+-]+\\.[A-Za-z]{2,}|[A-Z][a-z]+ [A-Z][a-z]+' .
```

Then manually inspect any hits to distinguish legitimate public org metadata from accidental personal references.
