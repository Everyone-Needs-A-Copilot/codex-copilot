#!/usr/bin/env bash
# Shared organization-plugin resolution for setup-project.sh and
# update-project.sh. Both scripts source this file instead of each
# reimplementing the same precedence rules.
#
# Resolution order (highest precedence first):
#   1. Explicit --org-plugin PATH
#   2. orgPluginSourcePath recorded in the project's .codex-copilot.json
#      (so a later plain run keeps an already-installed org plugin updated
#      without the flag being re-passed)
#   3. Auto-detected sibling: FRAMEWORK_ROOT's parent directory is searched
#      for a small list of KNOWN sibling directory names (below), and each
#      one found is searched for an org plugin BY MANIFEST --
#      plugins/*/.codex-plugin/plugin.json -- never by hardcoding the org
#      repo's own directory name a second time. This matters because the
#      same org repo is checked out under different directory names in
#      different consumption paths:
#        - a dev-adjacent clone:   <parent>/codex-copilot-internal
#        - a pinned-mirror tier:   <parent>/codex-organization
#          (~/.copilot/mirrors/codex-foundation's sibling tier directory is
#          named after the TIER ID in copilot.layers.yml, "codex-
#          organization" -- NOT the repo name "codex-copilot-internal".
#          Matching only the repo name, as this resolution originally did,
#          can never fire in that real consumer path.)
#      A manifest named literally "codex-copilot" is never a valid match
#      (an org-adjacent repo vendors its own copy of the base plugin for
#      its own project setup -- e.g. codex-copilot-internal's own
#      plugins/codex-copilot/ -- and installing that as "the org plugin"
#      would collide with the base plugin's own install path). More than
#      one remaining candidate under a given sibling is ambiguous and is
#      skipped with a warning, never guessed.
#   4. --no-org-plugin suppresses all of the above and is checked first,
#      short-circuiting the rest of the resolution.
#
# No flag, no recorded config key, and no sibling repo present resolves to
# nothing -- this is what keeps a fresh install byte-for-byte identical to
# behavior before organization-plugin support existed.
#
# Callers must set before calling codex_resolve_org_plugin_source:
#   FRAMEWORK_ROOT     - absolute path to the codex-copilot framework root
#   ORG_PLUGIN_ARG      - value of --org-plugin, or "" if not given
#   NO_ORG_PLUGIN       - 1 if --no-org-plugin was given, else 0
#   CODEX_CONFIG_PATH   - path to the project's .codex-copilot.json (may not
#                         exist yet -- treated as "no recorded key" if so)
#
# codex_resolve_org_plugin_source sets on return:
#   ORG_PLUGIN_SOURCE      - absolute path to a valid org plugin directory
#                            (one containing .codex-plugin/plugin.json), or ""
#   ORG_PLUGIN_SOURCE_DESC - human-readable description of how it was
#                            resolved (or why nothing was resolved)
#
# An explicit --org-plugin that fails validation is a hard error (exit 1):
# the user asked for a specific path and it is wrong. A recorded config key
# or an auto-detected sibling that fails validation is a soft skip (warning
# to stderr, resolution continues/stops with ORG_PLUGIN_SOURCE=""): the
# machine state changed since the last run and should not abort an
# otherwise-routine update.

# Known sibling directory-name conventions to search for an org plugin,
# relative to FRAMEWORK_ROOT's parent. See the module-level comment above
# for why there are two.
_org_plugin_candidate_roots() {
  local parent="$1"
  printf '%s\n' \
    "${parent}/codex-copilot-internal" \
    "${parent}/codex-organization"
}

