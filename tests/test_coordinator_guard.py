"""Coordinator-rule PreToolUse guard: main thread restricted, subagents never blocked."""
import json, os, subprocess, tempfile, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOOKS = ROOT / "plugins/codex-copilot/hooks"
GUARD = HOOKS / "coordinator-guard.sh"

class GuardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.home = self.tmp / "home"; self.home.mkdir()
        self.main = self.tmp / "main.jsonl"; self.sub = self.tmp / "sub.jsonl"
        self.main.write_text(json.dumps({"payload": {"source": "cli", "thread_source": "user"}}) + "\n")
        self.sub.write_text(json.dumps({"payload": {"source": {"subagent": {"thread_spawn": {}}}, "thread_source": "subagent"}}) + "\n")

    def run_guard(self, tool, tool_input, transcript, **env):
        e = {**os.environ, "HOME": str(self.home), **env}
        e.pop("COPILOT_COORDINATOR", None) if "COPILOT_COORDINATOR" not in env else None
        payload = {"hook_event_name": "PreToolUse", "tool_name": tool, "tool_input": tool_input,
                   "session_id": "s1", "transcript_path": str(transcript) if transcript else None}
        r = subprocess.run(["/bin/bash", str(GUARD)], input=json.dumps(payload), capture_output=True, text=True, env=e)
        self.assertEqual(r.returncode, 0, r.stderr)
        return "deny" in r.stdout

    def bash(self, cmd, t=None, **env):
        return self.run_guard("Bash", {"command": cmd}, t or self.main, **env)

    def test_main_allowlist(self):
        for c in ["tc task list --json", "cc status", "cc skill get x", "git status --short", "git -C /x log --oneline | head -5",
                  "git worktree list", "/Users/me/.local/bin/cc progress", "git branch"]:
            self.assertFalse(self.bash(c), c)

    def test_main_denied(self):
        for c in ["cat README.md", "ls", "git commit -m x", "git worktree add x", "cc memory search x", "tc task list; rm -rf x",
                  "git log | sh", "git status > out", "echo $(whoami)", "head file"]:
            self.assertTrue(self.bash(c), c)

    def test_subagent_never_blocked(self):
        self.assertFalse(self.bash("cat README.md", self.sub))
        self.assertFalse(self.run_guard("apply_patch", {"command": "*** Begin Patch\n*** Add File: /p/x\n+a\n*** End Patch"}, self.sub))

    def test_fails_open_without_transcript(self):
        self.assertFalse(self.bash("cat x", self.tmp / "missing.jsonl"))
        self.assertFalse(self.run_guard("Bash", {"command": "cat x"}, None))

    def test_edits(self):
        patch = lambda p: {"command": f"*** Begin Patch\n*** Add File: {p}\n+a\n*** End Patch"}
        self.assertTrue(self.run_guard("apply_patch", patch("/proj/a.py"), self.main))
        self.assertFalse(self.run_guard("apply_patch", patch(f"{self.home}/.codex/memories/n.md"), self.main))
        self.assertTrue(self.run_guard("apply_patch", patch(f"{self.home}/.codex/memories/../x"), self.main))
        self.assertTrue(self.run_guard("Write", {"file_path": "/proj/a"}, self.main))
        self.assertFalse(self.run_guard("Write", {"file_path": f"{self.home}/.codex/scratchpad/a"}, self.main))

    def test_other_tools_untouched(self):
        self.assertFalse(self.run_guard("spawn_agent", {"message": "x"}, self.main))

    def test_escape_hatch_logged(self):
        self.assertFalse(self.bash("cat x", COPILOT_COORDINATOR="off"))
        log = self.home / ".codex/log/coordinator-bypass.log"
        self.assertTrue(log.exists() and "coordinator-bypass" in log.read_text())

    def test_prompt_hook_always_injects(self):
        r = subprocess.run(["/bin/bash", str(HOOKS / "user-prompt-protocol.sh")], input=json.dumps({"prompt": "hello"}),
                           capture_output=True, text=True)
        self.assertIn("Coordinator rule (2026-11-05)", json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"])

    def test_hooks_json_registers_guard(self):
        d = json.loads((HOOKS / "hooks.json").read_text())
        self.assertTrue(any("coordinator-guard.sh" in h["command"] for e in d["hooks"]["PreToolUse"] for h in e["hooks"]))

if __name__ == "__main__":
    unittest.main()
