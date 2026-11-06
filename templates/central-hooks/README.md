# Central hook implementations

Real logic for the Codex Copilot plugin hooks. The plugin's `hooks/*.sh` files are frozen shims (Codex hashes the whole plugin directory for trust, so the plugin must stay byte-identical across releases). Each shim resolves `~/.copilot/current/codex-copilot/templates/central-hooks/<name>` and execs it, so edits here ship with the release pointer and never re-prompt trust.

Marker gate: every hook except `coordinator-guard.sh` is a no-op unless the project (walking up from the payload `cwd`, else `$PWD`) contains `copilot.project.json`. The coordinator guard is ungated: the coordinator rule is a global owner rule.
