---
subject: issue-10
role: architecture
loop_state: scope-proposed
---

# Survey: current-state read for issue #10 (enforcement of adopted methodology)

## What exists today (read from the files, not assumed)

- `architecture/hooks/directive.sh` — one `core_role_directive` call
  sourcing `core/hooks/lib/role-directive.sh`. Its third argument
  (`PRODUCES`) is a single string:
  `"ADR (context/decision/consequences/alternatives-considered), C4
  context/container boundary diagram. WRITE_SCOPE: [...]"`. This is the
  entirety of this role's methodology *directive* text — one line, no
  phase split, no stage/judgment-criteria/prohibition language. It was
  deepened once already by issue-1 (adding `alternatives-considered` and
  naming the C4 level), but it is still a summary line, not the
  facet-level executable text issue #10 asks for.
- `architecture/hooks/adr-gate.sh` — a `PreToolUse` hook on
  `Write|Edit`, scoped only to `docs/issue-<n>/reports/architecture.md`
  (the **phase-2** record). Once `loop_state` leaves
  `scope-proposed|proposed`, it greps for `Context`, `Decision`,
  `Consequences`, `Alternatives Considered` and a C4-diagram marker,
  failing (`exit 1`) if any is absent. This is a real, working
  methodology gate — but its coverage is phase-2-only. **Nothing in this
  repo checks phase-1 artifacts (survey/scout-brief/proposal) for
  required elements, and nothing enforces the *order* survey → scout
  → proposal → APPROVE → phase-2.** A session could write
  `docs/issue-<n>/reports/architecture.md` with `loop_state: landed`
  today without a survey or scout-brief ever existing, and `adr-gate.sh`
  would not notice — it only reads the report file's own content.
- `architecture/hooks/hooks.json` registers `SessionStart` →
  `directive.sh` and one `PreToolUse` entry → `adr-gate.sh`. No other
  hook exists in this plugin.
- No `tests/` directory exists anywhere in this repo (confirmed:
  `find . -iname tests` under the repo root returns nothing outside
  `.git`). There is no gate-test harness of any kind for `adr-gate.sh`
  today; issue-1's report records only a manual, undocumented fixture
  check in prose ("Verification" section), not a runnable test.
- No `agents/` directory exists in this plugin (`architecture/` has only
  `hooks/` and `.claude-plugin/`).
- `docs/issue-5/proposals/stub-check-dedup.md` (landed) establishes this
  repo's precedent for the "reference canon only, do not vendor" rule:
  `architecture/hooks/tests/stub-check.sh` was deleted and replaced by a
  reference-run against `core/hooks/tests/stub-check.sh`; the repo also
  explicitly declined to create a local `docs/handbooks/canon-scripts.md`
  copy, "copying it would itself repeat the anti-pattern this issue
  fixes." Any new gate this proposal designs must keep this shape: cite
  `core`'s canon location, never copy its script bodies or its record-
  fields-gate logic.
- `docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md` (landed,
  per commit `0a65f6d`) is the sibling "implementation" role's precedent
  for moving from vendored per-role gates to core-canon references; it
  does not itself demonstrate a hook-machine of "400+ lines" rigor — it
  is a *removal* of role-specific machinery in favor of core's generic
  gate, the opposite direction from what issue #10 now asks this role to
  do (add role-specific machinery back, deliberately, for phase-1
  coverage this time).
- `docs/issue-1/proposals/2026-07-31-architecture-norms.md` is the
  "immediately-preceding maturation issue" the issue-10 body refers to.
  Its "Plugin-reflection plan" section already anticipated needing a
  role-specific gate distinct from any core-canon filename (the
  `stub-check.sh` reserved-name collision with `record-fields-gate.sh`,
  resolved by naming the phase-2 gate `adr-gate.sh` instead). The same
  naming discipline applies to whatever phase-1 gate this proposal
  designs.

## Skip-record: no "implementation-rulebook" hook-machine reference inside this repository

This repository (`architecture-rulebook`) does not contain a plugin
named `implementation` or `implementation-rulebook`, and its own
`docs/issue-2`/`docs/issue-5` implementation-role reports describe only
a canon-reference migration and a vendored-file removal — neither shows
"progress-gate/state-tracking hook machine 400+ lines" rigor. No such
artifact exists inside this repo's git history to cite as an in-repo
comparable.

A comparable hook-machine artifact **was found on local disk, outside
this repository**, at
`pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh`
(sibling checkout of a differently-named, separately-versioned
`pricing-rulebook` repo, not a module of this repository and not
fetchable via this repo's git remotes). It is used below (scout-brief)
as a **pattern reference only** — its exact code is not, and must not
be, copied into this plugin; only its *shape* (fail-closed PreToolUse
gate, JSON-payload parsing, required-element checklist, kill switch,
"cannot determine resulting content → deny" rule) is cited as prior art
for the design in `docs/issue-10/proposals/`.

## What's missing for enforcement parity (gap line)

1. **Directive text**: still one summary line; issue #10 wants phase-1
   and phase-2 each split into concrete stage/judgment-criteria/
   prohibition text at facet granularity (e.g., a phase-1 facet for
   "survey must precede proposal," a phase-2 facet for "ADR section
   completeness," each with its own prohibition language), not one
   `PRODUCES` string.
2. **Phase-1 methodology gate**: does not exist. No hook checks that
   `docs/issue-<n>/reports/architecture/survey.md`,
   `.../scout-brief.md`, and `docs/issue-<n>/proposals/*.md` exist (or
   contain required sections) before a phase-2 report can be written or
   before an APPROVE is honored.
3. **Ordering/state tracking**: does not exist. `adr-gate.sh` reads only
   the target file's own `loop_state`; nothing tracks whether the
   *sequence* survey → scout-brief → proposal → APPROVE → phase-2 record
   was actually followed for a given `issue-<n>`.
4. **Gate tests**: no `tests/` directory, no fixtures, no runnable
   pass/fail cases exist for `adr-gate.sh` today, let alone for a new
   phase-1 gate.
5. **Agents/checklists**: none exist; issue #10 asks to add them "if the
   methodology requires a repeated procedure" — the survey→scout→
   proposal sequence itself is exactly such a repeated procedure, so this
   is in scope for the phase-1 proposal to consider.

## Sources

- `architecture/hooks/directive.sh` (this repo, current)
- `architecture/hooks/adr-gate.sh` (this repo, current)
- `architecture/hooks/hooks.json` (this repo, current)
- `docs/issue-1/proposals/2026-07-31-architecture-norms.md` (this repo)
- `docs/issue-1/reports/architecture.md` (this repo)
- `docs/issue-5/proposals/stub-check-dedup.md` (this repo)
- `docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md` (this repo, referenced by README/commit `0a65f6d`)
- `docs/specs/approvers.md` (this repo)
- `pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh` (external sibling checkout, pattern reference only — not a source this repo can vendor from)
