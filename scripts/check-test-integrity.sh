#!/usr/bin/env bash
# Refuse completion when the tests that grade the work have been modified.
#
# WHY THIS EXISTS: benchmarking (copilot-bench, 2026-08-15) found that on a task
# describing a bug that did not exist, 5 of 6 Codex runs introduced a defect into
# correct code (`>= 100` became `> 100`) and then rewrote the assertions to match --
# renaming test_ten_percent_at_100 to test_ten_percent_over_100 and adding an assertion
# for the newly broken behaviour. The test runner reported "5 passed".
#
# A pass is only evidence if the tests are unchanged. This makes that checkable.
#
# Usage:  scripts/check-test-integrity.sh [base-ref]
# Exit 0 = tests untouched.  Exit 1 = tests modified; the run is unverified.
set -euo pipefail

BASE="${1:-HEAD}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "not a git repository; cannot verify test integrity" >&2
  exit 0
fi

# Anything that defines the grade: unit tests, fixtures, and perf harnesses.
PATTERNS='(^|/)(test_[^/]*\.py|[^/]*_test\.py|[^/]*\.test\.[jt]sx?|[^/]*\.spec\.[jt]sx?)$|(^|/)tests?/'

changed=$(git diff --name-only "$BASE" 2>/dev/null || true)
changed="$changed
$(git diff --name-only --cached "$BASE" 2>/dev/null || true)
$(git ls-files --others --exclude-standard 2>/dev/null || true)"

touched=$(printf '%s\n' "$changed" | sed '/^$/d' | sort -u | grep -E "$PATTERNS" || true)

if [ -n "$touched" ]; then
  echo "TEST INTEGRITY FAILED — these files define the grade and were modified:" >&2
  printf '  %s\n' $touched >&2
  echo >&2
  echo "If the task was to write or update tests, this check does not apply --" >&2
  echo "re-run with the base ref from before that work. Otherwise the implementation" >&2
  echo "is what needs fixing, and this run must be reported as unverified." >&2
  exit 1
fi

echo "test integrity ok — no graded file was modified"
