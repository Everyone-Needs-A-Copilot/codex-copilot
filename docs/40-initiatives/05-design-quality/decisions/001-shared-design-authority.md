# ADR 001 — Shared design authority, native execution

**Decision:** Implement reusable design operations once in `cc`, strengthen the
existing native specialists, and preserve `tc` as the only task/QA authority.

Impeccable contributes useful surface modes, focused design actions, critique
before detector anchoring, edit feedback and visual iteration. Importing its whole
runtime as CSE's new protocol would duplicate task ownership and confuse detector
findings with design judgment. CSE instead uses its pinned engine as an explicit
local evidence source and provides independently authored specialist playbooks.

## Authority and evidence

Product facts, the user's brief and existing design decisions outrank aesthetic
heuristics. Modes describe a surface's job, not a style recipe. Initial judgment
is recorded before the scan; a sequential pass remains sequential. Receipt hashes
detect accidental edits and stale inputs, not malicious forgery or independent
model consumption. Verification reports establish structural readiness only;
QA must still inspect behavior, source/runtime identity and artifact relevance.

## Execution boundary

The machine owns the executable registry. Install uses packaged release digests;
registration checks the supplied hash and exact `engine-probe` identity. A project
cannot select another executable through its design contract. The trusted process
runs without a shell, with bounded output/time and process-group cleanup. This is
not an operating-system sandbox; registered executables retain host permissions.

The adapter selects local files, disables project/inline suppressions and automatic
DESIGN.md loading, and includes linked local stylesheets in evidence identity.
Relative stylesheet references must remain inside the project; root-relative
deployment paths require a locally resolvable capture or explicit manual evidence.
Remote CSS and JavaScript execution are outside static coverage. SwiftUI and other
unsupported languages require native rendered inspection, never a fictitious clean
web scan. The optional live workflow remains an external tool with explicit source
ownership and cleanup, not a globally started daemon.

## Source and licensing

Research source: [Impeccable at 2bc2879](https://github.com/pbakaus/impeccable/tree/2bc2879276c1f321a53c4ca99d3371e411329b52).
Detector: [engine-v0.1.3](https://github.com/pbakaus/impeccable/releases/tag/engine-v0.1.3).
The Darwin ARM64 asset SHA256 is
`23821135d4c62f1428fd15ddb9e91d695402727f43b13a6eb3e9f31fc01b4072`.
The engine's `engine-probe` reports 0.1.3; its general CLI version is not the engine
identity. The source license is Apache-2.0 with notices for derived guidance;
upstream binaries are downloaded separately and upstream skill prose is not
vendored into CSE. Packaged provenance and all supported platform digests live in
`cc/core/design/references/`.

## Alternatives and consequences

Vendoring every upstream command would make upgrades and native routing harder.
Using only a linter would miss intent, rendered states and behavioral failures.
Keeping only a small advisory pilot would leave accepted framework gaps open.
The chosen boundary provides the complete capability now, while reserving broad
effectiveness claims for observed outcomes. Upstream upgrades require a deliberate
pin update and fresh acceptance evidence, not a moving `latest` install.
