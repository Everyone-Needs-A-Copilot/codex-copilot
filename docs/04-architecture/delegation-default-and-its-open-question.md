# The delegation default, and the one question it leaves open

## The rule stands

Codex Copilot fires zero subagents by default. `spawn_agent` is used only when the user explicitly asks for delegation or parallel work. Three skill files implement it — `protocol` (twice), `specialist-agents` — and `SOUL.md` guards it as **The Hidden Worker**, one of five ratified anti-patterns, with a line in the sand: *parallel work is user-approved, scope-validated `spawn_agent` delegation only, with stream/file-ownership validation. No silent background workers.*

This is design, not omission. It was ratified on 2026-06-28 and it is not changing here.

## A recommendation that was wrong, and is withdrawn

A benchmark comparing this framework against Claude Copilot observed that Codex fired zero subagents where Claude fired several, and recommended flipping the default to make Codex delegate.

That recommendation was wrong on two counts, and both are worth naming rather than quietly dropping.

It treated a difference as a deficiency. Zero subagents is what "the user approves parallel work" produces when the user did not ask for parallel work. The measurement was of the rule functioning, read as the rule failing.

And it proposed overriding a ratified decision on the strength of a comparison nobody had run. Nothing in that benchmark compared inline specialist lensing against delegated specialist lensing on identical work. It compared two frameworks that differ in many ways at once and attributed the difference to the one thing it had noticed.

## The question that is genuinely open

**Does delegating the specialist lenses produce better work than applying them inline?**

Nobody knows. Arguments exist in both directions and neither has evidence:

- **For delegation.** A separate context per lens keeps each specialist's reasoning uncontaminated by the others', which is the entire premise of a specialist roster.
- **For inline.** A single context sees every lens's output as it forms, so a later lens can revise an earlier one without a handoff document — and the Claude-side benchmark's own worst finding was that its delegation chain resolved ambiguities internally and asked the user nothing, where the arm with no chain at all asked and got a materially better answer.

The second point deserves weight. The framework that delegated asked zero clarifying questions on a brief containing a real contradiction; the one that did not delegate asked three. That is not proof inline is better, but it is a reason not to assume delegation is.

## How it is being answered

`copilot-bench` carries an arm, `codex-copilot-delegating`, paired against `codex-copilot` on identical work. It changes nothing in this framework. It supplies the one input the rule already accepts — an explicit request for delegation, in the prompt, where a user would put it:

```yaml
- id: codex-copilot-delegating
  harness: codex
  layer: L5
  prompt_suffix: |
    I am explicitly asking for delegation on this work: use `spawn_agent` to
    dispatch each specialist lens as its own task rather than applying the lenses
    inline yourself. …
```

The prompt suffix is recorded verbatim in every trial manifest, so no reader has to wonder whether the two arms saw the same brief.

What the comparison decides:

- **Inline wins** → the ratified rule has evidence behind it rather than only principle, which is a strictly better position for it to be in.
- **Delegation wins** → that is a finding to take to `SOUL.md` through the process a ratified decision deserves. It is not a default a benchmark gets to change on its own.

Either outcome is worth having. Neither is worth pre-empting.
