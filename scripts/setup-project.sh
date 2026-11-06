#!/usr/bin/env bash
# Central-resolution setup (ADR-001, initiative 06-central-resolution).
#
# Framework files are NOT copied into the project. The Codex plugin, skills and
# hooks resolve through ~/.copilot/current; this script only seeds project-owned
# scaffolds (project AGENTS.md sections, SOUL.md, architecture principles,
# initiatives) when absent and delegates the marker, the thin framework section
# and the Codex trust entry to `cc project init`.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  setup-project.sh --project /path/to/project [options]

Options:
  --project PATH          Target project directory
  --name NAME             Project display name (defaults to basename of project path)
  --description TEXT      Project description (default: "Project using codex-copilot")
  --stack TEXT            Tech stack summary (default: "Unknown")
  --rules-file PATH       Project-specific rules to place in a newly created AGENTS.md
  --no-decision-instruments
                          Skip SOUL.md and architecture-principles scaffolding
  --no-tc-init            Skip tc init
  --help                  Show this help

Writes copilot.project.json, a thin Copilot section in AGENTS.md/CLAUDE.md and the
Codex trust entry through `cc project init`. Copies no plugin, skill, hook, QA gate,
marketplace or .codex-copilot.json. Safe to re-run: existing files are preserved.
Accepted for compatibility and ignored: --framework-root, --org-plugin,
--no-org-plugin, --force.
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH=""
PROJECT_NAME=""
PROJECT_DESCRIPTION="Project using codex-copilot"
TECH_STACK="Unknown"
RULES_FILE=""
DO_TC_INIT=1
DO_DECISION_INSTRUMENTS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_PATH="${2:-}"; shift 2 ;;
    --name) PROJECT_NAME="${2:-}"; shift 2 ;;
    --description) PROJECT_DESCRIPTION="${2:-}"; shift 2 ;;
    --stack) TECH_STACK="${2:-}"; shift 2 ;;
    --rules-file) RULES_FILE="${2:-}"; shift 2 ;;
    --no-decision-instruments) DO_DECISION_INSTRUMENTS=0; shift ;;
    --no-tc-init) DO_TC_INIT=0; shift ;;
    --framework-root|--org-plugin) echo "note: ${1} is ignored (central resolution)" >&2; shift 2 ;;
    --no-org-plugin|--force) echo "note: ${1} is ignored (central resolution)" >&2; shift ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_PATH}" ]]; then
  echo "--project is required" >&2
  usage >&2
  exit 1
fi
if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "Project path does not exist: ${PROJECT_PATH}" >&2
  exit 1
fi
if [[ -n "${RULES_FILE}" && ! -f "${RULES_FILE}" ]]; then
  echo "Rules file does not exist: ${RULES_FILE}" >&2
  exit 1
fi

PROJECT_PATH="$(cd "${PROJECT_PATH}" && pwd)"
[[ -n "${PROJECT_NAME}" ]] || PROJECT_NAME="$(basename "${PROJECT_PATH}")"

CC_BIN="${CC_BIN:-${HOME}/.local/bin/cc}"
if [[ ! -x "${CC_BIN}" ]]; then
  echo "cc not found at ${CC_BIN}. Install the Copilot machine tools first (set CC_BIN to override)." >&2
  exit 1
fi

PROJECT_RULES="Add project-specific rules here."
if [[ -n "${RULES_FILE}" ]]; then
  PROJECT_RULES="$(cat "${RULES_FILE}")"
fi
export PROJECT_NAME PROJECT_DESCRIPTION TECH_STACK PROJECT_RULES

# Project-owned scaffolds, rendered only when absent.
render_if_absent() {
  local source_path="$1" output_path="$2"
  [[ -f "${source_path}" ]] || { echo "Missing template: ${source_path}" >&2; exit 1; }
  [[ -e "${output_path}" ]] && return 0
  mkdir -p "$(dirname "${output_path}")"
  python3 - "${source_path}" "${output_path}" <<'PY'
import os
import sys
from pathlib import Path

content = Path(sys.argv[1]).read_text()
for key in ("PROJECT_NAME", "PROJECT_DESCRIPTION", "TECH_STACK", "PROJECT_RULES"):
    content = content.replace("{{" + key + "}}", os.environ[key])
Path(sys.argv[2]).write_text(content)
PY
}

T="${FRAMEWORK_ROOT}/templates"
render_if_absent "${T}/AGENTS.project.template.md" "${PROJECT_PATH}/AGENTS.md"
if [[ "${DO_DECISION_INSTRUMENTS}" -eq 1 ]]; then
  render_if_absent "${T}/SOUL.template.md" "${PROJECT_PATH}/SOUL.md"
  render_if_absent "${T}/architecture-guiding-principles.template.md" "${PROJECT_PATH}/docs/01-architecture/12-architecture-guiding-principles.md"
fi
if [[ ! -e "${PROJECT_PATH}/docs/40-initiatives" ]]; then
  render_if_absent "${T}/initiatives/README.md" "${PROJECT_PATH}/docs/40-initiatives/README.md"
  render_if_absent "${T}/initiatives/_template/README.md" "${PROJECT_PATH}/docs/40-initiatives/_template/README.md"
  render_if_absent "${T}/initiatives/_template/phases/phase-1-plan.md" "${PROJECT_PATH}/docs/40-initiatives/_template/phases/phase-1-plan.md"
  render_if_absent "${T}/initiatives/_template/decisions/ADR-001-template.md" "${PROJECT_PATH}/docs/40-initiatives/_template/decisions/ADR-001-template.md"
  render_if_absent "${T}/initiatives/_template/retrospectives/README.md" "${PROJECT_PATH}/docs/40-initiatives/_template/retrospectives/README.md"
fi

# Marker, thin AGENTS.md/CLAUDE.md section, Codex trust entry: one writer.
"${CC_BIN}" project init "${PROJECT_PATH}"

if [[ "${DO_TC_INIT}" -eq 1 ]]; then
  if command -v tc >/dev/null 2>&1; then
    (cd "${PROJECT_PATH}" && tc init --json >/dev/null) || true
  fi
fi

echo "Configured project: ${PROJECT_PATH}"
echo "Framework resolves through ~/.copilot/current; verify with: cc doctor"
