---
subject: issue-2
role: implementation
loop_state: landed
---

# Phase-2 record: switch to core canon references

Executes `docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md` after
phase-2 approval (issue comment `APPROVE issue-2/implementation`).

## Why

core landed a single canonical source for warrant-hunt (core issue #63)
and for the three role-agnostic gates plus the `directive.sh`
boilerplate (core issue #66); this repo still vendored its own copies of
all four. Issue #2 asks this repo to drop its copies and reference core
canon instead, since core's own `hooks.json` now fires the three gates
globally for every plugin install and `warrant`'s plugin supplies
`warrant-hunter`. This transition is also a stated prerequisite for this
repo's own rulebook-maturation phase 2, per the issue.

## Done

1. Deleted `architecture/agents/warrant-hunter.md`. `warrant`'s canon
   `warrant-hunter` subagent supplies it once installed alongside this
   plugin (README Install section updated).
2. Deleted `architecture/hooks/trailer-gate.sh`,
   `architecture/hooks/record-fields-gate.sh`,
   `architecture/hooks/handbook-trigger-gate.sh`, and their `PreToolUse`
   entries in `architecture/hooks/hooks.json`. `hooks.json` now registers
   only the `SessionStart` -> `directive.sh` entry; `core`'s own
   `hooks.json` fires all three globally for every plugin install.
3. Replaced `architecture/hooks/directive.sh` with the stub form: sources
   `core/hooks/lib/role-directive.sh` and makes one `core_role_directive`
   call.
4. No `RECORD_FIELDS_TERMINAL_STATES` entry added — per the proposal's
   survey, this role has no non-`landed` terminal state to preserve; the
   default applies.
5. Added `architecture/hooks/tests/stub-check.sh` as a byte-identical
   copy of `core/hooks/tests/stub-check.sh` and ran it (output below).

## Open question 1 resolution (WRITE_SCOPE / BOUNDARY CASE)

No approver answer was recorded against the proposal's open questions,
so the proposal's own recommendation, option (b), was applied: both
fields are folded as extra sentences into the `PRODUCES` and `HAND-OFF`
argument strings rather than emitted as separate lines. This keeps the
call inside `core_role_directive`'s four-argument signature with no
regrown boilerplate.

## Deviation from the proposal's literal stub text

The proposal's draft stub (section 3) kept the `trap ... EXIT` /
`set -uo pipefail` pair alongside the source line and call, split the
`core_role_directive` call across multiple backslash-continued lines,
and reasoned this should still pass `stub-check.sh`. Running the actual
`core/hooks/tests/stub-check.sh` (copied from
`tokenmaxxxer-core/core/hooks/tests/stub-check.sh`) against that draft
form empirically fails: the structural check's `other` regex excludes
only blank/comment lines, the shebang, lines containing
`role-directive.sh` or `core_role_directive`, and plain assignments —
`trap`/`set` lines and continuation-only argument lines match none of
those and are flagged as regrown boilerplate. The delivered
`directive.sh` therefore drops the trap/set pair and puts the entire
`core_role_directive` call on one line; this passes structurally (see
below). This trades away the "sourcing script's own abnormal exit"
safety net `role-directive.sh`'s header describes for the sourcing
script — noted here since the proposal read this as an open risk, not a
decided outcome, and the run below is what confirms it.

## `stub-check.sh` run (item 5)

Command: `architecture/hooks/tests/stub-check.sh architecture/hooks`

```
stub-check: ok — no vendored 'trailer-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'parse-check.sh' under architecture/hooks
stub-check: ok — architecture/hooks/directive.sh is a role-directive stub
```

Exit code: 0.

## Success criteria check (from the proposal)

- `architecture/agents/warrant-hunter.md` and the three vendored gate
  scripts no longer exist — done.
- `architecture/hooks/hooks.json` registers only `directive.sh` under
  `SessionStart`, nothing under `PreToolUse` — done.
- `architecture/hooks/directive.sh` passes `stub-check.sh`'s structural
  check — done (see run above).
- `architecture/hooks/tests/stub-check.sh architecture/hooks` exits 0 —
  done.
- `README.md`'s Install and Layout sections match the post-change file
  tree — done.

## Open findings

- Open question 2 (`CLAUDE_PLUGIN_ROOT_CORE` resolution against a live
  Claude Code plugin-install layout) remains unverified in this
  environment, same as the proposal noted; `directive.sh` uses the exact
  fallback expression from `role-directive.sh`'s own header comment. If
  it resolves incorrectly under this marketplace's actual install
  layout, that surfaces as a `SessionStart` hook failure, not a silent
  miss.
- Dropping the `trap`/`set -uo pipefail` pair (see Deviation above)
  removes the "catch the sourcing script's own abnormal exit" behavior
  `role-directive.sh`'s header describes as a gap `core_role_directive`
  cannot close from inside the sourced function. No abnormal-exit
  failure was observed in this session's `stub-check.sh` run, but this
  is a real behavior change from the previous `directive.sh`, not
  proposal-anticipated boilerplate removal.
