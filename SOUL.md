# Codex Copilot — SOUL

> **The decision instrument. When in doubt, consult this file.**
> This is not a vision statement or a mission poster. It is the tool you use to
> decide whether a proposed feature *belongs* in this product — by staying true
> to its purpose.
>
> **How to use it:** Run any feature, request, or "wouldn't it be cool if…"
> through **Section 5: Feature Filter**. Pass the gates in order. If a feature
> can't survive the filter in under a minute, the answer is **no**.
>
> **It is living.** It changes only when real evidence says the product changed —
> and every change is logged in **Section 10: Evolution**.

> **STATUS: DRAFT v0.1 — retrofit from documentation; pending owner ratification.** (2026-06-28)
<!-- This file was retrofitted from the repo's docs (README, AGENTS.md, docs/, parity/,
     VERSION.json) and code surface. Inferences are marked INFERRED; CONFIRM. Owner-only
     calls (anti-pattern lines in the sand, founding decisions, priority order) are left
     as TODO: owner and must NOT be treated as settled until ratified. -->

---

## 1. The Job

**When** a developer runs Codex on serious software work,
**they want to** get disciplined, lead-engineer behavior with specialist lenses, durable task memory, and explicit verification,
**so they can** trust the output without re-checking it by hand — and without the framework pretending Codex has features it doesn't.

**The struggling moment:**
AI coding sessions fail in predictable ways: they jump from vague intent straight to code, forget prior decisions, skip QA or treat a green build as verification, code against stale third-party API knowledge, bury long plans in chat history, and blur architecture, UX, implementation, and testing into one generic response. A Codex user who has seen Claude Copilot's discipline wants the same rigor — but every "port" they reach for either fakes Claude-only runtime features (and breaks), or abandons the discipline entirely. The friction is being forced to choose between *discipline* and *honesty about the runtime you're actually on*.

**Who this serves:**

| User | What they need |
|------|---------------|
| **The Codex developer** (primary) | A repeatable specialist workflow, durable `tc`/`cc` state, and a QA gate that actually holds — inside Codex, with no fake Claude primitives. |
| **The team / reviewer** | Trust that a "done" claim carries evidence, that plans survived the session, and that parallel work was scoped and approved — not hidden. |
| **The maintainer over time** | A parity baseline that tracks Claude Copilot's *intent* and a release-fitness check that stays green, so adoption is honest and auditable. |

---

## 2. The Essence

**Soul statement:**
A Codex-native operating layer that translates Claude Copilot's discipline — specialist routing, durable memory, evidence-bound quality gates — into real Codex primitives, and refuses to fake the runtime features Codex doesn't have.

**The deeper aim:**
The developer stops choosing between rigor and honesty. They get a framework that behaves like a disciplined lead engineer *and* never lies about what the platform underneath it can do — so its "done" can be trusted.

**As a person, this product would be:**
An honest senior engineer who has clearly worked somewhere more sophisticated, brings that discipline with them, but never bluffs. When asked for a feature the platform can't support, they say so plainly and offer the real, inspectable substitute instead of a convincing fake.

**Would NOT be:**
The cargo-culter who reproduces another platform's syntax for the feeling of parity, ships a `VERDICT: APPROVED` with nothing behind it, and calls a green build "verified."

| It IS | It IS NOT |
|-------|-----------|
| A Codex-native instruction/skill/script layer that runs *inside* Codex | A standalone app, hosted service, MCP server, or model/LLM provider |
| A mirror of Claude Copilot's capability *intent*, expressed in Codex primitives | A one-for-one reimplementation of Claude slash commands, named-agent syntax, or lifecycle hooks |
| A consumer of the shared `cc`/`tc` CLIs | Its own memory engine, task engine, or database |
| An evidence-bound QA discipline (artifact marker + verdict token) | A trust-the-verdict rubber stamp where a bare `APPROVED` passes |
| A leaf foundational layer that tracks `claude-copilot` upstream | The Claude Copilot framework itself, or a fork that vendors `cc`/`tc` |

