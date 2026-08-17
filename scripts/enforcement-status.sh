#!/usr/bin/env bash
# enforcement-status.sh — answers one question: is this framework actually
# running in this project, or is it only present?
#
# WHY THIS EXISTS.
#
# Codex Copilot installs as an instruction layer plus a small set of wired
# paths: a plugin link, a skills link, and an executable QA gate. AGENTS.md is
# project-owned and, once generated, is never touched again. So a project can
# carry the complete instruction layer -- AGENTS.md naming the specialists,
# $protocol, the QA gate's evidence contract -- while every wired path is
# missing, stale, or dangling. Nothing reports that. The session reads the
# instructions and behaves like plain Codex with some markdown in it: the
# specialists are described but never reachable, and the QA gate cannot refuse
# anything because there is no gate to run.
#
# This is not hypothetical. A benchmark of the sibling framework measured
# exactly that state -- instruction layer present, mechanical enforcement
# unregistered -- across 300+ runs, and read the result as the framework's
# design rather than as a framework that was not running. Turning enforcement
# on for the same arm, model and task changed the behaviour immediately.
#
# Every check this framework has asks "was the method followed in this repo?"
# None asked "is the thing on, here, now?" That is what this script asks, and
# it is the whole of its job: it repairs nothing and mutates nothing.
#
# EXIT CODES (so this is usable in a gate, not just by eye):
#   0  enforcement is wired, or this is not a Codex Copilot project at all
#   1  the instruction layer is present and enforcement is NOT wired
#   2  bad usage

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/enforcement-status.sh [--project PATH] [--json] [--quiet]

Reports whether a project carrying the Codex Copilot instruction layer also has
its enforcement paths wired. Read-only: repairs nothing.

  --project PATH  Project to inspect. Defaults to the current directory.
  --json          Machine-readable output.
  --quiet         Exit code only.

Repair with:
  scripts/setup-project.sh --project PATH --name NAME   (first install)
  scripts/update-project.sh --project PATH              (repair a wired project)
EOF
}

PROJECT_PATH="$PWD"
JSON=0
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_PATH="${2:-}"; shift 2 ;;
    --json)    JSON=1; shift ;;
    --quiet)   QUIET=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$PROJECT_PATH" || ! -d "$PROJECT_PATH" ]]; then
  echo "Not a directory: ${PROJECT_PATH}" >&2
  exit 2
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# ---------------------------------------------------------------------------
# Is the instruction layer here at all?
#
# Deliberately narrow. A bare AGENTS.md is not evidence of this framework --
# plenty of repos have one. The framework's own marker is its plugin
# directory or skills link, so a project only counts as "claims to be a Codex
# Copilot project" when one of those is present. Otherwise this script must
# stay silent: a check that fires in every unrelated directory is one an
# operator learns to ignore, which recreates the original silence wearing a
# different hat.
# ---------------------------------------------------------------------------
INSTRUCTION_MARKERS=()
[[ -e "${PROJECT_PATH}/AGENTS.md" ]] && INSTRUCTION_MARKERS+=("AGENTS.md")
[[ -e "${PROJECT_PATH}/plugins/codex-copilot" ]] && INSTRUCTION_MARKERS+=("plugins/codex-copilot")
[[ -e "${PROJECT_PATH}/.claude/skills/codex-copilot" ]] && INSTRUCTION_MARKERS+=(".claude/skills/codex-copilot")

CLAIMS_FRAMEWORK=0
if [[ -e "${PROJECT_PATH}/plugins/codex-copilot" ]] \
  || [[ -e "${PROJECT_PATH}/.claude/skills/codex-copilot" ]]; then
  CLAIMS_FRAMEWORK=1
fi

if [[ "$CLAIMS_FRAMEWORK" -eq 0 ]]; then
  if [[ "$QUIET" -eq 0 ]]; then
    if [[ "$JSON" -eq 1 ]]; then
      printf '{"project":"%s","framework_project":false,"wired":null,"missing":[]}\n' "$PROJECT_PATH"
    else
      echo "Not a Codex Copilot project (no plugin or skills link). Nothing to report."
    fi
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# The wired paths. A dangling symlink is the failure mode that matters most:
# it exists to `[[ -e ]]`'s predecessors, passes a careless presence check, and
# resolves to nothing -- so each path is checked for what it must actually BE.
# ---------------------------------------------------------------------------
MISSING=()

check_dir() {
  local rel="$1" abs="${PROJECT_PATH}/$1"
  if [[ -L "$abs" && ! -e "$abs" ]]; then
    MISSING+=("${rel} (dangling symlink)")
  elif [[ ! -d "$abs" ]]; then
    MISSING+=("${rel} (missing)")
  fi
}

check_exec() {
  local rel="$1" abs="${PROJECT_PATH}/$1"
  if [[ -L "$abs" && ! -e "$abs" ]]; then
    MISSING+=("${rel} (dangling symlink)")
  elif [[ ! -f "$abs" ]]; then
    MISSING+=("${rel} (missing)")
  elif [[ ! -x "$abs" ]]; then
    MISSING+=("${rel} (not executable — cannot refuse anything)")
  fi
}

check_dir  "plugins/codex-copilot"
check_dir  "plugins/codex-copilot/skills"
check_dir  ".claude/skills/codex-copilot"
check_exec "scripts/copilot-gate.sh"

[[ -f "${PROJECT_PATH}/AGENTS.md" ]] || MISSING+=("AGENTS.md (missing — the specialists are never named)")

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [[ "${#MISSING[@]}" -eq 0 ]]; then
  if [[ "$QUIET" -eq 0 ]]; then
    if [[ "$JSON" -eq 1 ]]; then
      printf '{"project":"%s","framework_project":true,"wired":true,"missing":[]}\n' "$PROJECT_PATH"
    else
      echo "Enforcement is wired: plugin, skills and an executable QA gate are all present."
    fi
  fi
  exit 0
fi

if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON" -eq 1 ]]; then
    printf '{"project":"%s","framework_project":true,"wired":false,"markers":[' "$PROJECT_PATH"
    for i in "${!INSTRUCTION_MARKERS[@]}"; do
      [[ "$i" -gt 0 ]] && printf ','
      printf '"%s"' "${INSTRUCTION_MARKERS[$i]}"
    done
    printf '],"missing":['
    for i in "${!MISSING[@]}"; do
      [[ "$i" -gt 0 ]] && printf ','
      printf '"%s"' "${MISSING[$i]}"
    done
    printf ']}\n'
  else
    echo "Enforcement is NOT wired in this project."
    echo
    echo "  Instruction layer present: ${INSTRUCTION_MARKERS[*]}"
    echo "  Not wired:"
    for item in "${MISSING[@]}"; do
      echo "    - ${item}"
    done
    echo
    echo "  What this means in a session: the specialists are described but not"
    echo "  reachable, \$protocol has nothing to route to, and the QA gate cannot"
    echo "  refuse anything. The session will read like this framework and behave"
    echo "  like plain Codex, and nothing else will tell you."
    echo
    echo "  Repair: scripts/update-project.sh --project ${PROJECT_PATH}"
  fi
fi
exit 1
