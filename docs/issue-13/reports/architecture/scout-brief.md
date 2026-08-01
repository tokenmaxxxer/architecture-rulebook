---
subject: issue-13
role: architecture
loop_state: scope-proposed
---

# Scout brief: fail-closed hook wrappers + secure kill-switch/semantic-scoping patterns (issue #13)

WebSearch is available; two searches run (see `Sources:`).

## Must-bes

- **Exit-code discipline is the whole game.** Confirmed via Claude Code's
  own hook contract: only exit code 2 blocks a `PreToolUse` call; any
  other non-zero code is a non-blocking error the tool call proceeds
  past anyway. A trap/wrapper fix must force *every* exit path —
  anticipated or not — to `exit 2` on failure, not just add more `deny()`
  calls.
- **Kill switches must be allowlists of "off" values, not denylists of
  "on" values.** Fail-secure default = unrecognized input keeps the
  protection active, matching the searched guidance that flag-evaluation
  failures must not inadvertently disable protection.
- **Semantic checks need locality, not just presence.** A trigger phrase
  and its supporting citation must be scoped to the same section/
  paragraph, not merely co-present anywhere in a multi-thousand-line
  file.

## Performance axes

- **Strictness vs. false-positive rate**: word-boundary/adjacency
  scoping cuts false positives (the `일반적으로` case) but costs more
  code and more edge cases (what counts as "same section"?) than
  whole-file substring matching.
- **Wrapper generality vs. proportionality**: a full generic trap
  library (arbitrary signal handling, cleanup callbacks) is more than
  three single-purpose gate scripts need; issue #13 itself scopes this
  to the shared `gate-lib.sh` from core issue #72 rather than asking
  this repo to build its own generic version — see GAP LINE.

## Pattern to adopt

The Claude Code hooks documentation's own stated pattern — "decide your
failure mode up front: fail closed (exit 2) for security/enforcement
hooks" — combined with a shell `trap 'exit 2' ERR` (or equivalent
`trap … EXIT`-based wrapper that inspects `$?`) placed at the very top
of the script, before any `set -uo pipefail` or logic runs. This
converts *any* uncaught error (Python traceback, command-not-found,
unset variable) into the same `exit 2` fail-closed denial the code's
explicit `deny()`/`fail_closed()` paths already produce — no new
per-error-site code, one wrapper closes the whole class of gap.

## Pattern to deliberately skip

Full allowlist-based command parsing to close the Bash-tool-write bypass
(defect e) — general shell-command parsing (quoting, subshells, `eval`,
pipes) to reliably detect every way a write could reach a docs/ path via
`Bash` is a much larger surface than three scoped gate scripts should
own; the proportionate move is a bounded heuristic (literal `>`/`>>`/
`tee` redirection targets under `docs/`) plus explicit deferral of the
general case to core issue #72's shared library, not building a shell
parser in this repo.

## GAP LINE

The survey confirms defects (a) trap-at-top/fail-open, (b) both the
undocumented-and-unimplemented `ARCHITECTURE_CYCLE_OFF` switch and the
backwards denylist convention on the three existing switches, (c)
citation-gate's whole-file substring semantic check, and (e) the
Bash-tool bypass, as real gaps against the must-bes above; (d)
absolute-path handling is already correct. The gap this scouting closes
is *design pattern selection* for (a)/(b)/(c) — trap-at-top wrapper,
allowlist kill-switch convention, adjacency-scoped semantic check — not
new defect discovery beyond the survey.

## Stage count

2 stages: (1) this scout brief, scoped narrowly since the fixes
themselves are conventional shell/security patterns rather than an open
design space requiring deep comparative research; (2) the proposal,
which applies these patterns to each confirmed defect.

Sources:
- https://code.claude.com/docs/en/hooks (Claude Code hooks reference — exit-code semantics)
- https://github.com/anthropics/claude-code/issues/21988 ("[BUG] PreToolUse hooks exit code ignored — operations proceed after hook failure")
- https://thinkingthroughcode.medium.com/the-silent-failure-mode-in-claude-code-hook-every-dev-should-know-about-0466f139c19f (fail-closed vs fail-open hook design, "only exit 2 blocks")
- https://upstat.io/blog/feature-flags-kill-switches (kill-switch operational pattern; default state should match normal operation)
- https://designingsecuresoftware.com/preview_fulltext/dss04/ (Designing Secure Software ch.4 — allowlist vs blocklist fail-secure tradeoffs)
