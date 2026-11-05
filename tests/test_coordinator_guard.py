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
                  "git worktree list", "/Users/me/.local/bin/cc progress", "git branch", "git branch -a", "git branch -r", "git branch -v", "git branch --list", "git branch --list 'f*'",
                  "git branch --show-current", "git rev-parse HEAD", "git log --oneline -n 5 && git status"]:
            self.assertFalse(self.bash(c), c)

    def test_main_denied(self):
        for c in ["cat README.md", "ls", "git commit -m x", "git worktree add x", "cc memory search x", "tc task list; rm -rf x",
                  "git log | sh", "git status > out", "echo $(whoami)", "head file",
                  "git status & cat /etc/passwd", "git status &cat /etc/passwd", "git branch -D x", "git branch newbranch", "git branch -v x",
                  "git branch -m a b", "git log --output=f", "git log --output f", "git log --ext-diff", "git log --textconv",
                  "git -c core.pager=sh log", "git log -c", "git status --exec-path=/x", "git log -p", "git log --patch", "git log -sp",
                  "git rev-parse --output=f", "git worktree list --porcelain; git worktree prune", "git worktree remove x"]:
            self.assertTrue(self.bash(c), c)

    def test_git_allowlist_blocks_bypasses(self):
        for c in ["git log --outp=f", "git log --out=f", "git log --ou=f", "git log '--output=f'", 'git log "--outp=f"',
                  "git log --ext", "git log --textc", "git log --cc", "git log --diff-merges=on", "git log --pa", "git log -u",
                  "git log -O f", "git log --open-files-in-pager", "git log --show-signature", "git --git-dir=/x log",
                  "git log --git-dir=/x", "git --work-tree=/x status", "git status --work-tree=/x", "git rev-parse --git-dir=/x",
                  "git log --format=%h\\x", "git log $X", "git log 'a", "git status -uall", "git worktree list --foo",
                  "pwd x", "date -s 12:00", "readlink", "readlink -f x", "git rev-parse --verify HEAD"]:
            self.assertTrue(self.bash(c), c)

    def test_git_allowlist_allows(self):
        for c in ["git status -s", "git status --short -b", "git status --branch", "git status --porcelain", "git status --porcelain=v2",
                  "git log --oneline -n 5", "git log -5", "git log --max-count=3", "git log --format=%h", "git log --pretty='%h %s'",
                  'git log --format="%h %an"', "git log --graph --decorate --all", "git log --since=2.days --until=yesterday --author=bob",
                  "git log --stat", "git log --name-only", "git log --name-status", "git log --first-parent --no-merges",
                  "git log main..HEAD", "git log origin/main...HEAD", "git log HEAD~3 -- src docs/a.md", "git log 'v1.0'",
                  "git branch --list 'f*'", "git branch -vv", "git worktree list --porcelain", "git rev-parse --abbrev-ref HEAD",
                  "git rev-parse --short HEAD", "git rev-parse --show-toplevel", "git rev-parse --git-dir", "git rev-parse --is-inside-work-tree",
                  "pwd", "date", "date -u +%F", "readlink x", "git -C /x status -s"]:
            self.assertFalse(self.bash(c), c)

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
