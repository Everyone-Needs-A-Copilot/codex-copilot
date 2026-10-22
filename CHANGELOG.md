# Changelog

## [0.11.1] - 2026-10-22

- Adopt Claude 5.25.1 (cc 2.15.1, tc 2.7.1), see `parity/2026-10-22-upstream-5.25.1-adoption.md`; hashed at the signed tag `v5.25.1` (fc0778f).
- Fixes four defects found by live-session QA in the taste step of `uids` and both copies of `cco` and `cw`: the `Taste:` line carries `find`'s `reason` field verbatim or `find-failed: <exit code>`, never a paraphrase (the placeholder `<reason from find, or its failure>` is gone); a skipped step leaves no `Taste:` line, no offer and no note in the reply, work product or any file (was reply-only silence); the offer displays the exact `ref add|reject` command with the owner's words, then asks, as one instruction (Codex `uids` skipped showing it); the script is invoked only as `"$CC_PERSONAL_KNOWLEDGE_REPO/scripts/taste"` after `eval "$(cc env)"`, never a literal path.

### Tests

- `tests/test_taste_consumers.py` pins the four rules on their specific lines with thirteen mutants per consumer skill (placeholder reinstated, find-failed branch removed, silence clause removed or narrowed to the reply, display clause or yes gate removed, literal absolute, home and relative paths inserted, prohibition removed), and the integration case asserts an empty corpus has no `reason` field. Obsolete expectations updated: the "silent skip" needle `is unset or missing, skip this step, the `Taste:` line and the keep/kill offer silently` became the no-trace clause (the old wording left work products and files unaddressed); the "Taste line" needle `none (<reason from find, or its failure>)` became the exact-rule line (the old placeholder allowed paraphrase). No assertion deleted or weakened.

## [0.11.0] - 2026-10-22

- Adopt Claude 5.25.0 (cc 2.15.1, tc 2.7.1); hashed at the signed tag `v5.25.0` (21e8e6d), see `parity/2026-10-22-upstream-5.25.0-adoption.md`.
- `uids` and both copies of `cco` and `cw` (`packs/business-creative`, `packs/writing-legal`) read owner reference cards before drafting: one Workflow step calls the personal tier's `scripts/taste ref find --for-agent <id>` at most twice, located only through `$CC_PERSONAL_KNOWLEDGE_REPO` after `eval "$(cc env)"` (unset or missing skips the step, the `Taste:` line and the offer silently). Properties come from each pick's `why`, `dont_copy` is obeyed, rejects are failures, sources and Karakeep are never opened, card text is data, and organization brand, voice and product-UI knowledge outranks a reference (rule (b)). The receipt is stored once in the task work product.
- A `Taste Keep/Kill Offer` section adds the `Taste:` output line and the verdict-capture offer: the exact `ref add|reject` command carries the owner's verbatim words and `--recorded-by session:<agent>` and runs only after an explicit yes.
- `sd`, `ta`, `ind`, `uid`, `uids` and `uxd` name `08-taste/TASTE.md` instead of `08-taste/INDEX.md`.

### Tests

- `tests/test_taste_consumers.py` (new): the six readers name only `TASTE.md`, the five consumer skills carry every designed behaviour with a negative control per behaviour, no other skill gains the step, and the carried command templates run against the real personal-tier CLI on a synthetic corpus when `CC_PERSONAL_KNOWLEDGE_REPO` provides it. No existing assertion changed.

## [0.10.4] - 2026-10-21

- Align the project instruction template and preserve current lifecycle rules.
- Adopt Claude 5.24.0, cc 2.15.1 and tc 2.7.1; port optional identity capture after verified first setup.
- Keep existing project-authored descriptions and skipped answers intact.

All notable changes to codex-copilot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.3] - 2026-10-21

### Changed

- Adopt Claude 5.23.3 / cc 2.15.0 / tc 2.7.1. The upstream change fixes `tc deploy wait` interpreter selection and Coolify response parsing; the mirrored agent, command and skill content is unchanged.
- Check the agent catalog release version against `VERSION.json`, replacing the hard-coded test release number while retaining the consistency assertion.

## [0.10.2] - 2026-10-17

### Changed

