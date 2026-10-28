"""Parity and packaging contract for the `$new-product` skill.

The skill is authored upstream in claude-copilot at `.claude/skills/new-product/`
and vendored here byte-for-byte at `plugins/codex-copilot/skills/new-product/`.
Two gates keep the copies identical:

* the mirror must match `parity/skill-folder-hashes.json`, the committed
  per-file SHA-256 manifest of the whole folder (so a local edit cannot drift
  silently, and SKILL.md is not the only file covered), and
* when a claude-copilot checkout carrying the skill is available
  (`CLAUDE_COPILOT_ROOT`, or a sibling `claude-copilot`), its folder must be
  byte-identical to the mirror.

Update the manifest after a deliberate re-vendoring with:

    python3 tests/test_new_product_parity.py --write-manifest
"""

import hashlib
import json
import os
import pathlib
import re
import shutil
import sys
import tempfile
import unittest

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
SKILL = "new-product"
MIRROR = ROOT / "plugins/codex-copilot/skills" / SKILL
POLICY = ROOT / "plugins/codex-copilot/agent-prompts" / f"{SKILL}.openai.yaml"
MANIFEST = ROOT / "parity/skill-folder-hashes.json"


def tree_hashes(folder: pathlib.Path) -> dict:
    """Relative path -> sha256 for every file; symlinks are reported, never followed."""
    hashes = {}
    for path in sorted(folder.rglob("*")):
        if path.is_symlink():
            hashes[path.relative_to(folder).as_posix()] = "symlink:" + os.readlink(path)
        elif path.is_file():
            hashes[path.relative_to(folder).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return hashes


def divergence(expected: dict, actual: dict) -> dict:
    return {
        "missing": sorted(set(expected) - set(actual)),
        "extra": sorted(set(actual) - set(expected)),
        "changed": sorted(n for n in set(expected) & set(actual) if expected[n] != actual[n]),
    }


def find_upstream_skill():
    candidate = pathlib.Path(
        os.environ.get("CLAUDE_COPILOT_ROOT", ROOT.parent / "claude-copilot")
    ).expanduser().resolve()
    skill = candidate / ".claude/skills" / SKILL
    return skill if (skill / "SKILL.md").is_file() else None


class NewProductMirrorParityTest(unittest.TestCase):
    def test_mirror_matches_committed_whole_folder_manifest(self):
        manifest = json.loads(MANIFEST.read_text())
        self.assertEqual(manifest["schemaVersion"], 1)
        expected = manifest["skills"][SKILL]
        self.assertTrue(expected, "manifest lists no files for the skill")
        self.assertEqual(
            divergence(expected, tree_hashes(MIRROR)),
            {"missing": [], "extra": [], "changed": []},
        )

    def test_mirror_is_byte_identical_to_claude_copilot_source(self):
        upstream = find_upstream_skill()
        if upstream is None:
            self.skipTest("no claude-copilot checkout carrying .claude/skills/new-product")
        self.assertEqual(
            divergence(tree_hashes(upstream), tree_hashes(MIRROR)),
            {"missing": [], "extra": [], "changed": []},
            f"mirror diverges from {upstream}",
        )

    def test_divergence_check_detects_one_byte_change_removal_and_addition(self):
        baseline = tree_hashes(MIRROR)
        with tempfile.TemporaryDirectory() as tmp:
            copy = pathlib.Path(tmp) / SKILL
            shutil.copytree(MIRROR, copy)
            self.assertEqual(divergence(baseline, tree_hashes(copy)), {"missing": [], "extra": [], "changed": []})

            skill_md = copy / "SKILL.md"
            data = bytearray(skill_md.read_bytes())
            data[-1] ^= 0x01
            skill_md.write_bytes(bytes(data))
            self.assertEqual(divergence(baseline, tree_hashes(copy))["changed"], ["SKILL.md"])

            data[-1] ^= 0x01
            skill_md.write_bytes(bytes(data))
            reference = next((copy / "references").glob("*.md"))
            reference.unlink()
            (copy / "assets/extra.md").write_text("x")
            result = divergence(baseline, tree_hashes(copy))
            self.assertEqual(result["missing"], [reference.relative_to(copy).as_posix()])
            self.assertEqual(result["extra"], ["assets/extra.md"])
            self.assertEqual(result["changed"], [])

    def test_skill_frontmatter_is_valid_and_codex_safe(self):
        text = (MIRROR / "SKILL.md").read_text(encoding="utf-8")
        meta = yaml.safe_load(text.split("---", 2)[1])
        self.assertEqual(meta["name"], SKILL)
        self.assertRegex(meta["name"], r"^[a-z0-9]+(-[a-z0-9]+)*$")
        self.assertGreaterEqual(len(meta["description"]), 80)
        self.assertIn("$new-product", meta["description"])
        self.assertLessEqual(set(meta), {"name", "description"})

    def test_codex_only_policy_lives_outside_the_shared_folder(self):
        self.assertTrue(POLICY.is_file())
        policy = yaml.safe_load(POLICY.read_text())
        self.assertEqual(policy["policy"]["allow_implicit_invocation"], False)
        self.assertEqual(policy["interface"]["display_name"], "New Product")
        self.assertIn("$new-product", policy["interface"]["default_prompt"])
        # A nested agents/ directory would hide the skill from Codex.
        self.assertFalse((MIRROR / "agents").exists())
        self.assertFalse(list(MIRROR.rglob("*.openai.yaml")))

    def test_plugin_packaging_ships_the_skill_with_the_plugin(self):
        plugin_root = ROOT / "plugins/codex-copilot"
        manifest = json.loads((plugin_root / ".codex-plugin/plugin.json").read_text())
        skills_root = (plugin_root / manifest["skills"]).resolve()
        self.assertEqual(skills_root, (plugin_root / "skills").resolve())
        self.assertTrue((skills_root / SKILL / "SKILL.md").is_file())
        self.assertFalse(any(p.is_symlink() for p in MIRROR.rglob("*")))

    def test_mirror_has_no_runtime_specific_paths_outside_the_adapter(self):
        offenders = []
        for path in MIRROR.rglob("*.md"):
            if path.name == "runtime.md":
                continue
            text = path.read_text(encoding="utf-8")
            offenders += [f"{path.relative_to(MIRROR)}: {t}" for t in ("@agent-", ".claude/") if t in text]
        self.assertEqual(offenders, [])


if __name__ == "__main__":
    if sys.argv[1:] == ["--write-manifest"]:
        existing = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"schemaVersion": 1, "skills": {}}
        existing["skills"][SKILL] = tree_hashes(MIRROR)
        MANIFEST.write_text(json.dumps(existing, indent=2, sort_keys=True) + "\n")
        print(f"wrote {MANIFEST}")
    else:
        unittest.main()
