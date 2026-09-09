"""Native base setup compatibility with the existing shared cc runner."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class FoundationEntrypointTests(unittest.TestCase):
    def test_entry_guide_preserves_native_boundary(self):
        guide = (ROOT / 'docs/01-setup/04-foundation-entrypoint.md').read_text()
        for term in ('scripts/setup-project.sh', '--framework-root', '--no-org-plugin',
                     '$protocol', 'cc verify plan', 'cc verify run', 'cc verify status',
                     'Packs are not activated', 'source-bound QA'):
            self.assertIn(term, guide)

    def test_clean_native_consumer_preserves_owner_and_uses_shared_verification(self):
        candidates = [os.environ.get('CODEX_SHARED_CC'),
                      str(ROOT.parent / 'claude-copilot/tools/cc/.venv/bin/cc'),
                      shutil.which('cc')]
        cli = None
        for candidate in candidates:
            if not candidate or not Path(candidate).is_file():
                continue
            probe = subprocess.run([candidate, '--version'], capture_output=True, text=True, timeout=10)
            if probe.returncode == 0 and probe.stdout.startswith('cc version'):
                capability = subprocess.run([candidate, 'verify', '--help'], capture_output=True, timeout=10)
                if capability.returncode == 0:
                    cli = candidate
                    break
        if cli is None:
            self.skipTest('shared Copilot cc verify unavailable; set CODEX_SHARED_CC to the verified CLI')

        with tempfile.TemporaryDirectory(prefix='cse-native-entry-') as scratch:
            project = Path(scratch) / 'project'
            project.mkdir()
            subprocess.run(['git', 'init', '-q', str(project)], check=True, timeout=10)
            owner = project / 'AGENTS.md'
            owner.write_text('# Owner rules\nPreserve this project.\n')
            for _ in range(2):
                setup = subprocess.run(['bash', str(ROOT / 'scripts/setup-project.sh'),
                                        '--project', str(project), '--framework-root', str(ROOT),
                                        '--no-org-plugin', '--no-tc-init'], cwd=ROOT,
                                       capture_output=True, text=True, timeout=30)
                self.assertEqual(setup.returncode, 0, setup.stdout + setup.stderr)
                self.assertEqual(owner.read_text(), '# Owner rules\nPreserve this project.\n')
            self.assertEqual([p.name for p in (project / 'plugins').iterdir()], ['codex-copilot'])
            plugin = project / 'plugins/codex-copilot'
            self.assertTrue((plugin / 'skills/protocol/SKILL.md').is_file())
            self.assertTrue((plugin / 'skills/specialist-agents/references/verification-policy.md').is_file())
            self.assertTrue(os.access(project / 'scripts/copilot-gate.sh', os.X_OK))
            self.assertTrue((project / '.claude/skills/codex-copilot').resolve().samefile(plugin / 'skills'))
            self.assertFalse((plugin / 'skills/cpa').exists())
            (project / 'check.py').write_text(
                'from pathlib import Path\n'
                'assert "Preserve this project." in Path("AGENTS.md").read_text()\n'
                'assert Path("plugins/codex-copilot/skills/protocol/SKILL.md").is_file()\n')
            manifest = {'schemaVersion': 1, 'inputs': ['AGENTS.md', 'check.py'],
                        'fallbackLanes': ['entry'], 'lanes': [{'id': 'entry', 'description': 'Native entry',
                        'paths': ['AGENTS.md'], 'argv': ['{python}', 'check.py'], 'cwd': '.',
                        'timeoutSeconds': 5, 'hermetic': False}]}
            (project / 'verification.json').write_text(json.dumps(manifest))

            def cc(*args):
                result = subprocess.run([cli, 'verify', *args, '--root', str(project), '--json'],
                                        cwd=project, capture_output=True, text=True, timeout=15)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                return json.loads(result.stdout)

            plan = cc('plan', '--changed', 'AGENTS.md', '--task', 'fixture-32')
            plan_path = Path(scratch) / 'plan.json'
            plan_path.write_text(json.dumps(plan))
            run = cc('run', '--plan', str(plan_path))
            self.assertEqual(run['status'], 'passed')
            self.assertEqual(run['approval'], 'none; tc alone grants task approval')
            self.assertEqual(cc('status', '--run', run['runId'])['status'], 'passed')
            overview = subprocess.run([cli, 'status', '--project', str(project), '--json'],
                                      cwd=project, capture_output=True, text=True, timeout=15)
            self.assertEqual(overview.returncode, 0, overview.stdout + overview.stderr)
            observed = json.loads(overview.stdout)
            self.assertTrue(observed['readOnly'])
            self.assertEqual(observed['verification']['run']['id'], run['runId'])
            self.assertTrue(all(r['running'] == 'unknown' for r in observed['foundation']['runtimes']))
            self.assertFalse((project / '.copilot/tasks.db').exists())


if __name__ == '__main__':
    unittest.main()
