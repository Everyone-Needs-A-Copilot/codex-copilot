# Contributing to codex-copilot

## Principles

Contributions should preserve three constraints:

- stay native to Codex
- keep the framework portable across machines and projects
- prefer explicit workflow discipline over clever hidden automation

## Development Setup

1. Clone the repository.
2. Review [README.md](./README.md), [Architecture](./docs/04-architecture/00-overview.md), and [AGENTS.md](./AGENTS.md).
3. Use the installer against a throwaway project to validate bootstrap changes:

```bash
./scripts/setup-project.sh \
  --project /tmp/codex-copilot-smoke \
  --name "smoke-test" \
  --description "smoke test" \
  --stack "shell" \
  --no-tc-init
```

## Contribution Areas

- documentation and onboarding
- installer portability and project bootstrap behavior
- skill quality and routing behavior
- plugin metadata and packaging
- safety checks against machine-specific or personal references

## Standards

### Documentation

- keep examples machine-portable
- do not embed personal names, emails, or local filesystem paths unless they are explicit placeholders
- explain Codex-specific constraints clearly rather than implying unsupported features

### Scripts

- use portable path resolution
- fail clearly on missing prerequisites
- prefer relative links in generated project files
- avoid destructive behavior unless explicitly requested

### Skills and Instructions

- keep specialist roles generic
- avoid company-specific policy unless clearly framed as an example
- align docs with actual Codex behavior

## Pull Requests

Before opening a PR:

1. Run a repo-wide search for machine-specific paths and personal references.
2. Validate the bootstrap flow on a throwaway project.
3. Run `python3 -m unittest discover -s tests -v`.
4. Review generated `AGENTS.md`, `.codex-copilot.json`, `.claude/cc/config.json`, and `.claude/skills/codex-copilot`.
5. Update docs and the [Capability Matrix](./docs/05-reference/01-capability-matrix.md) when behavior changes.

## Security

Do not commit:

- tokens, API keys, or secrets
- private config files with credentials
- personal machine paths in shipped docs or templates
- local metadata that identifies a contributor’s workstation

Security issues should be reported per [SECURITY.md](./SECURITY.md).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
