#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  setup-project.sh --project /path/to/project [options]

Options:
  --project PATH          Target project directory
  --name NAME             Project display name (defaults to basename of project path)
  --description TEXT      Project description (default: "Project using codex-copilot")
  --stack TEXT            Tech stack summary (default: "Unknown")
  --framework-root PATH   Override detected codex-copilot framework root
  --rules-file PATH       Append project-specific rules from file into AGENTS.md
  --force                 Overwrite existing AGENTS.md and metadata files
  --no-tc-init            Skip tc init
  --help                  Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/AGENTS.project.template.md"

PROJECT_PATH=""
PROJECT_NAME=""
PROJECT_DESCRIPTION="Project using codex-copilot"
TECH_STACK="Unknown"
FRAMEWORK_ROOT_OVERRIDE=""
RULES_FILE=""
FORCE=0
DO_TC_INIT=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_PATH="${2:-}"
      shift 2
      ;;
    --name)
      PROJECT_NAME="${2:-}"
      shift 2
      ;;
    --description)
      PROJECT_DESCRIPTION="${2:-}"
      shift 2
      ;;
    --stack)
      TECH_STACK="${2:-}"
      shift 2
      ;;
    --framework-root)
      FRAMEWORK_ROOT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --rules-file)
      RULES_FILE="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --no-tc-init)
      DO_TC_INIT=0
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
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

if [[ -z "${PROJECT_NAME}" ]]; then
  PROJECT_NAME="$(basename "${PROJECT_PATH}")"
fi

if [[ -n "${FRAMEWORK_ROOT_OVERRIDE}" ]]; then
  FRAMEWORK_ROOT="$(cd "${FRAMEWORK_ROOT_OVERRIDE}" && pwd)"
  TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/AGENTS.project.template.md"
fi

if [[ ! -f "${TEMPLATE_PATH}" ]]; then
  echo "Missing template: ${TEMPLATE_PATH}" >&2
  exit 1
fi

if [[ -n "${RULES_FILE}" && ! -f "${RULES_FILE}" ]]; then
  echo "Rules file does not exist: ${RULES_FILE}" >&2
  exit 1
fi

mkdir -p "${PROJECT_PATH}/.agents/plugins"
mkdir -p "${PROJECT_PATH}/plugins"

PLUGIN_LINK="${PROJECT_PATH}/plugins/codex-copilot"
FRAMEWORK_PLUGIN_PATH="${FRAMEWORK_ROOT}/plugins/codex-copilot"

if [[ ! -d "${FRAMEWORK_PLUGIN_PATH}" ]]; then
  echo "Missing framework plugin directory: ${FRAMEWORK_PLUGIN_PATH}" >&2
  exit 1
fi

relative_path() {
  python3 - "$1" "$2" <<'PY'
from pathlib import Path
import os
import sys

source = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).resolve()
print(os.path.relpath(target, source))
PY
}

PLUGIN_LINK_DIR="$(dirname "${PLUGIN_LINK}")"
RELATIVE_PLUGIN_TARGET="$(relative_path "${PLUGIN_LINK_DIR}" "${FRAMEWORK_PLUGIN_PATH}")"

if [[ -L "${PLUGIN_LINK}" || -e "${PLUGIN_LINK}" ]]; then
  if [[ "${FORCE}" -eq 1 ]]; then
    rm -rf "${PLUGIN_LINK}"
  else
    echo "Plugin link/path already exists: ${PLUGIN_LINK}" >&2
    echo "Re-run with --force to replace it." >&2
    exit 1
  fi
fi

ln -s "${RELATIVE_PLUGIN_TARGET}" "${PLUGIN_LINK}"

cat > "${PROJECT_PATH}/.agents/plugins/marketplace.json" <<'EOF'
{
  "name": "codex-copilot-project",
  "interface": {
    "displayName": "Codex Copilot Project"
  },
  "plugins": [
    {
      "name": "codex-copilot",
      "source": {
        "source": "local",
        "path": "./plugins/codex-copilot"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
EOF

cat > "${PROJECT_PATH}/.codex-copilot.json" <<EOF
{
  "installType": "symlink",
  "pluginPath": "./plugins/codex-copilot",
  "projectName": "${PROJECT_NAME}"
}
EOF

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

PROJECT_RULES="Add project-specific rules here."
if [[ -n "${RULES_FILE}" ]]; then
  PROJECT_RULES="$(cat "${RULES_FILE}")"
fi
export PROJECT_RULES

TMP_FILE="$(mktemp)"
cp "${TEMPLATE_PATH}" "${TMP_FILE}"
sed -i.bak \
  -e "s/{{PROJECT_NAME}}/$(escape_sed "${PROJECT_NAME}")/g" \
  -e "s/{{PROJECT_DESCRIPTION}}/$(escape_sed "${PROJECT_DESCRIPTION}")/g" \
  -e "s/{{TECH_STACK}}/$(escape_sed "${TECH_STACK}")/g" \
  "${TMP_FILE}"
rm -f "${TMP_FILE}.bak"

if grep -q "{{PROJECT_RULES}}" "${TMP_FILE}"; then
  RULES_TMP="$(mktemp)"
  python3 - "${TMP_FILE}" "${RULES_TMP}" <<'PY'
from pathlib import Path
import os
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
rules = os.environ["PROJECT_RULES"]
content = src.read_text()
dst.write_text(content.replace("{{PROJECT_RULES}}", rules))
PY
  mv "${RULES_TMP}" "${TMP_FILE}"
fi

AGENTS_PATH="${PROJECT_PATH}/AGENTS.md"
if [[ -f "${AGENTS_PATH}" && "${FORCE}" -ne 1 ]]; then
  echo "AGENTS.md already exists: ${AGENTS_PATH}" >&2
  echo "Re-run with --force to replace it." >&2
  rm -f "${TMP_FILE}"
  exit 1
fi
mv "${TMP_FILE}" "${AGENTS_PATH}"

if [[ "${DO_TC_INIT}" -eq 1 ]]; then
  if command -v tc >/dev/null 2>&1; then
    (cd "${PROJECT_PATH}" && tc init --json >/dev/null) || true
  elif [[ -x "${PROJECT_PATH}/.venv-tc/bin/tc" ]]; then
    (cd "${PROJECT_PATH}" && ./.venv-tc/bin/tc init --json >/dev/null) || true
  fi
fi

echo "Configured project: ${PROJECT_PATH}"
echo "Framework root: ${FRAMEWORK_ROOT}"
echo "Plugin link: ${PLUGIN_LINK}"
echo "Plugin source: ${RELATIVE_PLUGIN_TARGET}"
echo "AGENTS.md: ${AGENTS_PATH}"
