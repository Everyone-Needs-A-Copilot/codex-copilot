# Codex QA Gate

Claude Copilot uses runtime hooks to block implementation closure until QA passes. Codex Copilot substitutes that with explicit task state, work products, and tests.

## Task Metadata

Implementation tasks that need verification should carry:

```json
{
  "requiresQa": true,
  "qaStatus": "pending"
}
```

After QA approval, record:

```json
{
  "requiresQa": true,
  "qaStatus": "approved",
  "qaWpId": 123,
  "qaArtifact": "test-run|pytest tests/ exit=0 \"47 passed\"",
  "verifiedAt": "2026-06-09T00:00:00Z"
}
```

## Work Product Contract

`$me` stores a `code` work product.

`$qa` stores a `test` work product with one artifact marker and one verdict token:

```text
ARTIFACT: test-run|pytest tests/ exit=0 "47 passed"
VERDICT: APPROVED
VERDICT: APPROVED-WITH-MINOR-FIXES
VERDICT: REJECTED
```

Passing verdicts are only valid when paired with an external artifact. A bare
`VERDICT: APPROVED` does not pass `scripts/copilot-gate.sh`.

Accepted artifact marker types:

- `test-run`: a failable command, exit code, and useful output excerpt
- `file-check`: a file exists in the expected shape
- `diff-check`: expected and actual values match
- `screenshot-check`: screenshot or visual inspection evidence for UI work
- `a11y-check`: keyboard, focus, semantic, or automated accessibility evidence
- `design-fidelity-check`: comparison against `SOUL.md`, UX/UI specs, or design work products

## Inspection

Run:

```bash
scripts/copilot-gate.sh
```

or check one task:

```bash
scripts/copilot-gate.sh --task 123
```

The script fails when a QA-required task has no approved metadata with `qaArtifact`
and no approved test work product with a valid `ARTIFACT:` marker.

## Boundary

This is not a hidden runtime hook. It is an explicit Codex-native gate that agents, scripts, and tests can inspect.
