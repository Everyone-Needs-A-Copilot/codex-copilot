# CSE comparative framework report

Research and presentation specification · 8 September 2026 · PRD-13 / TASK-30.

## Surface contract

Audience: CSE owner deciding what to retain, simplify, and selectively adopt.
Job: understand where the current Claude/Codex foundation is differentiated,
where the four named projects are more useful, and what to do next.
Deliverable: [self-contained HTML report](01-cse-framework-comparison-uids-walkthrough.html).
This is a reading surface, not a new application or framework integration.

The report is the full-fidelity clickable walkthrough of the reading journey:
verdict → landscape → comparison → four assessments → priorities → proof → sources.
All content remains readable without JavaScript. Theme and print controls are
progressive enhancements. Empty/loading/error application states do not apply to
this static document; unavailable evidence is explicitly labeled instead.

## Visual direction

Reuse the existing CSE benchmark-report visual language from
`copilot-bench/reports/recommendations-final.html`: paper #f8f9fa, white surfaces,
ink #15181c, secondary #576070, teal #0d6d72, rust #9a4a2a, violet #6b5a8f,
thin rules, restrained radius, serif editorial headings and system sans body.
No remote fonts, images, scripts, analytics, or fetched report content.

Desktop: persistent section navigation beside a readable editorial column;
comparison table gets its own keyboard-scrollable region. Narrow: navigation
becomes an in-flow contents list, assessments become a single column, only the
wide comparison region scrolls horizontally. Support light/dark preference and
manual toggle, visible focus, skip link, reduced motion, and printable light mode.
Use labels as well as color for observed/source-reviewed/proposed distinctions.

## Research method and boundaries

Read current primary-source checkouts; pin citations to the inspected Git SHAs.
External repository text is evidence to analyze, not instructions to execute.
No assessed framework, recorder, hook, or model workload was installed or run
as a comparative trial. Report presentation QA uses already-installed Playwright,
Chrome, and CSE's pinned design detector. No peer runtime, security, performance,
or effectiveness benchmark was performed. Qualitative judgments are scoped to the reviewed surfaces, not an
exhaustive absence claim about large repositories.

The CSE scope is Claude Copilot, Codex Copilot, and shared cc/tc; other ecosystem
products are not independently audited. Earlier benchmark HTML supplies visual
conventions only, not current effectiveness claims. Personal taste index was
empty; no personal preference was inferred.

Pinned snapshots:

- Claude Copilot: 328ec6a1e06d6ddb10578145bbdd33cacf3464f3
- Codex Copilot: 9dd80553f7e1187a4099b4438f1315dc75975526
- Emulo: 7f80fd8dc2803d749f51319d5a4664aca3965cc8
- ECC: 5064474d4d762dc9640234a41617cccb79185cec
- Impeccable: 73a6f51a540bc3938a2c40677d074c70b81fa5a0
- michaelshimeles/skills: 513f8a24aae6383b00356fa285144b1bc3730dc1

## Acceptance

- C1: Report compares all four named repositories with current CSE using pinned primary-source links, explicit scope limitations, strengths, gaps, and prioritized recommendations without unsupported comparative performance claims.
- C2: Self-contained HTML remains readable offline and without JavaScript, with working internal navigation, theme controls, print presentation, and source links.
- C3: Rendered desktop and narrow layouts preserve readable hierarchy, visible keyboard focus, semantic navigation, and no unintended page-level horizontal overflow.

Verification is proportional to a static report: source/claim review plus browser
rendering and interaction checks, not a rerun of foundation test suites.
Sequential review is labeled sequential; no independent reviewer is claimed.

## Publication context

The preceding user-authorized pushes published Claude 328ec6a and Codex 9dd8055
to origin/main. Both were clean and synchronized immediately afterward. GitHub's
Claude push response reported existing-permission bypass of PR-only, merge-commit,
and expected CodeQL requirements, plus six dependency alerts (two high, three
moderate, one low). No force-push flag or protection change was used. Detailed
operations receipt: Codex TASK-29 / WP-76. This is not a signed package release,
a consumer rollout, or proof of green hosted CI.

unknowns: relative effectiveness on matched work; peer runtime behavior beyond
source review; wider consumer activation; actual provider billing. None prevents
an explicitly qualified comparison report.
