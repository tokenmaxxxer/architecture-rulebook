---
subject: issue-10
role: architecture
loop_state: scope-proposed
---

# Proposal: turn issue-1's adopted methodology into an enforcement mechanism

## Request (paraphrased intent)

Issue #10 says issue-1's maturation left the adopted methodology as one
directive summary line plus a phase-2-only content gate
(`adr-gate.sh`) — real, but partial. It asks this role to (1) deepen the
directive text per phase into stages/judgment-criteria/prohibitions at
facet granularity, (2) add a **methodology gate** that mechanically
checks the required PRODUCES elements of the approved norm, with state
tracking if the methodology has an order constraint (survey → evidence →
proposal, in this role's case), (3) add gate tests under a `tests/`
directory, and (4) add agents/checklists if a repeated procedure is
warranted — matched to the rigor level the issue calls "hook-machine,"
and constrained to reference core's canon only, never vendor it.

See `docs/issue-10/reports/architecture/survey.md` for the current-state
read and `docs/issue-10/reports/architecture/scout-brief.md` for the
scouted pattern this proposal builds on.

## Constraints

- **Phase-1 only.** This document is a design spec. No hook file, no
  test file, no directive-text edit ships in this PR. Everything under
  "Design (for phase 2)" below is a precise spec for phase 2, applied
  only after a human `APPROVE issue-10/architecture`.
- **Canon-reference only, never vendor** (issue body's `캐논 참조만·복사
  금지`, and this repo's own issue-5 precedent). The new phase-1 gate
  must cite `core`'s canon location/mechanism by pointer (e.g.
  `core/hooks/tests/stub-check.sh`, `core`'s generic
  `record-fields-gate.sh`) and must not copy either their code or the
  external `pricing-rulebook`'s `methodology-gate.sh` code — only its
  *shape* is adopted, per the scout-brief.
- **`write_scope` and role boundary are unchanged.** This proposal does
  not touch `WRITE_SCOPE: ["docs/issue-<n>/decisions/**"]`, the
  `HAND-OFF`/`BOUNDARY CASE` text, or any other role's territory.
- **Additive to `adr-gate.sh`, not a replacement.** The existing
  phase-2 gate stays; this proposal only adds phase-1 coverage and
  closes one phase-2 gap the scout-brief names (resulting-content
  computation for `MultiEdit`/unresolvable edits).
- **Naming discipline.** Any new gate filename must avoid
  `stub-check.sh`'s reserved core-canon names (`record-fields-gate.sh`,
  `trailer-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
  `stub-check.sh` itself), per issue-1's already-hit collision.

## Design (for phase 2 — spec only)

### 1. Directive deepening (facet-level, phase-split)

Today's single `PRODUCES` string in `directive.sh` stays as the
one-line summary `core_role_directive` already expects (its signature is
fixed by core canon and this proposal does not ask core to change it).
What deepens is a **new phase-1/phase-2 facet document**,
`docs/handbooks/architecture-methodology.md` (this rulebook's own
handbook, not a core-canon file — handbooks are per-role per
`core`'s handbook-trigger-gate convention already referenced in the
README), containing:

- **Phase 1 facet** — stages: (a) survey current-state +external
  research, (b) scout-brief (skip only if the spec leaves no design
  decision open — issue-1's own skip-condition text, carried forward
  verbatim), (c) proposal citing both by path. Judgment criteria: a
  proposal is "ready" only if every claim sourced from outside this repo
  carries a URL or a `Sources:` entry (issue-1's citation-format rule,
  now generalized to this role's every future proposal, including this
  one). Prohibitions: no proposal may restate survey findings inline
  instead of citing the survey path; no phase-1 PR may contain any hook,
  gate, or test file edit (draft text only).
- **Phase 2 facet** — stages: (a) write the ADR-shaped
  `docs/issue-<n>/reports/architecture.md` record with the four required
  ADR sections plus a C4-level diagram, (b) run the phase-1-gate and
  phase-2-gate (`adr-gate.sh`) locally before requesting merge, (c) note
  in the record's "Open findings" any known gate limitation (mechanical,
  not semantic checks — proportionality already established in
  issue-1). Judgment criteria: a record is "landed"-ready only once both
  gates pass with no bypass env var set. Prohibitions: no phase-2 record
  may set `loop_state: landed` while a required phase-1 artifact
  (survey/scout-brief/proposal) for the same `issue-<n>` is absent —
  this is the new ordering rule the phase-1 gate (below) will enforce
  mechanically, not just document.

Before/after snippet (`directive.sh`'s `PRODUCES` argument — unchanged
text, since the facet detail lives in the new handbook, not this string;
listed here to make explicit that *no* directive.sh edit is proposed):

```
# unchanged:
"PRODUCES (required record fields): ADR (context/decision/consequences/alternatives-considered), C4 context/container boundary diagram. WRITE_SCOPE: [\"docs/issue-<n>/decisions/**\"]"
```

