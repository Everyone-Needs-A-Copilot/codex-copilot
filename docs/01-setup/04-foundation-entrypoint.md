# One foundation entry path

**Set up the target project with the existing script, start with `$protocol`,
verify the agreed result, then stop when source-bound QA passes.** There is no new
installer, task engine, mandatory agent chain or automatic paid service.

## Set up one project

From the reviewed Codex foundation checkout, for an existing target Git repository:

```sh
scripts/setup-project.sh --project /absolute/path/to/project \
  --framework-root "$PWD" --no-org-plugin
```

This selects the source you are reviewing and suppresses organization auto-detection
for a base-only setup. The script copies the native project plugin and QA gate,
creates project wiring, and initializes `tc` when available. Existing owner-authored
instructions and decision instruments are preserved. Re-running uses the existing
content-aware updater; it does not authorize overwriting project ownership.
Use the reported source and results, not the version number alone.

The default production updater can prefer the pinned foundation mirror. An explicit
`--framework-root` tests a reviewed source candidate; it neither advances that pin
nor proves foundation-signed publication. See [setup details](02-setup-project.md).
If a shared Claude + Codex project is already being managed through canonical
`cc reconcile`, keep that exact plan/apply/verify route instead of stacking a
second installer over it.

Open the target project in Codex, review/trust its native hooks through the host's
normal controls, then start with:

```text
Read AGENTS.md and use $protocol for this task: <concrete result>.
```

Agree on the deliverable, criteria, consumers, verification scope/cap and exclusions.
Use `tc` for the task and evidence. Required criteria gate completion; unrelated
discoveries are recorded separately rather than opening another automatic loop.

## Optional means explicit

Keep the base plugin and mandatory QA. Add organization content only by choosing
the organization source; add [capability packs](../02-user-guides/06-capability-packs.md)
only when the task needs them. Packs are not activated by the base command above.
Machine onboarding (`cc onboard`), remote repository creation, model evaluations,
browser services and real UI pilots are not routine setup or verification steps.
The shortened path does not resurrect Claude's retired partial reference profile.

## Shared verification, not a Codex runner

The shared Copilot CLI supplies `cc verify plan`, `run` and `status`. Check
`cc --version` and `cc verify --help`: bare `cc` may be the C compiler, and an older
installed snapshot may lack the source capability despite the same version label.
Use a verified shared CLI or the prepared Claude source environment; Codex does
not vendor or reinstall the engine. Missing tooling is reported, never simulated.

Use `cc status --project /absolute/path/to/project --json` for observed setup and
the latest verification plan/lane/cap/artifact. Installation/registration does not
prove activation or a running agent; unsupported live/blocked state remains unknown.
Check `cc status --help` first: status is a source-only addition to development
`cc 2.13.1`, not proof that an earlier published/tagged `2.13.1` snapshot has it.

With a reviewed project-owned `verification.json`, from the target project:

```sh
mkdir -p .copilot
cc verify plan --base HEAD --task TASK_ID --json > .copilot/verification-plan.json
# Review selected commands, input scopes, reasons and caps before running them.
cc verify run --plan .copilot/verification-plan.json --json
cc verify status --run RUN_ID --json
```

Use the current task and emitted run ID; choose the actual review base rather than
`HEAD` when the batch is already committed. The manifest contains executable
project commands with the invoking user's permissions. Setup does not invent or
install application assertions: if there is no manifest, select the project's
existing checks and explicitly author/review its lane manifest, or run those
checks directly with task-bound evidence. Do not copy unrelated foundation suites.

Reports remain private under `.copilot/verification/`, with progress, caps, exit
codes and logs. A failed or incomplete result is not approval; do not silently
restart. Review changed-test integrity and retain the existing
[tc QA gate](../02-user-guides/04-quality-gates.md), even when execution succeeded.
An artifact can be reused only under its unchanged inputs; another task's approval
cannot. Once required source-bound QA passes, close this task and stop.

This source path does not claim global deployment, published release fitness,
live model adherence or a completed UI pilot. Current compatibility and reviewed
semantic adoption are recorded in the [parity contract](../05-reference/03-parity-contract.md).
