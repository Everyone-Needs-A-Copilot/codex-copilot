import json
import os
from pathlib import Path
import subprocess

import pytest

ADAPTER = Path(__file__).resolve().parents[1] / "plugins/codex-copilot/hooks/safety-policy.sh"
PAYLOAD = {"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "git status"}}


def run(cc, payload=PAYLOAD):
    return subprocess.run(["bash", str(ADAPTER)], input=json.dumps(payload), text=True,
                          capture_output=True, env={**os.environ, "CODEX_COPILOT_CC": str(cc)})


@pytest.mark.parametrize("decision,exit_code", [("allow", 0), ("warn", 0), ("deny", 2), ("error", 2), ("unexpected", 2)])
def test_decisions(tmp_path, decision, exit_code):
    cc = tmp_path / "cc"
    cc.write_text("#!/bin/sh\ncat >/dev/null\nprintf '%s' '" + json.dumps({"schema_version": 1, "decision": decision, "reason": "fixture"}) + "'\n")
    cc.chmod(0o755)
    result = run(cc)
    assert result.returncode == exit_code
    if exit_code == 2:
        assert result.stderr.strip(), "Codex requires stderr with exit 2"


def test_missing_evaluator_denies(tmp_path):
    result = run(tmp_path / "missing")
    assert result.returncode == 2 and result.stderr.strip()


def test_failed_evaluator_cannot_allow(tmp_path):
    cc = tmp_path / "cc"
    cc.write_text('#!/bin/sh\ncat >/dev/null\necho \'{"schema_version":1,"decision":"allow","reason":"bad"}\'\nexit 1\n')
    cc.chmod(0o755)
    assert run(cc).returncode == 2


@pytest.mark.parametrize("payload", [None, {}, {"tool_name": "apply_patch"}, {**PAYLOAD, "tool_input": {"command": None}}])
def test_unknown_payload_denies(payload):
    assert run("/bin/true", payload).returncode == 2