**Key boundary — read this twice:**
Codex Copilot mirrors Claude Copilot, but only its **intent**. A capability is allowed in *only* if it can be expressed honestly in a real Codex primitive — `AGENTS.md`, a Codex skill, `tc`/`cc` state, a script, or a test. If a capability requires a Claude runtime feature Codex does not provide (SessionStart / PreToolUse / SubagentStop hooks, slash-command syntax, named-agent syntax), it is **substituted with an explicit, inspectable mechanism — or refused. It is never faked.** "Claude lifecycle hooks" here means runtime events only; it does *not* mean the design-led `$protocol`, which stays design-led.

---

## 3. Design Principles

### Principle 1: Native Over Imitation
**Meaning:** Every capability is expressed through a real Codex primitive. Borrowed *ideas* are welcome; borrowed *syntax that only works on Claude* is not.
**Rejection:** We reject reimplementing Claude slash commands, Claude named-agent syntax, and Claude lifecycle hooks one-for-one. They become Codex skills, `tc` metadata, scripts, work products, and tests instead.
**Test:** "Can this be expressed in a real Codex primitive — or does it pretend a Claude runtime feature exists?" If it pretends, reject.

### Principle 2: Evidence Or It Didn't Pass
**Meaning:** A passing QA verdict is only valid when paired with an external, failable artifact (`test-run`, `file-check`, `diff-check`, `screenshot-check`, `a11y-check`, `design-fidelity-check`).
**Rejection:** We reject a bare `VERDICT: APPROVED`. `scripts/copilot-gate.sh` fails a QA-required task that has no approved metadata with `qaArtifact` and no `ARTIFACT:` marker.
**Test:** "Does this claim of 'done' carry a failable artifact someone else could re-run?" No artifact → not passed.

### Principle 3: Durable Over Chat
**Meaning:** Decisions, specs, implementation notes, and test results live in `tc`/`cc`, not only in chat or markdown that vanishes.
**Rejection:** We reject writing planning or work state into markdown. If a PRD/task doesn't exist for substantial work, create it in `tc` rather than narrating a plan into the session.
**Test:** "If this session disappeared, does the plan/decision/result still exist in `tc`/`cc`?" If only in chat → not durable.

### Principle 4: Discipline Before Speed
**Meaning:** Classify and frame work, then apply the right specialist lens, before writing code. `$protocol` routes; specialists carry distinct jobs.
**Rejection:** We reject jumping from a vague request straight to implementation when the work needs architecture, QA, security, service-design, UX, UI, docs, or ops thinking first.
**Test:** "Was this classified and routed to the right specialist lens before coding?" If it went request → code, redo.

### Principle 5: Borrow, Don't Rebuild
**Meaning:** Codex Copilot is a leaf layer. It reuses the shared `cc`/`tc` CLIs for all memory, task, and docs work and owns no engine of its own.
**Rejection:** We reject building (or vendoring/forking) a memory engine, task engine, or database here. The framework is *degraded*, not re-implemented, when `cc`/`tc` are absent.
**Test:** "Are we delegating to the shared CLI — or duplicating something it already owns?" Duplication → reject.

### When Principles Conflict
*Settle the priority order in advance, so a live argument doesn't have to.*

<!-- TODO: owner — Ratify the priority order when principles collide. The retrofit's
     read of the evidence is that honesty is load-bearing above all (the product's stated
     reason to exist), i.e. Native Over Imitation > Evidence Or It Didn't Pass >
     Durable Over Chat > Discipline Before Speed > Borrow, Don't Rebuild. CONFIRM or correct. -->

Priority order (proposed, unratified): **Native Over Imitation > Evidence Or It Didn't Pass > Durable Over Chat > Discipline Before Speed > Borrow, Don't Rebuild** <!-- INFERRED FROM DOCS; CONFIRM -->

---

## 4. Anti-Patterns

### The Claude Cosplay
**Drift:** To *feel* at parity, someone reimplements Claude slash-command syntax, named-agent syntax, or runtime hook enforcement so the framework "looks like the real thing." <!-- INFERRED FROM DOCS; CONFIRM -->
**Why it kills us:** The fake breaks inside Codex, and the moment one feature is a bluff, the whole framework's "done" stops being trustworthy. Honesty is the product.
**Early warning:** "Let's add hook support," "describe the gate as a runtime hook," "match Claude's `/command` syntax exactly," "say we're at full parity."
**Line in the sand:** <!-- TODO: owner — state the non-negotiable. Evidence ("Honest Boundaries", parity "Deferred") says: never describe hook enforcement as implemented until Codex provides a matching lifecycle surface; always substitute, never fake. CONFIRM wording. -->

