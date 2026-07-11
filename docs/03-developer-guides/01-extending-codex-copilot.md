# Extending Codex Copilot

## Choose The Correct Surface

| Change | Canonical surface |
| --- | --- |
| specialist behavior | `plugins/codex-copilot/skills/<name>/SKILL.md` |
| active roster or routing | `plugins/codex-copilot/agent-catalog.json` |
| optional domain capability | `packs/<pack>/` |
| target-project scaffolding | `scripts/setup-project.sh` and `templates/` |
| parity adoption | `parity/claude-baseline.json` and `VERSION.json` |
| task or memory engine behavior | shared `tc` or `cc` source, not this repository |

## Extension Rules

1. Start with `$protocol` and the appropriate specialist.
2. Create `tc` context for substantial work.
3. Keep optional domain capabilities dormant in packs.
4. Update the machine-readable catalog before prose reference pages.
5. Add or update tests for behavior and compatibility contracts.
6. Route implementation through `$qa` with an evidence artifact.

Do not reproduce Claude-only syntax or lifecycle behavior. Translate the intent into a real Codex primitive or state the limitation.

## Related Guides

- [Capability Packs](../02-user-guides/06-capability-packs.md)
- [Architecture](../04-architecture/00-overview.md)
- [Capability Matrix](../05-reference/01-capability-matrix.md)
- [Release And Publishing](./02-release-and-publishing.md)
