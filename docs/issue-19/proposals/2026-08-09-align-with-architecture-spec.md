---
subject: issue-19
loop_state: scope-proposed
files:
  - docs/handbooks/architecture-methodology.md
  - arch-adr-content-gate/hooks/adr-content-gate.sh
  - arch-adr-content-gate/README.md
  - arch-adr-content-gate/tests/fixtures/**
  - arch-sequence-gate/hooks/sequence-gate.sh
  - arch-sequence-gate/README.md
  - arch-sequence-gate/tests/fixtures/**
  - README.md
---

## Request

Issue #19 asks this rulebook's vocabulary and gates to be aligned with the
realized marketplace spec `roles/specs/architecture.spec.json`
(on-the-record): its five `required_fields`
(`decision_id`/`context`/`considered_options`/`decision_drivers`/`outcome`)
and its five-value `loop_state` vocabulary
(`drafting`/`reviewing`/`landed`/`decision-not-ripe`/`options-unreachable`)
must be layered onto the existing methodology docs, hooks, and gates,
additively — strengthening what exists, not deleting it.

## Constraints

- Every spec required-field name must appear verbatim and grep-discoverable
  in the rulebook docs after phase 2
  (`grep -ri <field> docs/ README.md` for each of the five fields).
- The rulebook's `loop_state` vocabulary must match the spec's five-value
  set exactly — no stale (`scope-proposed`/`proposed`) or extra states left
  in the live rulebook vocabulary that a `loop_state` grep over docs/
  and the gate scripts would surface.
- `tests/run-gate-tests.sh` must be run (and, if phase 2 changes gate
  behavior, updated) so it passes after the change.
- The change must be additive: existing methodology content (the four ADR
  sections, the C4 diagram requirement, the phase-1/phase-2 stage
  structure) is strengthened, never removed.
- Any spec field that has no natural, non-forced home in this rulebook must
  be called out explicitly with reasoning in this proposal, not silently
  dropped — see "What will be done" below; no field in this spec triggers
  that case, but each field's home is stated explicitly for that reason.
- Provenance for this task is `executed-unit`: phase 2 execution must be
  traceable to actual file edits and an actual gate-test run, not asserted.

## Rationale

Three real tradeoffs were considered and decided:

**(a) New `docs/decisions/*.md` ADR-file layer now, vs. keep `decision_id`/
`considered_options` mapped onto the existing
`docs/issue-<n>/reports/architecture.md` record.** Decision: defer the
physical `docs/decisions/` split; keep `decision_id`/`considered_options`
mapped onto the existing per-issue report for this phase. The spec's
`write_scope` literally names `docs/decisions/*.md`, but this repo has zero
files under that path today, and the existing per-issue report already
carries the Alternatives-Considered content the spec's `considered_options`
maps onto. Standing up a parallel `docs/decisions/` tree with no content in
it yet would be scaffolding for its own sake and would fragment where a
decision's full record lives, working against "strengthen, don't delete."
Rejected: building the new tree now, because it duplicates a structure this
task has no concrete decision to populate it with.

**(b) Rename "Alternatives Considered" into a structured `considered_options:`
ref-list right away, vs. keep it prose-shaped and defer ref-list machinery.**
Decision: keep it prose-shaped for phase 2, and add the literal string
`considered_options` as a documented mapping label alongside the existing
"Alternatives Considered" heading, without building ref-list resolution.
The spec's `reference_resolution.checked_by` names
`on-the-record/hooks/role-spec-reference-guard.sh` — a hook this repo does
not have, and issue-19 does not ask this repo to build that mechanism.
Rejected: building ref-list resolution now, because it is out of this
issue's scope and would require inventing enforcement machinery the issue
never asked for.

**(c) Retroactively migrate every existing landed record's `loop_state`
value, vs. only change the vocabulary going forward for new records.**
Decision: do not rewrite historical records; `docs/issue-1`, `docs/issue-10`,
`docs/issue-13`, `docs/issue-16` keep their existing `scope-proposed`/
`proposed`/`landed` values as historical record. Rewriting merged history is
not requested by issue-19 and risks contradicting already-approved records.
However, `scope-proposed`/`proposed` as *live, currently-hardcoded*
vocabulary in the gate scripts, the handbook, the README, and the gate test
fixtures (which exercise those states as inputs, not as historical
artifacts) IS considered stale for the purposes of the acceptance check's
grep, because that grep runs over `docs/` and `README.md` — the rulebook's
prescriptive vocabulary, not per-issue historical logs read as data. Phase 2
will replace `scope-proposed`/`proposed` with `drafting`/`reviewing`
everywhere they are prescribed as the vocabulary to use (handbook, README,
gate scripts' comparison logic, and gate test fixtures), while leaving
historical `docs/issue-<n>/...` frontmatter values untouched as a record of
what was true when written.

## What will be done

Field-by-field mapping:

| spec field | required | proposed home |
|---|---|---|
| `decision_id` | true | New required frontmatter field on `docs/issue-<n>/reports/architecture.md`, e.g. `decision_id: issue-<n>` (or a more specific slug when a report covers a distinct decision), since this repo has no `docs/decisions/` directory yet (see Rationale (a)). Enforced by `adr-content-gate.sh`. |
| `context` | true | Already covered by the existing gate-checked `## Context` / `**Context**` section — no structural change needed. The literal string "context" is already reachable by the acceptance grep via that heading; this is noted, not re-implemented. |
| `considered_options` | true | The existing "Alternatives Considered" check in `adr-content-gate.sh` is extended (not replaced) so the literal string `considered_options` also appears in the rulebook docs (handbook text, gate script comments, README), mapped explicitly onto the human-facing "Alternatives Considered" heading. Both labels coexist; the heading stays prose-shaped per Rationale (b). |
| `decision_drivers` | false | New optional section/field introduced in `docs/handbooks/architecture-methodology.md` (documented as optional, mirroring the spec's `required: false`) and referenced in `adr-content-gate.sh`'s comments/checks as a field the gate must accept as present-or-absent — its absence must never hard-fail the gate. |
| `outcome` | true | New required frontmatter field on `docs/issue-<n>/reports/architecture.md`, e.g. `outcome: accepted \| rejected \| superseded`, validated by `adr-content-gate.sh` against that three-value enum. This is added as frontmatter rather than a bullet under the existing `## Decision` section because `outcome` is a machine-checked enum value (the spec's `recomputation` rule ties it to the ADR's own status), and frontmatter is the rulebook's existing convention for machine-checked fields (e.g. `loop_state` is already frontmatter, not prose) — the `## Decision` section remains the narrative explanation of the same outcome. |

`loop_state` migration — exact file list and mapping:

- `arch-adr-content-gate/hooks/adr-content-gate.sh`: replace the hardcoded
  `scope-proposed`/`proposed` progress-state comparisons with
  `drafting`/`reviewing`; add explicit handling/pass-through for
  `decision-not-ripe` and `options-unreachable`.
- `arch-sequence-gate/hooks/sequence-gate.sh`: same replacement in its
  `if loop_state in ("", "scope-proposed", "proposed")` test ->
  `if loop_state in ("", "drafting", "reviewing")`.
- `docs/handbooks/architecture-methodology.md`: update all references to
  `scope-proposed`/`proposed` as the prescribed phase-1/phase-2 progress
  vocabulary to `drafting`/`reviewing`; document `landed` as unchanged;
  document `decision-not-ripe` and `options-unreachable` as new refusal/error
  states.
- `README.md`: same vocabulary update wherever `loop_state` values are
  listed or the `write_scope` is stated; also update `write_scope` from
  `["docs/issue-<n>/decisions/**"]` to explicitly note it targets the
  existing `docs/issue-<n>/reports/architecture.md` record (per Rationale
  (a) — no new `docs/decisions/**` scope is added in this phase).
- `arch-adr-content-gate/tests/fixtures/**` and
  `arch-sequence-gate/tests/fixtures/**`: update `event.json`/`expect.txt`
  fixtures currently exercising `scope-proposed`/`proposed` to use
  `drafting`/`reviewing`, and add new fixtures covering `decision-not-ripe`
  and `options-unreachable` behavior.

New state semantics:

- `decision-not-ripe` (refusal): triggered when a proposal's constraints are
  insufficient or the decision's reversibility is unclear — the correct
  response is to defer and hold in this state rather than force a premature
  ADR.
- `options-unreachable` (error): triggered when `considered_options`
  references cannot be resolved or read — the correct response is to fail
  loudly in this state rather than fabricate options.

## Out of scope

- Building a `role-spec-reference-guard.sh`-equivalent reference-resolution
  enforcement hook — issue-19 asks for field/vocabulary alignment, not that
  specific mechanism.
- The spec's `recomputation` rule — the spec itself marks its own
  `checked_by` as "TBD (follow-up)."
- Creating an actual `docs/decisions/*.md` file for any real decision — this
  is methodology alignment only; no new architecture decision is being
  proposed here.
- Retroactively rewriting historical records' `loop_state` values in
  `docs/issue-1`, `docs/issue-10`, `docs/issue-13`, `docs/issue-16` — per the
  Rationale (c) decision above, only live/prescriptive vocabulary is
  migrated, not historical record frontmatter.

## How you'll know it worked

- `grep -ri decision_id docs/ README.md`,
  `grep -ri context docs/ README.md`,
  `grep -ri considered_options docs/ README.md`,
  `grep -ri decision_drivers docs/ README.md`, and
  `grep -ri outcome docs/ README.md` each return matches after phase 2.
- `grep -rn "loop_state" docs/ README.md architecture/ arch-*-gate/` shows
  only `drafting`/`reviewing`/`landed`/`decision-not-ripe`/
  `options-unreachable` in the rulebook's live/prescriptive vocabulary
  (handbook, README, gate scripts, updated gate fixtures) — no
  `scope-proposed`/`proposed` survivors outside historical
  `docs/issue-<n>/...` record frontmatter, which is explicitly out of scope
  per the Rationale (c) decision.
- `bash tests/run-gate-tests.sh` passes after phase 2's gate-script and
  fixture edits.
