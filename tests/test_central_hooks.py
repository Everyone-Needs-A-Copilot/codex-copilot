"""Central-model hooks: frozen plugin shims, marker gate, delegation to the release pointer."""
import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from central_helpers import link_central_release

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugins/codex-copilot"
HOOKS = PLUGIN / "hooks"
HOOKS_JSON_SHA256 = "f67888ce20153ec1cc30f66287c971ce92b6e463a7ae749a6f8910c8b4833f77"
GATED = ["debug-circuit-breaker", "design-feedback", "subagent-return-contract", "user-prompt-protocol"]


class FrozenPluginTests(unittest.TestCase):
    def test_hooks_json_is_byte_identical_to_0_16_8(self):
        self.assertEqual(hashlib.sha256((HOOKS / "hooks.json").read_bytes()).hexdigest(), HOOKS_JSON_SHA256)

    def test_plugin_has_no_symlinks_or_generated_files(self):
        tracked = subprocess.run(["git", "ls-files", "-z", str(PLUGIN)], cwd=ROOT, capture_output=True,
                                 text=True, check=True).stdout.split("\0")
        for rel in filter(None, tracked):
            self.assertFalse((ROOT / rel).is_symlink(), rel)
            self.assertNotIn("__pycache__", rel)

    def test_every_hook_script_is_a_thin_shim(self):
        for script in HOOKS.glob("*.sh"):
            text = script.read_text()
            self.assertLess(len(text.splitlines()), 20, script.name)
            self.assertIn(f"templates/central-hooks/{script.name}", text)
            self.assertTrue((ROOT / "templates/central-hooks" / script.name).is_file())


FROZEN_FILES = [
    ".codex-plugin/plugin.json",
    "hooks/coordinator-guard.sh",
    "hooks/debug-circuit-breaker.sh",
    "hooks/design-feedback.sh",
    "hooks/hooks.json",
    "hooks/subagent-return-contract.sh",
    "hooks/user-prompt-protocol.sh",
]
# sha256 over sorted "relpath NUL content-sha256" lines. Changing this value means Codex
# hook trust is invalidated for every user; it must not change in ordinary releases.
FROZEN_TREE_SHA256 = "b03913bce82aab238e39f3c2c47cb824500b18f1b7d1a03112f6952ad04632a2"


def plugin_tree_hash():
    files = sorted(str(p.relative_to(PLUGIN)) for p in PLUGIN.rglob("*") if p.is_file())
    digest = hashlib.sha256()
    for rel in files:
        digest.update(f"{rel}\0{hashlib.sha256((PLUGIN / rel).read_bytes()).hexdigest()}\n".encode())
    return files, digest.hexdigest()


class FrozenPluginDirectoryTests(unittest.TestCase):
    def test_plugin_directory_holds_only_frozen_files(self):
        files, _ = plugin_tree_hash()
        self.assertEqual(files, FROZEN_FILES)

    def test_plugin_directory_hash_is_frozen(self):
        _, tree = plugin_tree_hash()
        self.assertEqual(tree, FROZEN_TREE_SHA256, "plugin dir changed; Codex would show hooks as modified")

    def test_plugin_version_is_decoupled_from_product_version(self):
        version = json.loads((ROOT / "VERSION.json").read_text())
        plugin = json.loads((PLUGIN / ".codex-plugin/plugin.json").read_text())
        self.assertEqual(plugin["version"], version["pluginCoreVersion"])
        self.assertNotEqual(plugin["version"], version["version"])

    def test_moved_content_lives_in_the_release_tree(self):
        for rel in ["skills/protocol/SKILL.md", "agent-catalog.json", "agent-prompts/protocol.openai.yaml",
                    "scripts/protocol-cycle.py"]:
            self.assertTrue((ROOT / rel).is_file(), rel)


class MarkerGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.home = self.tmp / "home"
        self.home.mkdir()
        link_central_release(self.home)
        self.env = {**os.environ, "HOME": str(self.home)}

    def run_hook(self, name, payload, cwd=None):
        return subprocess.run(["/bin/bash", str(HOOKS / f"{name}.sh")], input=json.dumps(payload),
                              capture_output=True, text=True, env=self.env, cwd=cwd)

    def test_gated_hooks_are_silent_without_marker(self):
        bare = self.tmp / "bare"
        bare.mkdir()
        for name in GATED:
            r = self.run_hook(name, {"prompt": "hello", "cwd": str(bare)}, cwd=bare)
            self.assertEqual((r.returncode, r.stdout, r.stderr), (0, "", ""), name)

    def test_gated_hook_fires_with_marker_in_ancestor(self):
        proj = self.tmp / "proj"
        (proj / "src/deep").mkdir(parents=True)
        (proj / "copilot.project.json").write_text("{}")
        r = self.run_hook("user-prompt-protocol", {"prompt": "hi", "cwd": str(proj / "src/deep")})
        self.assertEqual(r.returncode, 0)
        self.assertIn("Coordinator rule", r.stdout)
        r = self.run_hook("subagent-return-contract", {"cwd": str(proj)})
        self.assertIn("SubagentStart", r.stdout)

    def test_marker_found_from_pwd_when_payload_has_no_cwd(self):
        proj = self.tmp / "proj2"
        proj.mkdir()
        (proj / "copilot.project.json").write_text("{}")
        r = self.run_hook("user-prompt-protocol", {"prompt": "hi"}, cwd=proj)
        self.assertIn("Coordinator rule", r.stdout)

    def test_missing_release_pointer_is_a_silent_no_op(self):
        proj = self.tmp / "proj3"
        proj.mkdir()
        (proj / "copilot.project.json").write_text("{}")
        empty = self.tmp / "emptyhome"
        empty.mkdir()
        for name in GATED + ["coordinator-guard"]:
            r = subprocess.run(["/bin/bash", str(HOOKS / f"{name}.sh")], input="{}", capture_output=True,
                               text=True, env={**os.environ, "HOME": str(empty)}, cwd=proj)
            self.assertEqual((r.returncode, r.stdout), (0, ""), name)

    def test_coordinator_guard_is_not_marker_gated(self):
        bare = self.tmp / "bare"
        bare.mkdir()
        transcript = self.tmp / "main.jsonl"
        transcript.write_text(json.dumps({"payload": {"source": "cli", "thread_source": "user"}}) + "\n")
        payload = {"tool_name": "Bash", "tool_input": {"command": "cat README.md"},
                   "transcript_path": str(transcript), "cwd": str(bare)}
        r = self.run_hook("coordinator-guard", payload, cwd=bare)
        self.assertEqual(r.returncode, 0)
        self.assertIn("deny", r.stdout)


if __name__ == "__main__":
    unittest.main()
