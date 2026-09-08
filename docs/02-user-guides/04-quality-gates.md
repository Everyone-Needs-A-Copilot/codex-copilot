# Quality Gates

Current QA uses shared **tc 2.0.0** to bind evidence to the project database,
task, registered acceptance criteria and tested source. Native routing/debug
hooks and optional design feedback do not complete QA.

## Register the acceptance contract

Implementation tasks that need verification carry `metadata.requiresQa=true`.
Register their observable acceptance criteria before implementation. For example,
adapt this `acceptance.json` to the actual project and include all relevant source,
configuration and dependency files:

```json
{
  "schemaVersion": 2,
  "criteria": [
    {"id": "C1", "expected": "Retry preserves unsaved draft text after a failed save"}
  ],
  "sources": ["src", "tests"]
}
```

Run in the target project's task database, replacing `123` with its task ID:

```bash
tc task get 123 --json
tc task contract 123 --file acceptance.json --json
```

Source scopes use canonical project-relative paths. Include product/design
authority for design work. Keep generated evidence outside source scopes, for
example in `.copilot/qa/`, so recording a result does not change what was tested.

## Capture the tested identity

`$me` stores its implementation work product and routes to `$qa`. Before running
verification, capture the identity with the same installed tc runtime that will
check and complete the task:

```bash
mkdir -p .copilot/qa
tc task evidence-identity 123 > .copilot/qa/before.txt
# Run the actual acceptance checks and preserve their artifacts.
tc task evidence-identity 123 > .copilot/qa/after.txt
cmp .copilot/qa/before.txt .copilot/qa/after.txt
```

If identity changed, capture a new baseline and rerun affected checks. The identity
includes source content, including dirty changes, new files and deletions; a commit
name alone is insufficient. Preserve the exact captured `IDENTITY:` line in the QA
work product.

## Work product contract

Store a `test` work product on the same task. The following is a template, not
passing evidence: replace every placeholder with an actual observation or the
captured identity, and repeat the criterion block for every registered criterion.

```text
Task: TASK-123
IDENTITY: <exact JSON from the captured IDENTITY line>
BASELINE: <prior source and behavior, or why a baseline is unavailable>
CRITERION: C1
EXPECTED: Retry preserves unsaved draft text after a failed save
OBSERVED: <what the acceptance check actually demonstrated>
ARTIFACT: test-run|<actual command, exit code, result and local evidence path>
UNTESTED: none
VERDICT: APPROVED
```

Use exactly one verdict for the result: `APPROVED`,
`APPROVED-WITH-MINOR-FIXES`, or `REJECTED`. Both passing verdicts require every
required criterion to be met; missing or untested required behavior requires
rejection. Criterion IDs and `EXPECTED:` text must match the registered contract.

Accepted artifact types are `test-run`, `file-check`, `diff-check`,
`screenshot-check`, `a11y-check` and `design-fidelity-check`. Record a failable check
and its observed result or an inspectable local artifact. QA must judge whether
the evidence demonstrates the behavior: hashes, field presence, a detector scan
and `cc design report` readiness do not establish behavioral truth.

Store the completed packet from a file:

```bash
tc wp store --task 123 --type test --title "Draft retry verification" \
  --file .copilot/qa/result.txt --json
```

## Inspect and complete

```bash
tc task check-qa 123 --json
scripts/copilot-gate.sh --task 123
tc task update 123 --status completed --json
```

`check-qa` inspects the current evidence; completion also rejects unfinished task
dependencies. The task authority rejects wrong-task, stale, incomplete or
conflicting evidence and rechecks source identity on completion. Metadata such as
`qaStatus` and `qaWpId` may index the evidence; it never grants approval by itself.
Once QA is required, it cannot be removed to bypass the gate.

Current setup installs `scripts/copilot-gate.sh` as a project-local executable
copy. Running it without `--task` inspects all QA-required tasks in that database.

## Historical compatibility

The native helper retains explicitly labeled artifact-only inspection when an
older tc lacks `check-qa`; this is not current tc 2 validation. Upgrade through the
verified shared installation before claiming current completion support. An
authoritative rejection never falls back to older work products.

Completed historical records remain historical. Pending work needs a registered
contract and fresh identity-bound verification; neither replayed approval tokens
nor rewriting old evidence is a migration. See [design quality](design-quality.md)
for the additional review and rendered-evidence workflow.
