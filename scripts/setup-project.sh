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
  --force                 Reserved for compatibility; refuses destructive replacement
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

if ! git -C "${PROJECT_PATH}" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Warning: target is not a git repository; cc project-scope skill discovery requires a git root." >&2
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

PLUGIN_LINK="${PROJECT_PATH}/plugins/codex-copilot"
FRAMEWORK_PLUGIN_PATH="${FRAMEWORK_ROOT}/plugins/codex-copilot"
SKILLS_LINK="${PROJECT_PATH}/.claude/skills/codex-copilot"
FRAMEWORK_SKILLS_PATH="${FRAMEWORK_PLUGIN_PATH}/skills"
MARKETPLACE_PATH="${PROJECT_PATH}/.agents/plugins/marketplace.json"
CODEX_COPILOT_METADATA="${PROJECT_PATH}/.codex-copilot.json"
AGENTS_PATH="${PROJECT_PATH}/AGENTS.md"

if [[ ! -d "${FRAMEWORK_PLUGIN_PATH}" ]]; then
  echo "Missing framework plugin directory: ${FRAMEWORK_PLUGIN_PATH}" >&2
  exit 1
fi

if [[ ! -d "${FRAMEWORK_SKILLS_PATH}" ]]; then
  echo "Missing framework skills directory: ${FRAMEWORK_SKILLS_PATH}" >&2
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
SKILLS_LINK_DIR="$(dirname "${SKILLS_LINK}")"
RELATIVE_SKILLS_TARGET="$(relative_path "${SKILLS_LINK_DIR}" "${FRAMEWORK_SKILLS_PATH}")"

if [[ -L "${PLUGIN_LINK}" || -e "${PLUGIN_LINK}" ]]; then
  echo "Plugin link/path already exists: ${PLUGIN_LINK}" >&2
  echo "Refusing to replace it automatically. Move or update it only after explicit approval for that path." >&2
  exit 1
fi

if [[ -L "${SKILLS_LINK}" || -e "${SKILLS_LINK}" ]]; then
  echo "Skill link/path already exists: ${SKILLS_LINK}" >&2
  echo "Refusing to replace it automatically. Move or update it only after explicit approval for that path." >&2
  exit 1
fi

if [[ -f "${MARKETPLACE_PATH}" ]]; then
  echo "Marketplace metadata already exists: ${MARKETPLACE_PATH}" >&2
  echo "Refusing to overwrite it automatically." >&2
  exit 1
fi

if [[ -f "${CODEX_COPILOT_METADATA}" ]]; then
  echo "Codex Copilot metadata already exists: ${CODEX_COPILOT_METADATA}" >&2
  echo "Refusing to overwrite it automatically." >&2
  exit 1
fi

if [[ -f "${AGENTS_PATH}" ]]; then
  echo "AGENTS.md already exists: ${AGENTS_PATH}" >&2
  echo "Refusing to overwrite it automatically." >&2
  exit 1
fi

mkdir -p "${PROJECT_PATH}/.agents/plugins"
mkdir -p "${PROJECT_PATH}/.claude/cc"
mkdir -p "${PROJECT_PATH}/.claude/memory/entries"
mkdir -p "${PROJECT_PATH}/.claude/skills"
mkdir -p "${PROJECT_PATH}/plugins"

ln -s "${RELATIVE_PLUGIN_TARGET}" "${PLUGIN_LINK}"
ln -s "${RELATIVE_SKILLS_TARGET}" "${SKILLS_LINK}"

MEMORY_GITIGNORE="${PROJECT_PATH}/.claude/memory/.gitignore"
if [[ ! -f "${MEMORY_GITIGNORE}" ]]; then
  cat > "${MEMORY_GITIGNORE}" <<'EOF'
memory.db
memory.db-shm
memory.db-wal
EOF
fi

touch "${PROJECT_PATH}/.claude/memory/entries/.gitkeep"

CC_CONFIG_PATH="${PROJECT_PATH}/.claude/cc/config.json"
if [[ ! -f "${CC_CONFIG_PATH}" ]]; then
  cat > "${CC_CONFIG_PATH}" <<'EOF'
{
  "$schema": "cc-config-v1",
  "version": 1,
  "paths": {
    "shared_docs": "@machine",
    "knowledge_repo": "@machine"
  }
}
EOF
fi

cat > "${MARKETPLACE_PATH}" <<'EOF'
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

cat > "${CODEX_COPILOT_METADATA}" <<EOF
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
sed \
  -e "s/{{PROJECT_NAME}}/$(escape_sed "${PROJECT_NAME}")/g" \
  -e "s/{{PROJECT_DESCRIPTION}}/$(escape_sed "${PROJECT_DESCRIPTION}")/g" \
  -e "s/{{TECH_STACK}}/$(escape_sed "${TECH_STACK}")/g" \
  "${TEMPLATE_PATH}" > "${TMP_FILE}"

if grep -q "{{PROJECT_RULES}}" "${TMP_FILE}"; then
  perl -0pi -e 's/\{\{PROJECT_RULES\}\}/$ENV{PROJECT_RULES}/g' "${TMP_FILE}"
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
echo "Skill link: ${SKILLS_LINK}"
echo "Skill source: ${RELATIVE_SKILLS_TARGET}"
echo "cc config: ${CC_CONFIG_PATH}"
echo "AGENTS.md: ${AGENTS_PATH}"
