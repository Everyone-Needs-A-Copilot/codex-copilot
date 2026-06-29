# AI Ecosystem Research — Methodology & Findings (for technical review)

**Status:** Research complete; no code changed. This is a reviewable record, not a directive.
**Date:** 2026-06-29
**Author:** Claude Code session (Opus 4.8), originating in the `voice-copilot` workspace.
**Companion (identical evidence, primary copy):** `claude-copilot/docs/70-reference/ai-ecosystem-research-methodology.md`
**Narrative / essay-oriented version:** `voice-copilot/thoughts/research/AI Ecosystem/` (5 topic docs).

---

## 0. Why this document exists, and why it lives here

The research originated in `voice-copilot` (a writing project) as feedstock for a thought
piece on "the idea of an AI ecosystem." The build-relevant conclusions concern the framework
(`claude-copilot`) and **this downstream port (`codex-copilot`)**, so the technical record is
placed in both repos where a developer would review and act on it.

`codex-copilot` is relevant because it **consumes the shared `cc`/`tc` binaries** and mirrors
the framework's intent via re-authored skills. Several findings (§3.1) concern *how* this port
relates to `claude-copilot` and were verified against this repo's own source. §7 is tailored
to what this repo would (and would not) inherit.

**The goal of this document is falsifiability.** Every factual claim should be independently
re-checkable from the repos; every recommendation traceable to the facts it rests on. Claims
that are judgment rather than fact are labelled as such.

---

## 1. The question investigated

The owner runs a multi-product "Copilot" ecosystem and described his mental model as four
layers — **Knowledge / Capabilities / Framework / Project** — plus two adjuncts (internal
hosting + secrets; external third-party systems). Three sub-questions:

1. **Comparison & gaps** — how does this model compare to 2025–2026 state-of-the-art agentic
   ecosystem architecture, and what is it missing?
2. **Measurement** — for any gap worth closing, how would you actually *measure* it at solo
   (single-operator) scale?
3. **Build locus & agent strategy** — if the gaps were closed, *which repos* would change?
   And: are specialized agents still the right approach given tool evolution?

---

## 2. Methodology

### 2.1 Approach — parallel sub-agent decomposition

Research was split across four independent sub-agents so each worked from a clean context
and could be cross-checked. Two rounds:

| Pass | Mandate | Method / tools | Output | Confidence tier |
|------|---------|----------------|--------|-----------------|
| **A — External benchmark** | How leaders decompose agentic ecosystems (2025–26); what a 4-layer model omits; good-for/not-good-for per element | Web research (WebSearch/WebFetch), ~15 sources, prioritising primary/practitioner sources | Layer-model union, ranked omissions, cutting-edge patterns | **2 (sourced)** |
| **B — Internal grounding** | Capture how the ecosystem is *documented* + the owner's vocabulary | Read `knowledge-copilot` `ECOSYSTEM.md`, product cards, the (empty) draft essay | Documented model + vocabulary + doc-vs-absent map | **1/2** |
| **C — Code-grounded verification** | Verify, by reading source, what each component *actually is* — and the Memory/Task mechanics | Repo reads of `claude-copilot`, `codex-copilot`, `cli-copilot`, `knowledge-copilot`; cited file:line | Corrected component map; Memory/Task mechanics | **1 (checkable)** |
| **D — Measurement research** | Solo-scale evals/observability/cost, mapped to this stack | Web research, 2025–26 tooling & eval practice | 3-domain measurement design + priority order | **2 (sourced)** |

Pass C deliberately **superseded** Pass B wherever they disagreed: docs were treated as
claims, source code as truth. The most consequential corrections (see §3) came from this.

### 2.2 Verification principles applied

- **Code over docs.** A documented behaviour was not accepted until confirmed in source;
  claims carry `file:line` so a reviewer can re-open them.
- **Trace to the consumer, not the producer.** For "which repo changes" (§4.2), the method
  was to follow each proposed change to where the code that *runs* it lives (`cc`, `tc`,
  hooks/gate, quality-gates), not where it is described.
