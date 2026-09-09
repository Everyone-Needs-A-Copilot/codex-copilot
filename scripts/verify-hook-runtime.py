#!/usr/bin/env python3
"""Exercise the installed Codex binary with canned responses; no model inference.

The loopback fixture only emits fixed, harmless tool calls. By default test hooks
and trust overrides are invocation-scoped. --project instead verifies saved
registration and trust without overriding them. Neither mode edits user config.
"""
import argparse
import json
from pathlib import Path
import select
import shlex
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer


def rpc(process, rid, method, params):
    process.stdin.write(json.dumps(dict(id=rid, method=method, params=params)) + "\n")
    process.stdin.flush()
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        if not select.select([process.stdout], [], [], 1)[0]:
            continue
        line = process.stdout.readline()
        if not line:
            raise RuntimeError("app-server closed before reply")
        row = json.loads(line)
        if row.get("id") == rid:
            if "error" in row:
                raise RuntimeError(str(row["error"]))
            return row["result"]
    raise RuntimeError(f"app-server timeout: {method}")


def discover(binary, project, overrides):
    command = [binary, "app-server", "--stdio"]
    for value in overrides:
        command += ["-c", value]
    process = subprocess.Popen(command, cwd=project, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    try:
        rpc(process, 1, "initialize", {"clientInfo": {"name": "copilot-canary", "version": "1"},
                                     "capabilities": {"experimentalApi": True}})
        config = rpc(process, 3, "config/read", {"cwd": str(project), "includeLayers": True})
        result = rpc(process, 2, "hooks/list", {"cwds": [str(project)]})
        result["config_layers"] = [{"name": x.get("name"), "disabledReason": x.get("disabledReason")}
                                   for x in config.get("layers", [])]
        return result
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--codex", default="codex")
    parser.add_argument("--hook-command", help="Explicit, reviewed candidate adapter command to test")
    parser.add_argument("--project", type=Path,
                        help="Verify saved hooks/trust in this project, with no hook overrides")
    args = parser.parse_args()
    if args.project and args.hook_command:
        parser.error("--project uses saved registration; --hook-command cannot be combined")
    evidence = Path(tempfile.mkdtemp(prefix="copilot-runtime-")).resolve()
    project = args.project.resolve(strict=True) if args.project else evidence
    if not args.project:
        subprocess.run(["git", "init", "-q", str(project)], check=True)
        config_dir = project / ".codex"
        config_dir.mkdir()
        (config_dir / "config.toml").write_text("[features]\nhooks = true\n")
    hook = evidence / "canary.py"
    hook.write_text('''import json, pathlib, sys
p = json.load(sys.stdin)
with pathlib.Path(__file__).with_name("hook-log.jsonl").open("a") as f:
    f.write(json.dumps(p) + "\\n")
if "denied-sentinel" in p.get("tool_input", {}).get("command", ""):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
        "permissionDecision": "deny", "permissionDecisionReason": "copilot harmless canary deny"}}))
''')
    declaration = {"hooks": {"PreToolUse": [{"matcher": "^Bash$", "hooks": [{
        "type": "command", "command": f"{shlex.quote(sys.executable)} {shlex.quote(str(hook))}",
        "timeout": 3}]}]}}
    if not args.project:
        (config_dir / "hooks.json").write_text(json.dumps(declaration))
    hook_command = args.hook_command or declaration["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
    overrides = [] if args.project else ["features.hooks=true", "features.plugins=false", "features.apps=false",
                 'hooks.PreToolUse=[{matcher="^Bash$",hooks=[{type="command",command='
                 + json.dumps(hook_command) + ',timeout=3}]}]']
    discovered = discover(args.codex, project, overrides)
    (evidence / "discovery.json").write_text(json.dumps(discovered, indent=2))
    entries = [h for row in discovered["data"] for h in row["hooks"]]
    if not entries:
        raise RuntimeError(f"No canary hook discovered; evidence at {evidence}")
    print(json.dumps({"evidence": str(evidence), "project": str(project), "stage": "discovered"}), flush=True)
    selected = [h for h in entries if ("safety-policy.sh" in h["command"]
                if args.project else h["command"] == hook_command)]
    assert len(selected) == 1, "Ambiguous canary registration"
    entry = selected[0]
    if args.project:
        assert entry["enabled"] and entry["trustStatus"] == "trusted", "Saved safety hook not trusted/enabled"
        assert not any(x.get("disabledReason") for x in discovered["config_layers"]), "Disabled config layer"
    else:
        overrides.append('hooks.state={' + json.dumps(entry["key"]) + '={trusted_hash='
                         + json.dumps(entry["currentHash"]) + '}}')
    trusted = discover(args.codex, project, overrides)
    (evidence / "trusted-discovery.json").write_text(json.dumps(trusted, indent=2))
    assert any(h["trustStatus"] == "trusted" and h["key"] == entry["key"]
               for row in trusted["data"] for h in row["hooks"]), "Trust override not effective"
    requests = []

    class Fixture(BaseHTTPRequestHandler):
        def log_message(self, *unused):
            pass

        def do_GET(self):
            data = json.dumps({"models": []}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def do_POST(self):
            raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            if self.headers.get("Content-Encoding"):
                raise RuntimeError("Fixture requires uncompressed requests")
            body = json.loads(raw)
            requests.append(body)
            index = len(requests)
            if index <= 2:
                target = "allowed-sentinel" if index == 1 else "denied-sentinel"
                item = {"type": "function_call", "id": f"fc_{index}",
                        "call_id": f"call_{index}", "name": "exec_command",
                        "arguments": json.dumps({"cmd": "touch " + shlex.quote(str(evidence / target)) if index == 1 else
                                                 "printf 'git push origin --force' > " + shlex.quote(str(evidence / target)),
                                                 "workdir": str(project), "yield_time_ms": 1000})}
            else:
                item = {"type": "message", "id": "msg_done", "role": "assistant",
                        "status": "completed", "content": [{"type": "output_text",
                        "text": "Canary complete.", "annotations": []}]}
            events = [{"type": "response.created", "response": {"id": f"resp_{index}"}},
                      {"type": "response.output_item.done", "output_index": 0, "item": item},
                      {"type": "response.completed", "response": {"id": f"resp_{index}",
                       "status": "completed", "output": [item],
                       "usage": {"input_tokens": 1, "output_tokens": 1, "total_tokens": 2}}}]
            data = "".join("event: " + event["type"] + "\ndata: " + json.dumps(event) + "\n\n"
                           for event in events).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    server = HTTPServer(("127.0.0.1", 0), Fixture)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    overrides += ['model_provider="canary"', 'model="gpt-5.1-codex"',
                  'model_providers.canary.name="Local fixed fixture"',
                  f'model_providers.canary.base_url="http://127.0.0.1:{server.server_port}/v1"',
                  'model_providers.canary.wire_api="responses"',
                  'model_providers.canary.requires_openai_auth=false',
                  'model_providers.canary.supports_websockets=false',
                  'features.enable_request_compression=false',
                  'features.remote_models=false', 'features.shell_snapshot=false',
                  'features.multi_agent=false', 'features.code_mode=false', 'features.apps=false',
                  'approval_policy="never"']
    command = [args.codex, "exec", "--ephemeral", "--json",
               "--sandbox", "workspace-write", "--skip-git-repo-check", "-C", str(project)]
    if not args.project:
        command.append("--ignore-user-config")
    for override in overrides:
        command += ["-c", override]
    command += ["Run the fixed local hook canary."]
    try:
        result = subprocess.run(command, input="", capture_output=True, text=True, timeout=40)
        (evidence / "stdout.jsonl").write_text(result.stdout)
        (evidence / "stderr.txt").write_text(result.stderr)
        assert result.returncode == 0, f"CLI exit {result.returncode}: {result.stderr[-2000:]}"
        assert len(requests) == 3, f"Expected 3 fixture requests, got {len(requests)}"
        assert (evidence / "allowed-sentinel").exists(), "Allowed command did not execute"
        assert not (evidence / "denied-sentinel").exists(), "Denied command executed"
        if not args.hook_command and not args.project:
            log = [json.loads(line) for line in (evidence / "hook-log.jsonl").read_text().splitlines()]
            assert len(log) == 2 and all(p["tool_name"] == "Bash" for p in log), "Wrong hook payloads"
        assert "blocked by PreToolUse hook" in json.dumps(requests[-1]), "No deny feedback"
        print(json.dumps({"verdict": "APPROVED", "binary": args.codex,
                          "version": subprocess.check_output([args.codex, "--version"], text=True).strip(),
                          "allowed": True, "denied": True, "evidence": str(evidence),
                          "project": str(project), "saved_registration": bool(args.project)}))
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=3)


if __name__ == "__main__":
    main()
