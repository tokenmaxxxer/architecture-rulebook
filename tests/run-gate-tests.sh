#!/usr/bin/env bash
# Repo-root discovery runner: finds every plugin's own tests/run.sh and
# invokes it, so there is one command that runs everything without any
# plugin depending on another's test harness. Per
# docs/issue-10/proposals/2026-07-31-architecture-enforcement.md §3, this
# file embeds no plugin's check logic itself.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$root"

fail=0
skipped=0
ran=0
for runner in */tests/run.sh; do
  [ -f "$runner" ] || continue
  plugin="$(dirname "$(dirname "$runner")")"
  echo "== $plugin =="
  if bash "$runner"; then
    ran=$((ran + 1))
  else
    rc=$?
    # Per the canonical test-env resolution convention
    # (docs/specs/test-env-resolution.md, issue #551), exit 75 from a
    # sub-runner is a SKIP (core unreachable outside spawn env), never a
    # FAIL; any other nonzero exit is a real failure.
    if [ "$rc" -eq 75 ]; then
      echo "SKIP $plugin"
      skipped=$((skipped + 1))
    else
      fail=1
    fi
  fi
done

if [ "$fail" -eq 0 ] && [ "$ran" -eq 0 ] && [ "$skipped" -gt 0 ]; then
  exit 75
fi
exit $fail
