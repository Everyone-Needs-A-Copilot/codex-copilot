#!/usr/bin/env bash
# Exercises update-project.sh against disposable scratch copies -- never a
# real product repo. Fails loudly (non-zero exit) on any regression so it is
# safe to wire into scripts/smoke-test.sh rather than being dead theatre.
#
# Scenarios:
#   1. fresh install    -- setup-project.sh then update-project.sh is a no-op
#   2. idempotence      -- a second update-project.sh run changes nothing
#   3. stale content     -- a hand-edited locked file is repaired in place
#   4. project ownership -- an owner: project file survives a stale edit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILURES=0
fail() {
  echo "FAIL: $1" >&2
  FAILURES=$((FAILURES + 1))
}
pass() {
  echo "PASS: $1"
}

SCRATCH_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "${SCRATCH_ROOT}"
}
trap cleanup EXIT

PROJECT_DIR="${SCRATCH_ROOT}/scratch-project"
mkdir -p "${PROJECT_DIR}"
git -C "${PROJECT_DIR}" init -q

SAMPLE_LOCKED_FILE="plugins/codex-copilot/skills/protocol/SKILL.md"
SAMPLE_LOCKED_FILE2="plugins/codex-copilot/agent-catalog.json"

echo "=== Scenario 1: fresh install ==="
"${SCRIPT_DIR}/setup-project.sh" --project "${PROJECT_DIR}" --name scratch-project >/dev/null

if [[ ! -f "${PROJECT_DIR}/copilot.lock.json" ]]; then
  UPDATE_OUTPUT_1="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
  echo "${UPDATE_OUTPUT_1}"
  # The very first update run legitimately does bookkeeping (writes
  # copilot.lock.json, refreshes .codex-copilot.json tracking fields) even
  # though the plugin content itself was just copied verbatim by
  # setup-project.sh -- what must be zero is actual content repair.
  UPDATED_COUNT="$(echo "${UPDATE_OUTPUT_1}" | grep "^Updated " | grep -oE '[0-9]+$')"
  ADDED_COUNT="$(echo "${UPDATE_OUTPUT_1}" | grep "^Added " | grep -oE '[0-9]+$')"
  if [[ "${UPDATED_COUNT}" == "0" && "${ADDED_COUNT}" == "0" ]]; then
    pass "fresh install: first update-project.sh run repairs 0 files (plugin was just copied verbatim)"
  else
    fail "fresh install: first update-project.sh run should not need to repair any framework file (updated=${UPDATED_COUNT} added=${ADDED_COUNT})"
  fi
else
  fail "fresh install: setup-project.sh should not have written copilot.lock.json itself"
fi

SNAPSHOT_A="${SCRATCH_ROOT}/snapshot-a.txt"
(cd "${PROJECT_DIR}" && find plugins/codex-copilot scripts/copilot-gate.sh -type f -exec shasum {} \; | sort) > "${SNAPSHOT_A}"

echo "=== Scenario 2: idempotence (second run is a no-op) ==="
UPDATE_OUTPUT_2="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
echo "${UPDATE_OUTPUT_2}"
SNAPSHOT_B="${SCRATCH_ROOT}/snapshot-b.txt"
(cd "${PROJECT_DIR}" && find plugins/codex-copilot scripts/copilot-gate.sh -type f -exec shasum {} \; | sort) > "${SNAPSHOT_B}"

if echo "${UPDATE_OUTPUT_2}" | grep -q "Result: no changes needed" && diff -q "${SNAPSHOT_A}" "${SNAPSHOT_B}" >/dev/null; then
  pass "idempotence: second run reports no changes needed and byte-for-byte diff is clean"
else
  fail "idempotence: second run mutated the tree or did not report no-changes-needed"
fi

echo "=== Scenario 3: stale content is repaired ==="
ORIGINAL_CONTENT="$(cat "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}")"
printf '%s\nSTALE DRIFT MARKER (not a released version)\n' "${ORIGINAL_CONTENT}" > "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}"
python3 - "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE2}" <<'PY'
import json
import sys
path = sys.argv[1]
data = json.loads(open(path).read())
data["__scratch_drift_marker__"] = "bytes-from-an-intermediate-commit"
open(path, "w").write(json.dumps(data))
PY

UPDATE_OUTPUT_3="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
echo "${UPDATE_OUTPUT_3}"

REPAIRED_1=$(diff -q "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}" "${FRAMEWORK_ROOT}/${SAMPLE_LOCKED_FILE}" >/dev/null 2>&1 && echo yes || echo no)
REPAIRED_2=$(diff -q "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE2}" "${FRAMEWORK_ROOT}/${SAMPLE_LOCKED_FILE2}" >/dev/null 2>&1 && echo yes || echo no)

if [[ "${REPAIRED_1}" == "yes" && "${REPAIRED_2}" == "yes" ]]; then
  pass "stale content: both drifted files (text + JSON) were repaired to match framework source"
else
  fail "stale content: drifted file(s) were not repaired (text=${REPAIRED_1} json=${REPAIRED_2})"
fi

echo "=== Scenario 4: ownership: project content survives ==="
python3 - "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
assert text.startswith("---"), "fixture assumption: SKILL.md has YAML frontmatter"
end = text.find("\n---", 3)
frontmatter, rest = text[:end], text[end:]
frontmatter += "\nowner: project"
path.write_text(frontmatter + rest + "\nPROJECT-OWNED CUSTOMIZATION (must survive updates)\n")
PY
PROJECT_OWNED_CONTENT="$(cat "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}")"

UPDATE_OUTPUT_4="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
echo "${UPDATE_OUTPUT_4}"

AFTER_CONTENT="$(cat "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}")"
if [[ "${PROJECT_OWNED_CONTENT}" == "${AFTER_CONTENT}" ]] && echo "${UPDATE_OUTPUT_4}" | grep -q "Preserved (ownership: project"; then
  pass "project ownership: owner: project frontmatter protected the customization from being overwritten"
else
  fail "project ownership: an owner: project file was overwritten -- this is the one unacceptable outcome"
fi

echo "=== Scenario 5: setup-project.sh re-run over an existing install repairs instead of refusing ==="
SETUP_RERUN_OUTPUT="$("${SCRIPT_DIR}/setup-project.sh" --project "${PROJECT_DIR}" --name scratch-project 2>&1)"
SETUP_RERUN_STATUS=$?
if [[ ${SETUP_RERUN_STATUS} -eq 0 ]] && [[ "${AFTER_CONTENT}" == "$(cat "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}")" ]]; then
  pass "setup-project.sh re-run over an existing install exits 0 and still preserves ownership: project content"
else
  fail "setup-project.sh re-run over an existing install failed or disturbed project-owned content (exit=${SETUP_RERUN_STATUS})"
fi

echo
if [[ "${FAILURES}" -eq 0 ]]; then
  echo "verify-update-project.sh: all scenarios passed"
  exit 0
else
  echo "verify-update-project.sh: ${FAILURES} scenario(s) FAILED" >&2
  exit 1
fi
