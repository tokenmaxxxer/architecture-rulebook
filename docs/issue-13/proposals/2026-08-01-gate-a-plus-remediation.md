---
subject: issue-13
role: architecture
loop_state: proposed
---

# Proposal: remediate the "grade B" gate audit toward fail-closed, allowlist-secure gates (issue #13)

## Request (paraphrased intent)

Issue #13's audit grades this rulebook's three `PreToolUse` gates "B"
and lists concrete defects: no trap-at-top (internal errors fail open),
a documented-but-unimplemented `ARCHITECTURE_CYCLE_OFF` kill switch,
citation-gate's semantic check being naive whole-file substring
matching, and asks for absolute-path normalization, fail-closed
everywhere, full `Edit`/`MultiEdit`/`replace_all` reconstruction, deny
reasons routed to stderr, semantic checks upgraded to
section/adjacency/structural scoping, a mandatory test matrix, and a
reconciled README. See `docs/issue-13/reports/architecture/survey.md`
for the current-state read (each defect verified against actual code)
and `docs/issue-13/reports/architecture/scout-brief.md` for the scouted
pattern choices this proposal applies.

## Blocker: core issue #72 ("게이트 하우스 표준") is open, `gate-lib.sh` does not exist

Issue #13 asks this remediation to build on a shared library,
`core/hooks/lib/gate-lib.sh`, from `tokenmaxxxer-core` issue #72. That
issue is confirmed still **open** (checked via `gh issue view 72
--repo tokenmaxxxer/tokenmaxxxer-core`), and `gate-lib.sh` is absent
from this checkout entirely (survey, "Blocker" section). Issue #13
explicitly instructs this rulebook to **reference** the shared library,
never reimplement it — the same "canon-reference only, never vendor"
discipline issue-10's proposal already established for `core`'s generic
`record-fields-gate.sh` (`docs/issue-10/proposals/
2026-07-31-architecture-enforcement.md`, Constraints section).

This proposal therefore does **not** attempt to write a local
`gate-lib.sh`-equivalent trap-at-top helper, and does not vendor one.
Two compliant paths forward for phase 2, both consistent with the
"reference, don't reimplement" instruction:

1. **Wait-and-recheck.** At phase-2 kickoff, re-check core issue #72's
   status. If landed, phase 2 sources `gate-lib.sh` from the `core`
   plugin installation (matching how `architecture/hooks/directive.sh`
   already sources `core/hooks/lib/role-directive.sh` today) and applies
   its trap-at-top helper to all three gates in this repo.
2. **Escalate, don't improvise.** If #72 is still open at phase-2
   kickoff, escalate to the human approver rather than silently
   substituting a local reimplementation. Waiting or escalating is the
   only compliant path — locally reimplementing `gate-lib.sh` is
   explicitly out of bounds per the issue's own instruction, even though
   it is technically straightforward (a `trap` one-liner) and it would
   be tempting to "just write the five lines." This proposal names that
   temptation and rejects it: the point of a shared gate-house library
   is that all rulebooks in the tokenmaxxxer family get the same
   trap-at-top guarantee from one audited source, not N slightly
   different reimplementations.

Everything below that depends on `gate-lib.sh` (the trap-at-top design)
is therefore written as a **spec conditioned on #72 landing**, not an
applied change; everything that does not depend on it (kill-switch
allowlist convention, citation-gate semantic scoping, Bash-bypass
heuristic, README reconciliation, test matrix) can proceed in phase 2
regardless of #72's status and is written as a normal spec.

## Constraints

- Phase-1 only — no hook file, no test file, no README edit ships in
  this PR. Everything under "Fix designs" is a spec for phase 2, applied
  only after a human `APPROVE issue-13/architecture`.
- Canon-reference only, never vendor (issue-10's precedent, restated
  above for the trap-at-top piece specifically).
- Additive/corrective to the three existing gates, not a rewrite of
  their working logic (resulting-content computation for `Write`/`Edit`/
  `MultiEdit`, the `loop_state`-gated firing condition, the glob
  matching) — survey confirms that logic is already correct and green
  on 9/9 fixtures; this proposal touches only the confirmed-defective
  parts.
- No change to `write_scope`, `HAND-OFF`/`BOUNDARY CASE` text, or any
  other role's territory.

## Fix designs (per confirmed defect — phase 2 spec only)

### 1. Trap-at-top wrapper (blocked on core issue #72)

