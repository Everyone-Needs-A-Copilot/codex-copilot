"""Native adapter contracts; shared engine owns scheduling/ownership semantics."""
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

class ProtocolParallelTest(unittest.TestCase):
    def test_catalog_default_has_bounded_convergence(self):
        catalog=json.loads((ROOT/'plugins/codex-copilot/agent-catalog.json').read_text())
        execution=catalog['execution']
        self.assertEqual(execution['default'],'parallel-ready')
        self.assertEqual(execution['backend'],'tc cycle')
        self.assertEqual(execution['deprecatedEntrypoints'],{'orchestrate':'protocol'})
        self.assertEqual(execution['writeOwnership'],'exclusive')
        self.assertEqual(execution['capacity'],'native-and-resource-limits')
        self.assertEqual(execution['cleanup'],'verified-merged-worktrees')

    def test_smoke_covers_catalog_roles_without_activating_packs(self):
        adapter=load('cycle_adapter','scripts/protocol-cycle.py')
        catalog=json.loads((ROOT/'plugins/codex-copilot/agent-catalog.json').read_text())
        self.assertEqual(adapter.role_ids(),[item['id'] for item in catalog['agents']])
        self.assertEqual(set(adapter.role_ids(True)),{item['id'] for item in catalog['agents']+catalog['optionalAgents']})
        self.assertEqual(len(adapter.role_ids(True)),len(set(adapter.role_ids(True))))

    def test_smoke_only_calls_shared_provider_free_lifecycle(self):
        adapter=load('cycle_cli','scripts/protocol-cycle.py')
        with patch('sys.argv',['protocol-cycle.py','smoke','--tc','/verified/tc','--json']),patch.object(adapter.subprocess,'run') as run:
            run.return_value.returncode=0
            self.assertEqual(adapter.main(),0)
            command=run.call_args.args[0]
            self.assertEqual(command[:3],['/verified/tc','cycle','smoke'])
            self.assertEqual(command[3:5],['--roles',','.join(adapter.role_ids())])
            self.assertEqual(command[-1],'--json')
            self.assertFalse(run.call_args.kwargs['check'])

    def test_smoke_propagates_engine_failure(self):
        adapter=load('cycle_failure','scripts/protocol-cycle.py')
        with patch('sys.argv',['protocol-cycle.py','smoke','--tc','/verified/tc']),patch.object(adapter.subprocess,'run') as run:
            run.return_value.returncode=7
            self.assertEqual(adapter.main(),7)

    def test_legacy_normalization_preserves_input_dependency_and_paths(self):
        adapter=load('legacy_cycle','scripts/orchestrate-validate.py')
        plan=adapter.normalize([{'streamId':'A','files':['src/a.py'],'streamDependencies':[]},{'streamId':'B','files':['src/b.py'],'streamPaths':['tests/b/**'],'streamDependencies':['A']}])
        self.assertEqual(plan['schemaVersion'],1)
        self.assertEqual(plan['streams'][1]['paths'],['src/b.py','tests/b/**'])
        self.assertEqual(plan['streams'][1]['dependsOn'][0]['event'],'built')
        self.assertEqual(plan['streams'][1]['dependsOn'][0]['stream'],'A')

    def test_invalid_legacy_ownership_shape_refused(self):
        adapter=load('bad_legacy','scripts/orchestrate-validate.py')
        with self.assertRaisesRegex(ValueError,'must be lists'):
            adapter.normalize([{'streamId':'A','files':'src/a.py','streamDependencies':[]}])
        with self.assertRaisesRegex(ValueError,'requires'):
            adapter.normalize([{'streamId':'A'}])

    def test_deprecated_entrypoint_does_not_repeat_old_launch_workflow(self):
        skill=(ROOT/'plugins/codex-copilot/skills/orchestrate/SKILL.md').read_text()
        self.assertIn('deprecated',skill.lower())
        self.assertIn('Continue with `$protocol`',skill)
        self.assertNotIn('Spawn Codex subagents only when explicitly requested',skill)
        adapter=(ROOT/'plugins/codex-copilot/skills/protocol/references/parallel-execution.md').read_text()
        for term in ['cc skill get parallel-execution','tc cycle ready','actual cwd','cross-scope','branch history','not proof of native']:
            self.assertIn(term,adapter)

    def test_active_entrypoints_do_not_retain_opt_in_gate(self):
        for name in ['AGENTS.md','templates/AGENTS.project.template.md','plugins/codex-copilot/skills/protocol/SKILL.md','plugins/codex-copilot/skills/launcher/SKILL.md','plugins/codex-copilot/skills/protocol-router/SKILL.md','plugins/codex-copilot/skills/specialist-agents/SKILL.md']:
            text=(ROOT/name).read_text()
            self.assertNotIn('only when the user explicitly',text,name)
            self.assertNotIn('at most three concurrently',text,name)

if __name__=='__main__':
    unittest.main()
