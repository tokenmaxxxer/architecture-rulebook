---
status: proposed
files:
  - tests/run-gate-tests.sh
  - tests/lib/test_env_resolve.py
  - arch-adr-content-gate/tests/run.sh
  - arch-citation-gate/tests/run.sh
  - arch-sequence-gate/tests/run.sh
---

## Request
Adopt the canonical test-env resolution convention landed at
on-the-record `docs/specs/test-env-resolution.md` (issue #551) across
this rulebook's gate-test scripts: outside the spawn env (no
`CLAUDE_PLUGIN_ROOT_CORE`, no reachable sibling core checkout), every
test script should exit with the convention's SKIP contract — explicit
message, distinct exit code (75) — instead of producing misleading
FAIL lines. Assertions that run when core IS reachable stay unchanged.

## Constraints
- Do not weaken any assertion that runs when core is reachable — the
  fix is purely in how a script behaves when core is *not* reachable.
- The convention's SKIP exit code (75) must never collide with a
  gate's own pass (0) / fail (1) / deny (2) exit codes, and must be
  distinguishable from `run-gate-tests.sh`'s own `fail=1` aggregation.
- No network fetch for core — resolution is local-only
  (`$CLAUDE_PLUGIN_ROOT_CORE` or a caller-supplied sibling candidate),
  per the convention doc.
- Test scripts must reference the convention doc (issue #22's
  acceptance check: grep for `test-env-resolution`).
- Each `fail-missing-core` fixture (one per gate) exists to test the
  *gate's* own missing-core message when `CLAUDE_PLUGIN_ROOT_CORE` is
  deliberately set to a bad path — this must keep working exactly as
  today, since it exercises resolution order step 1 (env var wins even
  when broken) and is orthogonal to the new pre-flight skip check.

## Rationale
Three shapes were visible from the survey (`docs/issue-22/reports/implementation/survey.md`):

1. **Vendor the on-the-record Python reference resolver
   (`gates/test_env_resolve.py`) verbatim** and have each `run.sh` shell
   out to it as a CLI, per the convention doc's own "Bash test runner"
   adoption section — chosen. It reuses the already-tested reference
   implementation instead of re-deriving the same resolution order, and
   matches the doc's explicit guidance for exactly this consumer shape.
2. **Re-implement the resolution order directly in bash** (inline or as
   one sourced `tests/lib/resolve-core.sh`) — rejected. It would drop
   the Python module's own test coverage
   (`gates/test_test_env_resolve.py`, covering the env-var hit, sibling
   hit, empty-stub-doesn't-count case, and the SKIP path) and create a
   second, unreviewed bash port of logic the convention already
   verified once. A bash reimplementation is also the kind of
   "consumer hand-rolls its own" the convention exists to stop.
3. **Only fix the top-level aggregator (`tests/run-gate-tests.sh`)** and
   leave each gate's own `run.sh` unchanged — rejected. A developer
   running a single gate's `tests/run.sh` directly (not through the
   aggregator) would still get misleading FAILs, and the issue's
   acceptance check requires the convention doc referenced by the
   scripts, not just the aggregator.

## What will be done
- Vendor `tests/lib/test_env_resolve.py`: a verbatim copy of the
  on-the-record `gates/test_env_resolve.py` reference implementation
  (resolve order: `$CLAUDE_PLUGIN_ROOT_CORE` if it contains a non-empty
  `hooks/lib/gate-lib.sh` → first caller-supplied sibling candidate with
  the same file → SKIP with message + exit 75), with a header comment
  citing `docs/specs/test-env-resolution.md` (on-the-record, issue
  #551) as its source and citing the module never being modified
  independently of that source.
- In each of `arch-adr-content-gate/tests/run.sh`,
  `arch-citation-gate/tests/run.sh`, `arch-sequence-gate/tests/run.sh`:
  before the fixture loop, invoke
  `python3 <repo_root>/tests/lib/test_env_resolve.py <candidates>` with
  the plugin's own sibling-checkout candidates (e.g. `../../core`,
  `../../../tokenmaxxxer-core/core`). On exit 75: print the SKIP
  message to stderr, exit 75 immediately (no fixtures run, no FAIL
  lines). On exit 0: export `CLAUDE_PLUGIN_ROOT_CORE` to the resolved
  path for the rest of the script (so the gate's own internal
  resolution — left untouched — finds it via step 1), then proceed
  with the existing fixture loop unchanged.
- In `tests/run-gate-tests.sh`: treat a sub-runner's exit code 75 as a
  distinct SKIP outcome (printed, counted, not folded into `fail=1`),
  while any other nonzero exit still marks the run failed. Final exit
  code stays 0 unless a real FAIL occurred; a run that is all-SKIP
  (e.g. no core reachable anywhere) exits 75 itself so the caller can
  tell "unverifiable here" apart from "actually green."
- Each modified script gets a comment citing
  `docs/specs/test-env-resolution.md` (satisfies the issue's grep
  check).

## Out of scope
- Any change inside the gate scripts themselves
  (`arch-*-gate/hooks/*.sh`) — their own core resolution and exit-2
  behavior when core is broken/missing stays exactly as is, per the
  issue's "do not weaken" constraint.
- The `fail-missing-core` fixtures and their `env.sh` files — unchanged.
- Adding a network-fetch fallback for core — the convention explicitly
  excludes this from the canonical contract.
- Any change to the on-the-record repo itself.

## How you'll know it worked
- On a plain checkout with `CLAUDE_PLUGIN_ROOT_CORE` unset and no
  sibling core checkout: `bash tests/run-gate-tests.sh` produces zero
  FAIL lines for any `pass-*`/non-missing-core fixture — only SKIP
  output, exit code 75.
- With `CLAUDE_PLUGIN_ROOT_CORE` pointed at a real core checkout (or a
  reachable sibling `../../core`): the exact same PASS/FAIL results as
  before this change, for every fixture including `fail-missing-core`.
- `grep -rl test-env-resolution tests/ arch-*-gate/tests/run.sh` finds
  every modified script.
- If any script's failure once core is reachable turns out to be a real
  gate defect (not env-related), it is recorded as a finding rather
  than masked by the new SKIP path.
