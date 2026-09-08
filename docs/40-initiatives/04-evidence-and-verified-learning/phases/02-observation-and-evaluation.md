# Observation and evaluation

TASK-13 and TASK-14 own implementation and verification; status lives in `tc`.

```bash
cc skill select "delivery evidence" --required qa --max-chars 12000 --json
cc doctor --runtime-details --json
cc doctor --exercise-runtime --json
cc eval adoption-freeze plan.json --output frozen.json
cc eval adoption-check frozen.json observations.json
```

Skill selection uses existing catalog precedence and signed Knowledge receipts.
Returned text has a SHA256 identity, selection reason, character/UTF-8 byte counts
and exclusions for budget/duplicate content. It does not claim token measurements
or actual runtime consumption. Persist the receipt once in `tc`, not on every turn.
Compare receipts to detect repeated loading; do not infer mandatory constraints
from a relevance score. Repository/system constraints still apply outside skills.

Doctor's existing JSON contract remains stable. The explicit runtime-details mode
uses a separate document so Control Tower can display it without recomputing truth.
An exercise result is recomputed, bounded and tied to current project files and
effective disable switches. Changed identity during the probe invalidates it.
Unknown trust and lifecycle dispatch stay unknown, even when direct probes pass.

For an outcome trial, freeze the same model, effort, runtime/version/configuration,
tool configuration, task inputs and rubric for both variants. Only the intended
framework/rule revision changes. Separate learning source identities from held-out
case sources. Fix task and replicate counts before running; reject changed inputs,
duplicate records, reused evidence, missing variants and invalid/baseline-failure
trials. Keep correctness, necessary clarification, abstention, misapplied rules,
human rework and context/call costs separate. `cc survival` is an edit proxy.

The initial policy asks for six distinct tasks and two repetitions per variant,
zero candidate correctness/clarification/abstention failures or unauthorized effects,
no increase in misapplied rules, at least 10% less reviewed human rework, and no more
than 10% added context characters or calls. These are a conservative pilot decision,
not statistical significance or a quality guarantee. No improvement retains the
baseline. Real results require actual reviewed task evidence; synthetic checks only
prove the policy mechanics. The benchmark's pilot handoff documents run selection.
