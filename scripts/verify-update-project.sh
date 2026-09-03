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
#   5. setup.sh re-run repairs an existing install instead of refusing
#   6. org plugin: --no-org-plugin (and no config/sibling) leaves a fresh
#      install byte-for-byte identical to a plain base-only install
#   7. org plugin: explicit --org-plugin installs alongside the base plugin
#   8. org plugin: a later plain update-project.sh run (no flag) keeps it
#      updated from the orgPluginSourcePath recorded in .codex-copilot.json,
#      including repairing hand-edited drift
#   9. org plugin: --no-org-plugin suppresses sync without uninstalling it
#  10. mode preservation: a hand-flipped executable bit is detected and
#      repaired on the next run, and the run reports it rather than saying
#      "no changes needed"
#  11. auto-detect fires against a codex-organization-named sibling (the
#      pinned-mirror tier layout), not just codex-copilot-internal
#  12. a sibling whose only manifest is named "codex-copilot" is never
#      mistaken for the org plugin (base-plugin-name collision guard)
#
# Scenarios 6-12 use a synthetic fixture plugin under the scratch root --
# never the real codex-copilot-internal sibling repo -- so this script
# stays meaningful and portable on a machine with no organization repo
# checked out.

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

# Scenarios 1-5 pass --no-org-plugin throughout so their assertions stay
# scoped to the base plugin and independent of whatever organization repo
# state happens to exist on the machine running this script. Organization
# plugin behavior is exercised separately in scenarios 6-9 below.
echo "=== Scenario 1: fresh install ==="
"${SCRIPT_DIR}/setup-project.sh" --project "${PROJECT_DIR}" --name scratch-project --no-org-plugin >/dev/null

if [[ ! -f "${PROJECT_DIR}/copilot.lock.json" ]]; then
  UPDATE_OUTPUT_1="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}" --no-org-plugin)"
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
UPDATE_OUTPUT_2="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}" --no-org-plugin)"
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

UPDATE_OUTPUT_3="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}" --no-org-plugin)"
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

UPDATE_OUTPUT_4="$("${SCRIPT_DIR}/update-project.sh" --project "${PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}" --no-org-plugin)"
echo "${UPDATE_OUTPUT_4}"

AFTER_CONTENT="$(cat "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}")"
if [[ "${PROJECT_OWNED_CONTENT}" == "${AFTER_CONTENT}" ]] && echo "${UPDATE_OUTPUT_4}" | grep -q "Preserved (ownership: project"; then
  pass "project ownership: owner: project frontmatter protected the customization from being overwritten"
else
  fail "project ownership: an owner: project file was overwritten -- this is the one unacceptable outcome"
fi

echo "=== Scenario 5: setup-project.sh re-run over an existing install repairs instead of refusing ==="
SETUP_RERUN_OUTPUT="$("${SCRIPT_DIR}/setup-project.sh" --project "${PROJECT_DIR}" --name scratch-project --no-org-plugin 2>&1)"
SETUP_RERUN_STATUS=$?
if [[ ${SETUP_RERUN_STATUS} -eq 0 ]] && [[ "${AFTER_CONTENT}" == "$(cat "${PROJECT_DIR}/${SAMPLE_LOCKED_FILE}")" ]]; then
  pass "setup-project.sh re-run over an existing install exits 0 and still preserves ownership: project content"
else
  fail "setup-project.sh re-run over an existing install failed or disturbed project-owned content (exit=${SETUP_RERUN_STATUS})"
fi

# Scenario 6 deliberately uses --no-org-plugin rather than relying on the
# absence of a sibling org repo: auto-detection (resolution order item 3)
# is inherently machine-dependent -- this repo's own dev machines may well
# have codex-copilot-internal checked out as a sibling -- so a portable,
# deterministic regression check exercises suppression explicitly instead.
# The auto-detect path itself is exercised by hand against the real sibling
# where one exists (see docs/01-setup/02-setup-project.md).
echo "=== Scenario 6: --no-org-plugin produces a base-only install with no orgPlugin* metadata ==="
NOORG_PROJECT_DIR="${SCRATCH_ROOT}/noorg-project"
mkdir -p "${NOORG_PROJECT_DIR}"
git -C "${NOORG_PROJECT_DIR}" init -q
"${SCRIPT_DIR}/setup-project.sh" --project "${NOORG_PROJECT_DIR}" --name noorg-project --no-org-plugin >/dev/null

PLUGIN_ENTRY_COUNT="$(find "${NOORG_PROJECT_DIR}/plugins" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
SKILLS_BRIDGE_COUNT="$(find "${NOORG_PROJECT_DIR}/.claude/skills" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"

