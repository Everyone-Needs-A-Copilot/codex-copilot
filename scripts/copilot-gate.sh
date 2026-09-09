#!/usr/bin/env bash
# Inspect QA-required tasks using the same tc predicate that gates completion.
# Passing evidence includes VERDICT: APPROVED (or APPROVED-WITH-MINOR-FIXES)
# and ARTIFACT: test-run|... (also file/diff/screenshot/a11y/design-fidelity-check).
set -euo pipefail
TC="${CODEX_COPILOT_TC:-tc}"
TASK_ID=""
case "${1:-}" in
  --task) TASK_ID="${2:?--task requires an ID}"; shift 2 ;;
  --help|-h)
    echo "Usage: scripts/copilot-gate.sh [--task TASK_ID]"
    echo "Requires tc task check-qa; task-bound ARTIFACT and VERDICT evidence is authoritative."
    exit 0 ;;
esac
[[ $# -eq 0 ]] || { echo "Unexpected arguments" >&2; exit 2; }
command -v "$TC" >/dev/null || { echo "copilot-gate: tc unavailable" >&2; exit 2; }
command -v jq >/dev/null || { echo "copilot-gate: jq unavailable" >&2; exit 2; }
if [[ -n "$TASK_ID" ]]; then
  TASKS="$("$TC" task get "$TASK_ID" --json | jq -ce '[.]')"
else
  TASKS="$("$TC" task list --json)"
fi
IDS="$(jq -er '
  if type != "array" then error("invalid task list") else . end |
  [.[] | . as $t |
    (.metadata // {} | if type == "string" then fromjson else . end) as $m |
    if ($m | type) != "object" then error("invalid task metadata") else . end |
    select($m.requiresQa == true) | $t.id] | map(tostring) | join("\n")
' <<< "$TASKS")"
checked=0
failed=0
while IFS= read -r id; do
  [[ -n "$id" ]] || continue
  checked=$((checked + 1))
  if ! result="$("$TC" task check-qa "$id" --json)" ||
     ! jq -e --arg id "$id" '.approved == true and (.task_id | tostring) == $id and (.work_product_id | type) == "number"' <<< "$result" >/dev/null; then
    echo "TASK-$id: QA gate failed or returned an invalid response"
    failed=1
  fi
done <<< "$IDS"
[[ "$failed" -eq 0 ]] || { echo "QA gate failed" >&2; exit 1; }
echo "QA gate passed ($checked QA-required task(s) checked)"
