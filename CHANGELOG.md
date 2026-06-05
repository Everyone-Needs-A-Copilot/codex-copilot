# Changelog

All notable changes to codex-copilot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