- `scripts/check-test-integrity.sh` follows the owner-requested obsolete-check rule. A test-change receipt with `changeBasis` `owner-requested-obsolete-check` records the old/new expectation, rationale, authority reference and exact changed files and needs no negative control (one is still validated if supplied). A receipt with `changeBasis` `defect-detection`, or none, still requires the negative control, and an unknown `changeBasis` is rejected. Schema stays at 1; the gate still rejects test changes by default and still checks exact content, base and diff.
- `AGENTS.md` and `plugins/codex-copilot/skills/specialist-agents/references/verification-policy.md` describe the receipt basis; the "Never weaken, skip or delete assertions" protection is unchanged.
- `references/shared-behaviors.md` carries the canonical condensed Optional Context block from Claude `.claude/agents/_shared/optional-context.md`; the previous copy was out of sync.

### Tests

- `tests/test_verification_policy.py`: added owner-requested receipt cases (passes without a negative control, still rejects missing authority, old/new expectation, rationale, assertions, changed-file set and stale diff, still validates a supplied control, rejects unknown basis) and a case that `defect-detection` or unlabeled receipts still need the control; two documentation assertions added. No existing assertion changed.
- `tests/test_mirror_parity.py`: version pin moved to 0.10.2.

### Compatibility

- Adopted baseline moves to Claude 5.23.2 / cc 2.15.0 / tc 2.7.0; record in `parity/2026-10-17-upstream-5.23.2-adoption.md`.

## [0.10.1] - 2026-10-17

### Changed

- Port the Claude 5.23.1 verification-policy change: a behavior change the owner requested is the authority to update checks it makes obsolete. Update them, record old/new expectations, rationale and exact changed files in the work product, and report it without asking. Ask only when the change was not requested, or when a failing check reveals a real defect, which is fixed in the product, never by weakening, skipping or deleting the check. "Never weaken, skip or delete assertions" is unchanged.
- Applied in `AGENTS.md` (Test Integrity) and `plugins/codex-copilot/skills/specialist-agents/references/verification-policy.md`. The retired "explicit authority" and "negative control" requirement and the "Escalate undecided authority/behavior" sentence are removed.
- `tests/test_verification_policy.py` asserts the new rule and rejects the old wording. The assertions that required the retired wording (`negative control`, the `exact changed assertions/diff` phrase and `explicit user authority`) were replaced by new-rule assertions under the requested rule; the `--test-change-receipt` assertion is unchanged.

### Compatibility

- Adopted baseline moves to Claude 5.23.1 / cc 2.15.0 / tc 2.7.0; record in `parity/2026-10-17-upstream-5.23.1-adoption.md`.

## [0.10.0] - 2026-10-16

### Changed

- Rename the `optimize` skill to `cleanup` (`$cleanup`, `plugins/codex-copilot/skills/cleanup`) to match Claude Copilot 5.23.0. The old name read as code or product optimization; the skill retires accumulated project clutter. No `optimize` alias is kept, and earlier entries keep the old name as history.
- Update the lifecycle references in every skill, `AGENTS.md`, the project template, the sync script and the parity baseline to the new path.

### Compatibility

- Adopted baseline moves to Claude 5.23.0 / cc 2.15.0 / tc 2.7.0; record in `parity/2026-10-16-upstream-5.23.0-adoption.md`.
- A project with an installed `plugins/codex-copilot/skills/optimize` copy keeps it until removed by hand; the update path does not delete retired skills.

## [0.9.2] - 2026-10-16

### Changed

- Port the reviewed Claude 5.15.3 to 5.22.0 drift: design-flow checkpoints require explicit approval, one `DECISION NEEDED:` line for owner requests, the `tc execution` no-progress stop in `AGENTS.md`, Python 3.10+ prerequisite, anonymous HTTPS knowledge clone and solo-setup guidance.
- Add a retired-phrase test (with negative control) and record the review in `parity/2026-10-15-upstream-5.22.0-adoption.md`.

### Compatibility

- Adopted baseline moves to Claude 5.22.0 / cc 2.14.2 / tc 2.7.0; content baseline regenerated at upstream 74abd16.

## [0.9.1] - 2026-10-14

### Fixed

