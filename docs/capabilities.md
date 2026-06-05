# Capability Matrix

Codex Copilot mirrors Claude Copilot 5.6.0 through Codex-native primitives. This page is the source of truth for what is implemented, what is substituted, and what remains limited by Codex runtime surfaces.

| Claude Copilot Capability | Codex Copilot Equivalent | Status | Boundary |
| ------------------------- | ------------------------ | ------ | -------- |
| `CLAUDE.md` project instructions | `AGENTS.md` project instructions | Implemented | Codex reads repo instructions rather than Claude-specific project instructions. |
| 16 framework agents | 16 `agent-*` Codex skills | Implemented | Specialists run as skills in the main session unless delegation is explicitly requested. |
| `@agent-*` invocation | `$agent-*` skills and `$agent-launcher` | Codex-native substitute | Codex does not expose a custom named-agent registry. |
| `/protocol` | `$protocol` | Implemented | Skill-based workflow, not platform slash-command syntax. |
| `/continue` | `$continue` | Implemented as workflow skill | Reads `tc` and `cc` context when available; no automatic checkpoint runtime. |
| `/pause` | `$pause` | Implemented as workflow skill | Stores pause state through `tc`/`cc` when available; does not create Claude checkpoints. |
| `/map` | `$map` | Implemented as workflow skill | Produces or stores a map; writing `PROJECT_MAP.md` requires explicit request. |
| `/memory` | `$memory` | Implemented as workflow skill | Uses `cc memory` and `tc progress` where configured. |
| `/extensions` | `$extensions` | Implemented as inspection workflow | Explains project/global/base resolution; does not perform automatic prompt assembly. |
| `/orchestrate` | `$orchestrate` | Explicit-delegation substitute | Plans streams and validates boundaries; does not auto-spawn headless workers without user-approved delegation. |
| `/setup`, `/setup-copilot` | `$setup-copilot` | Implemented as verification workflow | Provides safe setup/repair guidance; does not remove existing resources. |
| `/setup-project` | `$setup-project` plus `scripts/setup-project.sh` | Implemented | Installer refuses replacement of existing project wiring. |
| `/update-project` | `$update-project` | Implemented as workflow skill | Inspects drift and suggests safe updates; destructive replacement requires explicit current approval. |
| `/update-copilot` | `$update-copilot` | Implemented as workflow skill | Checks git/tooling safely; no reset, clean, force-push, or deletion without explicit approval. |
| `/knowledge-copilot` | `$knowledge-copilot` and `$agent-kc` | Implemented as workflow skill | Guides creation/linking/status; does not delete or replace existing knowledge. |
| `/config` | `$config` | Implemented as workflow skill | Reads `cc` config and env hydration state. |
| `/reflect` | `$reflect` | Implemented as workflow skill | Stores lessons through `cc`/`tc` when available. |
| `/skills-approve` | `$skills-approve` | Implemented as workflow skill | Reviews available skills; no hidden allow-list state. |
| Memory Copilot MCP | `cc memory` CLI | Implemented dependency | Requires Claude Copilot `cc` CLI installed. |
| Skills Copilot MCP | `cc skill` plus Codex skills | Implemented dependency | `cc skill --scope project` requires running inside a git repo. |
| Task Copilot | `tc` CLI | Implemented dependency | `tc init` creates `.copilot/tasks.db`; work products are stored through `tc`. |
| Mechanical Claude hooks | Instructions, skills, and tests | Codex-native substitute | Codex has no equivalent runtime hook surface in this project. |
| Headless worker orchestration | Explicit `spawn_agent` delegation | Limited substitute | Codex delegation is user-approved and scoped; no autonomous background worker loop. |

