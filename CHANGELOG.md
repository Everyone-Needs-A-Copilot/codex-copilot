# Changelog

All notable changes to codex-copilot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
