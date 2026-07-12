import json
import os
import pathlib
import re
import shutil
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
        self.assertEqual(catalog["version"], "0.6.0")
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

    def test_generated_routing_is_current(self):
        result = subprocess.run(
            ["python3", "scripts/generate-routing.py", "--check"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_upstream_freshness_detects_component_drift(self):
        with tempfile.TemporaryDirectory() as tmp:
            upstream = pathlib.Path(tmp)
            (upstream / "VERSION.json").write_text(json.dumps({
                "framework": "99.0.0",
                "components": {"cc": {"version": "99.0.0"}, "tc": {"version": "99.0.0"}},
            }))
            result = subprocess.run(
                ["python3", "scripts/check-upstream-parity.py", "--upstream", str(upstream), "--json"],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(json.loads(result.stdout)["status"], "fail")

    def find_upstream_checkout(self):
        candidate = pathlib.Path(
            os.environ.get("CLAUDE_COPILOT_ROOT", ROOT.parent / "claude-copilot")
        ).expanduser().resolve()
        if not (candidate / "VERSION.json").is_file():
            self.skipTest("no local claude-copilot checkout available for content parity tests")
        return candidate

    def test_content_baseline_matches_manifest_schema(self):
        manifest = json.loads((ROOT / "parity/upstream-content-hashes.json").read_text())
        self.assertEqual(set(manifest.keys()), {"generated_at", "upstream_commit", "files", "versions"})
        self.assertIsInstance(manifest["files"], dict)
        self.assertTrue(manifest["files"], "content baseline has no hashed files")

        sha256_re = re.compile(r"^[0-9a-f]{64}$")
        for relpath, digest in manifest["files"].items():
            self.assertTrue(sha256_re.match(digest), f"bad sha256 for {relpath}: {digest}")
            self.assertTrue(
                relpath.startswith((".claude/agents/", ".claude/commands/", ".claude/skills/")),
                f"unexpected file in content manifest: {relpath}",
            )
            self.assertTrue(relpath.endswith(".md"), f"non-markdown file in content manifest: {relpath}")

        self.assertEqual(set(manifest["versions"].keys()), {"framework", "agents", "commands"})
        self.assertRegex(manifest["upstream_commit"], r"^[0-9a-f]{40}$")

    def test_content_check_detects_synthetic_agent_drift(self):
        upstream_root = self.find_upstream_checkout()
        with tempfile.TemporaryDirectory() as tmp:
            upstream = pathlib.Path(tmp) / "upstream"
            shutil.copytree(upstream_root / ".claude" / "agents", upstream / ".claude" / "agents")
            shutil.copytree(upstream_root / ".claude" / "commands", upstream / ".claude" / "commands")
            shutil.copytree(upstream_root / ".claude" / "skills", upstream / ".claude" / "skills")
            shutil.copyfile(upstream_root / "VERSION.json", upstream / "VERSION.json")

            drifted = upstream / ".claude" / "agents" / "qa.md"
            drifted.write_text(drifted.read_text() + "\n<!-- synthetic drift marker -->\n")

            result = subprocess.run(
                ["python3", "scripts/check-upstream-parity.py", "--upstream", str(upstream), "--content", "--json"],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            content = json.loads(result.stdout)["content"]
            self.assertEqual(content["status"], "drift")
            self.assertEqual(content["changed"], [".claude/agents/qa.md"])
            self.assertEqual(content["added"], [])
            self.assertEqual(content["removed"], [])
            self.assertEqual(content["version_diffs"], {})

    def test_content_update_baseline_round_trips_to_pass(self):
        self.find_upstream_checkout()
        with tempfile.TemporaryDirectory() as tmp:
            baseline_path = pathlib.Path(tmp) / "upstream-content-hashes.json"

            update = subprocess.run(
                ["python3", "scripts/check-upstream-parity.py", "--update-baseline", "--baseline", str(baseline_path), "--json"],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            self.assertEqual(update.returncode, 0, update.stdout + update.stderr)
            self.assertTrue(baseline_path.is_file())
            self.assertEqual(json.loads(update.stdout)["status"], "updated")

            check = subprocess.run(
                ["python3", "scripts/check-upstream-parity.py", "--content", "--baseline", str(baseline_path), "--json"],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            self.assertEqual(check.returncode, 0, check.stdout + check.stderr)
            self.assertEqual(json.loads(check.stdout)["content"]["status"], "pass")

    def test_specialist_chain_comparator_requires_evidence_and_compares(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = pathlib.Path(tmp)
            def scorecard(variant, score):
                return {"variant": variant, "cases": [{"id": "case-1", "criteria": {"correctness": {"score": score, "evidence": "test-run|example"}}}]}
            generalist = tmp_path / "generalist.json"
            specialist = tmp_path / "specialist.json"
            generalist.write_text(json.dumps(scorecard("generalist", 0.5)))
            specialist.write_text(json.dumps(scorecard("specialist", 0.8)))
            result = subprocess.run(
                ["python3", "scripts/compare-specialist-chain.py", "--generalist", str(generalist), "--specialist", str(specialist), "--json"],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(json.loads(result.stdout)["verdict"], "specialist-chain")
            invalid = scorecard("specialist", 0.8)
            invalid["cases"][0]["criteria"]["correctness"]["evidence"] = ""
            specialist.write_text(json.dumps(invalid))
            rejected = subprocess.run(
                ["python3", "scripts/compare-specialist-chain.py", "--generalist", str(generalist), "--specialist", str(specialist)],
                cwd=ROOT, capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(rejected.returncode, 0)

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
            ROOT / "docs/02-user-guides/03-live-docs.md",
        ]
        for path in checked:
            self.assertIn("cc docs", path.read_text(), f"missing Live Docs guidance in {path}")

    def test_codex_qa_gate_substitute_is_documented_and_scripted(self):
        checked = [
            ROOT / "AGENTS.md",
            ROOT / "templates/AGENTS.project.template.md",
            ROOT / "plugins/codex-copilot/skills/qa/SKILL.md",
            ROOT / "docs/02-user-guides/04-quality-gates.md",
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

    def test_qa_gate_rejects_metadata_only_approval(self):
        with tempfile.TemporaryDirectory() as tmp:
            fake_tc = pathlib.Path(tmp) / "tc"
            fake_tc.write_text(
                textwrap.dedent(
                    """\
                    #!/usr/bin/env python3
                    import json
                    import sys

                    args = sys.argv[1:]
                    if args[:3] == ["task", "list", "--json"]:
                        print(json.dumps([{
                            "id": 1,
                            "title": "Metadata-only approval",
                            "metadata": {
                                "requiresQa": True,
                                "qaStatus": "approved",
                                "qaArtifact": "trust me"
                            }
                        }]))
                    elif args[:4] == ["wp", "list", "--task", "1"]:
                        print("[]")
                    else:
                        print(json.dumps({}))
                    """
                )
            )
            fake_tc.chmod(0o755)
            env = os.environ.copy()
            env["PATH"] = f"{tmp}{os.pathsep}{env['PATH']}"
            result = subprocess.run(
                ["bash", "scripts/copilot-gate.sh"],
                cwd=ROOT,
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("TASK-1", result.stdout)

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
            ROOT / "docs/02-user-guides/02-protocol.md",
            ROOT / "docs/02-user-guides/01-daily-workflow.md",
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

        allowed = {ROOT / "docs/03-developer-guides/02-release-and-publishing.md"}
        for path in paths:
            if path in allowed:
                continue
            text = path.read_text()
            self.assertNotIn("/Users/", text, f"local user path in {path}")
            self.assertNotIn("/Volumes/", text, f"local volume path in {path}")

    def test_capability_matrix_covers_design_led_surfaces(self):
        text = (ROOT / "docs/05-reference/01-capability-matrix.md").read_text()
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
        getting_started = (ROOT / "docs/01-setup/03-getting-started.md").read_text()
        setup = (ROOT / "docs/01-setup/02-setup-project.md").read_text()
        for term in [
            ".claude/cc/config.json",
            ".claude/memory/entries/",
            ".claude/skills/codex-copilot",
            "plugins/codex-copilot",
            "docs/40-initiatives/",
            "scripts/copilot-gate.sh",
        ]:
            self.assertIn(term, getting_started)
            self.assertIn(term, setup)
        self.assertIn("git repository", getting_started)
        self.assertIn("git repository", setup)

    def test_force_guidance_matches_script_behavior(self):
        setup_doc = (ROOT / "docs/01-setup/02-setup-project.md").read_text()
        setup_skill = (ROOT / "plugins/codex-copilot/skills/setup-project/SKILL.md").read_text()
        self.assertIn("does not override", setup_doc)
        self.assertIn("compatibility-only", setup_skill)
        self.assertNotIn("Do not use `--force` unless", setup_skill)

    def test_numbered_documentation_and_initiative_contract_exist(self):
        required = [
            "docs/00-overview/00-overview.md",
            "docs/01-setup/00-overview.md",
            "docs/02-user-guides/00-overview.md",
            "docs/03-developer-guides/00-overview.md",
            "docs/04-architecture/00-overview.md",
            "docs/05-reference/00-overview.md",
            "docs/07-troubleshooting/00-overview.md",
            "docs/09-appendix/01-ai-ecosystem-research-methodology.md",
            "docs/40-initiatives/README.md",
            "docs/40-initiatives/_template/README.md",
        ]
        for rel in required:
            self.assertTrue((ROOT / rel).exists(), f"missing documentation contract file {rel}")

        for rel in [
            "AGENTS.md",
            "templates/AGENTS.project.template.md",
            "plugins/codex-copilot/skills/protocol/SKILL.md",
            "plugins/codex-copilot/skills/task-copilot/SKILL.md",
        ]:
            text = (ROOT / rel).read_text()
            self.assertIn("docs/40-initiatives/", text, f"missing initiative convention in {rel}")
            self.assertIn("tc", text, f"missing task-state boundary in {rel}")

    def test_docs_root_is_clean_and_legacy_paths_are_archived(self):
        root_markdown = sorted(path.name for path in (ROOT / "docs").glob("*.md"))
        self.assertEqual(root_markdown, ["README.md"])

        archive = (ROOT / "docs/90-archive/redirects/README.md").read_text()
        for former, target in {
            "docs/getting-started.md": "01-setup/03-getting-started.md",
            "docs/usage.md": "02-user-guides/01-daily-workflow.md",
            "docs/architecture.md": "04-architecture/00-overview.md",
            "docs/capabilities.md": "05-reference/01-capability-matrix.md",
            "docs/parity.md": "05-reference/03-parity-contract.md",
        }.items():
            self.assertIn(former, archive)
            self.assertIn(target, archive)

    def test_local_markdown_links_resolve(self):
        link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
        checked = [ROOT / "README.md", ROOT / "CONTRIBUTING.md", *sorted((ROOT / "docs").rglob("*.md"))]
        failures = []
        for path in checked:
            for target in link_pattern.findall(path.read_text()):
                if target.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                clean = target.split("#", 1)[0]
                if not clean:
                    continue
                resolved = (path.parent / clean).resolve()
                if not resolved.exists():
                    failures.append(f"{path.relative_to(ROOT)} -> {target}")
        self.assertEqual(failures, [], "broken local Markdown links:\n" + "\n".join(failures))

    def test_setup_scaffolds_initiatives_and_shared_qa_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = pathlib.Path(tmp) / "project"
            target.mkdir()
            subprocess.run(["git", "init", "-q", str(target)], check=True)
            result = subprocess.run(
                [
                    "bash",
                    "scripts/setup-project.sh",
                    "--project",
                    str(target),
                    "--name",
                    "fixture-project",
                    "--no-tc-init",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((target / "docs/40-initiatives/README.md").exists())
            self.assertTrue((target / "docs/40-initiatives/_template/phases/phase-1-plan.md").exists())
            qa_gate = target / "scripts/copilot-gate.sh"
            self.assertTrue(qa_gate.is_symlink())
            self.assertTrue(qa_gate.resolve().samefile(ROOT / "scripts/copilot-gate.sh"))
            self.assertTrue(os.access(qa_gate, os.X_OK))

    def test_setup_preserves_existing_initiative_documentation(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = pathlib.Path(tmp) / "project"
            initiatives = target / "docs/40-initiatives"
            initiatives.mkdir(parents=True)
            custom_index = "# Project Initiatives\n\nExisting project-owned content.\n"
            (initiatives / "README.md").write_text(custom_index)
            subprocess.run(["git", "init", "-q", str(target)], check=True)
            result = subprocess.run(
                [
                    "bash",
                    "scripts/setup-project.sh",
                    "--project",
                    str(target),
                    "--name",
                    "fixture-project",
                    "--no-tc-init",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual((initiatives / "README.md").read_text(), custom_index)
            self.assertFalse((initiatives / "_template").exists())

    def test_setup_refusal_is_atomic_and_force_does_not_clobber(self):
        for force in (False, True):
            with self.subTest(force=force), tempfile.TemporaryDirectory() as tmp:
                target = pathlib.Path(tmp) / "project"
                target.mkdir()
                agents = target / "AGENTS.md"
                agents.write_text("# Existing instructions\n")
                config = target / ".claude/cc/config.json"
                config.parent.mkdir(parents=True)
                config.write_text('{"custom":"keep-me"}\n')
                before = sorted(
                    str(path.relative_to(target))
                    for path in target.rglob("*")
                )
                command = [
                    "bash",
                    "scripts/setup-project.sh",
                    "--project",
                    str(target),
                    "--no-tc-init",
                ]
                if force:
                    command.append("--force")
                result = subprocess.run(
                    command,
                    cwd=ROOT,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                after = sorted(
                    str(path.relative_to(target))
                    for path in target.rglob("*")
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(before, after)
                self.assertEqual(config.read_text(), '{"custom":"keep-me"}\n')
                self.assertFalse((target / "plugins/codex-copilot").exists())


if __name__ == "__main__":
    unittest.main()
