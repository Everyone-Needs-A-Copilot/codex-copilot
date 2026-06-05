---
name: extensions
description: Use when you need the Codex Copilot equivalent of Claude Copilot /extensions: inspect knowledge repositories, extension status, active skills, and project/global/base resolution.
---

# Extensions

Inspect knowledge and extension status.

## Workflow

1. Check `cc config get paths.knowledge_repo`.
2. Inspect project and global knowledge manifests if configured.
3. Run `cc skill list --scope all` when available.
4. Explain resolution order: project -> global -> base.
5. Recommend setup or repair steps without deleting or replacing existing knowledge.

## Output

- knowledge repository status
- active skills summary
- extension resolution notes
- safe next steps

