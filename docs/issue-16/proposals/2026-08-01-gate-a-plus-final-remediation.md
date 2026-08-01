---
subject: issue-16
role: architecture
loop_state: proposed
---

# Proposal: 게이트 A+ 최종 마감 — 재감사 잔여 결함 보수 (issue #16)

## Request (paraphrased intent)

Issue #16's re-audit (2026-08-01, grade B) lists five residual defects
after issue-13's remediation attempt: `compliance-check` execution
record missing, trap-at-top absence (fail-open), `ARCHITECTURE_CYCLE_OFF`
undocumented-as-implemented, `일반적으로` Korean over-rejection, one URL
exempting every claim. It also requires hooks.json-matcher/code parity,
a missing-core test case, full suite green + a recorded compliance-check
pass, and zero old-role-name/ghost-file residue in README/manifest.
Preconditions (core #75, on-the-record #182) are landed — see
`docs/issue-16/reports/architecture/survey.md`.

## Constraints

- Phase-1 only — no hook file, no test fixture, no README edit ships in
  this PR. Everything under "Fix designs" is a phase-2 spec, applied
  only after `APPROVE issue-16/architecture`.
- Canon-reference only, never vendor `gate-lib.sh`/`gate-lib.py` (issue-10
  precedent, restated in issue-13's proposal).
- Survey confirms README/manifest already have zero ghost-file/old-role-
  name residue (requirement #4's negative check passes today) — this
  proposal does not invent README changes beyond what fix designs #1-#5
  below make newly true.
- PR #15 (`issue-13/architecture`, open, unmerged) contains prior work
  this proposal builds on directly rather than re-deriving: its
  `gate_reconstruct_write`/`gate_normalize_path`/`gate_parse_json_or_deny`
  wiring, its `replace_all` fixtures, and its citation section-adjacency
  scoping are correct and adopted as-is (verified against `core-main` in
  the survey — API names match exactly). Only the confirmed-still-broken
  parts below are respecified.

## Fix designs

### 1. `||`-guard the `gate-lib.sh` source line (fixes: trap-at-top/fail-open, compliance-check FAIL)

All three gates' source line changes from PR #15's unguarded form to
core's own mandated shape (`core/hooks/lib/gate-lib.sh:18`, verbatim
pattern):

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail
```

The `||` branch itself is what makes a missing/unreachable core fail
closed (exit 2, blocking) instead of fail-open (exit 127, non-blocking)
— `gate_trap_fail_closed` never gets a chance to install if sourcing
failed, so the guard on the source line is the only thing that can catch
that specific failure mode. Applies to
`arch-adr-content-gate/hooks/adr-content-gate.sh`,
`arch-citation-gate/hooks/citation-gate.sh`,
`arch-sequence-gate/hooks/sequence-gate.sh`.

### 2. Missing-core test fixture, per gate

New fixture per plugin (mirroring core's own `run-gate-lib-tests.sh`
group 7 shape) that sets `CLAUDE_PLUGIN_ROOT_CORE` to a nonexistent path
via `env.sh` (the per-fixture env mechanism PR #15's `run.sh` diff
already added) and expects `fail` (exit 2), proving fix design #1's
guard actually denies rather than silently allowing. One fixture per
plugin: `arch-adr-content-gate/tests/fixtures/fail-missing-core/`,
`arch-citation-gate/tests/fixtures/fail-missing-core/`,
`arch-sequence-gate/tests/fixtures/fail-missing-core/`.

### 3. `ARCHITECTURE_CYCLE_OFF` — implement it (resolve issue-13's punted open question)

Decision: implement, not remove-as-stray-doc. Rationale: it is the only
role-level `SessionStart` circuit breaker this role's directive already
advertises to a human operator (the comment predates issue-13, and
`docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md` references
the same intent) — removing the comment without ever having built the
switch it promises silently ships a lesser role directive than what's
already documented as the contract, and issue #16 (unlike issue-13)
explicitly re-lists it as a defect to fix, not a question to re-punt.

`architecture/hooks/directive.sh` gains a guard before
`core_role_directive(...)` is called, using core's own
`gate_kill_switch_active` (already the canon convention for every other
kill switch in this repo, imported the same way the gates import it):

```bash
#!/usr/bin/env bash
# SessionStart: architecture's role directive...
# Kill switch: export ARCHITECTURE_CYCLE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "architecture/directive.sh: cannot source gate-lib.sh" >&2; exit 0; }
gate_kill_switch_active "${ARCHITECTURE_CYCLE_OFF:-}" || exit 0
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh" || { echo "architecture/directive.sh: cannot source role-directive.sh" >&2; exit 0; }
core_role_directive "..." "..." "..." "..."
```

Note the missing-core fallback here is `exit 0` (fail-open), not `exit
2` — deliberately different from the three `PreToolUse` gates. A
`SessionStart` directive is advisory context injection, not an access
gate; a `PreToolUse` gate failing closed protects against an unreviewed
write landing, while a `SessionStart` hook failing closed would only
block the session from starting at all with no write-side benefit. This
asymmetry is stated explicitly here so phase-2 doesn't "fix" it into
matching the gates' fail-closed posture by mistake.

### 4. Narrow `일반적으로` out of `TRIGGER_PHRASES`, replace with a claim-shaped pattern

Remove the bare `일반적으로` string trigger. Replace with a pattern that
requires the word to co-occur with an authority-claim marker within the
same clause, matching the English trigger phrases' own shape (they are
already multi-word claims — "industry practice", "well-established" —
not single common words): `일반적으로\s*(쓰이는|사용되는|채택되는|알려진|받아들여지는)` (i.e. "generally
*used*/*adopted*/*known*/*accepted*" — a genuine industry-practice
assertion) in addition to keeping `업계 표준`/`널리 쓰이는` as-is (those
are already unambiguous claim phrases, not ordinary connectives).
`일반적으로` alone (e.g. "일반적으로 이렇게 본다", "일반적으로 낫다")
no longer triggers. This is a Sources-of-truth-preserving narrowing, not
a removal of the citation norm — an actual "generally adopted practice"
claim in Korean still requires a citation; a stylistic connective no
longer does.

### 5. Bash-write-bypass: either wire the matcher or drop the dead branch — wire it

`arch-sequence-gate/hooks/hooks.json`'s matcher changes from
`"Write|Edit|MultiEdit"` to `"Write|Edit|MultiEdit|Bash"`, making PR
#15's already-fixture-tested `tool == "Bash"` branch reachable in
production. (The alternative — deleting the Bash branch and its two
fixtures — was considered and rejected: the branch is the only guard
against the exact bypass issue-13's proposal named as a real gap,
deleting it to make the matcher/code pair trivially consistent would
regress coverage rather than fix the mismatch.) `arch-citation-gate` and
`arch-adr-content-gate` keep their `Write|Edit|MultiEdit`-only matchers
unchanged — they have no Bash branch, so no mismatch exists there;
adding `Bash` to their matcher would fire the hook on every Bash call
for no purpose (their gate exits 0 immediately since `tool not in
(...)`, but a no-op invocation on every Bash call is unnecessary
overhead this proposal declines to add without a corresponding check to
justify it).

### 6. Compliance-check: run it, record the result

Phase 2's implementation report
(`docs/issue-16/reports/architecture.md`) must include the literal
output of:

```bash
core/hooks/tests/compliance-check.sh architecture/hooks
core/hooks/tests/compliance-check.sh arch-adr-content-gate/hooks
core/hooks/tests/compliance-check.sh arch-citation-gate/hooks
core/hooks/tests/compliance-check.sh arch-sequence-gate/hooks
```

(one invocation per plugin's `hooks/` dir, per compliance-check.sh's own
usage contract — it globs `*-gate.sh` under the given dir) run against
the fully-fixed code from designs #1-#5, all four exiting 0. This closes
issue #16's "compliance-check 실행 기록 보완" item by creating the first
recorded run, not amending a prior one (survey confirms none exists).

### 7. README

Once designs #1-#6 land, `README.md`'s "Layout" section gains one
sentence noting all `arch-*-gate` hooks now carry the trap-at-top
guarantee via `core`'s `gate-lib.sh` (guarded source) and that
`arch-sequence-gate`'s matcher additionally covers `Bash`. No other
README/manifest change — survey confirms nothing else is stale.

## Disposition of PR #15 (open question below, not decided here)

This proposal's fix designs are written to apply on top of PR #15's
already-correct parts (gate-lib wiring shape, `replace_all` handling,
citation section-adjacency, existing 23 fixtures) rather than
re-implementing them, but PR #15 lives on branch `issue-13/architecture`
and this issue's branch is `issue-16/architecture` (contract v3: one
branch per issue×role, never shared). Phase 2 must therefore either (a)
cherry-pick/port PR #15's correct diff onto `issue-16/architecture` and
layer designs #1-#7 on top, closing PR #15 as superseded, or (b) wait
for a human to land PR #15 to `main` first and rebase. See open question
below — this proposal does not resolve which, since it is a merge-
sequencing call for the human approver, not an architecture decision.

## Mandatory test matrix (phase 2 acceptance)

Builds on PR #15's already-specified 23-fixture matrix (issue-13
proposal), adding exactly the fixtures this proposal's fix designs
require:

| Fixture | Plugin(s) | Purpose |
|---|---|---|
| `fail-missing-core` | all three gates | proves fix #1's `||` guard denies, not silently allows |
| `fail-korean-connective-no-claim` | arch-citation-gate | "일반적으로 이렇게 본다" (no claim-shaped co-occurrence) must PASS (no longer a false positive) |
| `fail-korean-claim-unsourced` | arch-citation-gate | "일반적으로 사용되는 방식이다" with no URL/Sources must still FAIL |
| `pass-bash-write-via-matcher` / `fail-bash-write-bypass` (already exists) | arch-sequence-gate | with fix #5's matcher change, confirm the existing fixture's `bash "$gate" < event.json` direct-invocation result now also matches what the hooks.json matcher would actually dispatch (i.e. the fixture is no longer testing dead code) |

**Acceptance criterion: `bash tests/run-gate-tests.sh` green (exit 0,
all fixtures PASS) at ship, plus the four `compliance-check.sh`
invocations from fix design #6 each exiting 0, both reported verbatim in
`docs/issue-16/reports/architecture.md`.**

## Open questions for the human approver

1. **PR #15 disposition** (see section above): port its diff onto
   `issue-16/architecture` and close #15 as superseded, or land #15 to
   `main` first and have phase 2 rebase onto that? This proposal's fix
   designs are written to be correct either way, but phase 2 needs one
   answer before it starts, not mid-implementation.
2. **`ARCHITECTURE_CYCLE_OFF` fail-open-on-missing-core choice** (fix
   design #3): confirm the `SessionStart`/`PreToolUse` fail-open/
   fail-closed asymmetry stated there is intended, not an oversight.
3. **Korean trigger-phrase co-occurrence list** (fix design #4): the
   four verbs listed (쓰이는/사용되는/채택되는/알려진/받아들여지는) are a
   judgment call on what counts as a genuine industry-practice claim in
   Korean, not a load-bearing exact set — confirm or adjust at phase 2.

## How success will be judged

- All five of issue #16's named defects have an applied fix (compliance-
  check record created; trap-at-top guard closes the fail-open path;
  `ARCHITECTURE_CYCLE_OFF` implemented; `일반적으로` false-positive
  fixed without weakening the genuine-claim check; URL-exemption already
  fixed by PR #15's section-scoping, carried forward).
- `arch-sequence-gate/hooks/hooks.json`'s matcher and its gate code's
  tool coverage are identical in practice — no advertised/tested branch
  is unreachable at runtime.
- A missing-core fixture exists and passes (fails closed) for every gate.
- `tests/run-gate-tests.sh` is green with the full matrix, and all four
  `compliance-check.sh` invocations exit 0 — both outputs shown verbatim
  in the phase-2 record, not summarized as "tests pass."
- README/manifest ghost-file check stays at zero (already true; phase 2
  must not regress it).

## Files (write set, once approved — phase 2 only)

- `arch-adr-content-gate/hooks/adr-content-gate.sh`, `arch-citation-gate/hooks/citation-gate.sh`, `arch-sequence-gate/hooks/sequence-gate.sh` (guarded source, fix designs #1)
- `arch-sequence-gate/hooks/hooks.json` (matcher fix #5)
- `architecture/hooks/directive.sh` (fix #3)
- `arch-citation-gate/hooks/citation-gate.sh` (trigger-phrase narrowing, fix #4 — same file as #1, listed separately for clarity)
- `arch-*-gate/tests/fixtures/**` (new fixtures per the matrix)
- `README.md` (fix #7)
- `docs/issue-16/reports/architecture.md` (phase-2 record, not created by this PR)

Sources:
- `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py`, `core/hooks/tests/compliance-check.sh`, `core/hooks/tests/run-gate-lib-tests.sh` (`tokenmaxxxer-core@52bdc15`, `main`) — landed canon this proposal applies by reference
- `docs/issue-16/reports/architecture/survey.md` (this repo) — current-state read each fix design responds to
- `docs/issue-13/proposals/2026-08-01-gate-a-plus-remediation.md` (this repo, merged to `main`) — prior spec this proposal builds on and narrows
- https://github.com/tokenmaxxxer/architecture-rulebook/pull/15 — unmerged prior implementation, audited directly (diff read in full) rather than trusted from its description
