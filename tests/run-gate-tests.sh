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
for runner in */tests/run.sh; do
  [ -f "$runner" ] || continue
  plugin="$(dirname "$(dirname "$runner")")"
  echo "== $plugin =="
  if ! bash "$runner"; then
    fail=1
  fi
done
exit $fail
