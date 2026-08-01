#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
gate="../hooks/adr-content-gate.sh"
fail=0
for dir in fixtures/*/; do
  name="$(basename "$dir")"
  expect="$(cat "$dir/expect.txt")"
  abs="$(cd "$dir" && pwd -P)"
  # Fixture-local env.sh (optional): sourced before invoking the gate, so a
  # fixture can set kill-switch/env-var scenarios without run.sh growing
  # per-fixture special cases. No env.sh present = no behavior change for
  # any existing fixture.
  envfile="$dir/env.sh"
  # event.json may contain a literal "{{ABS}}" placeholder, substituted with
  # this fixture's own resolved absolute path, so a fixture can exercise an
  # absolute file_path without hardcoding a path that varies at test time.
  payload="$(sed "s#{{ABS}}#$abs#g" "$dir/event.json")"
  if [ -f "$envfile" ]; then
    out="$(CLAUDE_PROJECT_DIR="$abs" bash -c '. "$1"; exec bash "$2"' _ "$envfile" "$gate" <<<"$payload" 2>&1)"
    rc=$?
  else
    out="$(CLAUDE_PROJECT_DIR="$abs" bash "$gate" <<<"$payload" 2>&1)"
    rc=$?
  fi
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
