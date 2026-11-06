#!/bin/bash
# Frozen shim - do not edit. Codex hashes this whole plugin directory for hook
# trust, so this file must stay byte-identical across releases. Real logic:
# $HOME/.copilot/current/codex-copilot/templates/central-hooks/coordinator-guard.sh
REAL="$HOME/.copilot/current/codex-copilot/templates/central-hooks/coordinator-guard.sh"
[ -f "$REAL" ] || exit 0
exec /bin/bash "$REAL"
