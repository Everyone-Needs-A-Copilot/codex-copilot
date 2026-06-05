# Publishing Notes

## Public Release Checklist

- remove machine-specific absolute paths from shipped docs and templates
- remove personal names and emails from plugin metadata unless intentionally public
- confirm repository URLs point to the organization-owned repo
- review generated files from `setup-project.sh`
- validate the bootstrap flow from a clean clone
- run `python3 -m unittest discover -s tests -v`
- confirm [capabilities.md](./capabilities.md) matches implemented skills and workflow boundaries

## Repo Ownership

This repository is intended to live under:

- `Everyone-Needs-A-Copilot/codex-copilot`

## Pre-Publish Verification

Recommended searches:

```bash
rg -n '/Users/|/Volumes/|@[A-Za-z0-9._%+-]+\\.[A-Za-z]{2,}|[A-Z][a-z]+ [A-Z][a-z]+' .
```

Then manually inspect any hits to distinguish legitimate public org metadata from accidental personal references.