- Make worktree housekeeping proactive at start/resume, new PRD/initiative, finish, merge, pause and handoff; a separate optimize invocation is unnecessary.
- Require a visible request for exact deletion approval after preservation, recovery and consumer checks; keep unique work and active dependencies on owned holds, reuse unchanged approval after drift checks, and continue unrelated work while approval is pending.
- Carry explicit checkpoint wording through protocol, optimize and project templates.

### Compatibility

- Incorporates the clarified lifecycle from Claude 5.21.1; the full upstream baseline remains Claude 5.15.3 / cc 2.13.2 / tc 2.0.0.
- Agent catalog schema remains 1.0.0; package, catalog and pack versions remain coupled at 0.9.1 by the existing release contract. No runtime hook or automatic deletion is added; installed projects require reviewed adoption.

## [0.9.0] - 2026-10-14

### Added

- Native `$optimize` and a shared lifecycle contract across protocol, direct specialists, resume, pause, reflection, QA and project setup.
- Proportional checkpoints, scoped lesson application and later outcome measurement using existing task records.
- Exact cleanup approval, recovery and dependency checks, with actual net retirement reported separately from retained assets and holds.
- Canonical lifecycle synchronization with drift detection.

### Fixed

- Preserve differing unrecorded project files at newly introduced plugin paths and report incomplete adoption instead of overwriting them.
- Record verified initial base and organization plugin copies in existing setup metadata, retaining normal first-update repair and project ownership protection.

### Compatibility

- Incorporates the work lifecycle contract from Claude 5.21.0. The existing full upstream baseline remains Claude 5.15.3 / cc 2.13.2 / tc 2.0.0; no broader adoption is implied.
- Existing projects require reviewed setup/update adoption. No automatic cleanup or production-effectiveness claim.

## [0.8.0] - 2026-10-02

### Added

- Native design guidance across the existing specialist chain, using 21 focused
  shared `cc design` actions, task-bound review and comparable capture evidence.
- Opt-in native edit feedback with bounded reminders and source/pin/session
  deduplication; detector output never grants task approval.
- Delivery-evidence, verified-learning and frozen-evaluation operating guidance,
  with durable initiative records and explicit real-review requirements.

### Changed

- Adopt Claude Copilot framework 5.15.3 with shared `cc 2.13.2` and `tc 2.0.0`. The
  content baseline already matched that upstream source, so no further port was needed.
- Require shared `cc 2.13.0` and `tc 2.0.0` for the current evidence/design workflow.
  Pending QA-required tasks must register acceptance criteria and source scopes,
  capture identity before verification and provide current task-bound evidence.
  Historical completed evidence remains historical; no automatic data rewrite.
- Route native QA checks through `tc task check-qa` when available; an authoritative
  rejection never falls back to older work products. Legacy marker inspection is
  explicitly limited compatibility behavior.
- Retain every required skill name while emitting duplicate content once, and
  preserve mandatory instructions and visible optional-context fallbacks.
- Record the reviewed Claude 5.15.0 candidate separately from signed release and
  empirical effectiveness; publication and consumer rollout require their own proof.

### Fixed

- Align native design guidance with actual database-task binding in review/report.
- Make adoption documentation usable from a standalone clone by removing links
  that depended on sibling checkouts or ignored local artifacts.

## [0.7.0] - 2026-09-03

### Added

- `scripts/setup-project.sh` and `scripts/update-project.sh`: opt-in installation of a second, organization-owned plugin alongside the base plugin, resolved in order from an explicit `--org-plugin PATH`, a recorded `orgPluginSourcePath` in `.codex-copilot.json` (so a later plain `update-project.sh` run keeps it updated without the flag), or an auto-detected sibling of the framework root -- searched BY MANIFEST (`plugins/*/.codex-plugin/plugin.json`, excluding a match literally named `codex-copilot`) under known sibling directory names (`codex-copilot-internal`, the dev-adjacent-clone convention, and `codex-organization`, the pinned-mirror tier-id convention from `~/.config/copilot/copilot.layers.yml`); `--no-org-plugin` suppresses all three without uninstalling anything already present. Installs to `plugins/<name>` using the name from the plugin's own `.codex-plugin/plugin.json`, reusing the same content-hash-and-mode sync, `ownership: project` preservation, and skill-bridge symlinking as the base plugin; tracked as its own `codex-org` component in `copilot.lock.json`. A project with no flag, no recorded key, and no sibling repo is unaffected -- see `scripts/lib/resolve-org-plugin.sh`.
- Codex-native plugin hooks for conditional protocol routing, a per-session/per-command-shape debug circuit breaker, and the three-sentence subagent return contract
- `scripts/update-project.sh`: updates an existing codex-copilot install in place, discovering and comparing every framework-owned plugin path by content (sha256) rather than declared version, so new hook assets and drift that does not match any released version are repaired too; a path marked `ownership: project` (via `owner: project` frontmatter or a `copilot.lock.json` entry) is never touched; idempotent; writes/refreshes `copilot.lock.json` and merges tracking fields into `.codex-copilot.json`
- `scripts/verify-update-project.sh`: disposable-scratch-repo verification (fresh install, idempotence, stale-content repair, project-owned survival, setup-project.sh re-run), wired into `scripts/smoke-test.sh`