Once `gate-lib.sh` exists and is sourced (path 1 above), each of the
three gate scripts adds, immediately after the shebang and before any
other logic:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"
gate_fail_closed_trap   # gate-lib.sh's helper; exact function name TBD
                         # by #72's landed API, not fixed here
set -uo pipefail
```

The helper's contract (spec, not implementation — #72 owns the
implementation): install a `trap ... ERR`/`trap ... EXIT` combination
that inspects the pending exit status and, for any non-zero code other
than an already-deliberate `exit 2`, rewrites it to `exit 2` and prints
a fixed `"<gate>: fail-closed: internal error (see above)"` line to
stderr before exiting. This closes the exact gap the survey traced: an
uncaught Python exception inside the `python3 <<'PY'` heredoc currently
exits 1 (non-blocking per Claude Code's hook contract, see
`docs/issue-13/reports/architecture/scout-brief.md`'s `Sources:`), and
after this change it would exit 2 (blocking) instead.

### 2. Kill-switch allowlist convention (not blocked — proceeds independently)

Applied to all three existing kill switches
(`ARCH_ADR_CONTENT_GATE_OFF`, `ARCH_CITATION_GATE_OFF`,
`ARCH_SEQUENCE_GATE_OFF`, and the deprecated alias
`ARCHITECTURE_ADR_GATE_OFF`), replacing the current denylist `case`
pattern with an allowlist that defaults to "gate stays ACTIVE":

```bash
case "${ARCH_CITATION_GATE_OFF:-}" in
  ""|0|false|no|off) ;;                 # recognized "gate active" values
  1|true|yes|on) exit 0 ;;              # recognized "gate disabled" values only
  *) : ;;                               # unrecognized -> gate stays ACTIVE (fall through)
