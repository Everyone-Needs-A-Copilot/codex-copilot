# Extensions And Packs

Codex Copilot keeps optional capabilities dormant until a project activates them.

## Pack Model

Packs live under `packs/<name>/` and include:

- `pack.json`
- `skills/<skill>/SKILL.md`

The baseline optional parity pack is `packs/business-creative/`, which contains:

- `kc`
- `cco`
- `cw`
- `cs`
- `cpa`

## Activation

Activate a pack in a project:

```bash
scripts/activate-pack.py --project /path/to/project --pack business-creative
```

The script refuses to replace existing skill links or marketplace files.

## Resolution

Use this order when explaining context:

1. project-local skills and knowledge
2. global `cc` knowledge and skills
3. activated packs
4. base Codex Copilot plugin skills

Codex cannot dynamically merge prompt sections the same way Claude extension docs describe. Pack activation is explicit and file-based.
