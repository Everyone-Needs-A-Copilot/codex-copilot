# Shared enforcement candidate

Status: hash-pinned local activation verified in the claude-copilot canary project;
not an upstream release or an ecosystem-wide rollout.
Execution record: knowledge-copilot-internal PRD-2 / TASK-2–5.

## Contract

`safety-policy.sh` validates the Codex `PreToolUse` / `Bash` payload and sends a
schema-1 shell request to `cc enforcement evaluate --json`. The evaluator reads
the canonical `.claude/hooks/security-rules.json` through the machine-configured
shared framework root. No Claude force-delegation, journey, or agent-state rule
is invoked. The candidate defaults to blocking destructive-command matches;
explicit `--destructive-action warn` is available in the shared CLI.

The adapter uses a valid Codex exit-2 denial with a nonempty stderr reason when
evaluation fails, the response is invalid, or policy denies. The plugin loader
also denies if the adapter is missing. Missing hook trust, host-skipped hooks,
and host timeouts cannot be repaired by an adapter that never runs. Regex matching
can also flag quoted command text and does not inspect script contents, arbitrary
MCP effects, or provide filesystem confinement. Path-scope enforcement is not
implemented by this shell-only candidate.

`tc task check-qa ID --json` and `tc task update --status completed` use the same
shared evidence predicate. It requires the latest task-bound test work product
to contain one passing verdict and an artifact marker; a newer recorded code
work product invalidates older QA. Unrecorded source changes are not detected.
The Codex gate validates the CLI's response, including task and work-product IDs.
This requires the candidate shared CLI changes; older installed CLIs are not a
supported activation target.

## Runtime evidence

`scripts/verify-hook-runtime.py` exercises the installed CLI with fixed local
responses and harmless file sentinels. It uses no model inference and makes no
saved trust edits. The generated fixture's hook is trusted for that invocation.
The loopback fixture exists only for this test and exits with it.

The generic hook and the candidate safety adapter both passed on CLI 0.153.4.
`cc enforcement status --project PATH --json` reports discovered hooks, trust,
disabled config layers, and binary/version; it deliberately reports runtime
enforcement as unverified until a separate execution probe establishes coverage.

## Activation and rollback

Release and install compatible shared `cc`/`tc` candidates before enabling this
plugin's new safety hook. First validate in `claude-copilot`; broader rollout is
a separate activation, not a side effect of repairing its registration.

Preserve `.codex/agents` and unrelated hook registrations. Back up the exact
legacy `hooks.json` bytes, remove only its four identified legacy framework
entries, and use the updated plugin for the new controls. Confirm project trust
and review the new hook hashes with the host. Re-run the real canary in that
host/project before claiming active enforcement. Restore the exact backup and
previous plugin/CLI versions if activation fails; do not delete `.codex`.

The user-authorized QA test-double update is complete: all 40 contract tests and
the full smoke suite passed. The original rejection/approval assertions remain
unchanged. The local build identifies cc as `2.12.14+enforcement.20260907`, tc as
`1.3.0+enforcement.20260907`, and the Codex 0.7.0 base with local build metadata
`enforcement.20260907`; Git tree identities distinguish it from released bits.

Saved project registration passed allow/deny execution probes with CLI 0.153.4
and the desktop-bundled binary 0.153.3. `--project PATH` on the verifier tests this
mode without hook/trust overrides. This is fresh-process runtime evidence, not
proof that an already-open desktop conversation hot-reloaded its configuration.
The local plugin is globally disabled and enabled only in the canary project.
Shared cc/tc launchers are machine-level. Their upstream releases, managed-layer
promotion, and broader hook activation remain separate work.
