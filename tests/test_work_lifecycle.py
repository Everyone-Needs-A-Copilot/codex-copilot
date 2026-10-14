"""Focused lifecycle distribution checks; isolated roots and no provider calls."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

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

    def test_native_skill_and_reference_survive_packaged_install(self):
        project = self.root / 'consumer'
        project.mkdir()
        owner = project / 'AGENTS.md'
        owner.write_text('# Owner\nKeep this exact authority.\n')
        for _ in range(2):
            result = subprocess.run(['bash', str(ROOT / 'scripts/setup-project.sh'),
                                     '--project', str(project), '--framework-root', str(ROOT),
                                     '--no-org-plugin', '--no-tc-init'], cwd=ROOT,
                                    capture_output=True, text=True, timeout=40)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(owner.read_text(), '# Owner\nKeep this exact authority.\n')
            installed = project / sync.DESTINATION
            self.assertEqual(installed.read_bytes(), (ROOT / sync.DESTINATION).read_bytes())
            self.assertTrue((installed.parent.parent / 'SKILL.md').is_file())
        self.assertFalse((project / 'plugins/codex-copilot/skills/cpa').exists())


    def install_consumer(self):
        project = self.root / 'collision-consumer'
        project.mkdir()
        result = self.update_consumer(project, setup=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        # First update adopts the setup receipt into the normal ownership lock.
        # Setup records copied files in metadata but does not write the lock.
        result = self.update_consumer(project)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return project

    def update_consumer(self, project, *, setup=False, dry_run=False):
        script = 'setup-project.sh' if setup else 'update-project.sh'
        command = ['bash', str(ROOT / 'scripts' / script), '--project', str(project),
                   '--framework-root', str(ROOT), '--no-org-plugin']
        if setup:
            command.append('--no-tc-init')
        if dry_run:
            command.append('--dry-run')
        return subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=40)

    def make_unrecorded_collision(self, project):
        path = 'plugins/codex-copilot/skills/optimize/SKILL.md'
        target = project / path
        target.write_bytes(b'# Existing project guidance\nPreserve unique owner work.\n')
        lock = project / 'copilot.lock.json'
        data = json.loads(lock.read_text())
        base = next(c for c in data['components'] if c['component'] == 'codex')
        base['files'] = [entry for entry in base['files'] if entry['path'] != path]
        lock.write_text(json.dumps(data))
        return path, target

    def test_unrecorded_collision_is_held_across_updates_and_dry_run(self):
        project = self.install_consumer()
        path, target = self.make_unrecorded_collision(project)
        before = target.read_bytes()
        lock = project / 'copilot.lock.json'
        lock_before = lock.read_bytes()
        result = self.update_consumer(project, dry_run=True)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(target.read_bytes(), before)
        self.assertEqual(lock.read_bytes(), lock_before)
        for _ in range(2):
            result = self.update_consumer(project)
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertIn('adoption incomplete', result.stdout)
            self.assertIn(path, result.stdout)
            self.assertEqual(target.read_bytes(), before)
            data = json.loads(lock.read_text())
            base = next(c for c in data['components'] if c['component'] == 'codex')
            entry = next(e for e in base['files'] if e['path'] == path)
            self.assertEqual(entry['ownership'], 'project')
            self.assertIn('unrecorded', entry['holdReason'])

    def test_setup_rerun_cannot_overwrite_unrecorded_collision(self):
        project = self.install_consumer()
        _, target = self.make_unrecorded_collision(project)
        before = target.read_bytes()
        result = self.update_consumer(project, setup=True)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual(target.read_bytes(), before)
        self.assertIn('adoption incomplete', result.stdout)

    def test_tracked_drift_repair_and_explicit_project_ownership_are_preserved(self):
        project = self.install_consumer()
        relative = 'plugins/codex-copilot/skills/optimize/SKILL.md'
        target = project / relative
        target.write_text('tracked framework drift')
        result = self.update_consumer(project)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(target.read_bytes(), (ROOT / relative).read_bytes())
        target.write_text('---\nowner: project\n---\nKeep customization.\n')
        before = target.read_bytes()
        result = self.update_consumer(project)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(target.read_bytes(), before)


    def test_first_update_repairs_recorded_setup_drift_but_holds_unknown_path(self):
        project = self.root / 'first-update'
        project.mkdir()
        result = self.update_consumer(project, setup=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((project / 'copilot.lock.json').exists())
        metadata = project / '.codex-copilot.json'
        data = json.loads(metadata.read_text())
        recorded = 'plugins/codex-copilot/agent-catalog.json'
        unknown = 'plugins/codex-copilot/skills/optimize/SKILL.md'
        roster = data['installedFiles']['codex']
        self.assertIn(recorded, [entry['path'] for entry in roster])
        # Model an upgrade path that was not in the original installed roster.
        data['installedFiles']['codex'] = [e for e in roster if e['path'] != unknown]
        metadata.write_text(json.dumps(data))
        (project / recorded).write_bytes(b'known installed framework drift')
        unique = b'previously unrecorded project work'
        (project / unknown).write_bytes(unique)
        result = self.update_consumer(project)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertEqual((project / recorded).read_bytes(), (ROOT / recorded).read_bytes())
        self.assertEqual((project / unknown).read_bytes(), unique)
        self.assertIn('adoption incomplete', result.stdout)

    def test_initial_org_setup_receipt_allows_first_update_drift_repair(self):
        project = self.root / 'org-consumer'
        project.mkdir()
        org = self.root / 'org-source'
        manifest = org / '.codex-plugin/plugin.json'
        manifest.parent.mkdir(parents=True)
        manifest.write_text(json.dumps({'name': 'lifecycle-org-fixture', 'version': '1.0.0'}))
        skill = org / 'skills/demo/SKILL.md'
        skill.parent.mkdir(parents=True)
        skill.write_text('---\nname: demo\ndescription: fixture\n---\nOwner fixture.\n')
        setup = subprocess.run(['bash', str(ROOT / 'scripts/setup-project.sh'),
                                '--project', str(project), '--framework-root', str(ROOT),
                                '--org-plugin', str(org), '--no-tc-init'], cwd=ROOT,
                               capture_output=True, text=True, timeout=40)
        self.assertEqual(setup.returncode, 0, setup.stdout + setup.stderr)
        self.assertFalse((project / 'copilot.lock.json').exists())
        installed = project / 'plugins/lifecycle-org-fixture/skills/demo/SKILL.md'
        installed.write_text('known installed org framework drift')
        update = subprocess.run(['bash', str(ROOT / 'scripts/update-project.sh'),
                                 '--project', str(project), '--framework-root', str(ROOT)],
                                cwd=ROOT, capture_output=True, text=True, timeout=40)
        self.assertEqual(update.returncode, 0, update.stdout + update.stderr)
        self.assertEqual(installed.read_bytes(), skill.read_bytes())


if __name__ == '__main__':
    unittest.main()
