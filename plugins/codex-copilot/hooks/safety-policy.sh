#!/bin/bash
# Codex adapter for cc's schema-1 shared shell policy. No Claude workflow rules.
# A detected failure denies; host-level skipping/timeouts remain host limitations.
set -uo pipefail

deny() {
  printf '%s\n' "Codex Copilot safety: $1" >&2
  exit 2
}

JQ="$(command -v jq 2>/dev/null)" || deny "jq is unavailable"
CC="${CODEX_COPILOT_CC:-$HOME/.local/bin/cc}"
[[ -x "$CC" ]] || deny "shared cc executable is unavailable"
PAYLOAD="$(cat)" || deny "cannot read hook input"
REQUEST="$("$JQ" -ce '
  if .hook_event_name == "PreToolUse" and .tool_name == "Bash"
     and (.tool_input.command | type) == "string"
     and (.tool_input.command | length) > 0
  then {schema_version:1,operation:"shell",command:.tool_input.command}
  else error("unsupported hook payload") end' <<< "$PAYLOAD" 2>/dev/null)" \
  || deny "unsupported hook payload"

RESULT="$(printf '%s' "$REQUEST" | "$CC" enforcement evaluate --json)" \
  || deny "shared safety evaluation unavailable"
DECISION="$("$JQ" -er '
  select(.schema_version == 1 and (.reason | type) == "string") | .decision |
  select(. == "allow" or . == "warn" or . == "deny")' <<< "$RESULT" 2>/dev/null)" \
  || deny "invalid shared safety response"
REASON="$("$JQ" -r '.reason' <<< "$RESULT")"
case "$DECISION" in
  deny) deny "$REASON" ;;
  warn) "$JQ" -cn --arg reason "$REASON" '{systemMessage:$reason}' ;;
  allow) exit 0 ;;
esac
