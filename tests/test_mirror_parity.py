import json
import os
import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
CLAUDE_VERSION = pathlib.Path(
    os.environ.get("CLAUDE_COPILOT_ROOT", ROOT.parent / "claude-copilot")
) / "VERSION.json"

EXPECTED_AGENTS = [
    "cco",
    "cpa",
    "cs",
    "cw",
    "do",
    "doc",
    "ind",
    "kc",
    "me",
    "qa",
    "sd",
    "sec",
    "ta",
    "uid",
    "uids",
    "uxd",
]

EXPECTED_COMMAND_SKILLS = [
    "config",
    "continue",
    "extensions",
    "knowledge-copilot",
    "map",
    "memory",
    "orchestrate",
    "pause",
    "reflect",
    "setup-copilot",
    "setup-project",
    "skills-approve",
    "update-copilot",
    "update-project",
]


class MirrorParityTest(unittest.TestCase):
    def load_catalog(self):
        return json.loads((ROOT / "plugins/codex-copilot/agent-catalog.json").read_text())

    def test_catalog_declares_claude_56_mirror(self):
        catalog = self.load_catalog()
        self.assertEqual(catalog["version"], "0.2.0")
        self.assertEqual(catalog["mirrors"]["source"], "claude-copilot")
        self.assertEqual(catalog["mirrors"]["framework"], "5.6.0")
        self.assertEqual(catalog["mirrors"]["mode"], "codex-native")

    def test_agent_roster_matches_claude_baseline(self):
        expected = EXPECTED_AGENTS
        if CLAUDE_VERSION.exists():
            source = json.loads(CLAUDE_VERSION.read_text())
            expected = source["components"]["agents"]["frameworkAgents"]

        catalog = self.load_catalog()
        actual = sorted(agent["id"] for agent in catalog["agents"])
        self.assertEqual(actual, sorted(expected))

        for agent_id in expected:
            self.assertTrue(
                (ROOT / f"plugins/codex-copilot/skills/agent-{agent_id}/SKILL.md").exists(),
                f"missing skill for agent {agent_id}",
            )
            self.assertTrue(
                (ROOT / f"plugins/codex-copilot/agent-prompts/agent-{agent_id}.openai.yaml").exists(),
                f"missing prompt metadata for agent {agent_id}",
            )

    def test_workflows_match_mirror_contract(self):
        workflows = self.load_catalog()["workflows"]
        self.assertEqual(workflows["bug"], ["qa", "me", "qa"])
        self.assertEqual(workflows["technical_feature"], ["ta", "me", "qa"])
        self.assertEqual(
            workflows["experience_feature"],
            ["sd", "uxd", "uids", "uid", "ta", "me", "qa"],
        )
        self.assertEqual(workflows["infrastructure"], ["do", "me", "qa"])
        self.assertEqual(workflows["creative_branch"], ["cco", "cw"])
        self.assertEqual(workflows["business_advisory"], ["cs", "cpa"])

    def test_command_equivalent_skills_exist(self):
        for skill in EXPECTED_COMMAND_SKILLS:
            self.assertTrue(
                (ROOT / f"plugins/codex-copilot/skills/{skill}/SKILL.md").exists(),
                f"missing command-equivalent skill {skill}",
            )
            self.assertTrue(
                (ROOT / f"plugins/codex-copilot/agent-prompts/{skill}.openai.yaml").exists(),
                f"missing command-equivalent prompt metadata {skill}",
            )

    def test_shared_behaviors_are_discoverable(self):
        shared = ROOT / "plugins/codex-copilot/skills/specialist-agents/references/shared-behaviors.md"
        specialist = ROOT / "plugins/codex-copilot/skills/specialist-agents/SKILL.md"
        self.assertTrue(shared.exists())
        self.assertIn("shared-behaviors.md", specialist.read_text())

    def test_no_stale_experience_chain_in_public_docs(self):
        stale = "sd -> uxd -> uids -> ta -> me -> qa"
        checked = [
            ROOT / "README.md",
            ROOT / "docs/protocol.md",
            ROOT / "docs/usage.md",
            ROOT / "plugins/codex-copilot/skills/protocol/SKILL.md",
            ROOT / "plugins/codex-copilot/skills/protocol/references/flows.md",
            ROOT / "plugins/codex-copilot/skills/agent-launcher/references/workflows.md",
        ]
        for path in checked:
            self.assertNotIn(stale, path.read_text(), f"stale chain in {path}")

    def test_setup_script_refuses_destructive_replacement(self):
        script = (ROOT / "scripts/setup-project.sh").read_text()
        self.assertNotRegex(script, re.compile(r"\brm\s+-"))
        self.assertNotIn("sed -i.bak", script)
        self.assertIn("Refusing to replace", script)
        self.assertIn("Refusing to overwrite", script)

    def test_no_stale_cc_source_path(self):
        for rel in ["AGENTS.md", "templates/AGENTS.project.template.md"]:
            text = (ROOT / rel).read_text()
            self.assertNotIn("/Volumes/Dev/Sites/COPILOT/claude-copilot", text)
            self.assertNotIn("/Users/", text)
            self.assertIn("Claude Copilot `tools/cc/`", text)

    def test_public_docs_do_not_ship_local_absolute_paths(self):
        checked_roots = [
            ROOT / "README.md",
            ROOT / "CHANGELOG.md",
            ROOT / "CONTRIBUTING.md",
            ROOT / "SECURITY.md",
            ROOT / "AGENTS.md",
            ROOT / "docs",
            ROOT / "templates",
        ]
        paths = []
        for item in checked_roots:
            if item.is_dir():
                paths.extend(item.rglob("*.md"))
            else:
                paths.append(item)

        allowed = {ROOT / "docs/publishing.md"}
        for path in paths:
            if path in allowed:
                continue
            text = path.read_text()
            self.assertNotIn("/Users/", text, f"local user path in {path}")
            self.assertNotIn("/Volumes/", text, f"local volume path in {path}")

    def test_capability_matrix_covers_mirrored_surfaces(self):
        text = (ROOT / "docs/capabilities.md").read_text()
        for term in [
            "$protocol",
            "$continue",
            "$pause",
            "$orchestrate",
            "$knowledge-copilot",
            "16 `agent-*` Codex skills",
            "cc memory",
            "cc skill",
            "tc",
            "Mechanical Claude hooks",
            "Headless worker orchestration",
        ]:
            self.assertIn(term, text)

    def test_getting_started_and_setup_docs_match_bootstrap_outputs(self):
        getting_started = (ROOT / "docs/getting-started.md").read_text()
        setup = (ROOT / "docs/setup-project.md").read_text()
        for term in [
            ".claude/cc/config.json",
            ".claude/memory/entries/",
            ".claude/skills/codex-copilot",
            "plugins/codex-copilot",
        ]:
            self.assertIn(term, getting_started)
            self.assertIn(term, setup)
        self.assertIn("git repository", getting_started)
        self.assertIn("git repository", setup)

    def test_force_guidance_matches_script_behavior(self):
        setup_doc = (ROOT / "docs/setup-project.md").read_text()
        setup_skill = (ROOT / "plugins/codex-copilot/skills/setup-project/SKILL.md").read_text()
        self.assertIn("does not override", setup_doc)
        self.assertIn("compatibility-only", setup_skill)
        self.assertNotIn("Do not use `--force` unless", setup_skill)


if __name__ == "__main__":
    unittest.main()
