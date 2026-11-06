#!/bin/bash
# Frozen shim - do not edit. Codex hashes this whole plugin directory for hook
# trust, so this file must stay byte-identical across releases. Real logic:
# $HOME/.copilot/current/codex-copilot/templates/central-hooks/subagent-return-contract.sh
REAL="$HOME/.copilot/current/codex-copilot/templates/central-hooks/subagent-return-contract.sh"
[ -f "$REAL" ] || exit 0
PAYLOAD="$(cat 2>/dev/null)"
DIR=""
if command -v jq >/dev/null 2>&1; then DIR="$(jq -r '.cwd // empty' <<< "$PAYLOAD" 2>/dev/null)"; fi
[ -d "$DIR" ] || DIR="$PWD"
while :; do
  [ -f "$DIR/copilot.project.json" ] && break
  [ "$DIR" = "/" ] || [ -z "$DIR" ] && exit 0
  DIR="$(dirname "$DIR")"
done
exec /bin/bash "$REAL" <<< "$PAYLOAD"
