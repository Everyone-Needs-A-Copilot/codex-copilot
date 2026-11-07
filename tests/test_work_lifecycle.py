"""Focused lifecycle distribution checks; isolated roots and no provider calls."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from central_helpers import env_with, stub_cc

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('lifecycle_sync', ROOT / 'scripts/sync-work-lifecycle.py')
sync = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sync)


class LifecycleDistributionTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix='copilot-lifecycle-')
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.claude = self.root / 'claude'
        self.codex = self.root / 'codex'
        self.source = self.claude / sync.SOURCE
        self.destination = self.codex / sync.DESTINATION
        self.source.parent.mkdir(parents=True)
        self.source.write_bytes(b'# Work lifecycle\n\nEvidence before acceptance.\n')
        # The CLI now carries the canonical verification policy too, so its fixture root holds both files.
        self.policy_source = self.claude / sync.POLICY_SOURCE
        self.policy_destination = self.codex / sync.POLICY_DESTINATION
        self.policy_source.write_bytes(b'## Verification Tiers\n\nT1 copy, T2 structural, T3 foundational.\n')

    def test_copy_is_exact_and_leaves_unrelated_files_untouched(self):
        other = self.codex / 'project-owned.txt'
        other.parent.mkdir(parents=True)
        other.write_text('owner authority')
        self.assertTrue(sync.synchronize(self.claude, self.codex))
        self.assertEqual(self.destination.read_bytes(), self.source.read_bytes())
        self.assertEqual(other.read_text(), 'owner authority')
        before = self.destination.stat().st_mtime_ns
        self.assertTrue(sync.synchronize(self.claude, self.codex))
        self.assertEqual(self.destination.stat().st_mtime_ns, before)

    def test_check_fails_drift_and_missing_without_writing(self):
        self.assertFalse(sync.synchronize(self.claude, self.codex, check=True))
        self.assertFalse(self.codex.exists())
        sync.synchronize(self.claude, self.codex)
        self.source.write_bytes(b'changed authority\n')
        before = self.destination.read_bytes()
        self.assertFalse(sync.synchronize(self.claude, self.codex, check=True))
        self.assertEqual(self.destination.read_bytes(), before)
        sync.synchronize(self.claude, self.codex)
        self.assertTrue(sync.synchronize(self.claude, self.codex, check=True))

    def test_missing_or_empty_source_preserves_existing_reference(self):
        sync.synchronize(self.claude, self.codex)
        before = self.destination.read_bytes()
        self.source.write_bytes(b'')
        with self.assertRaises(ValueError):
            sync.synchronize(self.claude, self.codex)
        self.source.unlink()
        with self.assertRaises(ValueError):
            sync.synchronize(self.claude, self.codex)
        self.assertEqual(self.destination.read_bytes(), before)

    def test_redirected_destination_is_rejected(self):
        self.destination.parent.mkdir(parents=True)
        outside = self.root / 'outside.txt'
        outside.write_text('protected')
        self.destination.symlink_to(outside)
        with self.assertRaises(ValueError):
            sync.synchronize(self.claude, self.codex)
        self.assertEqual(outside.read_text(), 'protected')

    def test_cli_check_reports_drift_without_copying(self):
        script = self.codex / 'scripts/sync-work-lifecycle.py'
        script.parent.mkdir(parents=True)
        script.write_bytes((ROOT / 'scripts/sync-work-lifecycle.py').read_bytes())
        result = subprocess.run([sys.executable, str(script), '--claude-root',
                                 str(self.claude), '--check'], capture_output=True,
                                text=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertFalse(self.destination.exists())
        result = subprocess.run([sys.executable, str(script), '--claude-root',
                                 str(self.claude)], capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.destination.read_bytes(), self.source.read_bytes())
        self.assertEqual(self.policy_destination.read_bytes(), self.policy_source.read_bytes())

    def test_policy_copy_is_byte_for_byte_and_check_detects_drift(self):
        pair = (sync.POLICY_SOURCE, sync.POLICY_DESTINATION)
        self.assertFalse(sync.synchronize(self.claude, self.codex, check=True, pair=pair))
        self.assertTrue(sync.synchronize(self.claude, self.codex, pair=pair))
        self.assertEqual(self.policy_destination.read_bytes(), self.policy_source.read_bytes())
        self.assertTrue(sync.synchronize(self.claude, self.codex, check=True, pair=pair))
        self.policy_destination.write_bytes(self.policy_source.read_bytes() + b'reworded locally\n')
        self.assertFalse(sync.synchronize(self.claude, self.codex, check=True, pair=pair))
        self.assertEqual(sync.synchronize_all(self.claude, self.codex, check=True), [sync.DESTINATION, sync.POLICY_DESTINATION])

    def test_missing_canonical_policy_fails_the_cli_closed(self):
        self.policy_source.unlink()
        script = self.codex / 'scripts/sync-work-lifecycle.py'
        script.parent.mkdir(parents=True)
        script.write_bytes((ROOT / 'scripts/sync-work-lifecycle.py').read_bytes())
        result = subprocess.run([sys.executable, str(script), '--claude-root', str(self.claude)],
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 2)

    def test_native_skill_and_reference_ship_in_release_not_projects(self):
        # Central model: the lifecycle reference lives in the release tree that
        # ~/.copilot/current/codex-copilot resolves to; setup copies nothing.
        installed = ROOT / sync.DESTINATION
        self.assertTrue(installed.is_file())
        self.assertTrue((installed.parent.parent / 'SKILL.md').is_file())
        project = self.root / 'consumer'
        project.mkdir()
        owner = project / 'AGENTS.md'
        owner.write_text('# Owner\nKeep this exact authority.\n')
        home = self.root / 'home'
        home.mkdir()
        stub = stub_cc(home)
        for _ in range(2):
            result = subprocess.run(['bash', str(ROOT / 'scripts/setup-project.sh'),
                                     '--project', str(project), '--no-tc-init'], cwd=ROOT,
                                    capture_output=True, text=True, timeout=40,
                                    env=env_with(home, CC_BIN=str(stub)))
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue(owner.read_text().startswith('# Owner\nKeep this exact authority.\n'))
        self.assertFalse((project / 'plugins').exists())
        self.assertFalse((project / sync.DESTINATION).exists())
        self.assertFalse((project / '.codex-copilot.json').exists())
        self.assertFalse((project / 'copilot.lock.json').exists())


if __name__ == '__main__':
    unittest.main()