if [[ "${PLUGIN_ENTRY_COUNT}" == "1" ]] \
  && [[ "${SKILLS_BRIDGE_COUNT}" == "1" ]] \
  && ! grep -q "orgPlugin" "${NOORG_PROJECT_DIR}/.codex-copilot.json" \
  && python3 -c "import json,sys; sys.exit(0 if len(json.load(open(sys.argv[1]))['plugins'])==1 else 1)" "${NOORG_PROJECT_DIR}/.agents/plugins/marketplace.json"; then
  pass "--no-org-plugin: exactly one plugins/ entry, one skills bridge, no orgPlugin* metadata anywhere"
else
  fail "--no-org-plugin: an organization plugin artifact leaked into a suppressed install"
fi

echo "=== Scenario 7: explicit --org-plugin installs alongside the base plugin ==="
ORG_FIXTURE_SOURCE="${SCRATCH_ROOT}/org-plugin-fixture"
mkdir -p "${ORG_FIXTURE_SOURCE}/.codex-plugin" "${ORG_FIXTURE_SOURCE}/skills/demo-skill/scripts"
cat > "${ORG_FIXTURE_SOURCE}/.codex-plugin/plugin.json" <<'JSON'
{
  "name": "scratch-org-plugin",
  "version": "1.0.0",
  "description": "Synthetic organization plugin fixture for verify-update-project.sh",
  "skills": "./skills/"
}
JSON
cat > "${ORG_FIXTURE_SOURCE}/skills/demo-skill/SKILL.md" <<'MD'
---
name: demo-skill
---
# Demo Skill

Synthetic fixture skill content, version 1.
MD
# A source file with the executable bit set, to prove mode -- not just
# content -- is propagated. `git`'s own working tree only tracks the
# owner-exec bit, so 0755 (not some other combination) is the meaningful
# fixture value here.
cat > "${ORG_FIXTURE_SOURCE}/skills/demo-skill/scripts/demo-script.sh" <<'SH'
#!/usr/bin/env bash
echo "synthetic fixture executable, version 1"
SH
chmod 755 "${ORG_FIXTURE_SOURCE}/skills/demo-skill/scripts/demo-script.sh"
chmod 644 "${ORG_FIXTURE_SOURCE}/skills/demo-skill/SKILL.md"

ORG_PROJECT_DIR="${SCRATCH_ROOT}/org-project"
mkdir -p "${ORG_PROJECT_DIR}"
git -C "${ORG_PROJECT_DIR}" init -q
"${SCRIPT_DIR}/setup-project.sh" \
  --project "${ORG_PROJECT_DIR}" \
  --name org-project \
  --org-plugin "${ORG_FIXTURE_SOURCE}" \
  >/dev/null

ORG_PLUGIN_INSTALLED_MANIFEST="${ORG_PROJECT_DIR}/plugins/scratch-org-plugin/.codex-plugin/plugin.json"
ORG_PLUGIN_INSTALLED_SKILL="${ORG_PROJECT_DIR}/plugins/scratch-org-plugin/skills/demo-skill/SKILL.md"
ORG_PLUGIN_INSTALLED_SCRIPT="${ORG_PROJECT_DIR}/plugins/scratch-org-plugin/skills/demo-skill/scripts/demo-script.sh"
ORG_SKILLS_BRIDGE="${ORG_PROJECT_DIR}/.claude/skills/scratch-org-plugin"

