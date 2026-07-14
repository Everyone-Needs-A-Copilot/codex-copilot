#!/usr/bin/env bash
# install-parity-warn-hook.sh — install/update a pre-commit hook block in
# claude-copilot (the upstream/authoring repo) that WARNS when a commit
# touches codex-copilot's content-level parity surface
# (.claude/agents/*.md, .claude/commands/*.md, .claude/skills/**/SKILL.md)
# so a re-sync doesn't get silently skipped again
# (t6-two-harnesses-one-behavior).
#
# Mirrors copilot-control-tower/tools/cse-bench/install-claim-sweep-hook.sh's
# pattern: idempotent, and CHAINS onto whatever is already in the target
# hook rather than clobbering it (claude-copilot's pre-commit already has a
# claim-sweep managed block; this installer only ever touches the block
# between its own BEGIN/END markers). The CHECKER
# (warn-parity-drift.sh) always lives in codex-copilot next to this
# installer; the TARGET repo is claude-copilot, found via
# CLAUDE_COPILOT_ROOT, --target-repo PATH, or the sibling directory
# convention (../claude-copilot relative to this codex-copilot checkout).
#
# Usage:
#   cd codex-copilot && scripts/install-parity-warn-hook.sh
#     # installs into ../claude-copilot's pre-commit hook (sibling default)
#   scripts/install-parity-warn-hook.sh --target-repo /path/to/claude-copilot
#     # explicit target

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_COPILOT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECKER_ABS="$SCRIPT_DIR/warn-parity-drift.sh"

if [ ! -f "$CHECKER_ABS" ]; then
  echo "install-parity-warn-hook.sh: warn-parity-drift.sh not found next to this script ($SCRIPT_DIR)" >&2
  exit 1
fi

TARGET_REPO_ARG=""
if [ "${1:-}" = "--target-repo" ]; then
  TARGET_REPO_ARG="${2:-}"
  if [ -z "$TARGET_REPO_ARG" ]; then
    echo "install-parity-warn-hook.sh: --target-repo requires a path" >&2
    exit 1
  fi
fi

if [ -z "$TARGET_REPO_ARG" ]; then
  TARGET_REPO_ARG="${CLAUDE_COPILOT_ROOT:-$CODEX_COPILOT_ROOT/../claude-copilot}"
fi

if ! REPO_ROOT="$(git -C "$TARGET_REPO_ARG" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "install-parity-warn-hook.sh: $TARGET_REPO_ARG is not inside a git repository (pass --target-repo PATH or set CLAUDE_COPILOT_ROOT)" >&2
  exit 1
fi

HOOKS_PATH_CONFIG="$(git -C "$REPO_ROOT" config --get core.hooksPath || true)"
if [ -z "$HOOKS_PATH_CONFIG" ]; then
  HOOKS_DIR="$REPO_ROOT/.git/hooks"
else
  case "$HOOKS_PATH_CONFIG" in
    /*) HOOKS_DIR="$HOOKS_PATH_CONFIG" ;;
    *)  HOOKS_DIR="$REPO_ROOT/$HOOKS_PATH_CONFIG" ;;
  esac
fi

mkdir -p "$HOOKS_DIR"
HOOK_FILE="$HOOKS_DIR/pre-commit"

BEGIN_MARKER="# BEGIN codex-parity-warn hook (managed by codex-copilot/scripts/install-parity-warn-hook.sh — do not hand-edit this block)"
END_MARKER="# END codex-parity-warn hook"

HOOK_BLOCK="$BEGIN_MARKER
if [ -f \"$CHECKER_ABS\" ]; then
  CODEX_COPILOT_ROOT=\"$CODEX_COPILOT_ROOT\" bash \"$CHECKER_ABS\" || true
else
  : # codex-copilot (and this checker) not present on this checkout; nothing to check.
fi
$END_MARKER"

if [ -f "$HOOK_FILE" ] && grep -qF "$BEGIN_MARKER" "$HOOK_FILE"; then
  BEGIN_LINE="$(grep -nF "$BEGIN_MARKER" "$HOOK_FILE" | head -1 | cut -d: -f1)"
  END_LINE="$(grep -nF "$END_MARKER" "$HOOK_FILE" | head -1 | cut -d: -f1)"
  TMP_HOOK="$(mktemp "${TMPDIR:-/tmp}/pre-commit.XXXXXX")"
  if [ "$BEGIN_LINE" -gt 1 ]; then
    head -n "$((BEGIN_LINE - 1))" "$HOOK_FILE" > "$TMP_HOOK"
  else
    : > "$TMP_HOOK"
  fi
  printf '%s\n' "$HOOK_BLOCK" >> "$TMP_HOOK"
  tail -n "+$((END_LINE + 1))" "$HOOK_FILE" >> "$TMP_HOOK"
  mv "$TMP_HOOK" "$HOOK_FILE"
  ACTION="updated the existing managed block in"
elif [ -f "$HOOK_FILE" ]; then
  printf '\n%s\n' "$HOOK_BLOCK" >> "$HOOK_FILE"
  ACTION="appended a managed block to (chained onto) the existing"
else
  {
    printf '#!/usr/bin/env bash\nset -e\n\n%s\n' "$HOOK_BLOCK"
  } > "$HOOK_FILE"
  ACTION="created a new"
fi
chmod +x "$HOOK_FILE"

echo "install-parity-warn-hook.sh: $ACTION pre-commit hook at $HOOK_FILE"
echo "install-parity-warn-hook.sh: target-repo=$REPO_ROOT checker=$CHECKER_ABS hooks-dir=$HOOKS_DIR"