- **Existing data is the contract.** Component counts/roles were taken from authoritative
  source (typer registrations, `manifest.json`, `VERSION.json`), not prose docs.
- **Corrections logged, not silently smoothed.** Where the initial (docs-based) read was
  wrong, the delta is recorded so the reasoning chain is auditable.

### 2.3 Confidence tiers (used throughout)

- **Tier 1 — High, checkable.** Code-grounded facts about this ecosystem; re-verify by
  reading the cited files.
- **Tier 2 — Medium, sourced.** External-field synthesis and measurement-tooling claims.
  Sources cited, but not independently re-derived from primary material — spot-check via §8.
- **Tier 3 — Judgment.** Recommendations (§4.2–4.4): reasoning from Tier 1+2; explicitly
  opinion, offered with derivation so it can be argued with.

### 2.4 Limitations (read before trusting)

- **No code was executed or tested.** All mechanics in §3 were derived by *reading* source.
- **The external benchmark (Pass A/D) is single-pass synthesis**, not adversarially
  re-verified. Any pricing/limit/tool-feature claim is time-sensitive and second-hand.
- **Recall bias.** Session memory referenced a *legacy* system; caught by Pass C (§3.2) but a
  reminder that prior-context claims need code confirmation.
- **Scope.** "Solo operator" framing assumed; "overkill" judgments are scale-dependent.

---

## 3. Verified facts (Tier 1 — re-checkable)

A reviewer can confirm each directly. Suggested checks in `> blockquotes`.

### 3.1 Component map (corrected) — Codex-relevant items emphasised

- **Codex Copilot = hand-maintained Codex-native port, NOT an auto-mirror.** This repo shares
  only the `cc`/`tc` binaries (pinned in `VERSION.json`, sourced from Claude Copilot's
  `tools/cc` + `tools/tc`); the specialist roster/routing are **re-authored** as `SKILL.md`
  files under `plugins/`, with routing in `agent-catalog.json`. **Runtime hooks are NOT
  implemented** here — substituted by `scripts/copilot-gate.sh` + parity tests. Parity is a
  **manual checklist** (`parity/claude-baseline.json`, a single hand-captured snapshot); there
  is **no generation/sync script** in either direction — `tests/test_mirror_parity.py` only
  asserts this repo's internal self-consistency.
  > Check: `cat VERSION.json` (cc/tc pins + sources); `ls parity/ plugins/`; read `tests/test_mirror_parity.py`.

