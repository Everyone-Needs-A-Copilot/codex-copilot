# Initial validation and limits

This is the 2026-09-07 mechanism/activation record. [Shared gap closure](../../05-design-quality/phases/03-shared-gap-closure.md)
records the later cc/tc upgrade and verified native dispatch; versions and open
holds below describe the original run, not the current installation.

Implementation mechanism checks completed on 7 September 2026 under PRD-9 /
TASK-11–15. Architecture WP-16, security WP-17 and implementation WP-18–21 record
the choices and changes; task-bound QA work products remain authoritative in `tc`.

## Verified mechanisms

- Forty isolated acceptance checks exercised receipt integrity and independent
  sessions, approval/conflict gates, concurrent duplicate proposals, safe scalar
  persistence, retirement, budget/duplicate context behavior, direct runtime probes,
  disabled controls, frozen input/rubric integrity and conservative pilot decisions.
- Codex smoke, generated routing, version consistency and upstream content parity
  checks completed successfully. The content baseline changed only for the four
  native Claude playbooks whose intent was ported to Codex.
- The selected shared `cc` regression run reported 399 successes and the API run
  23. No test files changed during this task. Claude already had a modified
  `tests/hooks/test-pretool-check.sh`, so these observations are not a verified
  whole-repository test-suite claim.
- The active local `cc` entry point reports 2.12.15. The standard installer was
  staged and verified before entry-point activation. Existing global Claude
  ta/me/qa and reflect files received only the adopted sections, with backups.
- The personal taste corpus remains empty; all behavioral checks used disposable
  synthetic sources. No transcripts were mined and no real preference was promoted.

## Reviewable evidence

The local export directory `.copilot/adoption/` contains `validation.json`,
`source-manifest.json`, acceptance records, full selected-run/smoke logs, runtime
reports, CLI/playbook activation receipts and `backups/`. These exports are linked
from task-bound QA work products; they are not a competing task board.

## Remaining empirical work

The shared pilot policy and existing-benchmark handoff are installed. Live paired
model trials and real owner review have not been collected; net effectiveness
therefore remains unmeasured. The pilot must include a genuine clarification case
before making claims about that behavior. Keep mandatory correctness/judgment gates,
freeze inputs before learning, and retain baseline behavior without a positive result.

Direct native hook diagnostics are not runtime-origin lifecycle evidence. The
report deliberately leaves actual runtime trust/dispatch unknown. Existing consuming
project snapshots were preserved; this work updated authoritative framework sources,
active local cc and installed global Claude playbooks, without mass-rewriting dirty
project snapshots or publishing a release.
