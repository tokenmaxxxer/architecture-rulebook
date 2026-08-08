---
subject: issue-19
code_under_review: HEAD
loop_state: landed
---

## What was done

Applied the approved phase-1 proposal
(`docs/issue-19/proposals/2026-08-09-align-with-architecture-spec.md`)
end to end, per its field-by-field mapping and `loop_state` migration
table:

- **`docs/handbooks/architecture-methodology.md`**: added a "Spec
  alignment" section mapping the spec's five `required_fields`
  (`decision_id`/`context`/`considered_options`/`decision_drivers`/
  `outcome`) onto existing or new rulebook concepts, and documenting the
  five-value `loop_state` vocabulary (`drafting`/`reviewing`/`landed`/
  `decision-not-ripe`/`options-unreachable`); updated the phase-2
  prohibition paragraph to the new vocabulary.
- **`arch-adr-content-gate/hooks/adr-content-gate.sh`**: `loop_state`
  check now skips `drafting`/`reviewing` (was `scope-proposed`/
  `proposed`) and also skips the two new refusal/error states
  `decision-not-ripe`/`options-unreachable` (a record parked there is
  not asserting a decision). Added required `decision_id` and `outcome`
  (`accepted`/`rejected`/`superseded`) frontmatter checks. Extended the
  Alternatives-Considered check to also accept the literal
  `considered_options` label. Updated a stale in-file comment.
- **`arch-adr-content-gate/README.md`**: documented the new
  skip-states, the `considered_options` alias, and the new
  `decision_id`/`outcome` requirement.
- **`arch-adr-content-gate/tests/fixtures/**`**: migrated existing
  fixtures' `loop_state: scope-proposed`/`proposed` values to
  `drafting`/`reviewing`; added `decision_id`/`outcome` frontmatter to
  the four `pass-*` fixtures that exercise the content check with a
  decision-bearing `loop_state` (`pass-all-sections`, `pass-plain-edit`,
  `pass-multiedit-resolvable`, `pass-replace-all`); added two new
  fixtures (`pass-decision-not-ripe`, `pass-options-unreachable`)
  proving both new states skip the content check.
- **`arch-sequence-gate/hooks/sequence-gate.sh`**: same `loop_state`
  vocabulary migration as the ADR gate (`drafting`/`reviewing`/
  `decision-not-ripe`/`options-unreachable` all skip the phase-1-
  artifact-existence check). Updated a stale in-file comment.
- **`arch-sequence-gate/README.md`**: documented the new vocabulary and
  the two new skip-states.
- **`arch-sequence-gate/tests/fixtures/**`**: migrated existing
  fixtures' `loop_state` values the same way; added two new fixtures
  (`pass-decision-not-ripe-skips-check`,
  `pass-options-unreachable-skips-check`).
- **`README.md`**: added a "`loop_state` vocabulary" bullet and a
  "required record fields" bullet under the gate-house standard section;
  updated `write_scope` to state it targets the existing
  `docs/issue-<n>/reports/architecture.md` record rather than a new
  `docs/decisions/**` tree (per the proposal's Rationale (a)).

`bash tests/run-gate-tests.sh` was run after every gate-script/fixture
edit; the full suite (arch-adr-content-gate, arch-citation-gate,
arch-sequence-gate) passes with no failures.

## Why

Issue #19 asks this rulebook's vocabulary and gates to be layered with
`roles/specs/architecture.spec.json`'s required-field and `loop_state`
vocabulary, additively — strengthening the existing ADR/C4 methodology,
never deleting it.

## Upstream

- Basis: `docs/issue-19/proposals/2026-08-09-align-with-architecture-spec.md`
- Approval: issue #19 comment `APPROVE issue-19/implementation` by
  `JiwonJung94` (single-account mode; `JiwonJung94` is listed in
  `docs/specs/approvers.md`)

## What did not work

None as a discarded attempt. One gap surfaced during verification and
was closed within the frozen write set: the four
`arch-adr-content-gate` `pass-*` fixtures that exercise a
decision-bearing `loop_state` had no `decision_id`/`outcome`
frontmatter, so adding the new required-field check initially turned
them from PASS to FAIL; fixed by adding that frontmatter to the
fixtures (all four files are already inside the frozen
`arch-adr-content-gate/tests/fixtures/**` write-set entry).

## Rationale for deviations

`arch-sequence-gate/.claude-plugin/plugin.json`'s `description` field
still reads `loop_state scope-proposed/proposed` — stale prescriptive
text the proposal's own verification command
(`grep -rn "loop_state" ... arch-*-gate/`) would surface, but
`plugin.json` is not a path listed in the approved proposal's frozen
`files:` write set. Left untouched: scope-exceeded rule — finish what
the proposal covers, stop, report, never widen mid-build. Not a
functional defect (metadata text, not enforced logic); a future
issue/proposal adding that one path to its frozen write set closes it.

## Open findings

- `arch-sequence-gate/.claude-plugin/plugin.json`'s stale
  `scope-proposed/proposed` description text — see "Rationale for
  deviations" above.
  - Resolution path: a follow-up issue/proposal that lists
    `arch-sequence-gate/.claude-plugin/plugin.json` in its frozen write
    set and updates that one description string.

## Hunt record

See `docs/reports/2026-08-09-hunt-align-with-architecture-spec.md` for
the after-proposal hunt (no finding) and this transition's
before-landing hunt.

## closed_checks

- `bash tests/run-gate-tests.sh` full suite (arch-adr-content-gate,
  arch-citation-gate, arch-sequence-gate) — all PASS —
  code_under_review: HEAD
- `grep -ril <field> docs/ README.md` for each of `decision_id`,
  `context`, `considered_options`, `decision_drivers`, `outcome` —
  each returns matches — code_under_review: HEAD
- `grep -rn "loop_state" docs/handbooks README.md architecture
  arch-adr-content-gate arch-sequence-gate` outside `tests/fixtures/**`
  and outside historical `docs/issue-<n>/...` records — only
  `drafting`/`reviewing`/`landed`/`decision-not-ripe`/
  `options-unreachable` appear, except the one noted open finding in
  `arch-sequence-gate/.claude-plugin/plugin.json` — code_under_review:
  HEAD
