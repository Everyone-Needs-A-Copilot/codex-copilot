#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/copilot-gate.sh [--task TASK_ID]

Checks Codex Copilot QA-gate state in tc. A task that declares
metadata.requiresQa=true must have either metadata.qaStatus=approved or a test
work product whose content includes VERDICT: APPROVED.
EOF
}

TASK_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)
      TASK_ID="${2:-}"
      shift 2
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

if ! command -v tc >/dev/null 2>&1; then
  echo "copilot-gate: tc is not installed or not on PATH" >&2
  exit 2
fi

python3 - "$TASK_ID" <<'PY'
import json
import subprocess
import sys


task_id = sys.argv[1]


def run_json(cmd):
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    text = result.stdout.strip()
    return json.loads(text) if text else None


def metadata(task):
    raw = task.get("metadata")
    if not raw:
        return {}
    if isinstance(raw, dict):
        return raw
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def task_wps(tid):
    try:
        return run_json(["tc", "wp", "list", "--task", str(tid), "--json"]) or []
    except subprocess.CalledProcessError:
        return []


def wp_content(wp):
    wid = wp.get("id")
    if not wid:
        return ""
    try:
        full = run_json(["tc", "wp", "get", str(wid), "--json"]) or {}
    except subprocess.CalledProcessError:
        return ""
    return str(full.get("content") or "")


if task_id:
    tasks = [run_json(["tc", "task", "get", task_id, "--json"])]
else:
    tasks = run_json(["tc", "task", "list", "--json"]) or []

blocked = []
checked = 0

for task in tasks:
    if not task:
        continue
    meta = metadata(task)
    requires_qa = bool(meta.get("requiresQa"))
    if not requires_qa:
        continue
    checked += 1
    qa_status = str(meta.get("qaStatus") or "").lower()
    if qa_status in {"approved", "approved-with-minor-fixes"}:
        continue
    verdict_ok = False
    for wp in task_wps(task["id"]):
        if wp.get("type") != "test":
            continue
        content = wp_content(wp).upper()
        if "VERDICT: APPROVED" in content:
            verdict_ok = True
            break
    if not verdict_ok:
        blocked.append(f"TASK-{task['id']}: {task.get('title', '').strip()}")

if blocked:
    print("QA gate failed:")
    for item in blocked:
        print(f"- {item}")
    sys.exit(1)

print(f"QA gate passed ({checked} QA-required task(s) checked)")
PY
