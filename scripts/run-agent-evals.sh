#!/usr/bin/env bash

set -euo pipefail

CC_BIN="${CC_BIN:-$HOME/.local/bin/cc}"
if [[ ! -x "${CC_BIN}" ]]; then
  CC_BIN="$(command -v cc || true)"
fi
if [[ -z "${CC_BIN}" ]]; then
  echo "cc is not installed or not on PATH" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
git -C "${SCRATCH}" init -q

while IFS= read -r agent; do
  (
    cd "${SCRATCH}"
    "${CC_BIN}" eval run \
      --agent "${agent}" \
      --threshold 1.0 \
      --evals-dir "${ROOT}/.claude/evals" \
      --repo-root "${ROOT}" \
      --json >/dev/null
  )
done < <(cd "${ROOT}" && python3 - <<'PY'
import json
from pathlib import Path

catalog = json.loads(Path("plugins/codex-copilot/agent-catalog.json").read_text())
print("protocol")
for agent in catalog["agents"]:
    print(agent["id"])
PY
)

echo "Agent contract evals passed"
