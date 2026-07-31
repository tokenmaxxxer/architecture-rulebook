#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
gate="../hooks/adr-content-gate.sh"
fail=0
for dir in fixtures/*/; do
  name="$(basename "$dir")"
  expect="$(cat "$dir/expect.txt")"
  out="$(CLAUDE_PROJECT_DIR="$(cd "$dir" && pwd -P)" bash "$gate" < "$dir/event.json" 2>&1)"
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
