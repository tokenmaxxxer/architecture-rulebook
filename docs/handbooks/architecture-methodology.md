# architecture role: phase-1/phase-2 methodology

This handbook is this rulebook's own facet document (per `core`'s
handbook-trigger-gate convention), not a core-canon file. `directive.sh`'s
`PRODUCES` string points here for the stage/judgment-criteria/prohibition
detail that does not fit a one-line directive summary. Mechanical
enforcement of the norms below lives in the `arch-sequence-gate`,
`arch-citation-gate`, and `arch-adr-content-gate` plugins (see
`docs/issue-10/proposals/2026-07-31-architecture-enforcement.md` §0 for
which plugin owns which check).

## Phase 1 facet (기획서)

**Stages**

1. Survey current-state + external research — write
   `docs/issue-<n>/reports/architecture/survey.md`.
2. Scout-brief — write `docs/issue-<n>/reports/architecture/
   scout-brief.md`, unless the spec leaves no design decision open
   (issue-1's skip-condition text, carried forward verbatim); a skip must
   be stated explicitly in the proposal text.
3. Proposal citing both by path — write `docs/issue-<n>/proposals/*.md`.

**Judgment criteria** — a proposal is "ready" only if every claim
sourced from outside this repo carries a URL or a `Sources:` entry
(issue-1's citation-format rule, generalized to every future proposal by
this role). `arch-citation-gate` mechanizes this.

**Prohibitions** — no proposal may restate survey findings inline
instead of citing the survey path; no phase-1 PR may contain any hook,
gate, or test file edit (draft text only).

## Phase 2 facet (산출물)

**Stages**

1. Write the ADR-shaped `docs/issue-<n>/reports/architecture.md` record
   with the four required ADR sections plus a C4-level diagram.
2. Run `tests/run-gate-tests.sh` locally before requesting merge.
3. Note in the record's "Open findings" any known gate limitation
   (mechanical, not semantic checks — proportionality already
   established in issue-1).

**Judgment criteria** — a record is "landed"-ready only once
`arch-sequence-gate`, `arch-citation-gate`, and `arch-adr-content-gate`
all pass with no bypass env var set.

**Prohibitions** — no phase-2 record may set `loop_state: landed` (or
any state past `scope-proposed`/`proposed`) while a required phase-1
artifact (survey/scout-brief/proposal) for the same `issue-<n>` is
absent — `arch-sequence-gate` enforces this mechanically.

## Which plugin enforces what

| Concern | Plugin |
|---|---|
| Phase ordering (survey -> scout-brief -> proposal -> record) | `arch-sequence-gate` |
| Sourcing (external/industry claims cited) | `arch-citation-gate` |
| ADR+C4 required sections on the phase-2 record | `arch-adr-content-gate` |
| Human-facing ordered checklist | `arch-phase1-checklist` |

See `docs/issue-10/proposals/2026-07-31-architecture-enforcement.md` for
the full design rationale and open questions.
