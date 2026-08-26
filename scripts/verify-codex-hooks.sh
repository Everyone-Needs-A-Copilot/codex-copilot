#!/usr/bin/env bash
# Failable contract checks for the Codex-native plugin hooks.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_ROOT="${ROOT}/plugins/codex-copilot/hooks"
STATE_DIR="$(mktemp -d)"
trap 'rm -rf "${STATE_DIR}"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_debug_hook() {
  CODEX_COPILOT_HOOK_STATE_DIR="${STATE_DIR}" \
    bash "${HOOK_ROOT}/debug-circuit-breaker.sh"
}

jq -e '.hooks.UserPromptSubmit and .hooks.PreToolUse and .hooks.PostToolUse and .hooks.SubagentStart' \
  "${HOOK_ROOT}/hooks.json" >/dev/null || fail "hooks.json is missing a required event"

NON_MATCH="$(printf '%s' '{"prompt":"Summarize this note."}' | bash "${HOOK_ROOT}/user-prompt-protocol.sh")"
[[ -z "${NON_MATCH}" ]] || fail "routing hook emitted output for an unrelated prompt"

ROUTED="$(printf '%s' '{"prompt":"This backend API is failing."}' | bash "${HOOK_ROOT}/user-prompt-protocol.sh")"
[[ "$(jq -r '.hookSpecificOutput.hookEventName' <<< "${ROUTED}")" == "UserPromptSubmit" ]] || fail "routing hook returned the wrong event"
[[ "$(jq -r '.hookSpecificOutput.additionalContext' <<< "${ROUTED}")" == *'$qa'* ]] || fail "defect routing did not select qa"

SUBAGENT="$(printf '%s' '{}' | bash "${HOOK_ROOT}/subagent-return-contract.sh")"
[[ "$(jq -r '.hookSpecificOutput.additionalContext' <<< "${SUBAGENT}")" == *'three sentences'* ]] || fail "subagent contract was not injected"

POST_FAILURE='{"hook_event_name":"PostToolUse","session_id":"session-a","tool_name":"Bash","tool_input":{"command":"git -C /tmp/example status 42"},"tool_response":{"exit_code":1,"output":"fatal: failed"}}'
PRE_REPEAT='{"hook_event_name":"PreToolUse","session_id":"session-a","tool_name":"Bash","tool_input":{"command":"git -C /another/path status 99"}}'

FIRST="$(printf '%s' "${POST_FAILURE}" | run_debug_hook)"
[[ -z "${FIRST}" ]] || fail "first failure should be silent"

SECOND="$(printf '%s' "${POST_FAILURE}" | run_debug_hook)"
[[ "$(jq -r '.hookSpecificOutput.hookEventName' <<< "${SECOND}")" == "PostToolUse" ]] || fail "second failure did not emit PostToolUse context"

DENIAL="$(printf '%s' "${PRE_REPEAT}" | run_debug_hook)"
[[ "$(jq -r '.hookSpecificOutput.permissionDecision' <<< "${DENIAL}")" == "deny" ]] || fail "third repeat was not denied"

AFTER_RESET="$(printf '%s' "${PRE_REPEAT}" | run_debug_hook)"
[[ -z "${AFTER_RESET}" ]] || fail "denial did not reset the command-shape counter"

BYPASS="$(printf '%s' "${PRE_REPEAT}" | COPILOT_DEBUG_BLOCK=off run_debug_hook)"
[[ -z "${BYPASS}" ]] || fail "COPILOT_DEBUG_BLOCK=off did not bypass enforcement"

echo "Codex hook verification passed"
