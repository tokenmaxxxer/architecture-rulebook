# Survey: issue #16 재감사 잔여 결함 (게이트 A+ 최종 마감)

## Scout: skipped (justified)

No design decision open — every fix below is fully determined by the
already-landed core canon (`tokenmaxxxer-core` issue #75/#182, checked
against `core-main@52bdc15`) and by this repo's own prior issue-13
proposal (`docs/issue-13/proposals/2026-08-01-gate-a-plus-remediation.md`,
merged to main). Scouting an external product landscape has no bearing
on reconciling this repo's three gates against a reference
implementation this repo does not control. Remaining decision (ARCH_
CYCLE_OFF disposition) is answered directly by re-reading the code, not
by external research.

## Precondition check

- core issue #75 (gate-lib source guard + `gate_bash_write_targets` py
  parity): **landed**, `core@52bdc15` (`deliver(implementation): ...
  (issue-75) (#77)`). `gate-lib.sh`/`gate-lib.py` now export
  `gate_trap_fail_closed`, `gate_kill_switch_active`, `gate_deny`,
  `gate_allow`, `gate_bash_write_targets` (sh+py), and py-only
  `gate_parse_json_or_deny`, `gate_normalize_path`, `gate_reconstruct_write`.
- on-the-record #182 (`CLAUDE_PLUGIN_ROOT_CORE` injection in `spawn.py`):
  referenced by issue #16 as landed; not independently re-verified here
  (out of this repo's write scope) — taken as given per issue text.

## Current board state (main, this repo)

All three gates (`arch-adr-content-gate/hooks/adr-content-gate.sh`,
`arch-citation-gate/hooks/citation-gate.sh`,
`arch-sequence-gate/hooks/sequence-gate.sh`) on `main` are still the
**pre-remediation** shapes: hand-rolled denylist kill-switch `case`,
no `gate-lib.sh` sourcing at all, whole-file substring citation check.
This matches issue #16's re-audit (dated 2026-08-01, same day) — the
board is what's merged, and nothing from the issue-13 remediation is
merged yet.

## Existing unmerged work: PR #15 (`issue-13/architecture`, OPEN)

PR #15 already implements most of the issue-13 spec: sources
`core/hooks/lib/gate-lib.sh`/`gate-lib.py` (function names verified to
match `core-main`'s landed API exactly — `gate_trap_fail_closed`,
`gate_kill_switch_active`, `gate_parse_json_or_deny`,
`gate_normalize_path`, `gate_reconstruct_write` all present and
signature-compatible), replaces the denylist kill switches with
`gate_kill_switch_active`, upgrades citation-gate to section/adjacency
scoping, adds a Bash-write-bypass heuristic to sequence-gate, and adds
23 regression fixtures (33/33 claimed green). It is **not merged** (no
approving review; single-account APPROVE comment not found on
`gh issue view 13`'s comment list — 0 comments) and per contract v3 the
board reads from `main`, not open PRs.

Auditing PR #15's diff directly against issue #16's five remaining
defects (verified line-by-line, not assumed from its PR description):

### (a) trap-at-top / missing-core — NOT actually fixed, despite `gate_trap_fail_closed` being called

PR #15's sourcing line in all three gates:

```bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
```

carries **no `||` guard** on the source statement. `gate-lib.sh`'s own
usage doc (`core/hooks/lib/gate-lib.sh:11-18`, landed by issue #75)
states this exact line shape is the issue-75-confirmed defect: an
unguarded source that fails (e.g. `CLAUDE_PLUGIN_ROOT_CORE` pointed at a
missing/unreadable core) runs no code — including no `gate_trap_fail_closed`
definition — so the very next line, `gate_trap_fail_closed`, is a
"command not found" (exit 127), which Claude Code's hook contract reads
as non-blocking, i.e. **fail-open**. Core's own `compliance-check.sh`
(landed by issue #75, `core/hooks/tests/compliance-check.sh:44-51`) has a
literal check for exactly this shape (`gate-lib\.sh"$` with no `||` on
the same line) and would **FAIL** all three of this repo's gates as
written in PR #15. This is issue #16's "trap-at-top 부재(fail-open)" item,
still open despite the sourcing/trap call being present — the guard is
the load-bearing part, not the call.

Consequence: no missing-core fixture exists in PR #15's added fixture
set either (compared against core's own `run-gate-lib-tests.sh` group 7,
`missing-core` — `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent
directory, gate must deny, not silently allow). This is issue #16's
"missing-core 케이스" item.

### (b) `ARCHITECTURE_CYCLE_OFF` — still documented, still unimplemented

`architecture/hooks/directive.sh:4-7` (current `main`, unchanged by PR
#15 — that PR does not touch this file): comment line 5 states
`# export ARCHITECTURE_CYCLE_OFF=1` but `core_role_directive(...)` on
line 7 is called unconditionally; nothing in the script reads
`ARCHITECTURE_CYCLE_OFF`. issue-13's proposal explicitly punted this as
an open question ("out of scope... flagged as an open question",
`docs/issue-13/proposals/2026-08-01-gate-a-plus-remediation.md`
§Open questions #1) and it was never answered — issue #16 now requires a
resolution, not another punt.

### (c) `일반적으로` false-positive — narrowed, not fixed

PR #15's citation-gate diff keeps `일반적으로` verbatim in
`TRIGGER_PHRASES` (`citation-gate.sh` diff, unchanged list) and only
narrows the **citation-adjacency search radius** (whole-file → same
Markdown section / bounded line window). That fixes "one URL anywhere
exempts every claim in the file" (issue #16's separate "URL 1개 전 주장
면제" item) but does **not** fix the trigger-phrase itself: `일반적으로`
("generally"/"usually") is ordinary Korean prose vocabulary used in
non-citing sentences constantly (e.g. "일반적으로 이 방식이 더 낫다고
본다" — a personal architectural judgment, not an industry-practice
claim). Narrowing the search radius makes an already-common false
positive slightly cheaper to trigger (still a full-section rewrite to
appease), not less likely to fire on ordinary prose. issue #16 lists
this as a still-open defect and the diff confirms why: the phrase
itself was never re-examined.

### (d) hooks.json matcher / code coverage mismatch — Bash branch is dead code in production

PR #15 adds a `if tool == "Bash":` branch to
`arch-sequence-gate/hooks/sequence-gate.sh` (Bash-write-bypass
heuristic) and two regression fixtures that invoke the script directly
(`bash "$gate" < event.json`, bypassing Claude Code's hook dispatch
entirely). But `arch-sequence-gate/hooks/hooks.json`'s `PreToolUse`
matcher is **unchanged**: `"matcher": "Write|Edit|MultiEdit"` — no
`Bash`. In production, Claude Code never invokes this hook for a `Bash`
tool call at all, so the newly-tested branch is unreachable outside the
test harness. This is issue #16's "matcher-코드 정합" item verified
concretely: advertised (fixture-tested) coverage the matcher itself
never grants at runtime. (`arch-citation-gate` and
`arch-adr-content-gate` have no Bash branch and correctly keep their
`Write|Edit|MultiEdit`-only matchers — only `arch-sequence-gate` has
this specific mismatch.)

### (e) compliance-check — never run against this repo at all

Neither `main` nor PR #15 invokes core's `compliance-check.sh` against
this repo's `hooks/` anywhere (`grep -r compliance-check` finds nothing
in this repo's tests or CI-equivalent scripts). issue #16 asks for a
"compliance-check 실행 기록 보완" — this repo currently has no record of
having run it at all, so there is no baseline to "complete," only one to
create. Running it against PR #15's code as-is would currently **FAIL**
per (a) above — confirming (a) independently by the canon's own
detector, not just by manual doc-comment reading.

### README/manifest ghost-name check — clean

`README.md`, `.claude-plugin/marketplace.json`, and all five
`*/.claude-plugin/plugin.json` files were read in full: no stale
pre-issue-10 filenames (`architecture/hooks/adr-gate.sh`, the pre-split
monolithic layout) survive — `README.md`'s "Layout" section and the
marketplace manifest both list only files that exist on disk today, and
`ARCHITECTURE_ADR_GATE_OFF` is documented as an explicit, dated
deprecated alias rather than a silent leftover. **No ghost-file/old-role-
name fix is needed here** — issue #16's requirement #4 is already met on
`main`. (This finding narrows requirement #4's actual remaining work to
zero net-new README changes beyond what PR #15's own README diff already
adds for the kill-switch/trap-at-top state, which this proposal folds
into fix design #7 below rather than re-deriving from scratch.)

## Baseline test result

`bash tests/run-gate-tests.sh` on current `main`: 9/9 fixtures PASS
(pre-remediation baseline, unchanged from issue-13's survey).