### The Rubber Stamp
**Drift:** Under time pressure, QA records `VERDICT: APPROVED` without an artifact because "the change is obviously fine." <!-- INFERRED FROM DOCS; CONFIRM -->
**Why it kills us:** Evidence-bound QA is the one gate that makes "done" mean something. A passing verdict without evidence is worse than no gate — it's a false signal.
**Early warning:** "It builds, so it's verified," "skip the artifact this once," "bare approved is fine for small changes."
**Line in the sand:** <!-- TODO: owner — confirm: a passing verdict is invalid without an `ARTIFACT:` marker, no exceptions; `copilot-gate.sh` is authoritative. -->

### The Markdown Memory
**Drift:** A plan or decision gets written into a markdown file because it's quick, instead of into `tc`/`cc`. <!-- INFERRED FROM DOCS; CONFIRM -->
**Why it kills us:** Plans in markdown rot and fork; the framework's promise of durable context dies and Codex starts forgetting decisions again — the exact failure it exists to fix.
**Early warning:** "I'll just note the plan in a `.md`," "let's track tasks in a checklist file," "we don't need a `tc` task for this."
**Line in the sand:** <!-- TODO: owner — confirm: substantial planning/work state lives in `tc`/`cc`, not project markdown. -->

### The Hidden Worker
**Drift:** Background or headless orchestration is added so parallel work "just happens" without the user approving it. <!-- INFERRED FROM DOCS; CONFIRM -->
**Why it kills us:** Silent automation breaks the user-approved-delegation contract and the trust that the framework only does what was scoped and approved.
**Early warning:** "Run these agents in the background," "auto-spawn workers," "headless orchestration," "no need to ask the user."
**Line in the sand:** <!-- TODO: owner — confirm: parallel work is user-approved, scope-validated `spawn_agent` delegation only (via `$launcher`), with stream/file-ownership validation. -->

### The Global Pack
**Drift:** Business/creative specialists (`cco`, `cw`, `cs`, `cpa`, `kc`) get loaded into the default global plugin because "they're useful everywhere." <!-- INFERRED FROM DOCS; CONFIRM -->
**Why it kills us:** It bloats the default surface and erodes the "Codex-native operating layer for *software* work" focus; domain specialists belong opt-in per project, not global.
**Early warning:** "Just make `cw` global," "add the creative pack to the default roster," "everyone wants these on."
**Line in the sand:** <!-- TODO: owner — confirm: pack specialists stay dormant in `packs/` until a project runs `activate-pack.py`; never global by default. -->

---

## 5. Feature Filter

Use these gates **in order**. A feature must pass **all** of them.

### Gate 1: Native Primitive Test
> "Can this be expressed honestly in a real Codex primitive — `AGENTS.md`, a Codex skill, `tc`/`cc` state, a script, or a test?"

If it requires pretending a Claude runtime feature (hooks, slash/named-agent syntax) exists → reject. Substitute or stop. *(This is the load-bearing gate; most bad ideas die here.)*

### Gate 2: Parity Intent Test
> "Does this mirror a real Claude Copilot capability *intent*, or honestly serve the Codex workflow — rather than inventing net-new scope?"

If it's not in the parity baseline and not an honest substitution of upstream intent → defer and update `parity/` before reconsidering.

### Gate 3: Ownership Test
> "Does this belong *here*, or in the shared `cc`/`tc` engine, or in the consuming project?"

If it's memory/task/database behavior → it belongs in `cc`/`tc`, not in this leaf layer. Stop.

### Gate 4: Principle Test
> "Does it survive every principle in Section 3?"

One violation → redesign or reject.

### Gate 5: Anti-Pattern Test
> "Does building this drift toward The Claude Cosplay, The Rubber Stamp, The Markdown Memory, The Hidden Worker, or The Global Pack?"