esac
```

Note the first branch list above (`""|0|false|no|off`) is today's
existing "gate active" set — that's unchanged; what changes is that the
second branch (values that actually disable the gate) becomes an
explicit finite list instead of the current `*) exit 0` catch-all, and
the catch-all (`*`) becomes a no-op that falls through to normal
gate-active execution. A typo like `ARCH_CITATION_GATE_OFF=1x` no longer
silently disables the gate.

`ARCHITECTURE_CYCLE_OFF` is out of scope for this fix specifically: it
is not a gate kill switch (no `PreToolUse` gate reads it today — survey
finding (b)), it is a `SessionStart`-directive-only concept documented
in `architecture/hooks/directive.sh`. This proposal does not add a new
implementation for it, since doing so is outside the three gates issue
#13 audited and would be new scope, not remediation of an audited
defect; flagged as an open question below instead.

### 3. Citation-gate semantic upgrade: whole-file substring -> section-adjacency scoping

Replace `citation-gate.sh`'s current two independent whole-file checks
(`TRIGGER_PHRASES` match anywhere, `has_url`/`has_sources` anywhere —
`citation-gate.sh:105-114`) with a single pass that scopes both to the
same **section block**, where a section block is defined as the text
between one Markdown heading line (`^#{1,6}\s`) and the next (or EOF).
For each occurrence of a trigger phrase, the check looks for a URL or a
`Sources:` line only within that same block (or, as a bounded fallback
when no heading structure exists in the file at all, within N lines —
e.g. 15 — of the match, per the scout-brief's "adjacency" pattern).
Deny only when a specific trigger-phrase occurrence has no qualifying
citation nearby; the deny message names the specific line/section, not
just "this file." This directly fixes the `일반적으로` false-positive
and the "one URL anywhere exempts everything" over-permissiveness the
survey confirmed (survey defect (c)).

### 4. Bash-tool-write-bypass: conservative bounded scope

Add a narrow, explicitly-bounded check (not general shell parsing) to
each gate's `tool not in (...)` branch: when `tool_name == "Bash"`,
inspect `tool_input.command` for a literal `>`, `>>`, or `tee` token
immediately followed by (optionally quoted) whitespace and a path
string that, after the same `abs_path`/`rel` normalization already used
for `Write`/`Edit`/`MultiEdit`, matches the gate's own target glob. If
matched, treat it exactly like an unresolvable `Write` (fail closed —
`gate-lib.sh`'s trap or the existing `fail_closed()` path once #72
lands) rather than trying to reconstruct resulting content from a shell
command, since resulting-content computation for arbitrary shell
pipelines is out of scope. Everything the heuristic does not recognize
(command substitution, `eval`, multi-command chains via `&&`/`;`,
here-docs, `python3 -c` writing files, etc.) is explicitly **not**
covered by this fix and is deferred to core issue #72's guidance on
whether a shared, more general Bash-write detector belongs in
`gate-lib.sh` rather than being reimplemented three times in this repo.

### 5. Deny reasons to stderr, not stdout

Survey confirms this is **already correct** in all three gates: every
`deny()`/`fail_closed()` call writes via `sys.stderr.write(...)`
(`adr-content-gate.sh:49-55`, `citation-gate.sh:31-37`,
`sequence-gate.sh:38-44`), and the bash-level early-exit messages also
use `>&2` (e.g. `adr-content-gate.sh:41,44`). No fix needed here; listed
for completeness since issue #13 named it explicitly.

### 6. Full `Edit`/`MultiEdit`/`replace_all` reconstruction

Survey confirms `Edit` and `MultiEdit` resulting-content computation is
already implemented correctly in all three gates (single
`old_string`->`new_string` replace for `Edit`; sequential per-edit
replace with fail-closed-on-unresolvable for `MultiEdit` — e.g.
`adr-content-gate.sh:96-113`). What is **not** covered is `replace_all`:
none of the three gates' `Edit`/`MultiEdit` branches inspect a
`replace_all` field on `tool_input` at all. Today, `str.replace(o, n2,
1)` always replaces only the *first* occurrence, regardless of what the
actual tool call requests. If a real `Edit` call sets
`"replace_all": true`, the gate's resulting-content computation would
silently diverge from what the tool actually produces (checking only a
single-occurrence-replaced text while the real edit replaces every
occurrence), which is a correctness gap, not merely a missing test.
Fix: read `ti.get("replace_all")`; when truthy, use
`current.replace(o, n2)` (all occurrences) instead of `current.replace(o,
n2, 1)`, in both the `Edit` and (per-edit) `MultiEdit` branches, across
all three gates.

### 7. README reconciliation

`README.md`'s "Layout" section (repo root) currently describes the
plugin set accurately as of issue-10's landed state but should be
updated once phase 2 lands to additionally state: (a) which gates now
carry a trap-at-top guarantee via `core`'s `gate-lib.sh` (once #72
lands) vs. which are still pending that (if #72 has not landed by the
time other phase-2 fixes ship); (b) the corrected kill-switch semantics
("unrecognized value keeps the gate active," replacing the current
README's silence on this point); (c) a one-line pointer to
`tests/run-gate-tests.sh`'s expanded fixture coverage (test matrix
below). No README text is drafted here since it should reflect the
*actual* landed state, not a speculative one — phase 2 writes it after
the code changes land, not before.

## Mandatory test matrix

Grounded in the actual current fixture sets (survey + this reading of
`tests/run.sh`/`fixtures/` per gate):

