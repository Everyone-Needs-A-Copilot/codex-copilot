# Reviewed foundation source adoption: upstream 328ec6a to b064e27

Scope: Claude Copilot upstream commits ff12e44 "feat: add bounded foundation workflow and shared status (#82)" and 062cff0 "Repair CI hook fixtures and enforce green delivery (#84)", including "fix(context): compress instruction contracts within hard budgets". Source compatibility is Claude `5.15.3` / `cc 2.13.2` / `tc 2.0.0`. This record supports the Codex `0.8.0` release preparation; it is not itself a signed release, tag or consumer rollout.

## Exact review

The content baseline moves from upstream `328ec6a` to `b064e271a313b6ae81886dfca99dd470e70098be`. The reviewed upstream delta covers `.claude/agents/{cco,cpa,cs,cw,do,doc,ind,kc,me,qa,sd,sec,ta,uid,uids,uxd}.md`, `.claude/commands/protocol.md` and `.claude/commands/reflect.md`. Each file was classified as pure wording compression, a semantic change already present in the Codex mirror, or a semantic change missing from Codex. The baseline update used the normal port guard (a real port is present in the working tree); no no-port attestation was used.

| Upstream delta | Disposition |
|---|---|
| `cco`, `cpa`, `cs`, `cw`, `do`, `doc`, `ind`, `kc`, `sd`, `sec`, `uid`, `uids`, `uxd`: identical Output Contract and Runtime Precedence rewrite | Pure compression; same rules in fewer words (safety, non-negotiable framework rules, harness, user, Constitution, CLAUDE.md ordering, content-over-form exceptions and debug-spiral breaker unchanged). Codex already carries the output contract in `AGENTS.md` and its skills. Not ported. |
| `ta`: terser success criteria, workflow, priorities, stream planning, optional context, design and evidence sections | Pure compression; knowledge-repo ladder, taste-rule handling, ADR/fitness-function rules, test-requirement rules and re-planning on invalidated assumptions are unchanged. Not ported. |
| `me`, `qa`: Proportional Verification and "Fixed finish line" (fixed deliverable and criteria, one batch acceptance pass, stop after current source-bound QA approval, incomplete on missing evidence or exhausted cap) | Already present in the Codex mirror: `specialist-agents/references/verification-policy.md`, loaded by `skills/me` and `skills/qa` (ported in fb4000a). Remaining wording is compression. |
| `me`: new "Always: follow fixed acceptance scope and Proportional Verification" core behavior | Ported: `skills/me/SKILL.md` Operating Lens now states it, including that a new requirement needs an explicit scope decision. |
| `qa`: new "Always: verify fixed acceptance scope" and "Never: approve missing required evidence or expand completed work into unrelated repairs" | Ported: `skills/qa/SKILL.md` Operating Lens and Anti-Generic Rules. |
| `.claude/commands/protocol.md`: Fixed Delivery Boundary | Already identical in `skills/protocol/SKILL.md`. Project-protocol precedence, token-efficiency and optional-context edits are compression or Claude-only command-resolution syntax; not ported. |
| `.claude/commands/reflect.md`: shorter overview, dashboard template and edge-case text; memory-type table removed | Pure compression of Claude-specific command text; the Codex reflect skill's behavior is unchanged. Not ported. |

## Boundaries

Only two small behavioral lines were missing from the Codex mirror, and both are scope-discipline rules that the shared verification policy already enforces; the port makes the specialist skills state them directly. Version fields, changelog, manifests, `parity/claude-baseline.json` and tests are release-preparation edits made separately and are not changed by this adoption. A green content check alone does not establish semantic parity or a release-ready ecosystem; future instruction drift must be reviewed again.
