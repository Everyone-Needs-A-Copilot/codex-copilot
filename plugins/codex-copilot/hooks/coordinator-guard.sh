#!/bin/bash
# Codex PreToolUse hook: the main session is a coordinator (2026-11-05).
# Denies main-thread file edits and non-allowlisted shell. Spawned agents are never
# blocked: thread kind is read from the first line of the session transcript
# (thread_source / source.subagent). Fails OPEN on any parse error or when the
# thread kind cannot be determined. Escape hatch: COPILOT_COORDINATOR=off (logged).

JQ="$(command -v jq 2>/dev/null || true)"
[ -n "$JQ" ] || exit 0
PAYLOAD="$(cat 2>/dev/null)"
[ -n "$PAYLOAD" ] || exit 0

TOOL="$($JQ -r '.tool_name // empty' <<< "$PAYLOAD" 2>/dev/null)"
case "$TOOL" in
  Bash|apply_patch|Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

LOG_DIR="${COPILOT_COORDINATOR_LOG_DIR:-$HOME/.codex/log}"
if [ "${COPILOT_COORDINATOR:-}" = "off" ]; then
  mkdir -p "$LOG_DIR" 2>/dev/null
  printf '%s coordinator-bypass tool=%s session=%s\n' "$(date -u +%FT%TZ)" "$TOOL" \
    "$($JQ -r '.session_id // "unknown"' <<< "$PAYLOAD" 2>/dev/null)" >> "$LOG_DIR/coordinator-bypass.log" 2>/dev/null
  exit 0
fi

# Main thread only: spawned agents (thread_source=subagent) are never blocked.
TP="$($JQ -r '.transcript_path // empty' <<< "$PAYLOAD" 2>/dev/null)"
[ -n "$TP" ] && [ -r "$TP" ] || exit 0
KIND="$(head -n 1 "$TP" 2>/dev/null | $JQ -r '.payload | if .thread_source == "user" then "main" elif (.thread_source == "subagent" or ((.source|type) == "object" and (.source|has("subagent")))) then "sub" else "unknown" end' 2>/dev/null)"
[ "$KIND" = "main" ] || exit 0

deny() {
  $JQ -cn --arg r "Coordinator rule (2026-11-05): the main session does not $1. Dispatch an agent with spawn_agent. Allowed here: tc, cc status/list/progress/skill, git status/log/branch/worktree list, notes under ~/.codex/memories. Override: COPILOT_COORDINATOR=off (logged)." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

NOTE_DIRS="$HOME/.codex/memories/:$HOME/.codex/scratchpad/:${COPILOT_COORDINATOR_NOTES:-}"

path_ok() {
  local p="$1" d
  case "$p" in *..*) return 1 ;; esac
  case "$p" in "~/"*) p="$HOME/${p#\~/}" ;; esac
  IFS=: read -ra DIRS <<< "$NOTE_DIRS"
  for d in "${DIRS[@]}"; do
    [ -n "$d" ] || continue
    case "$d" in */) ;; *) d="$d/" ;; esac
    case "$p" in "$d"*) return 0 ;; esac
  done
  return 1
}

if [ "$TOOL" != "Bash" ]; then
  PATHS="$($JQ -r '[.tool_input | (.. | strings)] | join("\n")' <<< "$PAYLOAD" 2>/dev/null \
    | sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p; s/^\*\*\* Move to: (.*)$/\1/p')"
  FP="$($JQ -r '.tool_input.file_path // .tool_input.path // empty' <<< "$PAYLOAD" 2>/dev/null)"
  [ -n "$FP" ] && PATHS="$PATHS"$'\n'"$FP"
  PATHS="$(printf '%s' "$PATHS" | sed '/^$/d')"
  [ -n "$PATHS" ] || deny "edit files"
  while IFS= read -r p; do path_ok "$p" || deny "edit project files ($p)"; done <<< "$PATHS"
  exit 0
fi

CMD="$($JQ -r '.tool_input.command // empty' <<< "$PAYLOAD" 2>/dev/null)"
[ -n "$CMD" ] || exit 0
# Unwrap a plain `bash -lc '...'`/`zsh -lc` wrapper if present.
if [[ "$CMD" =~ ^(/bin/)?(ba|z)?sh\ +-l?c\ +[\'\"](.*)[\'\"]$ ]]; then CMD="${BASH_REMATCH[3]}"; fi

case "$CMD" in *'`'*|*'$('*|*'>'*|*'<'*|*$'\n'*) deny "run shell with substitution, redirection or multiple lines" ;; esac

seg_ok() {
  local s="$1"; read -ra W <<< "$s"
  [ ${#W[@]} -gt 0 ] || return 0
  local bin="${W[0]##*/}"
  case "$bin" in
    tc) return 0 ;;
    cc) case "${W[1]:-}" in status|list|progress|skill) return 0 ;; esac; return 1 ;;
    git)
      local i=1
      while [ "${W[$i]:-}" = "-C" ]; do i=$((i+2)); done
      case "${W[$i]:-}" in
        status|log|branch) return 0 ;;
        worktree) [ "${W[$((i+1))]:-}" = "list" ] && return 0 ;;
      esac
      return 1 ;;
    head|tail|wc) [ "$SEG_IDX" -gt 0 ] && return 0; return 1 ;;
  esac
  return 1
}

# Split on && || ; |  (each segment must be allowlisted; head/tail/wc only as pipe sinks).
SEG_IDX=0
while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg_ok "$seg" || deny "run work commands (${seg%% *})"
  SEG_IDX=$((SEG_IDX+1))
done < <(printf '%s\n' "$CMD" | sed -E 's/&&|\|\||;|\|/\n/g')
exit 0