If yes → reject, or redesign until it doesn't.

### Case Law (In / Out)

<!-- Seeded from decisions already visible in docs/code. INFERRED reasoning where the
     verdict is documented but the rationale is reconstructed; CONFIRM. Grow this forever. -->

| Feature | Verdict | Gate | Reasoning |
|---------|---------|------|-----------|
| Evidence-bound QA gate (`copilot-gate.sh`, artifact + verdict) | **IN** | 1, 4 | A native, inspectable substitute for Claude's hook-blocked closure; makes "done" mean something. |
| `$protocol` design-led routing into specialist flows | **IN** | 2, 4 | Mirrors `/protocol` intent via a native skill; discipline before speed. |
| Dormant capability packs, opt-in per project | **IN** | 3, 5 | Keeps domain specialists local, not global; honors The Global Pack line. |
| Reuse shared `cc`/`tc` CLIs (not vendored) | **IN** | 3, 5 | Leaf layer borrows the engine instead of rebuilding it. |
| Reimplement Claude lifecycle hooks one-for-one | **OUT** | 1 | Can't be done honestly in Codex; becomes scripts/`tc` metadata/tests instead. |
| Build an in-repo memory/task engine or database | **OUT** | 3 | Owned by `cc`/`tc`; duplicating it violates Borrow, Don't Rebuild. |
| Hidden background / headless worker orchestration | **OUT** | 5 | The Hidden Worker; parallel work must be user-approved and scope-validated. |
| Make `cco`/`cw`/`cs`/`cpa`/`kc` global specialists | **OUT** | 3, 5 | The Global Pack; they stay dormant until `activate-pack.py`. |

---

## 6. Quality Bar

**The standard:**
"Done" means honest, durable, and evidence-bound — the capability works through a real Codex primitive, its state survives in `tc`/`cc`, and any "passed" claim carries a re-runnable artifact.

**Non-negotiables:**

- [ ] Release fitness is green: version, manifest, parity, and smoke checks pass (`scripts/smoke-test.sh`, `VERSION.json`, `parity/claude-baseline.json`). <!-- INFERRED FROM DOCS; CONFIRM -->
- [ ] No capability is described or shipped as a Claude runtime feature; hooks are never claimed as "implemented" while platform-deferred.
- [ ] Every QA-required task passes `copilot-gate.sh`: approved metadata with `qaArtifact` and a `test` work product carrying a valid `ARTIFACT:` marker + `VERDICT:` token.
- [ ] Substantial planning/work state lives in `tc`/`cc`, not in project markdown.
- [ ] `setup-project.sh` refuses to overwrite existing `AGENTS.md`, plugin links, or skill links (never clobbers user work).
- [ ] Parity additions update `parity/` and `VERSION.json` so adoption stays auditable.

**Taste test:**
If a reader can't tell, from the docs alone, exactly which Claude features are *substituted* vs *deferred* vs *not done* — the honesty failed. The boundary must be legible, not buried.

**Quality failure modes:**

| Failure | Symptom |
|---------|---------|
| Dishonest parity | Docs imply full Claude parity or describe hook enforcement as implemented. |
| Hollow verdict | A QA-required task closes on a bare `VERDICT: APPROVED` with no artifact. |
| Leaked engine scope | Memory/task/db logic creeps into this repo instead of living in `cc`/`tc`. |
| Silent automation | Parallel work runs without explicit user approval and scope validation. |

---

## 7. Voice & Tone

**Character:**
Direct, plain, technical, and honest. Lowercase command names (`$protocol`, `cc docs`, `tc wp store`). States limitations out loud and calls that honesty intentional. Never hypes, never claims parity it can't back, never sells. It sounds like documentation written by an engineer who would rather under-promise than bluff.

**Language rules:**

| We Say | We Don't Say |
|--------|--------------|
| "Codex Copilot does not recreate Claude lifecycle hooks one-for-one." | "Full Claude Copilot parity, now on Codex!" |
| "Claude runtime hooks become explicit task metadata, scripts, work products, and tests." | "Seamless hooks support out of the box." |
| "A bare `VERDICT: APPROVED` does not pass `copilot-gate.sh`." | "QA passed." |
| "The framework is *degraded* without `cc`/`tc`." | "Works standalone, no dependencies." |
| "That honesty is intentional." | "Everything just works." |

