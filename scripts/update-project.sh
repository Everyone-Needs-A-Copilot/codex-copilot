#!/usr/bin/env bash
# Central-resolution update (ADR-001, initiative 06-central-resolution).
#
# Projects hold no framework copies, so there is nothing to update per project.
# A release reaches every project through ~/.copilot/current. This script only
# verifies: it runs `cc doctor` and, when the project has no marker yet, says so.
# It never writes to the project.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  update-project.sh --project /path/to/project

Verifies the project against the installed release (`cc doctor`). Writes nothing.
Accepted for compatibility and ignored: --framework-root, --org-plugin,
--no-org-plugin, --dry-run.
USAGE
}

PROJECT_PATH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_PATH="${2:-}"; shift 2 ;;
    --framework-root|--org-plugin) shift 2 ;;
    --no-org-plugin|--dry-run) shift ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_PATH}" || ! -d "${PROJECT_PATH}" ]]; then
  echo "--project must be an existing directory" >&2
  usage >&2
  exit 1
fi
PROJECT_PATH="$(cd "${PROJECT_PATH}" && pwd)"

if [[ ! -f "${PROJECT_PATH}/copilot.project.json" ]]; then
  echo "No copilot.project.json in ${PROJECT_PATH}; run scripts/setup-project.sh first." >&2
  exit 1
fi

CC_BIN="${CC_BIN:-${HOME}/.local/bin/cc}"
if [[ ! -x "${CC_BIN}" ]]; then
  echo "cc not found at ${CC_BIN}. Install the Copilot machine tools first (set CC_BIN to override)." >&2
  exit 1
fi

echo "Nothing to update: ${PROJECT_PATH} resolves through ~/.copilot/current."
cd "${PROJECT_PATH}" && exec "${CC_BIN}" doctor
