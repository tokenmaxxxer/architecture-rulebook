---
subject: issue-19
loop_state: scope-proposed
---

# Survey: aligning the rulebook with roles/specs/architecture.spec.json

## 1. Scope of the change

Issue #19 asks this rulebook to layer the on-the-record marketplace program's
realized `architecture` role spec (issue-521-525) onto the existing
phase-1/phase-2 methodology: its five `required_fields` and its five
`loop_state` values must appear in the rulebook's vocabulary, additively —
"strengthening existing content, never deleting methodology."

## 2. What exists today

- `docs/handbooks/architecture-methodology.md` is the phase-1/phase-2
  methodology handbook. Phase 1 stages: survey -> scout-brief (unless
  skip-justified) -> proposal. Phase 2 stages: an ADR-shaped record with
  "four required ADR sections plus a C4-level diagram," running
  `tests/run-gate-tests.sh`, and noting gate limitations in an
  "Open findings" section.

- `arch-adr-content-gate/hooks/adr-content-gate.sh:114-131` fires on
  Write/Edit/MultiEdit to `docs/issue-<n>/reports/architecture.md` once
  `loop_state` leaves the proposal-only states `scope-proposed`/`proposed`.
  It currently checks, by substring/regex match only:
  - a `## Context` (or `**Context**`) section
  - a `## Decision` (or `**Decision**`) section
  - a `## Consequences` (or `**Consequences**`) section
  - the literal phrase "alternatives considered"
  - a C4 diagram marker (```` ```mermaid ````, "C4 Context"/"C4 Container",
    or "context diagram"/"container diagram")

  It has NO concept of `loop_state` enum validation (any string value is
  accepted as-is), NO `decision_id` field, and NO `decision_drivers` field.
  Its "alternatives considered" check is a bare substring match, not a
  `considered_options` ref-list structure.

- `arch-sequence-gate/hooks/sequence-gate.sh` also reads the record's
  `loop_state` frontmatter, using the identical
  `if loop_state in ("", "scope-proposed", "proposed")` test to decide
  whether phase-1-artifact-existence enforcement applies. This is the only
  other place in the rulebook where `scope-proposed`/`proposed` are
  hardcoded as the progress states.

- A repo-wide grep confirms `scope-proposed` and `proposed` are the ad-hoc
  progress-state strings actually in use across every existing
  record/proposal frontmatter in this repo — `docs/issue-1`, `docs/issue-10`,
  `docs/issue-13`, `docs/issue-16` all use `loop_state: scope-proposed` for
  phase-1 docs and `proposed`/`landed` for phase-2 records. None of these are
  in the spec's `loop_state` vocabulary
  (`drafting`/`reviewing`/`landed`/`decision-not-ripe`/`options-unreachable`).
  This is the core stale-vocabulary gap issue #19 asks to close.

- `docs/decisions/` does not exist anywhere in this repo yet. The spec's
  `write_scope` says `docs/decisions/*.md`, but this rulebook's own
  `README.md` currently states
  `write_scope: ["docs/issue-<n>/decisions/**"]` — per-issue-scoped, not the
  flat top-level `docs/decisions/` the spec wants. This is a real mismatch to
  flag, not silently resolve.

- There is no `decision_id` or `decision_drivers` concept anywhere in this
  rulebook today. `considered_options` has no ref-list structure — only the
  bare "alternatives considered" substring check described above exists.

- `docs/specs/approvers.md` exists (a human approvers list) but there is no
  `docs/specs/architecture.spec.json` or similar spec file mirrored into this
  repo yet. The spec lives externally in the on-the-record marketplace
  program and this repo has never ingested it before — issue-19 is this
  repo's first alignment pass against it.

- Per this repo's own per-role contract: phase-1 proposal frontmatter needs
  a `files:` (frozen write set) and the seven sections `## Request`,
  `## Constraints`, `## Rationale` (must name a rejected alternative and
  why), `## What will be done`, `## Out of scope`,
  `## How you'll know it worked` — enforced by `proposal-shape-gate.sh` at
  write time. Also: `survey-order-gate.sh` requires the survey file to exist
  on disk before the proposal file is written, and requires the proposal to
  name any scout-skip condition explicitly in its own text if scouting was
  skipped.

- Test harness convention: each `arch-*-gate` plugin has its own
  `tests/fixtures/*/` (an `event.json` + `expect.txt` pair per case),
  discovered by `tests/run-gate-tests.sh` at the repo root.

## 3. Field-by-field mapping (spec `required_fields` -> rulebook state)

| spec field | type | required | current rulebook state |
|---|---|---|---|
| `decision_id` | ref | true | **missing entirely.** No frontmatter field or section identifies a record by a resolvable ID today. |
| `context` | string | true | **covered** by the existing gate-checked `## Context` / `**Context**` section (`adr-content-gate.sh:114-131`). |
| `considered_options` | ref[] | true | **partially covered.** Only a bare substring check for the phrase "alternatives considered" exists; no ref-list structure, no per-option resolution. |
| `decision_drivers` | string | false | **missing entirely.** No field, section, or gate check exists. |
| `outcome` | enum (`accepted`/`rejected`/`superseded`) | true | **missing as an enum.** The existing `## Decision` section captures a decision narratively, but no `outcome` value is asserted or validated against the spec's three-value enum. |

## 4. loop_state vocabulary mapping (spec set -> rulebook state)

| spec `loop_state` value | category | current rulebook equivalent |
|---|---|---|
| `drafting` | progress | no direct match; closest ad-hoc analog is `scope-proposed` (phase-1 progress) |
| `reviewing` | progress | no direct match; closest ad-hoc analog is `proposed` (phase-2 progress, pre-landed) |
| `landed` | terminal | already used verbatim in this repo (`loop_state: landed`) — matches the spec exactly |
| `decision-not-ripe` | refusal | **no equivalent anywhere in this rulebook.** No refusal state exists in current loop_state usage. |
| `options-unreachable` | error | **no equivalent anywhere in this rulebook.** No error state exists in current loop_state usage. |

The stale states in active use today — `scope-proposed` and `proposed` —
are not in the spec's vocabulary at all and are hardcoded in
`arch-adr-content-gate/hooks/adr-content-gate.sh`,
`arch-sequence-gate/hooks/sequence-gate.sh`,
`docs/handbooks/architecture-methodology.md`, `README.md`, and the gate
test fixtures under both plugins' `tests/fixtures/`.

## 5. External research: MADR standard check

The spec's `source_standard` field cites MADR (Markdown Any Decision
Records), https://adr.github.io/madr/. MADR's canonical decision-record
template has fields directly analogous to the spec's `required_fields`:
`Context and Problem Statement` (~= `context`), `Decision Drivers`
(~= `decision_drivers`), `Considered Options` (~= `considered_options`),
`Decision Outcome` with a chosen option and a status-like field
(~= `outcome`), and each record identified by its filename/id
(~= `decision_id`). This confirms the spec's `required_fields` are MADR's
own field names, not a novel vocabulary invented by the on-the-record
program — the mapping task ahead is "does this rulebook's existing
Context/Decision/Consequences/Alternatives-Considered/C4 scheme already
cover MADR's fields, and where does it fall short," which section 3 above
answers field-by-field. Source: https://adr.github.io/madr/.