- **Claude Copilot = markdown agents + hook-enforced protocol + `cc`/`tc` CLIs.** **15
  framework agents + `kc`** in its `.claude/agents/manifest.json` (not the README's "7").
  Hook enforcement from the April-2026 restructure after a measured 6% delegation rate.

- **CLI Copilot = standalone `copilot` CLI, 22 service groups, zero coupling to memory/task.**
  HTTP client to hosted products, not a wrapper of `cc`/`tc`.

- **Knowledge Copilot = plain-markdown vault, not a binary.** Boundary doc + One-Direction
  Principle at `00-best-practices/04-knowledge-vs-capability-boundary.md`.

### 3.2 Memory & Task mechanics — the largest correction

**The initial read (legacy `copilot-memory` MCP, `WORKSPACE_ID` scope, `initiative_*` tools)
was WRONG. That system was removed in the April-2026 restructure.** Corrected, code-grounded:

- **Memory = `cc memory`.** UUID-named **markdown files are the source of truth**, under
  `<git-root>/.claude/memory/entries/` (project) or `~/.claude/memory/entries/` (global) —
  **scope is project-vs-global, not `WORKSPACE_ID`**. SQLite FTS5 is a disposable, gitignored
  cache. Types: `decision | context | lesson | reference | person`. No auto-expiry; staleness
  *detected* via `cc memory check`.
- **Task = `tc`** over `.copilot/tasks.db` (per-project, directory-scoped):
  PRD → stream → task (+ DAG) → work_product; WPs > 8 KB externalize to `.copilot/wp/`.
  **Initiative/progress state lives here now, not in memory.**
- **`initiative_*` MCP tools no longer exist.** Any doc/instruction calling `initiative_update`
  is stale. (Codex-relevant: this repo substitutes hooks with `tc` metadata + `copilot-gate.sh`,
  so it relies on `tc` for exactly this state.)
  > Check (from a clone of claude-copilot): `grep -n "initiative" CHANGELOG.md`; this repo: `grep -rn "initiative_update" .`

---

## 4. Conclusions and their derivation

Each conclusion states: **the claim → what it's derived from → how to falsify it.**

### 4.1 The Loop (Tier 3 — conceptual model)

- **Claim:** the four-element model names the system *at rest* but omits the *runtime +
  learning* dimension the field models as **RUN → OBSERVE → JUDGE → CONSOLIDATE.** The
  ecosystem already implements RUN (Task), cross-session recall (Memory), partial OBSERVE
  (`cc usage`, `agent_log`); it lacks **JUDGE** (no output-quality evals) and a systematic
  **CONSOLIDATE** edge (no path promoting a durable `cc memory` lesson into the vault).
- **Derived from:** §3 + Pass A (reference architectures treat memory/eval/feedback as
  first-class peers).
- **Falsify by:** showing an existing eval surface, or an automated memory→knowledge
  promotion. (One-Direction Principle forbids a *sync engine*; CONSOLIDATE is expected to be
  human-approved promotion, not automation.)

### 4.2 Build locus — which repo changes (Tier 1 reasoning, Tier 3 recommendation)

| Repo | Changes? | Why (traced) |
|------|----------|--------------|
| **claude-copilot** | **Primary** | Owns `cc`, `tc`, hooks, `quality-gates.json`. All three measurement moves (§4.3) land here. |
| **codex-copilot** | **Inherit + hand-port** | Shares `cc`/`tc` → budget cap inherited free. No runtime hooks → trace + eval-gate need a Codex-side equivalent via `copilot-gate.sh`/parity. |
| **cli-copilot** | **No** | Zero coupling to memory/task and not the agent dispatcher. |
| **knowledge-copilot** | **No code** | Only a CONSOLIDATE *ritual* + docs; sync engine forbidden. |

- **Eval-cases caveat:** machinery is framework-level (`claude-copilot`); golden-set *cases*
  live beside each agent — for this repo, beside the re-authored `SKILL.md` agents under `plugins/`.
- **Falsify by:** finding `cli-copilot` spawns `claude -p` (pulls it into scope), or that this
  repo gains runtime hooks (removes the hand-port).

### 4.3 Measurement architecture (Tier 2 design / Tier 3 priority)

Priority order (highest leverage-to-effort first); full detail + sources in
`voice-copilot/thoughts/research/AI Ecosystem/03-measuring-it.md`:

1. **Cost cap** — per-task `--max-budget-usd` on non-interactive dispatch; actual cost logged.
2. **Quality gate** — 10-case golden set per agent (deterministic + LLM-as-judge, binary,
   CoT-before-verdict, **judged by a different model than under test**), via `promptfoo`,
   wired into the gate. *Answers "did a framework change degrade behaviour."*
3. **Trace** — `PostToolUse`/`Stop`-equivalent hook appends one JSONL line per tool call /
   handoff. **In this repo there is no runtime-hook layer**, so the trace must be emitted from
   the `copilot-gate.sh` / `tc`-metadata path — the most Codex-specific piece of work.
- **Deferred (Tier 3, overkill at solo scale):** Langfuse self-hosted, Braintrust/LangSmith,
  annotation queues, OTEL, online production monitoring.

### 4.4 Specialized agents — still warranted? (Tier 3)

- **Claim:** the decision is per-agent, on two tests — **(1) context isolation** (large
  intermediate work / parallelism / clean window) **or (2) distinct tool/permission scope.**
  Yes to either → keep as a sub-agent (here, a `SKILL.md` agent). No to both → deliver as an
  on-demand skill/command, not a resident persona. The owner's writing/lens agents pass;
  the 6-stage sequential design chain (`sd→uxd→uids→uid→ta→me`) is the over-decomposition
  candidate at solo scale.
- **Derived from:** Anthropic context-engineering guidance (isolation is the durable
  rationale), the framework's 6% delegation diagnostic (weak link was *orchestration*), and
  the coexistence of skills with agents.
- **Decisive test is empirical:** once §4.3 move 2 exists, A/B the specialized agent vs. a
  single generalist prompt on the same golden set. **Let the eval adjudicate per agent.**

---

## 5. How a reviewer can verify

- **Tier-1 facts (§3):** run the inline `> Check:` commands.
- **Tier-2 claims (§4.1, §4.3):** spot-check §8 sources, especially time-sensitive figures.
- **Tier-3 recommendations (§4.2–4.4):** falsification hooks stated inline; the agent question
  (§4.4) is settled by the golden-set A/B, not by argument.

---

## 6. Open questions / what this research did NOT establish

- Whether the 6-stage design chain underperforms a leaner one — **untested**; needs the
  §4.3-move-2 experiment.
- Real runtime behaviour of `cc`/`tc` (read, not executed).
- Whether the parity ritual would correctly propagate a Codex-side trace/eval equivalent — the
  manual checklist has no automated guard for new cross-cutting concerns.
- The external-field synthesis was not adversarially verified.

---

## 7. Implications for THIS repo (`codex-copilot`)

This repo is **inherit + hand-port**, not a primary build site:

- **Inherited for free:** any `cc`/`tc` change (e.g. a per-task budget field + `--max-budget-usd`)
  arrives via the shared binaries this repo already pins — no Codex code needed beyond bumping
  the pin and a parity-snapshot refresh.
- **Requires hand-port:** the **trace emitter and the eval gate**, because this repo has **no
  runtime hooks**. They must be expressed through `scripts/copilot-gate.sh` + `tc` task
  metadata, then captured in `parity/claude-baseline.json` and `tests/test_mirror_parity.py`.
  This is the single most Codex-specific piece of any future build.
- **Golden-set cases** for this repo's agents live beside the `SKILL.md` definitions under
  `plugins/`, not in `claude-copilot`.
- **Parity risk to flag:** the manual parity checklist has no automated detector for a *new*
  cross-cutting capability (like tracing). If `claude-copilot` adds one, nothing here will
  fail a test to remind the maintainer to port it — it must be added to the checklist by hand.

The primary copy, framed for the framework, is in
`claude-copilot/docs/70-reference/ai-ecosystem-research-methodology.md` §7.

---

## 8. Provenance & sources

**Method:** 4 parallel Claude Code sub-agents (2 web-research, 2 repo-read), 2026-06-29.
**Repo evidence:** `claude-copilot`, `codex-copilot`, `cli-copilot`, `knowledge-copilot`
working trees as of 2026-06-29 (paths/line refs are point-in-time).

**External sources (Tier 2 — spot-check before relying):**
Anthropic [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) ·
Anthropic [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) ·
[Bain — Three Layers of an Agentic AI Platform](https://www.bain.com/insights/the-three-layers-of-an-agentic-ai-platform/) ·
[Anatomy of Agentic Memory (arXiv 2602.19320)](https://arxiv.org/html/2602.19320v1) ·
[Interoperability protocols survey (arXiv 2505.02279)](https://arxiv.org/html/2505.02279v1) ·
[Confident AI — agent eval guide](https://www.confident-ai.com/blog/llm-agent-evaluation-complete-guide) ·
[Evidently — LLM-as-judge](https://www.evidentlyai.com/llm-guide/llm-as-a-judge) ·
[promptfoo](https://github.com/promptfoo/promptfoo) · [promptfoo CI/CD](https://www.promptfoo.dev/docs/integrations/ci-cd/) ·
[Langfuse — observability](https://langfuse.com/docs/observability/overview) ·
[Claude Code — costs docs](https://code.claude.com/docs/en/costs) · [ccusage](https://ccusage.com/guide/) ·
[Self-preference bias (arXiv 2410.21819)](https://arxiv.org/pdf/2410.21819).
Full annotated list: `voice-copilot/thoughts/research/AI Ecosystem/04-external-benchmark.md`.
