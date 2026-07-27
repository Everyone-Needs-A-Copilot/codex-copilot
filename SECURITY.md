# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.x.x | Yes |

## Reporting a Vulnerability

Do not open a public issue for a security vulnerability.

Report vulnerabilities through GitHub Security Advisories for this repository:

- `https://github.com/Everyone-Needs-A-Copilot/codex-copilot/security/advisories/new`

Include:

- a clear description of the issue
- impact and affected surfaces
- steps to reproduce
- any mitigation or patch suggestion

## Security Concerns Relevant to This Repo

- generated project instructions can unintentionally leak local machine paths if portability is not maintained
- plugin metadata should not contain personal names, emails, or workstation-specific references
- examples must avoid credentials, internal URLs, and private infrastructure details

## Best Practices for Contributors

- keep examples generic and portable
- use environment variables or documented placeholders instead of real credentials
- avoid committing local machine metadata
- review generated output, not just source files, before publishing changes