### Changed

- `scripts/setup-project.sh` no longer hard-refuses when the plugin/skill/QA-gate paths already exist; it delegates to `scripts/update-project.sh` to repair them in place and exits 0. `AGENTS.md`, `marketplace.json`, and install metadata are still never regenerated once present, but that is now a per-file skip rather than a whole-run abort.
- Updated the native-runtime boundary: Claude Code hook registration is still non-portable, while current Codex lifecycle hooks are used where their tested contracts match the intended behavior.
- Added the debugging-discipline and concise subagent-return rules to framework and generated project instructions.

### Fixed

- consumer repos frozen at an old plugin copy (labelled `0.6.1` or otherwise) had no in-place repair path; `update-project.sh` closes that gap
- plugin sync (base and org) compared files by content hash only, so a 755 source file (e.g. an org plugin's `scripts/*.py`, or the base plugin's `hooks/*.sh`) could land 644 in a project and stay that way forever -- a matching content hash reported the file "Unchanged" and the run "no changes needed", so the drift was permanently invisible to the updater. `sync_tree()` now compares mode alongside content; a mode-only mismatch is repaired and reported separately as "Mode repaired" (not folded into "Updated", since it is almost always a mechanical artifact of how the tree was moved, not a change to what the file says). `setup-project.sh`'s fresh-install `cp -R` (whose permission preservation is umask-sensitive) now runs a `normalize_tree_modes()` pass immediately after, sharing one `desired_mode()` implementation with `update-project.sh` via the new `scripts/lib/plugin_mode.py` rather than forking the rule.
- org-plugin auto-detection matched only a sibling directory literally named `codex-copilot-internal`, so it could never fire in the real pinned-mirror consumer path, where the sibling tier directory is named `codex-organization` (per `~/.config/copilot/copilot.layers.yml`'s tier id, not the repo name). Auto-detection now searches known sibling directory names by manifest instead.

## [0.6.1] - 2026-07-27

### Security

- prepared the first immutable foundation snapshot release signed by the
  dedicated ENAC release identity

## [0.6.0] - 2026-07-11

### Added

- upstream-aware Claude, `cc`, and `tc` parity freshness checks
- deterministic `cc eval` cases for protocol and specialist contracts
- catalog-derived generated workflow reference and drift check
- specialist-chain comparison protocol for recording A/B evidence without claiming unmeasured quality

### Changed

- adopted Claude Copilot `5.13.0`, `cc 1.7.0`, and `tc 1.3.0` capability intent
- made project setup preflight-only before mutation; `--force` no longer overwrites project-owned config
- required QA approval to come from an attached, evidence-bearing test work product rather than metadata alone

### Fixed

- closed the arbitrary `qaArtifact` metadata bypass in `copilot-gate.sh`
- prevented partial setup mutations when existing project wiring causes refusal

### Added

- standardized `docs/40-initiatives/NN-slug/` for initiative briefs, phases, decisions, validation evidence, and retrospectives linked to authoritative `tc` execution state
- added initiative indexes and templates to repository docs, shared Knowledge Copilot standards, and generated project scaffolding
- added a target-project `scripts/copilot-gate.sh` link to the shared QA gate
- added deterministic checks for numbered documentation, the archived legacy-path map, initiative scaffolding, local links, and generated setup output

### Changed

- reorganized documentation into numbered setup, user-guide, developer, architecture, reference, troubleshooting, appendix, and initiative sections
- reduced the root README to project purpose, audience, quick start, boundaries, and canonical documentation links
- clarified that machine-readable manifests own capability facts and that initiative Markdown complements rather than replaces `tc`
- reclassified hidden background workers as a non-goal instead of a future capability

## [0.5.0] - 2026-06-18

### Added

- adopted Claude Copilot `5.10.0` parity intent with Codex-native verification and observability contracts
- added artifact-bound QA gate support for `test-run`, `file-check`, `diff-check`, `screenshot-check`, `a11y-check`, and `design-fidelity-check`
- added schema-backed agent catalog metadata with routing edges and an explicit design chain
- added shared `scripts/lib/validation_result.py` for pass/warn/fail script reports
- added `writing-legal` pack metadata so the documented pack can be activated

### Changed

- updated `cc` baseline to `1.4.0` and documented `cc memory check`
- clarified that Claude lifecycle hooks are runtime hook surfaces, not the design-led product protocol
- tightened release fitness expectations for pack manifests and artifact-bound QA

## [0.4.1] - 2026-06-09

### Changed

- expanded README into a comprehensive project overview covering purpose, values, benefits, usage, specialists, quality gates, optional packs, and Codex-native boundaries
- added `docs/README.md` as the documentation index
- rewrote Getting Started, Install, and Usage guides with clearer setup, validation, Live Docs, QA gate, orchestration, and pack activation guidance
- updated version metadata across framework manifests and parity metadata

## [0.4.0] - 2026-06-09

### Added

- Claude Copilot `5.7.0` parity manifest and version metadata
- Live Docs guidance for installed third-party package APIs
- Codex-native QA gate convention with `tc` metadata, verdict work products, and `scripts/copilot-gate.sh`
- optional `business-creative` pack for `kc`, `cco`, `cw`, `cs`, and `cpa`
- stream validation utility for orchestration planning
- release fitness scripts for version, smoke, and parity checks
- `$setup` and `$setup-knowledge-sync` command-equivalent skills

### Changed

- deepened active specialist skills with success criteria, workflows, iteration loops, methodology, anti-generic rules, and routing contracts
- updated protocol routing to include infrastructure flow
- documented Codex-native substitutes for Claude hooks, named agents, and headless workers

## [0.3.0] - 2026-06-08

### Added

- direct software specialist skill names such as `$sd`, `$uxd`, `$uids`, `$uid`, `$ta`, `$me`, and `$qa`
- `$ind` industrial design specialist for physical, hardware, connected-product, and physical-digital work
- dormant capability pack convention for optional project-level domain skills
- `writing-legal` capability pack as the first dormant pack
- repository decision instruments in `$protocol` for `SOUL.md` and architecture guiding principles
- setup templates for `SOUL.md` and `docs/01-architecture/12-architecture-guiding-principles.md`

### Changed

- global plugin scope now focuses on design-led software creation specialists
- docs and generated project instructions now use direct specialist names instead of `agent-*` skill names
- experience workflows now route screen-changing work through service design, UX, UI design, UI implementation, architecture, engineering, and QA
- product language ownership now lives in `$uxd` and `$uids` for in-product labels, CTAs, empty states, errors, validation, and feedback
- `$qa` now verifies design intent, visual fidelity, responsive behavior, accessibility, product language, and decision-instrument alignment for product-facing work

### Removed

- globally active copywriting specialist in favor of optional domain-pack activation

## [0.2.0] - 2026-05-06

### Added

- `cc` CLI bridge for memory, skill discovery, and project config
- project bootstrap wiring for `.claude/cc`, `.claude/memory`, and `.claude/skills/codex-copilot`
- documentation for the new Memory and Skills Copilot CLI workflow
- public-facing documentation set for installation, usage, publishing, contribution, and security
- version metadata for public release
- MIT license for open-source publication

### Changed

- README expanded from internal summary to public project overview
- bootstrap installer and docs updated for machine-portable setup
- generated project files now avoid embedding absolute framework paths

### Removed

- personal contact metadata from shipped plugin manifest

## [0.1.0] - 2026-04-22

### Added

- initial Codex-native port of the Claude Copilot operating model
- protocol-first routing skill
- specialist skill set for architecture, implementation, QA, security, design, docs, ops, and copy
- project bootstrap installer with shared-framework linking
- Codex plugin packaging and local marketplace entry
