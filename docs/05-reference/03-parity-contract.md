# Claude Parity Contract

Codex Copilot mirrors Claude Copilot capability intent, not Claude-only syntax.

The current baseline is recorded in `parity/claude-baseline.json`:

- Claude Copilot framework: `5.10.0`
- `cc`: `1.4.0`
- `tc`: `1.1.0`
- Codex Copilot parity release: `0.5.0`

## Implemented

- `AGENTS.md` project instructions
- direct Codex skills for the software/product specialist roster
- `$protocol`, command-equivalent skills, and `tc` work products
- Live Docs guidance through `cc docs`
- memory drift checks through `cc memory check`
- artifact-bound QA-gate state convention through `tc` metadata, QA work products, and `scripts/copilot-gate.sh`
- optional specialist packs for `kc`, `cco`, `cw`, `cs`, and `cpa`
- stream validation through `scripts/orchestrate-validate.py`

## Substituted

Claude lifecycle hooks are substituted with explicit Codex mechanisms:

- preflight and routing instructions
- `tc` task metadata
- QA work products with `ARTIFACT:` markers and verdicts
- inspection scripts and tests

Here, "Claude lifecycle hooks" means Claude Code runtime events such as
SessionStart, PreToolUse, and SubagentStop. It does not mean the design-led
product creation protocol; the Codex protocol remains design-led.

Claude named-agent syntax is substituted with direct skill names and `agent-catalog.json`.

Headless worker orchestration is substituted with explicit user-approved `spawn_agent` launch templates and worktree safety checks.

## Deferred

Automatic runtime hook enforcement remains platform-dependent. Codex Copilot should not describe hook enforcement as implemented until Codex provides a matching lifecycle surface.

## Updating The Baseline

When Claude Copilot changes, update:

1. `parity/claude-baseline.json`
2. `VERSION.json`
3. `plugins/codex-copilot/agent-catalog.json`
4. `plugins/codex-copilot/agent-catalog.schema.json`
5. docs and tests that assert the parity surface

Then run:

```bash
scripts/smoke-test.sh
```