**Tone shifts:**

| Context | Tone |
|---------|------|
| Boundaries / non-goals | Plain and unapologetic — name what it won't do and why that's deliberate. |
| Errors / missing tooling | Specific and honest — state the limitation, then the concrete fallback (verify against local package files or official docs). |
| Verification | Evidence-first — describe the artifact and the failable check, not a feeling of confidence. |

---

## 8. Success Signals

**Positive signals (we're on track):**

- "A green QA verdict here always has evidence behind it — I don't re-check it by hand."
- "It never pretended Codex had a feature it doesn't; the boundaries were honest."
- "My plan was still in `tc` when I came back to the session."
- "It routed the work to the right specialist before anyone wrote code."

**Drift signals (we're losing the soul):**

| Signal | What it means |
|--------|---------------|
| A doc starts describing hook enforcement as "implemented" | Honesty drift → The Claude Cosplay. |
| QA-required tasks closing without `ARTIFACT:` markers | Gate rot → The Rubber Stamp. |
| Plans and decisions appearing in project markdown | Durable-context rot → The Markdown Memory. |
| `packs/` specialists showing up in the default global roster | Scope creep → The Global Pack. |
| New in-repo code that duplicates `cc`/`tc` behavior | Engine drift → Borrow, Don't Rebuild is breaking. |

**Recovery questions:**

1. Can this be expressed in a real Codex primitive, or are we faking a Claude runtime feature?
2. Does every "passed" claim still carry a re-runnable artifact?
3. <!-- TODO: owner — add the third recovery question you'd actually ask when a drift signal fires. -->

---

## 9. Founding Decisions

The settled calls this instrument is built on. Ratified with the owner <!-- TODO: owner — DATE on ratification -->.

<!-- These are reconstructed from docs as CANDIDATE founding decisions. Owner must ratify;
     do not treat as locked until then. -->

1. **Honesty over imitation is the reason to exist.** <!-- INFERRED FROM DOCS; CONFIRM --> The framework mirrors Claude Copilot's *intent* only, and never fakes a Claude runtime feature; it substitutes or refuses. Resolves The Claude Cosplay.
2. **QA is evidence-bound.** <!-- INFERRED FROM DOCS; CONFIRM --> A passing verdict requires an `ARTIFACT:` marker; `copilot-gate.sh` is authoritative. Resolves The Rubber Stamp.
3. **This is a leaf layer that borrows its engine.** <!-- INFERRED FROM DOCS; CONFIRM --> Memory/task/docs work delegates to shared `cc`/`tc`; no engine is built or vendored here. Resolves engine-scope creep.
4. **Delegation is user-approved only.** <!-- INFERRED FROM DOCS; CONFIRM --> No hidden background workers; parallel work is scoped, validated, and explicitly requested. Resolves The Hidden Worker.
5. **Priority order when principles conflict:** <!-- TODO: owner — ratify the order proposed in Section 3. -->
6. **The anti-patterns are named and kept:** The Claude Cosplay, The Rubber Stamp, The Markdown Memory, The Hidden Worker, The Global Pack. <!-- TODO: owner — confirm this set is complete and correctly named. -->

---

## 10. Evolution

This file changes only when:
- Real user outcomes shift what the product is for
- We learn something durable that contradicts a current principle or boundary
- The product's place in its ecosystem changes (e.g. the parity relationship with `claude-copilot` materially changes)

When updated, add the rationale to the changelog below.

### Changelog

| Date | Version | Change & rationale |
|------|---------|--------------------|
| 2026-06-28 | v0.1 | Drafted as root-level decision instrument, retrofitted from the repo's docs (README, AGENTS.md, `docs/`, `parity/`, `VERSION.json`) and code surface. Inferences marked `INFERRED; CONFIRM`; owner-only calls (anti-pattern lines in the sand, priority order, founding decisions, third recovery question) flagged `TODO: owner`. Pending owner ratification → v1.0. |
