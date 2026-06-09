# Release Fitness

Run release fitness before publishing or declaring parity.

## Checks

```bash
scripts/check-versions.sh
scripts/smoke-test.sh
python3 tests/test_mirror_parity.py
```

`scripts/check-versions.sh` verifies:

- `VERSION.json`
- plugin manifest version
- agent catalog version
- Claude parity baseline version
- required `cc` and `tc` component versions

`scripts/smoke-test.sh` runs parity tests, version checks, and a stream-validation sample.

## Parity Rules

- Do not describe Claude runtime hooks as implemented in Codex.
- Do not add optional specialists globally unless the product decision changes.
- Do not update the catalog without updating tests.
- Do not update the mirrored Claude version without updating the baseline manifest.
