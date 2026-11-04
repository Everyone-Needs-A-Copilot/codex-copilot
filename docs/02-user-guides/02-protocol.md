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

- reads `SOUL.md` before substantial product-facing work when present
- reads `docs/01-architecture/12-architecture-guiding-principles.md` before substantial durable technical work when present
- classifies the request
- chooses the workflow
- applies the right specialist thinking before implementation
- uses `tc` for substantial work
- uses `docs/40-initiatives/NN-slug/` for formal multi-phase initiative knowledge while keeping live execution state in `tc`
- uses Live Docs before third-party API planning or implementation
- records QA-required implementation work through the Codex QA gate convention
- continuously dispatches useful independent scopes through `$launcher` after plan approval, within native capacity and resource permits
- integrates contributions, binds independent QA to current source, and prepares exact cleanup automatically

## Default workflows

- defect: `qa -> me -> qa`
- technical: `ta -> me -> qa`
- experience: `sd -> uxd -> uids -> uid -> ta -> me -> qa`
- physical-digital: `ind -> sd -> uxd -> uids -> uid -> ta -> me -> qa`
- UI polish: `uids -> uid -> qa`
- security-sensitive: `ta -> sec -> me -> qa`
- infrastructure: `do -> me -> qa`

For user-facing work that does not materially change screens, components, or interface states, `$protocol` may explicitly skip `$uid` and state why.

## Important boundary

This is a Codex-native protocol skill, not a platform slash command.

The behavior is the same goal as `/protocol`, but expressed through:

- a native Codex skill
- specialist skills
- visible native `spawn_agent` for useful independent approved work by default
- explicit `tc` state and inspection scripts instead of hidden Claude hooks
