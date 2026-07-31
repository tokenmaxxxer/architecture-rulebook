# Proposal: remove vendored stub-check.sh, run by reference to core (issue #5)

Status: **proposed** (phase 1 — not implemented, not approved). See
`docs/issue-5/reports/implementation/survey.md` for the underlying survey.

## Problem

`architecture/hooks/tests/stub-check.sh` is a full vendored copy of the
core-canon stub-check script. Per core #69 canon, stub-check.sh must only be
referenced from the core installation (`core/hooks/tests/stub-check.sh`),
never copied into a rulebook. The vendored copy in this repo is exactly the
drift pattern the canon decision was meant to eliminate.

## Proposed changes (for phase 2, pending approval)

1. **Delete** `architecture/hooks/tests/stub-check.sh`.
   - No hooks.json entry references this file (confirmed in the survey), so
     no hooks.json edit is needed to remove a registration for it.
2. **No change needed to `architecture/hooks/hooks.json`** — it currently
   registers only `SessionStart` → `directive.sh` and has no stub-check
   entry to convert.
3. **Replace the execution path** for stub-check with a reference-run against
   the core installation, e.g. invoking
   `core/hooks/tests/stub-check.sh <path-to-architecture/hooks>` from
   whatever harness/CI step currently runs the vendored copy. Phase 2 should
   locate any such invocation (test harness, CI config, or manual
   instructions referencing the vendored path) and repoint it to the core
   path before deleting the vendored file, so stub-check coverage is not
   silently dropped.
4. **Record the pass**: after running stub-check via the core reference path
   against this rulebook's `architecture/hooks/` tree, record the pass result
   per this repo's record-keeping convention (e.g. under
   `docs/issue-5/reports/implementation/`), as instructed by the issue body
   ("core 참조 실행으로 stub-check 통과를 record에 기록하라").

## Out of scope for this proposal

- Any other rulebook's vendored copies (this repo covers the `architecture`
  role only).
- Establishing `docs/handbooks/canon-scripts.md` locally — the canon text is
  owned by core and was not found in this repo; no local copy is proposed
  (copying it would itself repeat the anti-pattern this issue fixes).

## Gate

Per the repo's role-based workflow, phase 2 (actually deleting
`architecture/hooks/tests/stub-check.sh` and repointing execution to core)
requires an **Approve** review from an approver listed in
`docs/specs/approvers.md` on the phase-1 PR before any implementation work
proceeds.