# Finds an org plugin under a candidate root BY MANIFEST
# (plugins/*/.codex-plugin/plugin.json), never by directory name. Prints
# the resolved plugin directory on stdout if exactly one valid candidate
# is found; prints nothing if none are found; warns to stderr (and prints
# nothing to stdout) if more than one remains -- ambiguous, never guessed.
_org_plugin_from_manifests() {
  local root="$1"
  local -a matches=()
  local manifest name
  shopt -s nullglob
  for manifest in "${root}"/plugins/*/.codex-plugin/plugin.json; do
    name="$(python3 -c "
import json, sys
try:
    print(json.load(open(sys.argv[1])).get('name') or '')
except Exception:
    print('')
" "${manifest}" 2>/dev/null || true)"
    if [[ -n "${name}" && "${name}" != "codex-copilot" ]]; then
      matches+=("$(cd "$(dirname "${manifest}")/.." && pwd)")
    fi
  done
  shopt -u nullglob
  if [[ "${#matches[@]}" -eq 1 ]]; then
    printf '%s\n' "${matches[0]}"
  elif [[ "${#matches[@]}" -gt 1 ]]; then
    echo "Warning: multiple candidate organization plugin manifests found under ${root}/plugins -- ambiguous, skipping auto-detect there: ${matches[*]}" >&2
  fi
}

codex_resolve_org_plugin_source() {
  ORG_PLUGIN_SOURCE=""
  ORG_PLUGIN_SOURCE_DESC="none available (no --org-plugin, no recorded orgPluginSourcePath, no auto-detected sibling)"

  if [[ "${NO_ORG_PLUGIN:-0}" -eq 1 ]]; then
    ORG_PLUGIN_SOURCE_DESC="suppressed via --no-org-plugin"
    return 0
  fi

  if [[ -n "${ORG_PLUGIN_ARG:-}" ]]; then
    if [[ ! -d "${ORG_PLUGIN_ARG}" ]]; then
      echo "--org-plugin path does not exist: ${ORG_PLUGIN_ARG}" >&2
      exit 1
    fi
    local resolved
    resolved="$(cd "${ORG_PLUGIN_ARG}" && pwd)"
    if [[ ! -f "${resolved}/.codex-plugin/plugin.json" ]]; then
      echo "--org-plugin path is not a valid plugin (missing .codex-plugin/plugin.json): ${resolved}" >&2
      exit 1
    fi
    ORG_PLUGIN_SOURCE="${resolved}"
    ORG_PLUGIN_SOURCE_DESC="explicit --org-plugin (${resolved})"
    return 0
  fi

  if [[ -f "${CODEX_CONFIG_PATH:-/nonexistent}" ]]; then
    local configured
    configured="$(python3 -c "
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
print(cfg.get('orgPluginSourcePath') or '')
" "${CODEX_CONFIG_PATH}" 2>/dev/null || true)"
    if [[ -n "${configured}" ]]; then
      if [[ -f "${configured}/.codex-plugin/plugin.json" ]]; then
        ORG_PLUGIN_SOURCE="${configured}"
        ORG_PLUGIN_SOURCE_DESC="recorded orgPluginSourcePath in .codex-copilot.json (${configured})"
        return 0
      fi
      echo "Warning: recorded orgPluginSourcePath in .codex-copilot.json is no longer a valid plugin: ${configured} -- skipping org plugin sync this run (pass --org-plugin to repoint it, or --no-org-plugin to stop tracking it)." >&2
      ORG_PLUGIN_SOURCE_DESC="recorded orgPluginSourcePath invalid, skipped (${configured})"
      return 0
    fi
  fi

  local sibling_parent candidate found
  sibling_parent="$(cd "$(dirname "${FRAMEWORK_ROOT}")" && pwd)"
  while IFS= read -r candidate; do
    [[ -d "${candidate}" ]] || continue
    found="$(_org_plugin_from_manifests "${candidate}")"
    if [[ -n "${found}" ]]; then
      ORG_PLUGIN_SOURCE="${found}"
      ORG_PLUGIN_SOURCE_DESC="auto-detected sibling (${found})"
      return 0
    fi
  done < <(_org_plugin_candidate_roots "${sibling_parent}")
}
