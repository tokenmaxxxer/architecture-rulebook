# Current-state survey — architecture-rulebook vs. core canon (issue-2)

## This repo's current copies

- `architecture/agents/warrant-hunter.md` — a role-scoped rewrite of the
  hunt agent (mandate text names architecture's own `decides`/`hand-off`
  strings), not a byte-identical vendor of the old standalone `warrant`
  plugin's agent.
- `architecture/hooks/trailer-gate.sh` — role-name substitution only
  against core's promoted version (`architecture:` prefix hardcoded, same
  `git commit` / `Subject: issue-<n>` logic).
- `architecture/hooks/record-fields-gate.sh` — **not** the same design as
  core's canon version. This copy checks two hardcoded fields (`adr`,
  `boundary-diagram`) via substring match and has no `loop_state` concept
  at all. Core's canon version implements contract §20 in full: five
  required sections (what-was-done / why / upstream-basis / `loop_state`
  / open-findings), plus a conditional next-steps/resolution-path
  requirement whenever `loop_state` is non-terminal, with the terminal set
  configurable via `RECORD_FIELDS_TERMINAL_STATES` (default `landed`).
  Switching to canon is a real behavior change here, not a no-op relabel.
- `architecture/hooks/handbook-trigger-gate.sh` — already a no-op
  (`exit 0 # placeholder verdict`) in both this repo and core's promoted
  version; role-name substitution only.
- `architecture/hooks/directive.sh` — hand-written boilerplate (trap,
  kill-switch case, `CLAUDE_ROLE` guard, heredoc) around four role-unique
  values (`YOU DECIDE`, `USE_WHEN`, `PRODUCES`, `WRITE_SCOPE`, `HAND-OFF`,
  `BOUNDARY CASE`, `RECORD`). Core's `role-directive.sh` factors the first
  four of those into a shared function; this repo's copy additionally
  carries `WRITE_SCOPE` and a `BOUNDARY CASE` paragraph that
  `core_role_directive`'s four-argument signature has no slot for.
- `architecture/hooks/hooks.json` — registers all three gates above under
  `PreToolUse`, plus `directive.sh` under `SessionStart`.
- `README.md` layout section documents all of the above as this repo's
  own files.

## Core canon (read from `tokenmaxxxer-core`, main, post issue-63/#65 and
issue-66/#68 merges)

- `core/hooks/hooks.json` registers `trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh` (plus `board-gate.sh`, `approval-gate.sh`,
  `gh-guard.sh`) under `PreToolUse` with matcher `.*`, fired for every
  plugin install — a rulebook no longer needs its own `hooks.json` entry
  for these three.
- `core/hooks/lib/role-directive.sh` exposes `core_role_directive
  <you_decide> <use_when> <produces> <hand_off>`, reads `CLAUDE_ROLE`,
  derives the kill-switch var name (`<ROLE>_CYCLE_OFF`), and renders the
  same directive shape this repo's copy hand-writes. Its own header
  documents the expected caller shape:
  ```
  . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
  core_role_directive "YOU DECIDE: ..." "USE WHEN: ..." "PRODUCES: ..." "HAND-OFF: ..."
  ```
  Rendered output ends with a fixed `RECORD: docs/issue-<n>/reports/<role>.md,
  phase-gated per contract v3 s19` line — no `WRITE_SCOPE` or `BOUNDARY CASE`
  slot exists in the shared function.
- `core/hooks/tests/stub-check.sh` — distributed to every rulebook
  (usage: `stub-check.sh [hooks-dir]`). Fails closed if any of
  `trailer-gate.sh` / `record-fields-gate.sh` / `handbook-trigger-gate.sh` /
  `parse-check.sh` exists anywhere under the target `hooks/` tree
  (maxdepth 3) — their presence is now itself the drift signal. For
  `directive.sh` it runs a structural check: every non-blank/non-comment
  line must be the source line, a plain `VAR=value` assignment, or the
  `core_role_directive` call — anything else (case statement, raw
  `echo`/`cat`, control flow) fails as "regrown boilerplate."
