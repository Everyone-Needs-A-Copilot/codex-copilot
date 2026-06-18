import json
import os
import pathlib
import re
import subprocess
import tempfile
import textwrap
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_SPECIALISTS = [
    "do",
    "doc",
    "ind",
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
    "setup",
    "setup-copilot",
    "setup-knowledge-sync",
    "setup-project",
    "skills-approve",
    "update-copilot",
    "update-project",
]

OPTIONAL_SPECIALISTS = ["cco", "cpa", "cs", "cw", "kc"]

REQUIRED_SPECIALIST_SECTIONS = [
    "## Success Criteria",
    "## Workflow",
    "## Iteration Loop",
    "## Methodology",
    "## Anti-Generic Rules",
    "## Route To Other Specialist",
]


class DesignLedContractTest(unittest.TestCase):
    def load_catalog(self):
        return json.loads((ROOT / "plugins/codex-copilot/agent-catalog.json").read_text())

    def load_baseline(self):
        return json.loads((ROOT / "parity/claude-baseline.json").read_text())

    def test_catalog_declares_design_led_release(self):
        catalog = self.load_catalog()
        self.assertEqual(catalog["schemaVersion"], "1.0.0")
        self.assertEqual(catalog["version"], "0.5.0")
        self.assertEqual(catalog["entrypoints"]["primary"], "protocol")
        self.assertEqual(catalog["entrypoints"]["launcher"], "launcher")
        self.assertEqual(catalog["designChain"], ["sd", "uxd", "uids", "uid", "ta", "me", "qa"])
        self.assertTrue((ROOT / "plugins/codex-copilot/agent-catalog.schema.json").exists())

    def test_specialist_roster_uses_direct_skill_names(self):
        catalog = self.load_catalog()
        actual = sorted(agent["id"] for agent in catalog["agents"])
        self.assertEqual(actual, sorted(EXPECTED_SPECIALISTS))

        for agent_id in EXPECTED_SPECIALISTS:
            self.assertTrue(
                (ROOT / f"plugins/codex-copilot/skills/{agent_id}/SKILL.md").exists(),
                f"missing skill for agent {agent_id}",
            )
            self.assertFalse(
                (ROOT / f"plugins/codex-copilot/skills/agent-{agent_id}/SKILL.md").exists(),
                f"stale agent-* skill for {agent_id}",
            )
        self.assertTrue((ROOT / "plugins/codex-copilot/skills/launcher/SKILL.md").exists())

    def test_workflows_match_design_led_contract(self):
        workflows = self.load_catalog()["workflows"]
        self.assertEqual(workflows["bug"], ["qa", "me", "qa"])
        self.assertEqual(workflows["technical_feature"], ["ta", "me", "qa"])
        self.assertEqual(
            workflows["experience_feature"],
            ["sd", "uxd", "uids", "uid", "ta", "me", "qa"],
        )
        self.assertEqual(
            workflows["physical_digital_feature"],
            ["ind", "sd", "uxd", "uids", "uid", "ta", "me", "qa"],
        )
        self.assertEqual(workflows["ui_polish"], ["uids", "uid", "qa"])
        self.assertEqual(workflows["security_sensitive"], ["ta", "sec", "me", "qa"])
        self.assertEqual(workflows["infrastructure"], ["do", "me", "qa"])

    def test_catalog_routing_edges_keep_design_chain_explicit(self):
        catalog = self.load_catalog()
        edges = {(edge["from"], edge["to"]) for edge in catalog["routingEdges"]}
        for edge in [
            ("sd", "uxd"),
            ("uxd", "uids"),
            ("uids", "uid"),
            ("uid", "ta"),
            ("ta", "me"),
            ("me", "qa"),
        ]:
            self.assertIn(edge, edges)
        for agent in catalog["agents"]:
            for field in ["id", "skill", "role", "model", "methodology", "purpose"]:
                self.assertIn(field, agent)

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

    def test_parity_baseline_matches_version_and_catalog(self):
        baseline = self.load_baseline()
        version = json.loads((ROOT / "VERSION.json").read_text())
        catalog = self.load_catalog()
        plugin = json.loads((ROOT / "plugins/codex-copilot/.codex-plugin/plugin.json").read_text())

        self.assertEqual(version["version"], baseline["baseline"]["codexParityVersion"])
        self.assertEqual(version["mirrors"]["frameworkVersion"], baseline["baseline"]["frameworkVersion"])
        self.assertEqual(version["components"]["cc"]["requiredVersion"], baseline["components"]["cc"]["version"])
        self.assertEqual(version["components"]["tc"]["requiredVersion"], baseline["components"]["tc"]["version"])
        self.assertEqual(plugin["version"], version["version"])
        self.assertEqual(catalog["version"], version["version"])
        self.assertEqual(sorted(baseline["activeSpecialists"]), sorted(EXPECTED_SPECIALISTS))
        self.assertEqual(sorted(baseline["optionalSpecialists"]), sorted(OPTIONAL_SPECIALISTS))

    def test_optional_business_creative_pack_is_activatable(self):
        manifest = json.loads((ROOT / "packs/business-creative/pack.json").read_text())
        self.assertEqual(sorted(manifest["specialists"]), sorted(OPTIONAL_SPECIALISTS))
        for specialist in OPTIONAL_SPECIALISTS:
            self.assertTrue(
                (ROOT / f"packs/business-creative/skills/{specialist}/SKILL.md").exists(),
                f"missing optional specialist {specialist}",
            )
        catalog_optional = sorted(agent["id"] for agent in self.load_catalog()["optionalAgents"])
        self.assertEqual(catalog_optional, sorted(OPTIONAL_SPECIALISTS))

    def test_all_pack_directories_have_manifests(self):
        for pack_dir in (ROOT / "packs").iterdir():
            if not pack_dir.is_dir():
                continue
            skills_dir = pack_dir / "skills"
            if not skills_dir.exists():
                continue
            manifest_path = pack_dir / "pack.json"
            self.assertTrue(manifest_path.exists(), f"missing pack manifest for {pack_dir.name}")
            manifest = json.loads(manifest_path.read_text())
            self.assertEqual(manifest["name"], pack_dir.name)
            for specialist in manifest["specialists"]:
                self.assertTrue(
                    (skills_dir / specialist / "SKILL.md").exists(),
                    f"{pack_dir.name} manifest references missing skill {specialist}",
                )

    def test_required_parity_docs_and_scripts_exist(self):
        baseline = self.load_baseline()
        for rel in baseline["requiredDocs"]:
            self.assertTrue((ROOT / rel).exists(), f"missing parity doc {rel}")
        for rel in baseline["scripts"]:
            self.assertTrue((ROOT / rel).exists(), f"missing parity script {rel}")

    def test_active_specialists_have_operational_contracts(self):
        for agent_id in EXPECTED_SPECIALISTS:
            text = (ROOT / f"plugins/codex-copilot/skills/{agent_id}/SKILL.md").read_text()
            for section in REQUIRED_SPECIALIST_SECTIONS:
                self.assertIn(section, text, f"{agent_id} missing {section}")

    def test_live_docs_is_wired_into_core_surfaces(self):
        checked = [
            ROOT / "AGENTS.md",
            ROOT / "templates/AGENTS.project.template.md",
            ROOT / "plugins/codex-copilot/skills/specialist-agents/references/shared-behaviors.md",
            ROOT / "plugins/codex-copilot/skills/ta/SKILL.md",
            ROOT / "plugins/codex-copilot/skills/me/SKILL.md",
            ROOT / "plugins/codex-copilot/skills/qa/SKILL.md",
            ROOT / "docs/live-docs.md",
        ]
        for path in checked:
            self.assertIn("cc docs", path.read_text(), f"missing Live Docs guidance in {path}")

    def test_codex_qa_gate_substitute_is_documented_and_scripted(self):
        checked = [
            ROOT / "AGENTS.md",
            ROOT / "templates/AGENTS.project.template.md",
            ROOT / "plugins/codex-copilot/skills/qa/SKILL.md",
            ROOT / "docs/quality-gates.md",
        ]
        for path in checked:
            text = path.read_text()
            self.assertIn("requiresQa", text, f"missing requiresQa convention in {path}")
            self.assertIn("VERDICT:", text, f"missing verdict convention in {path}")
            self.assertIn("ARTIFACT:", text, f"missing artifact convention in {path}")
        script = (ROOT / "scripts/copilot-gate.sh").read_text()
        self.assertIn("QA gate", script)
        self.assertIn("VERDICT: APPROVED", script)
        self.assertIn("design-fidelity-check", script)

    def test_qa_gate_requires_artifact_for_passing_verdict(self):
        with tempfile.TemporaryDirectory() as tmp:
            fake_tc = pathlib.Path(tmp) / "tc"
            fake_tc.write_text(
                textwrap.dedent(
                    """\
                    #!/usr/bin/env python3
                    import json
                    import os
                    import sys

                    args = sys.argv[1:]
                    if args[:3] == ["task", "list", "--json"]:
                        print(json.dumps([{"id": 1, "title": "Example", "metadata": {"requiresQa": True}}]))
                    elif args[:4] == ["wp", "list", "--task", "1"] and args[4:] == ["--json"]:
                        print(json.dumps([{"id": 7, "type": "test"}]))
                    elif args[:3] == ["wp", "get", "7"] and args[3:] == ["--json"]:
                        print(json.dumps({"content": os.environ["QA_CONTENT"]}))
                    else:
                        print(json.dumps({}))
                    """
                )
            )
            fake_tc.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{tmp}{os.pathsep}{env['PATH']}"

            env["QA_CONTENT"] = "Task: TASK-1 | WP: WP-7\nVERDICT: APPROVED\n"
            bare = subprocess.run(
                ["bash", "scripts/copilot-gate.sh"],
                cwd=ROOT,
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(bare.returncode, 0)

            env["QA_CONTENT"] = (
                "Task: TASK-1 | WP: WP-7\n"
                "ARTIFACT: test-run|pytest tests/test_example.py exit=0 \"1 passed\"\n"
                "VERDICT: APPROVED\n"
            )
            evidenced = subprocess.run(
                ["bash", "scripts/copilot-gate.sh"],
                cwd=ROOT,
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(evidenced.returncode, 0, evidenced.stdout + evidenced.stderr)

    def test_orchestration_validator_has_stream_contract(self):
        script = (ROOT / "scripts/orchestrate-validate.py").read_text()
        for term in ["streamId", "streamDependencies", "files", "cycle detected", "file ownership overlap"]:
            self.assertIn(term, script)
        self.assertIn("ValidationReport", script)

    def test_validation_result_contract_exists(self):
        text = (ROOT / "scripts/lib/validation_result.py").read_text()
        for term in ["CheckResult", "ValidationReport", "to_shell_json", "passed", "failed", "warned"]:
            self.assertIn(term, text)

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
            ROOT / "plugins/codex-copilot/skills/launcher/references/workflows.md",
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

    def test_capability_matrix_covers_design_led_surfaces(self):
        text = (ROOT / "docs/capabilities.md").read_text()
        for term in [
            "$protocol",
            "$continue",
            "$pause",
            "$orchestrate",
            "$knowledge-copilot",
            "direct Codex skills",
            "dormant capability packs",
            "cc memory",
            "cc memory check",
            "cc usage",
            "cc skill",
            "tc",
            "Mechanical Claude lifecycle hooks",
            "Headless worker orchestration",
        ]:
            self.assertIn(term, text)
        self.assertIn("not the design-led product protocol", text)

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
