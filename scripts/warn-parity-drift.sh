#!/usr/bin/env bash
# warn-parity-drift.sh — pre-commit WARNING (never blocking) that fires in
# claude-copilot when a commit touches a file tracked by codex-copilot's
# content-level parity contract (.claude/agents/*.md, .claude/commands/*.md,
# .claude/skills/**/SKILL.md) and the codex-copilot mirror has not been
# re-synced since.
#
# Root cause this closes: content_hash parity drift (t6-two-harnesses-
# one-behavior, C-4) recurred because nothing tied claude-copilot commits to
# a required codex-copilot re-sync -- the sync mechanism itself worked, it
# just wasn't re-run after later upstream commits landed. This hook is the
# reminder that was missing.
#
# Intentionally a WARNING, not a gate: blocking every claude-copilot commit
# on a downstream mirror's sync state would let an unrelated repo's lag
# block this repo's own work. It prints loudly and always exits 0.
#
# Installed into claude-copilot's pre-commit hook by
# install-parity-warn-hook.sh; this script is invoked with CWD at the
# claude-copilot repo root (git's normal pre-commit contract).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || true)"
CODEX_COPILOT_ROOT="${CODEX_COPILOT_ROOT:-$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)}"
CODEX_COPILOT_ROOT="${CODEX_COPILOT_ROOT:-$(pwd)/../codex-copilot}"
CHECKER="$CODEX_COPILOT_ROOT/scripts/check-upstream-parity.py"

if [ ! -f "$CHECKER" ]; then
  # codex-copilot not present on this checkout/machine; nothing to warn with.
  exit 0
fi

# Only look at files actually staged in this commit -- this is a targeted
# reminder about THIS commit, not a re-statement of all existing drift.
STAGED_TRACKED="$(git diff --cached --name-only --diff-filter=ACMR -- \
  '.claude/agents/*.md' '.claude/commands/*.md' '.claude/skills/**/SKILL.md' \
  2>/dev/null || true)"

if [ -z "$STAGED_TRACKED" ]; then
  exit 0
fi

RESULT="$(python3 "$CHECKER" --content --json --upstream "$(pwd)" 2>/dev/null || true)"
STATUS="$(printf '%s' "$RESULT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("content", {}).get("status", "unknown"))
except Exception:
    print("unknown")' 2>/dev/null)"

if [ "$STATUS" = "drift" ] || [ "$STATUS" = "unknown" ]; then
  echo "" >&2
  echo "=================================================================" >&2
  echo "PARITY WARNING: this commit touches codex-copilot's tracked mirror" >&2
  echo "surface but codex-copilot's content baseline is not confirmed" >&2
  echo "in sync (status: $STATUS):" >&2
  printf '%s\n' "$STAGED_TRACKED" | sed 's/^/  - /' >&2
  echo "" >&2
  echo "Once these changes are committed, re-run codex-copilot's parity" >&2
  echo "sweep (docs/05-reference/03-parity-contract.md \"Sweep Workflow\"):" >&2
  echo "  cd $CODEX_COPILOT_ROOT" >&2
  echo "  python3 scripts/check-upstream-parity.py --content --json" >&2
  echo "  # port any real behavior change into codex-copilot's mirrored" >&2
  echo "  # surface, then:" >&2
  echo "  python3 scripts/check-upstream-parity.py --update-baseline" >&2
  echo "This is a WARNING only -- it does not block this commit." >&2
  echo "=================================================================" >&2
  echo "" >&2
fi

exit 0