A new fifth `core_role_directive` argument does not exist in core's
current call signature; rather than requesting a cross-repo core-canon
change (out of scope, same reasoning issue-1's proposal used for its
option (b)), this proposal keeps the deepened stage/criteria/prohibition
text in the handbook file, and has `directive.sh`'s existing text
(unchanged) point to it by adding one clause: `"...WRITE_SCOPE: [...].
See docs/handbooks/architecture-methodology.md for phase-1/phase-2
stage detail."` — the only `directive.sh` line-text change this proposal
asks for.

### 2. Methodology gate (phase-1 coverage + phase-2 gap close)

New file: `architecture/hooks/phase1-gate.sh` (name chosen to avoid
`stub-check.sh`'s reserved list, mirroring the `adr-gate.sh` precedent).

- **Fires on**: `Write|Edit|MultiEdit` where `file_path` matches
  `docs/issue-<n>/reports/architecture.md` (mirrors `adr-gate.sh`'s
  target).
- **Checks, before allowing `loop_state` to leave
  `scope-proposed|proposed`**: that
  `docs/issue-<n>/reports/architecture/survey.md`,
  `docs/issue-<n>/reports/architecture/scout-brief.md` (unless that
  proposal's own text carries an explicit scout-skip note, matching
  issue-1's skip-condition language — checked by grep for a
  `scout-brief` mention plus a skip justification string), and at least
  one `docs/issue-<n>/proposals/*.md` file **exist on disk** (existence
  check, not content re-parsing of the phase-1 gate's own targets — the
  phase-1 gate that will separately validate those files, see next
  bullet, is a distinct concern from the phase-2 report gate re-deriving
  it).
- **State tracking for ordering**: rather than a new state-machine file,
  reuse the existing `loop_state` frontmatter convention already present
  in every record/proposal (per issue-1's confirmed "no genuine
  per-role terminal-state precedent" finding, this proposal does not
  invent a new terminal state either) — the ordering constraint becomes
  a **file-existence precondition** gated by the *target* file's own
  `loop_state`, exactly the mechanism `adr-gate.sh` already uses for its
  content check. This keeps state tracking as cheap as this repo's
  existing gates, per the scout-brief's "skip the pricing gate's
  full path-resolution scaffolding" call.
- **A second, separate check** on `Write|Edit|MultiEdit` to
  `docs/issue-<n>/proposals/*.md` itself: requires the required-sections
  list issue-1's own norm already states (Request, Constraints,
  substantive content, Rationale, Open questions, How success will be
  judged, Files) plus a `Sources:` list or inline URL whenever the
  proposal text contains phrases like "industry practice" or
  "well-established" (issue-1's citation-format rule, made mechanical).
- **Resulting-content computation**: adopt the scout-brief's "adopt"
  pattern — compute the resulting text for `Write`/`Edit`/`MultiEdit`
  before judging it (closing `adr-gate.sh`'s current `MultiEdit` gap in
  the same PR, as a small additive fix to the existing file, not a
  rewrite) — and **fail closed** (non-zero exit) when the resulting
  content cannot be determined, matching the scout-brief's must-be.
- **Where it hooks in**: a new `PreToolUse` entry in
  `architecture/hooks/hooks.json`, additive alongside the existing
  `SessionStart` and `adr-gate.sh` entries — not a pre-commit or CI
  step, consistent with every existing gate in this repo being a
  `PreToolUse` hook, not a separate CI job (this repo has no CI config
  today; introducing one is out of scope).
- **Canon pointer, not vendor**: the gate's header comment cites
  `core`'s generic `record-fields-gate.sh` (referenced via `core`'s own
  global `hooks.json` registration, per README) as the layer this file
  sits additively on top of, exactly as `adr-gate.sh`'s header already
  does — no core script body is copied.
- **Kill switch**: `ARCHITECTURE_PHASE1_GATE_OFF=1`, matching this
  repo's existing naming convention.

### 3. Gate test design (`tests/` layout — plan only, no working tests yet)

New top-level directory `tests/` (repo root, not inside `architecture/`,
since these test both `adr-gate.sh` and the new `phase1-gate.sh` as a
pair and are not plugin-runtime files themselves):

- `tests/run-gate-tests.sh` — a small runner invoking each `*-gate.sh`
  against synthetic `PreToolUse` JSON payloads (stdin), asserting exit
  codes.
- `tests/fixtures/phase1-gate/pass-full-sequence/` — survey.md +
  scout-brief.md + proposal.md all present, report `loop_state:
  landed` → gate must exit 0.
- `tests/fixtures/phase1-gate/fail-missing-survey/` — no survey.md,
  report `loop_state: landed` → gate must exit 1 (or 2, matching
  whatever fail-closed convention phase 2 settles on) with a message
  naming `survey.md` as missing.
- `tests/fixtures/phase1-gate/fail-missing-scout-brief-no-skip-note/` —
  survey.md present, no scout-brief.md, and no skip-justification string
  in the proposal → gate must fail.
- `tests/fixtures/phase1-gate/pass-scout-skip-justified/` — no
  scout-brief.md, but proposal text contains the skip-justification
  language → gate must exit 0.
