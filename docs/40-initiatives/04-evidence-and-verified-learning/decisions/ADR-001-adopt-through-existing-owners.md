# ADR-001: Adopt through existing owners

## Context

The reviewed repositories provide useful mechanisms but also automatic publication,
unbounded context growth and evidence/authority conflation that conflict with CSE.
The owner authorized implementing the recommendation after reviewing WP-14.

## Decision

Keep native handoffs in each framework, personal content in the existing private
taste corpus, and shared retrieval/runtime/evaluation reporting in `cc`. Preserve
`tc` QA as authoritative. Use local selected receipts and an opt-in frozen pilot;
no transcript observer, inference daemon or automatic policy promotion is added.
Reuse canonical evaluation hashes, catalog resolution and signed receipts.

## Consequences

Existing CLI defaults and doctor JSON consumers remain compatible. New commands
are explicit. Old taste candidates remain inspectable but need verified receipts
and recorded owner approval before promotion. Runtime diagnostics disclose their
scope and leave unobserved trust/dispatch unknown. The base remains generic.

## Alternatives rejected

Vendoring third-party skills, a second memory store, a new model runner, silently
mining histories, promoting inferred rules from frequency alone, mandatory video,
blanket Git/worktree actions and a speculative Greptile adapter add unjustified
scope or authority. Shared-operation extraction stays situational.

unknowns: net benefit on real work and runtime-origin trust/dispatch evidence remain unmeasured.
