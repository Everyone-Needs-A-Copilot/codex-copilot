"""Instruction fitness check for the consolidated approval and execution-limit rules (PRD-12).

Fails when a shipped instruction file still carries a retired rule that either
contradicted what `tc execution` enforces in code or duplicated it without enforcing it.
"""
from pathlib import Path
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCAN = ['AGENTS.md', 'templates', 'plugins/codex-copilot/skills', 'plugins/codex-copilot/agent-prompts']
RETIRED = [
    'Debug-spiral circuit breaker',
    'three consecutive unsuccessful',
    'max 3 iterations',
    'warn after 3 iterations',
    'Warns if >5 continuations',
    'Blocks if >10 continuations',
    'Auto-proceed at checkpoints - ALWAYS wait',
    'CRITICAL: Explicit approval required.** No auto-proceed.',
    'quote to raise',
    'verbatim quote to raise the cap',
]


def scan(paths):
    hits = []
    for base in paths:
        files = [base] if base.is_file() else sorted(base.rglob('*.md')) if base.exists() else []
        for path in files:
            text = path.read_text(errors='replace')
            hits += [f'{path}: {phrase}' for phrase in RETIRED if phrase in text]
    return hits


class RetiredPhraseTests(unittest.TestCase):
    def test_no_retired_rule_phrases_ship(self):
        self.assertEqual(scan([ROOT / p for p in SCAN]), [])

    def test_negative_control_rejects_retired_rule(self):
        with tempfile.TemporaryDirectory() as tmp:
            sample = Path(tmp) / 'agent.md'
            sample.write_text('**Debug-spiral circuit breaker.** After three consecutive unsuccessful fix attempts.\n')
            self.assertEqual(len(scan([sample])), 2)

    def test_consolidated_rules_are_present(self):
        checkpoints = (ROOT / 'plugins/codex-copilot/skills/protocol/references/checkpoints.md').read_text()
        self.assertIn('DECISION NEEDED:', checkpoints)
        self.assertIn('no auto-proceed', checkpoints)
        self.assertIn('`tc execution`', (ROOT / 'AGENTS.md').read_text())


if __name__ == '__main__':
    unittest.main()
