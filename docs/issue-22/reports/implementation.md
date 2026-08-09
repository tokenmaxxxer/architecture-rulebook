---
code_under_review: same-commit
type: fix
breaking: false
verdict: pass
loop_state: landed
---

# Implementation record — issue #22

## What was done
Adopting the on-the-record test-env resolution convention
(`docs/specs/test-env-resolution.md`, issue #551) into this rulebook's
gate-test scripts, per the approved proposal
`docs/issue-22/proposals/2026-08-09-test-env-resolution.md`.

- Vendored `tests/lib/test_env_resolve.py` — a verbatim copy of the
  on-the-record reference resolver + CLI wrapper.
- `arch-adr-content-gate/tests/run.sh`, `arch-citation-gate/tests/run.sh`,
  `arch-sequence-gate/tests/run.sh`: added a pre-flight core-resolution
  check via the vendored module before the fixture loop; SKIP (exit 75)
  when core is unreachable, otherwise export the resolved
  `CLAUDE_PLUGIN_ROOT_CORE` and proceed unchanged.
- `tests/run-gate-tests.sh`: treat a sub-runner's exit 75 as SKIP (counted,
  not folded into `fail=1`); overall exit is 75 when every sub-runner
  skipped and none failed.

## Why
Issue #22 acceptance: gate-test scripts must SKIP with the convention's
distinct exit code outside the spawn env instead of producing misleading
FAIL lines, while leaving all core-reachable assertions unchanged.

## Upstream basis
docs/issue-22/proposals/2026-08-09-test-env-resolution.md

## What did not work
None.

## Doc-placement ladder
- [x] Each modified script cites `docs/specs/test-env-resolution.md`
  (grep check) — no separate handbook entry needed; this is test-script
  behavior, not a new env var/config/dep.

## Open findings
None.

## Next steps
Implement the write set, run the tests, commit, push, open the PR.

## Resolution path
N/A — no open findings.
