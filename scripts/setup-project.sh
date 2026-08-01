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
  --no-decision-instruments
                          Skip SOUL.md and architecture-principles scaffolding
  --force                 Compatibility-only; existing project wiring is still preserved
  --no-tc-init            Skip tc init
  --help                  Show this help
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/AGENTS.project.template.md"
SOUL_TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/SOUL.template.md"
ARCH_TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/architecture-guiding-principles.template.md"
INITIATIVES_TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/initiatives"

PROJECT_PATH=""
PROJECT_NAME=""
PROJECT_DESCRIPTION="Project using codex-copilot"
TECH_STACK="Unknown"
FRAMEWORK_ROOT_OVERRIDE=""
RULES_FILE=""
FORCE=0
DO_TC_INIT=1
DO_DECISION_INSTRUMENTS=1

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
    --no-decision-instruments)
      DO_DECISION_INSTRUMENTS=0
      shift
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
  SOUL_TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/SOUL.template.md"
  ARCH_TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/architecture-guiding-principles.template.md"
  INITIATIVES_TEMPLATE_PATH="${FRAMEWORK_ROOT}/templates/initiatives"
fi

if [[ ! -f "${TEMPLATE_PATH}" ]]; then
  echo "Missing template: ${TEMPLATE_PATH}" >&2
  exit 1
fi

if [[ "${DO_DECISION_INSTRUMENTS}" -eq 1 ]]; then
  if [[ ! -f "${SOUL_TEMPLATE_PATH}" ]]; then
    echo "Missing template: ${SOUL_TEMPLATE_PATH}" >&2
    exit 1
  fi

  if [[ ! -f "${ARCH_TEMPLATE_PATH}" ]]; then
    echo "Missing template: ${ARCH_TEMPLATE_PATH}" >&2
    exit 1
  fi
fi

if [[ ! -d "${INITIATIVES_TEMPLATE_PATH}" ]]; then
  echo "Missing initiatives template directory: ${INITIATIVES_TEMPLATE_PATH}" >&2
  exit 1
fi

if [[ -n "${RULES_FILE}" && ! -f "${RULES_FILE}" ]]; then
  echo "Rules file does not exist: ${RULES_FILE}" >&2
  exit 1
fi

INITIATIVES_PATH="${PROJECT_PATH}/docs/40-initiatives"
INITIATIVES_EXISTED=0
if [[ -e "${INITIATIVES_PATH}" ]]; then
  INITIATIVES_EXISTED=1
fi

PLUGIN_LINK="${PROJECT_PATH}/plugins/codex-copilot"
FRAMEWORK_PLUGIN_PATH="${FRAMEWORK_ROOT}/plugins/codex-copilot"
SKILLS_LINK="${PROJECT_PATH}/.claude/skills/codex-copilot"
FRAMEWORK_SKILLS_PATH="${FRAMEWORK_PLUGIN_PATH}/skills"
QA_GATE_LINK="${PROJECT_PATH}/scripts/copilot-gate.sh"
FRAMEWORK_QA_GATE_PATH="${FRAMEWORK_ROOT}/scripts/copilot-gate.sh"
MARKETPLACE_PATH="${PROJECT_PATH}/.agents/plugins/marketplace.json"
INSTALL_METADATA_PATH="${PROJECT_PATH}/.codex-copilot.json"
AGENTS_PATH="${PROJECT_PATH}/AGENTS.md"

if [[ ! -d "${FRAMEWORK_PLUGIN_PATH}" ]]; then
  echo "Missing framework plugin directory: ${FRAMEWORK_PLUGIN_PATH}" >&2
  exit 1
fi

if [[ ! -d "${FRAMEWORK_SKILLS_PATH}" ]]; then
  echo "Missing framework skills directory: ${FRAMEWORK_SKILLS_PATH}" >&2
  exit 1
fi

if [[ ! -x "${FRAMEWORK_QA_GATE_PATH}" ]]; then
  echo "Missing executable QA gate: ${FRAMEWORK_QA_GATE_PATH}" >&2
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

SKILLS_LINK_DIR="$(dirname "${SKILLS_LINK}")"
PROJECT_PLUGIN_SKILLS_PATH="${PLUGIN_LINK}/skills"
RELATIVE_SKILLS_TARGET="$(relative_path "${SKILLS_LINK_DIR}" "${PROJECT_PLUGIN_SKILLS_PATH}")"

if [[ -L "${PLUGIN_LINK}" || -e "${PLUGIN_LINK}" ]]; then
  echo "Refusing to replace existing plugin link/path: ${PLUGIN_LINK}" >&2
  echo "Remove or update it manually after reviewing the target." >&2
  exit 1
fi

if [[ -L "${SKILLS_LINK}" || -e "${SKILLS_LINK}" ]]; then
  echo "Refusing to replace existing skill link/path: ${SKILLS_LINK}" >&2
  echo "Remove or update it manually after reviewing the target." >&2
  exit 1
fi

if [[ -L "${QA_GATE_LINK}" || -e "${QA_GATE_LINK}" ]]; then
  echo "Refusing to replace existing QA gate link/path: ${QA_GATE_LINK}" >&2
  echo "Remove or update it manually after reviewing the target." >&2
  exit 1
fi

if [[ -e "${AGENTS_PATH}" ]]; then
  echo "Refusing to overwrite existing AGENTS.md: ${AGENTS_PATH}" >&2
  echo "Review and update it manually or move it aside first." >&2
  exit 1
fi

if [[ -e "${MARKETPLACE_PATH}" ]]; then
  echo "Refusing to overwrite existing marketplace: ${MARKETPLACE_PATH}" >&2
  exit 1
