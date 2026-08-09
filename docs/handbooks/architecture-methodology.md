# architecture role: phase-1/phase-2 methodology

This handbook is this rulebook's own facet document (per `core`'s
handbook-trigger-gate convention), not a core-canon file. `directive.sh`'s
`PRODUCES` string points here for the stage/judgment-criteria/prohibition
detail that does not fit a one-line directive summary. Mechanical
enforcement of the norms below lives in the `arch-sequence-gate`,
`arch-citation-gate`, and `arch-adr-content-gate` plugins (see
`docs/issue-10/proposals/2026-07-31-architecture-enforcement.md` §0 for
which plugin owns which check).

## Spec alignment (`roles/specs/architecture.spec.json`, issue-19)

This role's phase-2 record maps onto the marketplace spec's five
`required_fields` and five-value `loop_state` vocabulary, additively —
the spec vocabulary is layered on top of this handbook's existing
ADR/C4 methodology, never replacing it.

| spec field | required | maps onto |
|---|---|---|
| `decision_id` | true | New required frontmatter field on `docs/issue-<n>/reports/architecture.md`, e.g. `decision_id: issue-<n>`. |
| `context` | true | The existing `## Context` / `**Context**` section. |
| `considered_options` | true | The existing "Alternatives Considered" section; both labels are accepted, the heading itself stays prose-shaped. |
| `decision_drivers` | false | Optional section in a phase-2 record; its absence never fails `arch-adr-content-gate`. |
| `outcome` | true | New required frontmatter field, `outcome: accepted \| rejected \| superseded`, enforced by `arch-adr-content-gate`. The narrative `## Decision` section remains the prose explanation of the same outcome. |

`loop_state` vocabulary — the spec's five values replace this
rulebook's prior `scope-proposed`/`proposed` progress states
(historical `docs/issue-<n>/...` record frontmatter already written with
the old values is left untouched, per the spec-alignment proposal's
Rationale (c)):

- `drafting` — phase-1 in progress (was `scope-proposed`).
- `reviewing` — phase-2 in progress, not yet decision-bearing (was
  `proposed`).
- `landed` — decision-bearing and complete; unchanged.
- `decision-not-ripe` — refusal state: the proposal's constraints are
  insufficient or reversibility is unclear; defer and hold here instead
  of forcing a premature ADR.
- `options-unreachable` — error state: `considered_options` references
  cannot be resolved or read; fail loudly here instead of fabricating
  options.

Both `decision-not-ripe` and `options-unreachable` are exempt from the
ADR/C4 required-section check and from the phase-1-artifact-existence
check (`arch-adr-content-gate`, `arch-sequence-gate`) the same way a
`drafting`/`reviewing` record is — a record parked in a refusal/error
state is not asserting a decision yet.

`write_scope` in this repo's `README.md` targets the existing
`docs/issue-<n>/reports/architecture.md` record, not a new
`docs/decisions/*.md` tree — see the spec-alignment proposal's
Rationale (a) for why that split is deferred.

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
any state past `drafting`/`reviewing`, except the refusal/error states
`decision-not-ripe`/`options-unreachable`) while a required phase-1
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

## Test-harness convention (issue-13)

Each `arch-*-gate` plugin's `tests/run.sh` discovers `tests/fixtures/*/`
generically (`event.json` + `expect.txt`, `pass`/`fail`), invoked via the
repo-root `tests/run-gate-tests.sh`. Since issue-13's remediation, a
fixture directory may additionally carry: an `env.sh` (sourced before the
gate runs, for kill-switch-value fixtures — absent by default, no
behavior change for fixtures without one) and a `{{ABS}}` placeholder in
`event.json` (substituted with that fixture's own resolved absolute path
before piping to the gate, for absolute-`file_path` fixtures). All three
gates now reference `core/hooks/lib/gate-lib.sh`/`gate-lib.py`
(never vendored) for trap-at-top, kill-switch allowlist, JSON
parse-or-deny, path normalization, and `replace_all`-correct
reconstruction — running the suite locally requires
`CLAUDE_PLUGIN_ROOT_CORE` pointed at an installed/checked-out `core`
plugin. See `docs/issue-13/reports/architecture.md` for the landed test
matrix.

### Test-env resolution (issue-22)

Since issue-22, running outside the spawn env no longer produces
misleading FAIL lines. Each `arch-*-gate/tests/run.sh` pre-flight-checks
core reachability via the vendored `tests/lib/test_env_resolve.py` — a
verbatim copy of the on-the-record reference resolver
(`docs/specs/test-env-resolution.md`, issue #551): resolution order is
`$CLAUDE_PLUGIN_ROOT_CORE` (if it contains a non-empty
`hooks/lib/gate-lib.sh`), then the first reachable sibling-checkout
candidate, then **SKIP** — printed to stderr, exit `75`
(`EX_TEMPFAIL`), never folded into a FAIL. `tests/run-gate-tests.sh`
treats a sub-runner's exit `75` as SKIP (counted separately from
`fail=1`) and itself exits `75` when every sub-runner skipped and none
ran or failed. Do not modify `tests/lib/test_env_resolve.py`
independently of the on-the-record source — changes belong upstream
first.