- `tests/fixtures/adr-gate/pass-all-sections/` and
  `tests/fixtures/adr-gate/fail-missing-alternatives/` — regression
  fixtures for the *existing* `adr-gate.sh`, since no test currently
  exists for it at all (survey finding); adding these closes that gap
  without changing `adr-gate.sh`'s logic.
- `tests/fixtures/adr-gate/fail-multiedit-unresolvable/` — exercises the
  scout-brief's adopted "cannot determine resulting content → deny"
  fix, once phase 2 lands it.

Phase 2 must decide the exact JSON payload shape/harness language
(bash+jq vs. a small python harness, matching whichever `phase1-gate.sh`
itself ends up using) — not fixed here.

### 4. Agents/checklists

The survey→scout-brief→proposal sequence is exactly the "repeated
procedure" issue #10 flags as agent/checklist-worthy. This proposal
recommends a checklist document (not a subagent — no tool-use loop is
needed, this is a documentation checklist), living beside the new
handbook: `docs/handbooks/architecture-phase1-checklist.md`, a short
ordered checklist (survey exists and cites sources → scout-brief exists
or skip is justified → proposal cites both by path and states Files/How-
success sections → ready for APPROVE) that a session reads before
opening a phase-1 PR. No new `agents/` subagent is proposed — this
role's `YOU DECIDE` does not involve a bounded search/hunt task the way
`warrant-hunter` does, so a full subagent would be overhead beyond what
a checklist doc provides (matches the proportionality argument issue-1's
proposal already used against TOGAF/arc42 weight).

## Rationale

The phase-2 gate (`adr-gate.sh`) already proved this repo's gate style
works and is cheap; the honest gap issue #10 is pointing at is that the
*same* rigor was never extended to phase-1, and nothing enforces that
phase-1 happened at all before a phase-2 record can claim `landed`.
Reusing `loop_state` + file-existence checks (rather than inventing a
new state-machine or importing the external pricing-rulebook's full
path-resolution scaffolding) keeps the enforcement mechanism
proportionate to what this single-plugin repo actually needs, per the
scout-brief's explicit "pattern to skip" call — new machinery should
close a real gap (ordering, phase-1 element checks, tests), not add
generality this repo has no use for.

## Open questions for the human approver

1. **Whether `phase1-gate.sh`'s existence check should also validate
   survey/scout-brief *content* (not just existence)**, or whether
   content validation of those two files is deferred to a later issue.
   This proposal recommends existence-only for phase 2's first cut,
   content-checking as a stated future enhancement, to keep phase 2's
   scope bounded.
2. **Whether the scout-brief skip-justification string match should be
   a fixed phrase list (cheap, brittle) or left to human review at
   APPROVE time (no mechanical check at all for the skip path).** This
   proposal recommends the fixed phrase-list approach for consistency
   with every other gate in this repo, but flags that it is the
   weakest-verified part of the design.
3. **Whether closing `adr-gate.sh`'s `MultiEdit` resulting-content gap
   belongs in this same phase-2 PR or a separate one**, since it touches
   an already-landed file rather than only adding new ones.

## How success will be judged

- `architecture/hooks/phase1-gate.sh` exists, is registered in
  `hooks.json`, cites `core`'s canon location by pointer only (grep
  shows no core script body duplicated), and demonstrably fails closed
  against a `docs/issue-<n>/reports/architecture.md` write missing a
  phase-1 artifact, and passes once all three phase-1 artifacts exist.
- `tests/run-gate-tests.sh` runs both gates against the fixtures listed
  above and reports pass/fail per fixture; at least one pass and one
  fail fixture exist per gate.
- `docs/handbooks/architecture-methodology.md` and
  `docs/handbooks/architecture-phase1-checklist.md` exist and are cited
  from `directive.sh`'s (unchanged-shape) `PRODUCES` string.
- This proposal's own phase-1 artifacts (this file, the survey, the
  scout-brief) satisfy the very citation/structure norm they describe —
  self-applying, per issue-1's precedent.

## Files (write set, once approved — phase 2 only)

- `architecture/hooks/phase1-gate.sh` (new)
- `architecture/hooks/adr-gate.sh` (small additive fix: resulting-content
  computation for `MultiEdit`, fail-closed on unresolvable edits)
- `architecture/hooks/hooks.json` (new `PreToolUse` entry)
- `docs/handbooks/architecture-methodology.md` (new)
- `docs/handbooks/architecture-phase1-checklist.md` (new)
- `tests/run-gate-tests.sh` and `tests/fixtures/**` (new)
- `architecture/.claude-plugin/plugin.json` / `README.md` (kept in sync
  with the new gate file and handbook references)
- `docs/issue-10/reports/architecture.md` (phase-2 record, not created by
  this PR)

## PHASE-1 STATUS

This proposal is **phase-1 output**. It awaits a human
`APPROVE issue-10/architecture` (per `docs/specs/approvers.md`) before
any phase-2 implementation — hook script, test file, or handbook file —
is written.
