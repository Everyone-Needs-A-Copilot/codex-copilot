# Workflows

## Standard sequences

| Workflow | Sequence |
|----------|----------|
| bug | `qa -> me -> qa` |
| technical feature | `ta -> me -> qa` |
| infrastructure | `do -> me -> qa` |
| experience feature | `sd -> uxd -> uids -> uid -> ta -> me -> qa` |
| UI polish | `uids -> uid -> qa` |
| security-sensitive feature | `ta -> sec -> me -> qa` |
| knowledge setup | `kc` |
| creative branch | `cco -> cw` |
| business advisory | `cs` or `cpa` |

## Spawn guidance

- use `explorer` when the output is analysis, diagnosis, decomposition, or review
- use `worker` when the output is code
- use `default` when the work is cross-functional or design-heavy
- do not auto-spawn unless the user explicitly requested delegation or parallel work

## Prompt skeleton

For a spawned specialist:

```text
You are acting as codex-copilot specialist <id>.
Use the <skill-name> playbook.
Own only this scope: <scope>.
Return: <expected output>.
Do not touch files outside: <paths>.
```
