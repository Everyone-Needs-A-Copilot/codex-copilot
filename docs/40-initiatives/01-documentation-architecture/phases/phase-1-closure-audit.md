# Phase 1 Closure Audit

## Outcome

The documentation system now has numbered setup, user-guide, developer, architecture, reference, troubleshooting, appendix, initiative, and archive sections. Former public paths are consolidated in `docs/90-archive/redirects/`, leaving only `README.md` at the documentation root.

`docs/40-initiatives/` is defined across the repository, shared Knowledge Copilot standard, Codex Copilot project instructions, protocol behavior, Task Copilot boundary, and generated project scaffolding.

## Validation Evidence

| Check | Result |
| --- | --- |
| `python3 -m unittest discover -s tests -v` | 28 tests passed |
| `scripts/check-versions.sh` | version and parity checks passed |
| `scripts/smoke-test.sh` | smoke tests passed |
| `bash -n scripts/setup-project.sh scripts/copilot-gate.sh scripts/check-versions.sh scripts/smoke-test.sh` | shell syntax passed |
| `git diff --check` | no whitespace errors |
| `$HOME/.local/bin/cc memory check --json` | pass, score 100, no flagged entries |

The test suite creates temporary projects to verify both fresh initiative scaffolding and preservation of existing `docs/40-initiatives/` content. It also verifies that `scripts/copilot-gate.sh` resolves to the shared executable gate.

## Acceptance Review

- documentation is organized by reader job and content type
- root README is limited to promise, audience, quick start, boundaries, and links
- machine-readable manifests remain authoritative for capability facts
- initiative Markdown and `tc` ownership are explicitly separated
- shared standards and the foundational product card reflect the new convention
- hidden workers remain a non-goal rather than a roadmap claim

## Residual Risk

Existing projects are not mutated automatically. They must adopt `docs/40-initiatives/` and the QA-gate link through a reviewed update so project-owned documentation and scripts are never overwritten.