mode_of() { stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1"; }

if [[ -f "${ORG_PLUGIN_INSTALLED_MANIFEST}" ]] \
  && diff -q "${ORG_PLUGIN_INSTALLED_SKILL}" "${ORG_FIXTURE_SOURCE}/skills/demo-skill/SKILL.md" >/dev/null 2>&1 \
  && [[ -L "${ORG_SKILLS_BRIDGE}" ]] \
  && [[ -d "${ORG_PROJECT_DIR}/plugins/codex-copilot" ]] \
  && python3 -c "
import json, sys
cfg = json.load(open(sys.argv[1]))
assert cfg.get('orgPluginName') == 'scratch-org-plugin', cfg
assert cfg.get('orgPluginSourcePath') == sys.argv[2], cfg
assert cfg.get('pluginPath') == './plugins/codex-copilot', cfg
" "${ORG_PROJECT_DIR}/.codex-copilot.json" "${ORG_FIXTURE_SOURCE}"; then
  pass "explicit --org-plugin: fixture plugin installed to plugins/scratch-org-plugin alongside plugins/codex-copilot, skill bridge linked, .codex-copilot.json records orgPluginSourcePath"
else
  fail "explicit --org-plugin: install did not land as expected (see files under ${ORG_PROJECT_DIR})"
fi

if [[ "$(mode_of "${ORG_PLUGIN_INSTALLED_SCRIPT}")" == "755" ]] && [[ "$(mode_of "${ORG_PLUGIN_INSTALLED_SKILL}")" == "644" ]]; then
  pass "explicit --org-plugin, fresh install: 755 source installs as 755, 644 source installs as 644 (setup-project.sh's cp -R + mode normalization)"
else
  fail "explicit --org-plugin, fresh install: mode not propagated correctly (script=$(mode_of "${ORG_PLUGIN_INSTALLED_SCRIPT}") skill=$(mode_of "${ORG_PLUGIN_INSTALLED_SKILL}"), want 755/644)"
fi

echo "=== Scenario 8: a later plain update-project.sh run keeps the org plugin updated from the recorded config key ==="
printf '\nSTALE ORG DRIFT (not a released fixture version)\n' >> "${ORG_PLUGIN_INSTALLED_SKILL}"

UPDATE_OUTPUT_8="$("${SCRIPT_DIR}/update-project.sh" --project "${ORG_PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
echo "${UPDATE_OUTPUT_8}"

if diff -q "${ORG_PLUGIN_INSTALLED_SKILL}" "${ORG_FIXTURE_SOURCE}/skills/demo-skill/SKILL.md" >/dev/null 2>&1 \
  && echo "${UPDATE_OUTPUT_8}" | grep -q "recorded orgPluginSourcePath in .codex-copilot.json"; then
  pass "plain re-run (no --org-plugin): drifted org plugin file repaired from the config-recorded source, base plugin untouched"
else
  fail "plain re-run did not repair org plugin drift from the recorded orgPluginSourcePath"
fi

UPDATE_OUTPUT_8B="$("${SCRIPT_DIR}/update-project.sh" --project "${ORG_PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
if echo "${UPDATE_OUTPUT_8B}" | grep -q "Result: no changes needed"; then
  pass "org plugin idempotence: a second plain re-run reports no changes needed"
else
  fail "org plugin idempotence: a second plain re-run still reported changes"
fi

echo "=== Scenario 9: --no-org-plugin suppresses sync without uninstalling an already-installed org plugin ==="
UPDATE_OUTPUT_9="$("${SCRIPT_DIR}/update-project.sh" --project "${ORG_PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}" --no-org-plugin)"
echo "${UPDATE_OUTPUT_9}"

if echo "${UPDATE_OUTPUT_9}" | grep -q "Org plugin: suppressed via --no-org-plugin" \
  && [[ -f "${ORG_PLUGIN_INSTALLED_MANIFEST}" ]] \
  && [[ -L "${ORG_SKILLS_BRIDGE}" ]]; then
  pass "--no-org-plugin: sync suppressed this run, previously-installed org plugin files left in place"
else
  fail "--no-org-plugin: either sync was not suppressed or the previously-installed org plugin was disturbed"
fi

echo "=== Scenario 10: a hand-flipped executable bit is detected, repaired, and reported (not silently 'unchanged') ==="
chmod 644 "${ORG_PLUGIN_INSTALLED_SCRIPT}"
if [[ "$(mode_of "${ORG_PLUGIN_INSTALLED_SCRIPT}")" != "755" ]]; then
  UPDATE_OUTPUT_10="$("${SCRIPT_DIR}/update-project.sh" --project "${ORG_PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
  echo "${UPDATE_OUTPUT_10}"

  if [[ "$(mode_of "${ORG_PLUGIN_INSTALLED_SCRIPT}")" == "755" ]] \
    && echo "${UPDATE_OUTPUT_10}" | grep -q "Org plugin -- Mode repaired (content matched, executable bit corrected): 1" \
    && echo "${UPDATE_OUTPUT_10}" | grep -q "  - skills/demo-skill/scripts/demo-script.sh" \
    && echo "${UPDATE_OUTPUT_10}" | grep -q "Result: changes applied"; then
    pass "mode drift: hand-flipped 644 was detected, chmod'd back to 755, and reported as a mode repair (content untouched, run does not claim 'no changes needed')"
  else
    fail "mode drift: executable bit was not repaired and/or not reported (mode=$(mode_of "${ORG_PLUGIN_INSTALLED_SCRIPT}"))"
  fi
else
  fail "mode drift fixture: chmod 644 did not actually flip the bit -- test setup is broken"
fi

UPDATE_OUTPUT_10B="$("${SCRIPT_DIR}/update-project.sh" --project "${ORG_PROJECT_DIR}" --framework-root "${FRAMEWORK_ROOT}")"
if echo "${UPDATE_OUTPUT_10B}" | grep -q "Result: no changes needed"; then
  pass "mode drift idempotence: a second plain re-run after the repair reports no changes needed"
else
  fail "mode drift idempotence: a second plain re-run after the repair still reported changes"
fi

# Scenarios 11-12 build a synthetic ecosystem layout under the scratch root
# to prove auto-detect works against the PINNED-MIRROR sibling naming
# (<parent>/codex-organization, per ~/.config/copilot/copilot.layers.yml's
# tier id), not just the dev-adjacent-clone naming
# (<parent>/codex-copilot-internal) already covered by scenarios 6-10 --
# and that a base-plugin-name collision is never mistaken for an org
# plugin. A symlink stands in for the framework root itself (`cd` through a
# symlink preserves the logical path in `pwd`, so dirname(FRAMEWORK_ROOT)
# resolves to the fake ecosystem directory, not the real one) -- this repo
# is never duplicated, only re-pointed-to.
echo "=== Scenario 11: auto-detect fires against a codex-organization-named sibling (pinned-mirror tier layout), not just codex-copilot-internal ==="
FAKE_ECOSYSTEM="${SCRATCH_ROOT}/fake-ecosystem"
mkdir -p "${FAKE_ECOSYSTEM}"
ln -s "${FRAMEWORK_ROOT}" "${FAKE_ECOSYSTEM}/codex-foundation"
FAKE_FRAMEWORK_ROOT="${FAKE_ECOSYSTEM}/codex-foundation"

mkdir -p "${FAKE_ECOSYSTEM}/codex-organization/plugins/scratch-org-plugin"
cp -R "${ORG_FIXTURE_SOURCE}/." "${FAKE_ECOSYSTEM}/codex-organization/plugins/scratch-org-plugin/"

TIER_PROJECT_DIR="${SCRATCH_ROOT}/tier-project"
mkdir -p "${TIER_PROJECT_DIR}"
git -C "${TIER_PROJECT_DIR}" init -q
"${SCRIPT_DIR}/setup-project.sh" \
  --project "${TIER_PROJECT_DIR}" \
  --name tier-project \
  --framework-root "${FAKE_FRAMEWORK_ROOT}" \
  > "${SCRATCH_ROOT}/tier-project-setup.log" 2>&1

TIER_INSTALLED_SCRIPT="${TIER_PROJECT_DIR}/plugins/scratch-org-plugin/skills/demo-skill/scripts/demo-script.sh"
if grep -q "Org plugin: auto-detected sibling (${FAKE_ECOSYSTEM}/codex-organization/plugins/scratch-org-plugin)" "${SCRATCH_ROOT}/tier-project-setup.log" \
  && [[ -f "${TIER_INSTALLED_SCRIPT}" ]] \
  && [[ "$(mode_of "${TIER_INSTALLED_SCRIPT}")" == "755" ]]; then
  pass "mirror-tier layout: no --org-plugin flag, no recorded config -- auto-detect found the org plugin under a codex-organization-named sibling by manifest, installed with mode 755 intact"
else
  fail "mirror-tier layout: auto-detect did not fire against a codex-organization-named sibling (see ${SCRATCH_ROOT}/tier-project-setup.log)"
fi

echo "=== Scenario 12: a sibling whose only manifest is named codex-copilot is never mistaken for the org plugin ==="
COLLISION_ECOSYSTEM="${SCRATCH_ROOT}/collision-ecosystem"
mkdir -p "${COLLISION_ECOSYSTEM}"
ln -s "${FRAMEWORK_ROOT}" "${COLLISION_ECOSYSTEM}/codex-foundation"
mkdir -p "${COLLISION_ECOSYSTEM}/codex-copilot-internal/plugins"
cp -R "${FRAMEWORK_ROOT}/plugins/codex-copilot" "${COLLISION_ECOSYSTEM}/codex-copilot-internal/plugins/codex-copilot"

COLLISION_PROJECT_DIR="${SCRATCH_ROOT}/collision-project"
mkdir -p "${COLLISION_PROJECT_DIR}"
git -C "${COLLISION_PROJECT_DIR}" init -q
"${SCRIPT_DIR}/setup-project.sh" \
  --project "${COLLISION_PROJECT_DIR}" \
  --name collision-project \
  --framework-root "${COLLISION_ECOSYSTEM}/codex-foundation" \
  > "${SCRATCH_ROOT}/collision-project-setup.log" 2>&1

COLLISION_PLUGIN_COUNT="$(find "${COLLISION_PROJECT_DIR}/plugins" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
if grep -q "Org plugin: none available" "${SCRATCH_ROOT}/collision-project-setup.log" \
  && [[ "${COLLISION_PLUGIN_COUNT}" == "1" ]]; then
  pass "base-plugin-name collision: a sibling whose only manifest is named codex-copilot resolves to no org plugin, never installed as one"
else
  fail "base-plugin-name collision: a codex-copilot-named manifest was mistakenly treated as the org plugin (see ${SCRATCH_ROOT}/collision-project-setup.log)"
fi

echo
if [[ "${FAILURES}" -eq 0 ]]; then
  echo "verify-update-project.sh: all scenarios passed"
  exit 0
else
  echo "verify-update-project.sh: ${FAILURES} scenario(s) FAILED" >&2
  exit 1
fi
