# Protocol

`$protocol` is the Codex Copilot equivalent of Claude Copilot's `/protocol` command.

## How to use it

Start new work with:

```text
Use $protocol to route this task through the right codex-copilot specialists.
```

You can also include the task inline:

```text
Use $protocol to add a new onboarding flow.
Use $protocol to fix the login regression.
Use $protocol to refactor the auth service.
```

## Behavior

`$protocol`:

- classifies the request
- chooses the workflow
- applies the right specialist thinking before implementation
- uses `tc` for substantial work
- hands off to `$agent-launcher` only when delegated subagents are explicitly desired

## Default workflows

- defect: `qa -> me -> qa`
- technical: `ta -> me -> qa`
- infrastructure: `do -> me -> qa`
- experience: `sd -> uxd -> uids -> uid -> ta -> me -> qa`
- UI polish: `uids -> uid -> qa`
- security-sensitive: `ta -> sec -> me -> qa`
- knowledge: `kc`
- creative branch: `cco -> cw`
- business advisory: `cs` or `cpa`

## Important boundary

This is a Codex-native protocol skill, not a platform slash command.

The behavior is the same goal as `/protocol`, but expressed through:

- a native Codex skill
- specialist skills
- native `spawn_agent` when explicitly requested

Optional experience branches mirror Claude Copilot:

- insert `ind` before `uxd` when product essentialism or affordances need review
- insert `cco -> cw` after `sd` when brand direction or messaging shapes the experience