| Case | adr-content-gate | citation-gate | sequence-gate |
|---|---|---|---|
| Plain `Edit` (old_string->new_string, no `replace_all`) | Missing — only `Write`-shaped (`pass-all-sections`) and `MultiEdit`-shaped (`fail-multiedit-unresolvable`) fixtures exist today | Missing — only `Write`-shaped fixtures exist (`pass-sourced`, `fail-unsourced-claim`) | Missing — only `Write`-shaped fixtures exist |
| `MultiEdit` (resolvable) | Partially covered (`fail-multiedit-unresolvable` covers the *unresolvable* case only; no resolvable-MultiEdit pass fixture) | Missing entirely | Missing entirely |
| `replace_all: true` | Missing (new case per fix design #6) | Missing | Missing |
| Malformed JSON payload | Missing — no fixture feeds invalid JSON to `event.json` | Missing | Missing |
| Kill switch, recognized OFF value | Missing (no fixture sets `ARCH_ADR_CONTENT_GATE_OFF`) | Missing | Missing |
| Kill switch, unrecognized value (must stay ACTIVE per fix #2) | Missing (new case) | Missing (new case) | Missing (new case) |
| Absolute `file_path` | Missing — all fixtures use relative paths in `event.json` | Missing | Missing |

Every cell above becomes a new fixture directory under the relevant
plugin's `tests/fixtures/`, following the existing
`event.json`+`expect.txt` shape `tests/run.sh` already discovers
generically (no `run.sh` change needed — the runner already globs
`fixtures/*/`). Phase 2's implementation report must show the fixture
count increase per plugin and the final `tests/run-gate-tests.sh` output
naming every new fixture by name.

**Acceptance criterion for phase 2 (not evaluated in this phase-1
PR): the full test suite — `bash tests/run-gate-tests.sh` — must be
green (exit 0, all fixtures PASS) at ship, including every new fixture
in the matrix above.** This phase-1 proposal only confirms the
*current* baseline (9/9 existing fixtures green, survey "Baseline test
result") — it does not and cannot demonstrate the expanded suite, since
no code changes ship in this PR.

## Reference-adoption note

This proposal adopts `core`'s gate-house standard
(`gate-lib.sh` plus `docs/handbooks/gate-house-standard.md`, per issue
#13's description of core issue #72) by reference only, once #72
lands. No part of this proposal vendors or reimplements `gate-lib.sh`
or its handbook; fix design #1 is explicitly written as blocked on that
library existing, and the blocker section above states the only two
compliant paths forward if it is not landed by phase-2 kickoff.

## Open questions for the human approver

1. **`ARCHITECTURE_CYCLE_OFF`**: should phase 2 implement it as a new,
   fourth `SessionStart`-scoped switch (out of scope for the three
   audited `PreToolUse` gates), or should the stray references in
   `architecture/hooks/directive.sh` and
   `docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md` simply be
   removed as documentation of an intent that was never carried through?
   This proposal does not resolve this — it is adjacent to, not inside,
   the three audited gates.
2. **Section-adjacency threshold** for fix #3 (heading-block scoping vs.
   the N-line fallback): this proposal recommends heading-block as
   primary with a 15-line fallback for files with no heading structure,
   but the exact fallback line count is not load-bearing and should be
   confirmed or adjusted at phase 2.
3. **Timing if core issue #72 is still open at phase-2 kickoff**: this
   proposal recommends implementing fix designs #2-#6 (which do not
   depend on #72) in one phase-2 PR now, and deferring only #1
   (trap-at-top) to a follow-up PR once #72 lands, rather than blocking
   all of phase 2 on #72. Confirm this split is acceptable, or state a
   preference to wait for #72 before shipping anything.

## How success will be judged

- Survey's five findings (a)-(e) each have either an applied fix (a, b,
  c, e — modulo #72's blocker for a's specific mechanism) or an explicit
  "already correct, no change" note (d) carried into the phase-2 report.
- All three kill switches use the allowlist convention (#2); a fixture
  proves an unrecognized value keeps each gate active.
- citation-gate's false-positive on `일반적으로`-without-a-nearby-source
  is fixed and has a regression fixture.
- `replace_all: true` is honored in resulting-content computation across
  all three gates, with a fixture.
- `tests/run-gate-tests.sh` is green with the full expanded matrix from
  the table above, reported explicitly in the phase-2 implementation
  report (not just "tests pass").
- `README.md` accurately states the landed kill-switch semantics and
  (if #72 has landed) the trap-at-top guarantee's status.
- No `gate-lib.sh`-equivalent code is vendored anywhere in this repo;
  `grep` for any body resembling one returns nothing.

## Files (write set, once approved — phase 2 only)

- `arch-adr-content-gate/hooks/adr-content-gate.sh` (kill-switch
  allowlist, `replace_all`, trap-at-top once #72 lands)
- `arch-citation-gate/hooks/citation-gate.sh` (kill-switch allowlist,
  `replace_all`, section-adjacency semantic scoping, trap-at-top once
  #72 lands)
- `arch-sequence-gate/hooks/sequence-gate.sh` (kill-switch allowlist,
  `replace_all`, trap-at-top once #72 lands, bounded Bash-write
  heuristic)
- `arch-*-gate/tests/fixtures/**` (new fixtures per the test matrix,
  all three plugins)
- `README.md` (Layout/kill-switch reconciliation)
- `docs/issue-13/reports/architecture.md` (phase-2 record, not created
  by this PR)

Sources:
- `docs/issue-13/reports/architecture/survey.md` (this repo — current-state
  read each fix design above responds to)
- `docs/issue-13/reports/architecture/scout-brief.md` (this repo — pattern
  choices and external sources for the exit-code/kill-switch claims above)
- https://code.claude.com/docs/en/hooks (Claude Code hooks reference —
  exit-code semantics underlying fix design #1)
