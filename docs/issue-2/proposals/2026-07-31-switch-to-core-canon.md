---
subject: issue-2
role: implementation
loop_state: scope-proposed
---

# Proposal: switch architecture-rulebook to core canon references

## Request (paraphrased intent)

core landed a single canonical source for warrant-hunt (core issue #63)
and for the three role-agnostic gates plus the `directive.sh` boilerplate
(core issue #66). This repo still carries its own copies of all four.
The issue asks, in one batch: (1) drop the vendored `warrant-hunter.md`
in favor of core's canon, (2) drop the three vendored gate scripts and
their `hooks.json` registrations in favor of core's global registration,
(3) shrink `directive.sh` to the stub form (shared function + role-unique
call only), (4) preserve any genuine per-role difference explicitly via
`RECORD_FIELDS_TERMINAL_STATES` if one exists, (5) record a passing run
of `core/hooks/tests/stub-check.sh` against this repo's `hooks/` tree.
This transition is a stated prerequisite for this repo's own
rulebook-maturation phase 2.

## Constraints

- Phase-1 only — no code changes ship in this PR; see
  `docs/issue-2/reports/implementation/survey.md` for the current-state
  read of both this repo and core canon.
- The survey found item 4's premise does not apply here: this repo's
  current `record-fields-gate.sh` has no `loop_state` concept to begin
  with, so there is no non-`landed` terminal state to preserve. Default
  applies; `RECORD_FIELDS_TERMINAL_STATES` is not set anywhere in the
  plan below unless the approver knows of a terminal state this survey
  missed.
- This repo's `directive.sh` carries two role-unique fields
  (`WRITE_SCOPE`, `BOUNDARY CASE`) that `core_role_directive`'s
  four-argument signature (`you_decide`, `use_when`, `produces`,
  `hand_off`) has no slot for. Preserving them requires emitting
  content beyond the one sanctioned call, which risks failing
  `stub-check.sh`'s structural check (see survey finding 2) depending on
  how strictly the reviewer/gate interprets "regrown boilerplate." Left
  as an open question below rather than decided unilaterally.
- `${CLAUDE_PLUGIN_ROOT}`-relative resolution of core's plugin root from
  inside this repo's own `directive.sh` could not be verified against
  live Claude Code plugin-install state in this environment (survey
  finding 3). The stub below uses the exact fallback expression
  documented in `role-directive.sh`'s own header comment, since that is
  the one sanctioned form on record; if it does not resolve correctly at
  runtime under this marketplace's actual install layout, that surfaces
  as a SessionStart hook failure in phase 2, not a silent miss (the hook
  has `set -uo pipefail` and no swallowed-error path around the source
  line).

## What will be done (phase 2 only — not applied yet)

### 1. Remove the vendored warrant-hunter (issue item 1)

Delete `architecture/agents/warrant-hunter.md`. No replacement file is
added in this repo: core's `warrant` plugin supplies the shared
`warrant-hunter` subagent once installed alongside this plugin (same
"declared as a marketplace dependency, not vendored" pattern core's own
`core`/`scout`/`terse`/`freelunch` entries already use, per
`docs/issue-63/proposals/...` in `tokenmaxxxer-core`). `README.md`'s
Install section gains a line for adding the `tokenmaxxxer-core`
marketplace and installing `core` + `warrant` alongside `architecture`;
the Layout section drops the `agents/warrant-hunter.md` bullet.

### 2. Remove the three vendored gates + their hooks.json entries (item 2)

Delete `architecture/hooks/trailer-gate.sh`,
`architecture/hooks/record-fields-gate.sh`,
`architecture/hooks/handbook-trigger-gate.sh`. Remove their three
`PreToolUse` entries from `architecture/hooks/hooks.json`, leaving only
the existing `SessionStart` -> `directive.sh` entry. Core's own
`hooks.json` fires all three globally with matcher `.*` for every plugin
install (confirmed in survey), so no replacement entry is added here.
`README.md`'s Layout section drops the three corresponding bullets.

### 3. Shrink directive.sh to the stub form (item 3)

Replace `architecture/hooks/directive.sh` with:

```bash
#!/usr/bin/env bash
# SessionStart: architecture's role directive — sources core canon
# (core/hooks/lib/role-directive.sh) for the shared boilerplate and
# supplies only this role's four unique values. Kill switch:
# export ARCHITECTURE_CYCLE_OFF=1
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail

. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: 컴포넌트 경계·의존 방향" \
  "USE_WHEN: 새 모듈 경계나 기존 경계 변경이 걸릴 때" \
  "PRODUCES (required record fields): ADR (context/decision/consequences), boundary diagram" \
  "HAND-OFF: 인터페이스 형태 세부는 → api-design; 성능 예산이 걸리면 → performance-engineering"
```

The `trap`/`set -uo pipefail` pair stays, per `role-directive.sh`'s own
header note that a trap installed inside the sourced function cannot
catch the sourcing script's own abnormal exit. This drops the local
`ARCHITECTURE_CYCLE_OFF` case-statement and `CLAUDE_ROLE` guard that
`core_role_directive` now performs internally, and drops `WRITE_SCOPE`
and the `BOUNDARY CASE` paragraph — see open question below.

### 4. Terminal-state config (item 4)

No `RECORD_FIELDS_TERMINAL_STATES` entry added. Per the survey, this
repo's current gate has no `loop_state` mechanism at all to compare
against, so there is no established per-role terminal state to carry
forward — the default (`landed`) applies once core's version is in
effect. If the approver knows of an intended non-`landed` terminal state
for `architecture` (e.g. because a maturation-phase-2 doctrine document
elsewhere already commits to one), that value should be supplied before
this proposal is approved so it can be added to
`architecture/hooks/hooks.json`'s (now-empty of gate entries, but still
present for `directive.sh`) `env` block, or the approver can confirm the
default is correct and this step closes as "confirmed no-op."

### 5. stub-check.sh verification (item 5)

Add `architecture/hooks/tests/stub-check.sh` as a byte-identical copy of
core's `core/hooks/tests/stub-check.sh` (distributed the same way
`parse-check.sh` already is elsewhere, per the file's own header). Run
`architecture/hooks/tests/stub-check.sh architecture/hooks` after steps
1-3 land and record the pass/fail output in
`docs/issue-2/reports/implementation.md` (phase-2 record), per contract
v3 s19.

## Open questions for the human approver

1. **`WRITE_SCOPE` / `BOUNDARY CASE` preservation.** These two fields are
   real content this role currently ships (write-scope enforcement
   context and an explicit boundary-case escalation instruction) but have
   no slot in `core_role_directive`'s four-argument signature and no
   core-canon precedent for how a rulebook adds role-unique trailer
   content without regrowing the boilerplate `stub-check.sh` polices
   against. Three options, none decided here:
   - (a) drop both lines — they become tribal knowledge living only in
     `README.md`'s frontmatter-style summary and this proposal's own
     history, not in the SessionStart directive text itself;
   - (b) fold `WRITE_SCOPE` into the existing `PRODUCES`/`HAND-OFF`
     argument strings as extra sentences (stays inside the sanctioned
     call, no stub-check risk, but changes those two fields' semantics
     from core's other 43 rulebooks);
   - (c) accept a `stub-check.sh` structural-check risk and emit one
     additional literal line after the `core_role_directive` call (e.g.
     `printf 'WRITE_SCOPE: [...]\nBOUNDARY CASE: ...\n'`), which is
     mechanically simple but is exactly the kind of "one more line" that
     `stub-check.sh`'s comment describes as regrowth risk over time.
   Recommendation, not a decision: (b) — it stays strictly inside the
   sanctioned interface and keeps this rulebook's copy immune to a future
   `stub-check.sh` tightening, at the cost of `WRITE_SCOPE` no longer
   being its own labeled line in the rendered directive.
2. **`CLAUDE_PLUGIN_ROOT_CORE` resolution.** Confirm (or correct) that
   the fallback expression from `role-directive.sh`'s own header comment
   resolves correctly against this marketplace's actual plugin-install
   layout once `core` is installed alongside `architecture` — this could
   not be verified without live Claude Code plugin-install state.

## How success will be judged

- `architecture/agents/warrant-hunter.md` and the three vendored gate
  scripts no longer exist in this repo.
- `architecture/hooks/hooks.json` registers only `directive.sh` under
  `SessionStart`, nothing under `PreToolUse`.
- `architecture/hooks/directive.sh` passes `stub-check.sh`'s structural
  check (source line / one `core_role_directive` call / plain
  assignments only, per the approver's answer to open question 1).
- `architecture/hooks/tests/stub-check.sh architecture/hooks` exits 0,
  with its output recorded in `docs/issue-2/reports/implementation.md`.
- `README.md`'s Install and Layout sections match the post-change file
  tree.

## Files (write set, once approved)

- `architecture/agents/warrant-hunter.md` (delete)
- `architecture/hooks/trailer-gate.sh` (delete)
- `architecture/hooks/record-fields-gate.sh` (delete)
- `architecture/hooks/handbook-trigger-gate.sh` (delete)
- `architecture/hooks/hooks.json`
- `architecture/hooks/directive.sh`
- `architecture/hooks/tests/stub-check.sh` (new)
- `README.md`
- `docs/issue-2/reports/implementation.md` (phase-2 record)
