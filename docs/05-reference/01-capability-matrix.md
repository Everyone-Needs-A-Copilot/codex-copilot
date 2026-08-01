# Capability Matrix

Codex Copilot translates the useful parts of Claude Copilot into Codex-native primitives while keeping the global plugin focused on design-led software creation. This page explains the current capability surface; machine-readable manifests remain authoritative.

Authoritative sources:

- `plugins/codex-copilot/agent-catalog.json` for specialists and routing
- `VERSION.json` for framework and dependency versions
- `parity/claude-baseline.json` for the adopted Claude baseline
- script behavior and `--help` output for executable contracts

| Claude Copilot Capability | Codex Copilot Equivalent | Status | Boundary |
| ------------------------- | ------------------------ | ------ | -------- |
| `CLAUDE.md` project instructions | `AGENTS.md` project instructions | Implemented | Codex reads repo instructions rather than Claude-specific project instructions. |
| software specialist agents | direct Codex skills such as `$sd`, `$uxd`, `$uid`, `$ta`, `$me`, and `$qa` | Implemented | Specialists run as skills in the main session unless delegation is explicitly requested. |
| named-agent invocation | direct `$skill` names and `$launcher` | Codex-native substitute | Codex does not expose a custom named-agent registry. |
| `/protocol` | `$protocol` | Implemented | Skill-based workflow, not platform slash-command syntax. |
| `/continue` | `$continue` | Implemented as workflow skill | Reads `tc` and `cc` context when available; no automatic checkpoint runtime. |
| `/pause` | `$pause` | Implemented as workflow skill | Stores pause state through `tc`/`cc` when available; does not create Claude checkpoints. |
| `/map` | `$map` | Implemented as workflow skill | Produces or stores a map; writing `PROJECT_MAP.md` requires explicit request. |
| `/memory` | `$memory` | Implemented as workflow skill | Uses `cc memory`, `cc memory check`, and `tc progress` where configured. |
| `/extensions` | `$extensions` | Implemented as inspection workflow | Explains project/global/base resolution; does not perform automatic prompt assembly. |
| `/orchestrate` | `$orchestrate` | Explicit-delegation substitute | Plans streams and validates boundaries; does not auto-spawn headless workers without user-approved delegation. |
| `/setup`, `/setup-copilot` | `$setup-copilot` | Implemented as verification workflow | Provides safe setup/repair guidance; does not remove existing resources. |
| `/setup-project` | `$setup-project` plus `scripts/setup-project.sh` | Implemented | Installer refuses replacement of existing project wiring. |
| `/update-project` | `$update-project` | Implemented as workflow skill | Inspects drift and suggests safe updates; destructive replacement requires explicit current approval. |
| `/update-copilot` | `$update-copilot` | Implemented as workflow skill | Checks git/tooling safely; no reset, clean, force-push, or deletion without explicit approval. |
| `/knowledge-copilot` | `$knowledge-copilot` | Implemented as workflow skill | Guides creation/linking/status; does not delete or replace existing knowledge. |
| `/config` | `$config` | Implemented as workflow skill | Reads `cc` config and env hydration state. |
| `/reflect` | `$reflect` | Implemented as workflow skill | Stores lessons through `cc`/`tc` when available. |
| `/skills-approve` | `$skills-approve` | Implemented as workflow skill | Reviews available skills; no hidden allow-list state. |
| Memory Copilot MCP | `cc memory` and `cc memory check` CLI | Implemented dependency | Requires Claude Copilot `cc` CLI installed; drift checks find broken paths, command references, version conflicts, and stale entries. |
| Skills Copilot MCP | `cc skill` plus Codex skills | Implemented dependency | `cc skill --scope project` requires running inside a git repo. |
| Task Copilot | `tc` CLI | Implemented dependency | `tc init` creates `.copilot/tasks.db`; work products are stored through `tc`. |
| Live Docs | `cc docs` CLI guidance in specialists | Implemented dependency | Requires compatible `cc`; falls back to local package files or official docs when unavailable. |
| Claude quota observability | `cc usage` CLI | Optional utility | Reports Claude session quota, not Codex/OpenAI usage; useful for Claude Copilot tooling but not a Codex protocol gate. |
| domain agents and extensions | dormant capability packs | Implemented convention | Packs stay inactive until a project exposes selected skills through its own local plugin. |
| Mechanical Claude lifecycle hooks | `tc` metadata, artifact-bound QA work products, `scripts/copilot-gate.sh`, instructions, and tests | Codex-native substitute | This refers to Claude runtime hooks such as SessionStart/PreToolUse/SubagentStop, not the design-led product protocol. Codex has no equivalent runtime hook surface in this project. |
| Headless worker orchestration | Explicit `spawn_agent` delegation plus stream validation | Limited substitute | Codex delegation is user-approved and scoped; no autonomous background worker loop. |
| Claude 16-agent roster | 11 active software/product skills plus optional `business-creative` pack | Codex-native substitute | `kc`, `cco`, `cw`, `cs`, and `cpa` are activatable rather than globally loaded. |
| Worktree stream validation | `scripts/orchestrate-validate.py` | Implemented utility | Validates stream metadata, dependencies, cycles, and file ownership before parallel work. |
| Initiative documentation | `docs/40-initiatives/NN-slug/` plus linked `tc` context | Implemented convention | Markdown preserves initiative goals, phases, decisions, validation evidence, and retrospectives; `tc` remains authoritative for live execution and QA state. |
