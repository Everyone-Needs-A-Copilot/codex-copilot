"""Fast local instruction/integrity contracts; no models or foundation installs."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / 'scripts/check-test-integrity.sh'


def digest(content):
    return hashlib.sha256(content).hexdigest()


class VerificationPolicyTests(unittest.TestCase):
    def test_native_skills_load_policy_and_retain_approval_authority(self):
        shared = ROOT / 'plugins/codex-copilot/skills/specialist-agents/references/verification-policy.md'
        policy = shared.read_text()
        for role in ('me', 'qa'):
            skill = (ROOT / f'plugins/codex-copilot/skills/{role}/SKILL.md').read_text()
            self.assertIn('../specialist-agents/references/verification-policy.md', skill)
            self.assertIn('Do not downgrade requiresQa', skill)
        for term in ('Instructions/routing', 'Logic/transformation', 'Storage/installation',
                     'UI behavior', 'Unknown impact selects a broader named lane',
                     'tc remains the sole\nsource-bound QA authority', 'negative control',
                     'exact changed\nassertions/diff', 'two falsified', 'Timeout is incomplete'):
            self.assertIn(term, policy)
        authority = (ROOT / 'AGENTS.md').read_text()
        self.assertIn('explicit user authority', authority)
        self.assertIn('--test-change-receipt', authority)
        self.assertNotIn('"The tests pass" is only evidence if the tests are unchanged', authority)


class SmokeDiscoveryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='cse-smoke-discovery-')
        self.repo = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        (self.repo / 'tests').mkdir()
        scripts = self.repo / 'scripts'
        scripts.mkdir()
        (scripts / 'smoke-test.sh').write_bytes((ROOT / 'scripts/smoke-test.sh').read_bytes())
        # Later production checks are never run by these disposable wiring fixtures.
        for name in ('verify-codex-hooks.sh', 'check-versions.sh', 'run-agent-evals.sh',
                     'verify-update-project.sh'):
            (scripts / name).write_text('echo checked >> later-checks.log\n')
        for name in ('check-upstream-parity.py', 'generate-routing.py', 'orchestrate-validate.py'):
            (scripts / name).write_text("with open('later-checks.log', 'a') as log: log.write('checked\\n')\n")

    def run_smoke(self, cap='10'):
        env = os.environ.copy()
        env['COPILOT_SMOKE_PYTHON_TIMEOUT'] = cap
        return subprocess.run(['bash', 'scripts/smoke-test.sh'], cwd=self.repo, env=env,
                              capture_output=True, text=True, timeout=15)

    def test_new_test_files_are_discovered_once_without_editing_smoke(self):
        for name in ('original', 'added_after_wiring'):
            (self.repo / f'tests/test_{name}.py').write_text(
                f'import unittest\nclass Case(unittest.TestCase):\n'
                f'    def test_{name}(self): self.assertEqual(1 + 1, 2)\n')
        result = self.run_smoke()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Ran 2 tests', result.stderr)
        self.assertEqual(result.stderr.count('test_added_after_wiring ('), 1)
        self.assertEqual(result.stdout.count('[python-test-discovery] start'), 1)
        self.assertIn('[python-test-discovery] exit=0 elapsed=', result.stdout)
        self.assertEqual(len((self.repo / 'later-checks.log').read_text().splitlines()), 8)
        self.assertIn('Smoke tests passed', result.stdout)

    def test_failing_discovered_test_preserves_failure_and_stops_later_steps(self):
        (self.repo / 'tests/test_regression.py').write_text(
            'import unittest\nclass Case(unittest.TestCase):\n'
            '    def test_regression(self): self.assertEqual(1 + 1, 3)\n')
        result = self.run_smoke()
        self.assertEqual(result.returncode, 1)
        self.assertIn('[python-test-discovery] exit=1 elapsed=', result.stdout)
        self.assertIn('FAILED (failures=1)', result.stderr)
        self.assertFalse((self.repo / 'later-checks.log').exists())
        self.assertNotIn('Smoke tests passed', result.stdout)

    def test_timeout_kills_owned_descendant_but_not_unrelated_process(self):
        (self.repo / 'tests/test_hung.py').write_text(
            'import pathlib, subprocess, sys, time, unittest\n'
            'class Case(unittest.TestCase):\n'
            '    def test_hung(self):\n'
            '        child = subprocess.Popen([sys.executable, "-c", "import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); time.sleep(60)"])\n'
            '        pathlib.Path("owned-child.pid").write_text(str(child.pid))\n'
            '        time.sleep(60)\n')
        unrelated = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'],
                                     start_new_session=True)
        try:
            result = self.run_smoke(cap='0.5')
            self.assertEqual(result.returncode, 124, result.stdout + result.stderr)
            self.assertIn('incomplete timeout elapsed=', result.stdout)
            self.assertFalse((self.repo / 'later-checks.log').exists())
            self.assertIsNone(unrelated.poll())
            pid = int((self.repo / 'owned-child.pid').read_text())
            process = subprocess.run(['ps', '-p', str(pid), '-o', 'stat='],
                                     capture_output=True, text=True, timeout=5)
            self.assertTrue(process.returncode != 0 or process.stdout.strip().startswith('Z'),
                            f'owned descendant still running: {process.stdout}')
        finally:
            unrelated.terminate()
            unrelated.wait(timeout=5)

    def test_invalid_caps_fail_before_test_execution(self):
        for cap in ('0', '-1', 'nan', 'inf', '901', 'bad'):
            with self.subTest(cap=cap):
                result = self.run_smoke(cap)
                self.assertEqual(result.returncode, 2)
                self.assertIn('invalid cap', result.stdout)
                self.assertFalse((self.repo / 'later-checks.log').exists())

    def test_empty_inventory_is_incomplete_not_green(self):
        result = self.run_smoke()
        self.assertEqual(result.returncode, 2)
        self.assertIn('No Python tests discovered', result.stderr)
        self.assertFalse((self.repo / 'later-checks.log').exists())
        self.assertNotIn('Smoke tests passed', result.stdout)


class IntegrityReceiptTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='cse-integrity-test-')
        self.repo = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.git('config', 'commit.gpgsign', 'false')
        (self.repo / 'tests').mkdir()
        (self.repo / 'tests/test_contract.py').write_text('assert 1 + 1 == 2\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture baseline')
        self.base = self.git('rev-parse', 'HEAD').decode().strip()

    def git(self, *args, check=True):
        return subprocess.run(['git', *args], cwd=self.repo, capture_output=True,
                              check=check, timeout=10).stdout

    def run_gate(self, receipt=None, base='HEAD', cwd=None):
        args = ['bash', str(GATE), base]
        if receipt is not None:
            receipt_path = self.repo / 'receipt.json'
            receipt_path.write_text(json.dumps(receipt))
            args += ['--test-change-receipt', str(receipt_path)]
        return subprocess.run(args, cwd=cwd or self.repo, capture_output=True, text=True, timeout=10)

    def change_test(self):
        (self.repo / 'tests/test_contract.py').write_text('assert {1, 2} == set([1, 2])\n')

    def receipt(self, paths=('tests/test_contract.py',)):
        # The defect is deliberately reintroduced in an isolated failable command.
        control = subprocess.run(['python3', '-c', 'assert 1 + 1 == 3'],
                                 capture_output=True, timeout=10)
        log = self.repo / 'negative-control.log'
        log.write_bytes(control.stderr)
        entries = []
        for name in paths:
            values = {}
            for label, ref in (('beforeSha256', f'{self.base}:{name}'), ('indexSha256', f':{name}')):
                result = subprocess.run(['git', 'show', ref], cwd=self.repo, capture_output=True, timeout=10)
                values[label] = digest(result.stdout) if result.returncode == 0 else None
            path = self.repo / name
            entries.append({'path': name, **values,
                            'afterSha256': digest(path.read_bytes()) if path.is_file() else None,
                            'assertions': 'Replace obsolete scalar arithmetic fixture with exact member equality; fixture gate test only.'})
        diffs = [self.git('diff', '--no-ext-diff', '--no-textconv', '--binary', '--no-renames',
                          *extra, self.base, '--', *sorted(paths)).hex()
                 for extra in ([], ['--cached'])]
        return {
            'schemaVersion': 1, 'baseCommit': self.base, 'task': 'fixture-task',
            'authorizationRef': 'fixture authority: explicitly testing receipt validation',
            'oldExpectation': 'Old fixture asserts scalar arithmetic',
            'newExpectation': 'New fixture asserts exact member equality',
            'rationale': 'Synthetic gate fixture, not approval for a real product contract change',
            'changes': entries, 'diffSha256': digest(json.dumps(diffs, separators=(',', ':')).encode()),
            'negativeControl': {'command': ['python3', '-c', 'assert 1 + 1 == 3'],
                                'exitCode': control.returncode, 'path': log.name,
                                'sha256': digest(log.read_bytes()),
                                'rejectedBehavior': 'Arithmetic defect deliberately fails the assertion'},
        }

    def test_unchanged_tests_and_source_only_edit_pass(self):
        self.assertEqual(self.run_gate().returncode, 0)
        (self.repo / 'source.py').write_text('answer = 42\n')
        self.assertEqual(self.run_gate().returncode, 0)

    def test_changed_tests_reject_by_default_and_exact_receipt_does_not_approve(self):
        self.change_test()
        self.assertEqual(self.run_gate().returncode, 1)
        result = self.run_gate(self.receipt())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('tc approval is still required', result.stdout)

    def test_missing_authority_contract_assertions_or_negative_control_reject(self):
        self.change_test()
        original = self.receipt()
        for key in ('authorizationRef', 'rationale', 'oldExpectation', 'newExpectation', 'negativeControl'):
            with self.subTest(key=key):
                receipt = json.loads(json.dumps(original))
                del receipt[key]
                self.assertEqual(self.run_gate(receipt).returncode, 1)
        original['changes'][0]['assertions'] = ''
        self.assertEqual(self.run_gate(original).returncode, 1)

    def test_changed_source_index_diff_or_artifact_invalidates_receipt(self):
        self.change_test()
        receipt = self.receipt()
        self.git('add', 'tests/test_contract.py')
        self.assertEqual(self.run_gate(receipt).returncode, 1)
        receipt = self.receipt()
        receipt['diffSha256'] = '0' * 64
        self.assertEqual(self.run_gate(receipt).returncode, 1)
        receipt = self.receipt()
        (self.repo / 'negative-control.log').write_text('replaced')
        self.assertEqual(self.run_gate(receipt).returncode, 1)
        receipt = self.receipt()
        (self.repo / 'tests/test_contract.py').write_text('assert False\n')
        self.assertEqual(self.run_gate(receipt).returncode, 1)

    def test_additional_untracked_or_hidden_staged_test_change_rejects(self):
        self.change_test()
        receipt = self.receipt()
        (self.repo / 'tests/test_extra.py').write_text('assert True\n')
        self.assertEqual(self.run_gate(receipt).returncode, 1)
        self.git('add', 'tests/test_contract.py')
        (self.repo / 'tests/test_contract.py').write_bytes(self.git('show', 'HEAD:tests/test_contract.py'))
        self.assertEqual(self.run_gate().returncode, 1)

    def test_new_and_deleted_tests_require_exact_receipt(self):
        (self.repo / 'tests/test_new.py').write_text('assert True\n')
        (self.repo / 'tests/test_contract.py').unlink()
        self.assertEqual(self.run_gate().returncode, 1)
        result = self.run_gate(self.receipt(('tests/test_contract.py', 'tests/test_new.py')))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_negative_control_cannot_claim_success_traverse_or_use_symlink(self):
        self.change_test()
        original = self.receipt()
        for field, value in (('exitCode', 0), ('path', '../outside.log'), ('command', [])):
            with self.subTest(field=field):
                receipt = json.loads(json.dumps(original))
                receipt['negativeControl'][field] = value
                self.assertEqual(self.run_gate(receipt).returncode, 1)
        link = self.repo / 'linked.log'
        link.symlink_to(self.repo / 'negative-control.log')
        original['negativeControl']['path'] = link.name
        self.assertEqual(self.run_gate(original).returncode, 1)

    def test_invalid_base_or_nonrepository_fails_closed(self):
        self.assertEqual(self.run_gate(base='missing-ref').returncode, 1)
        with tempfile.TemporaryDirectory(prefix='cse-integrity-outside-') as outside:
            self.assertEqual(self.run_gate(cwd=outside).returncode, 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