- `docs/issue-66/reports/implementation.md` (core repo) records the
  authoritative rollout instructions for "per-rulebook follow-up": delete
  the three vendored gates + `hooks.json` entries, replace `directive.sh`
  with the lib-call stub via `${CLAUDE_PLUGIN_ROOT}`-relative resolution
  against core's install path, drop `stub-check.sh` in and wire it into
  the rulebook's own test harness, and set
  `RECORD_FIELDS_TERMINAL_STATES` if this role's terminal `loop_state`
  set is genuinely non-`landed`.
- Core's `warrant` plugin (`core` marketplace) is the canonical home for
  `warrant-hunter.md` and the work-unit hunt protocol (issue-63). It is a
  generic, write-set-scoped hunter (stance rotates over
  silent-failure / composition-regression / design-error at whatever
  transition dispatched it) — it carries no role-specific mandate text.
  It supersedes this repo's role-scoped hunter concept entirely; issue-63's
  own proposal (`tokenmaxxxer-core` `docs/issue-63/proposals/...`) states
  each of the 43 rulebooks' `agents/warrant-hunter.md` becomes "a one-line
  reference stub ... declared as a marketplace dependency, not a vendored
  file" — same pattern `core`/`scout`/`terse`/`freelunch` already use.

## Gaps / open points found

1. **No `RECORD_FIELDS_TERMINAL_STATES` precedent in this repo.** This
   repo's current `record-fields-gate.sh` copy has no `loop_state`
   concept at all (see above), so there is no existing per-role terminal
   state to preserve — nothing in this repo's history or contract
   establishes a terminal `loop_state` other than `landed`. Default
   (`landed`) applies; no override needed for item 4.
2. **`WRITE_SCOPE` and `BOUNDARY CASE` have no slot in
   `core_role_directive`.** These two lines are architecture-role-unique
   content that core's four-argument stub cannot render. They must be
   preserved as extra output appended by this repo's own `directive.sh`
   stub, printed after the `core_role_directive` call — the stub-check
   structural rule (source line / assignment / the one call) would reject
   inline heredoc text added *before* the call, so any role-unique
   trailer text must come from a second, equally simple line, not from
   growing back the old heredoc. **Confirmed against stub-check.sh's
   actual regex**: it only scans lines that are non-blank/non-comment and
   not already matched by the source-line/call/assignment patterns —
   nothing in the script anchors those three per-file to the *last* line
   of the file, so an emitted `cat <<'EOF' ... EOF` block placed *after*
   `core_role_directive` would still contain non-matching lines (`cat`,
   the heredoc content lines, `EOF`) and would fail the same as before.
   The proposal below therefore keeps `WRITE_SCOPE`/`BOUNDARY CASE`
   preservation as an **open question for the approver**, not a
   unilateral design choice, since stub-check.sh's own text does not
   document a sanctioned way to add role-unique trailer content beyond
   the four `core_role_directive` arguments.
3. **`CLAUDE_PLUGIN_ROOT_CORE` / `${CLAUDE_PLUGIN_ROOT}`-relative
   resolution across separately-installed plugins is unverified from
   inside this repo.** `role-directive.sh`'s own doc comment gives a
   fallback (`$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" ...)`)
   that assumes `core` sits two directories up from the sourcing script —
   true only when both plugins are installed under a shared parent
   (e.g. the same marketplace cache root). This repo's marketplace
   (`tokenmaxxxer-architecture`) is separate from `tokenmaxxxer-core`;
   whether Claude Code's plugin runtime places both under one common root
   at install time could not be confirmed by reading files alone (no
   local Claude Code plugin-install state was available to inspect in
   this environment). Flagged as an open question below rather than
   guessed.

## Scout skip record

Scouting was skipped. This is a mechanical core-canon reference-migration
task inside an internal agent-tooling rulebook, with no product/UX
surface and no external best-in-class system to benchmark against — the
issue names exact source files in a sibling repo (`tokenmaxxxer-core`)
to switch to, and the one real open design point (`RECORD_FIELDS_TERMINAL_STATES`)
is resolved by reading this repo's own current gate logic (finding 1
above), not by external reconnaissance. Per scout-directive's skip
conditions ("spec literally leaves no design decision open" — true for
items 1/2/5; items 3/4 have a decision but it is answered from this
repo's own current-state, covered above).
