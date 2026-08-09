#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
gate="../hooks/citation-gate.sh"

# Pre-flight core resolution per the canonical test-env resolution
# convention (docs/specs/test-env-resolution.md, issue #551): outside the
# spawn env, SKIP with a distinct exit code instead of misleading FAILs.
resolved="$(python3 "../../tests/lib/test_env_resolve.py" "../../../core" "../../../tokenmaxxxer-core/core")"
rc=$?
if [ "$rc" -eq 75 ]; then
  exit 75
fi
export CLAUDE_PLUGIN_ROOT_CORE="$resolved"

fail=0
for dir in fixtures/*/; do
  name="$(basename "$dir")"
  expect="$(cat "$dir/expect.txt")"
  absdir="$(cd "$dir" && pwd -P)"
  # {{ABS}} in event.json is substituted with this fixture's own absolute
  # path, so a fixture can exercise an absolute file_path without baking in
  # a path that only exists on the machine that authored the fixture.
  payload="$(sed "s#{{ABS}}#$absdir#g" "$dir/event.json")"
  # A fixture may supply env.sh to set gate-specific env vars (e.g. the
  # kill switch) for just this one run; sourced in a subshell so nothing
  # leaks to later fixtures. No env.sh present is a no-op — zero behavior
  # change for every pre-existing fixture.
  if [ -f "$dir/env.sh" ]; then
    out="$( (. "$dir/env.sh"; CLAUDE_PROJECT_DIR="$absdir" bash "$gate") <<<"$payload" 2>&1 )"
  else
    out="$(CLAUDE_PROJECT_DIR="$absdir" bash "$gate" <<<"$payload" 2>&1)"
  fi
  rc=$?
  if [ "$expect" = "pass" ] && [ "$rc" -eq 0 ]; then
    echo "PASS $name"
  elif [ "$expect" = "fail" ] && [ "$rc" -ne 0 ]; then
    echo "PASS $name"
  else
    echo "FAIL $name (expected $expect, got rc=$rc): $out"
    fail=1
  fi
done
exit $fail
