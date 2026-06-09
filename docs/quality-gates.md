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
  "verifiedAt": "2026-06-09T00:00:00Z"
}
```

## Work Product Contract

`$me` stores a `code` work product.

`$qa` stores a `test` work product with one verdict token:

```text
VERDICT: APPROVED
VERDICT: APPROVED-WITH-MINOR-FIXES
VERDICT: REJECTED
```

## Inspection

Run:

```bash
scripts/copilot-gate.sh
```

or check one task:

```bash
scripts/copilot-gate.sh --task 123
```

The script fails when a QA-required task has no approved metadata and no approved test work product.

## Boundary

This is not a hidden runtime hook. It is an explicit Codex-native gate that agents, scripts, and tests can inspect.