fi

if [[ -e "${INSTALL_METADATA_PATH}" ]]; then
  echo "Refusing to overwrite existing install metadata: ${INSTALL_METADATA_PATH}" >&2
  exit 1
fi

# Mutation starts only after every collision and input check has passed.
mkdir -p "${PROJECT_PATH}/.agents/plugins"
mkdir -p "${PROJECT_PATH}/.claude/cc"
mkdir -p "${PROJECT_PATH}/.claude/memory/entries"
mkdir -p "${PROJECT_PATH}/.claude/skills"
mkdir -p "${PROJECT_PATH}/plugins"
mkdir -p "${PROJECT_PATH}/scripts"
if [[ "${DO_DECISION_INSTRUMENTS}" -eq 1 ]]; then
  mkdir -p "${PROJECT_PATH}/docs/01-architecture"
fi
if [[ "${INITIATIVES_EXISTED}" -eq 0 ]]; then
  mkdir -p "${INITIATIVES_PATH}/_template/phases"
  mkdir -p "${INITIATIVES_PATH}/_template/decisions"
  mkdir -p "${INITIATIVES_PATH}/_template/retrospectives"
fi

cp -R "${FRAMEWORK_PLUGIN_PATH}" "${PLUGIN_LINK}"
ln -s "${RELATIVE_SKILLS_TARGET}" "${SKILLS_LINK}"
cp "${FRAMEWORK_QA_GATE_PATH}" "${QA_GATE_LINK}"
chmod +x "${QA_GATE_LINK}"

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

cat > "${INSTALL_METADATA_PATH}" <<EOF
{
  "installType": "copy",
  "pluginPath": "./plugins/codex-copilot",
  "projectName": "${PROJECT_NAME}"
}
EOF

render_project_template() {
  local source_path="$1"
  local output_path="$2"

  if [[ -f "${output_path}" ]]; then
    return 0
  fi

  python3 - "${source_path}" "${output_path}" <<'PY'
from pathlib import Path
import os
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
content = src.read_text()
content = content.replace("{{PROJECT_NAME}}", os.environ["PROJECT_NAME"])
content = content.replace("{{PROJECT_DESCRIPTION}}", os.environ["PROJECT_DESCRIPTION"])
content = content.replace("{{TECH_STACK}}", os.environ["TECH_STACK"])
dst.write_text(content)
PY
}

PROJECT_RULES="Add project-specific rules here."
if [[ -n "${RULES_FILE}" ]]; then
  PROJECT_RULES="$(cat "${RULES_FILE}")"
fi
export PROJECT_RULES
export PROJECT_NAME
export PROJECT_DESCRIPTION
export TECH_STACK

python3 - "${TEMPLATE_PATH}" "${AGENTS_PATH}" <<'PY'
from pathlib import Path
import os
import sys

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
content = src.read_text()
content = content.replace("{{PROJECT_NAME}}", os.environ["PROJECT_NAME"])
content = content.replace("{{PROJECT_DESCRIPTION}}", os.environ["PROJECT_DESCRIPTION"])
content = content.replace("{{TECH_STACK}}", os.environ["TECH_STACK"])
content = content.replace("{{PROJECT_RULES}}", os.environ["PROJECT_RULES"])
dst.write_text(content)
PY

if [[ "${DO_DECISION_INSTRUMENTS}" -eq 1 ]]; then
  render_project_template "${SOUL_TEMPLATE_PATH}" "${PROJECT_PATH}/SOUL.md"
  render_project_template "${ARCH_TEMPLATE_PATH}" "${PROJECT_PATH}/docs/01-architecture/12-architecture-guiding-principles.md"
fi

if [[ "${INITIATIVES_EXISTED}" -eq 0 ]]; then
  render_project_template "${INITIATIVES_TEMPLATE_PATH}/README.md" "${INITIATIVES_PATH}/README.md"
  render_project_template "${INITIATIVES_TEMPLATE_PATH}/_template/README.md" "${INITIATIVES_PATH}/_template/README.md"
  render_project_template "${INITIATIVES_TEMPLATE_PATH}/_template/phases/phase-1-plan.md" "${INITIATIVES_PATH}/_template/phases/phase-1-plan.md"
  render_project_template "${INITIATIVES_TEMPLATE_PATH}/_template/decisions/ADR-001-template.md" "${INITIATIVES_PATH}/_template/decisions/ADR-001-template.md"
  render_project_template "${INITIATIVES_TEMPLATE_PATH}/_template/retrospectives/README.md" "${INITIATIVES_PATH}/_template/retrospectives/README.md"
fi

if [[ "${DO_TC_INIT}" -eq 1 ]]; then
  if command -v tc >/dev/null 2>&1; then
    (cd "${PROJECT_PATH}" && tc init --json >/dev/null) || true
  elif [[ -x "${PROJECT_PATH}/.venv-tc/bin/tc" ]]; then
    (cd "${PROJECT_PATH}" && ./.venv-tc/bin/tc init --json >/dev/null) || true
  fi
fi

echo "Configured project: ${PROJECT_PATH}"
echo "Framework root: ${FRAMEWORK_ROOT}"
echo "Project plugin: ${PLUGIN_LINK}"
echo "Plugin source: ${FRAMEWORK_PLUGIN_PATH}"
echo "Skill link: ${SKILLS_LINK}"
echo "Skill source: ${RELATIVE_SKILLS_TARGET}"
echo "QA gate: ${QA_GATE_LINK}"
echo "Initiatives: ${INITIATIVES_PATH}"
echo "cc config: ${CC_CONFIG_PATH}"
echo "AGENTS.md: ${AGENTS_PATH}"
