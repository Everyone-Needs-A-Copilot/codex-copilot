# Specialist-Chain Evaluation

Codex Copilot uses specialist lenses in the main session by default. That is an
honest Codex-native substitute for Claude's context-isolated agents, but it does
not prove that every stage earns its context cost.

Evaluate the chain with paired runs of the same frozen task and repository state:

1. Run once with a single generalist prompt and once through `$protocol`.
2. Do not let either run read the other's output.
3. Score both against the same acceptance criteria and evidence sources.
4. Copy `evals/specialist-chain/scorecard-template.json` for each variant.
5. Compare the completed scorecards:

```bash
python3 scripts/compare-specialist-chain.py \
  --generalist /path/generalist.json \
  --specialist /path/specialist.json \
  --json
```

Every score requires evidence. The comparator only aggregates recorded
observations; it does not run a model or claim that deterministic contract
checks measure output quality. Use several representative tasks before changing
the default workflow, and treat a result inside the minimum delta as inconclusive.
