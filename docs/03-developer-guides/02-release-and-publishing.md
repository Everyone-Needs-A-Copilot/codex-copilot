# Release And Publishing

Run release fitness before publishing or declaring parity.

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
- artifact-bound QA gate conventions

`scripts/smoke-test.sh` runs parity tests, version checks, and a stream-validation sample.

### Parity Rules

- Do not describe Claude runtime hooks as implemented in Codex.
- Do not confuse Claude lifecycle hooks with the design-led product protocol.
- Do not add optional specialists globally unless the product decision changes.
- Do not update the catalog without updating tests.
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
