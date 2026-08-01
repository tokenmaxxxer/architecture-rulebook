#!/usr/bin/env bash
# Runs arch-sequence-gate against its own tests/fixtures/*. Each fixture
# directory is a throwaway project root (docs/... laid out as needed)
# plus an event.json describing the PreToolUse payload, and an
# expect.txt of either "pass" or "fail".
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
gate="../hooks/sequence-gate.sh"
gate_abs="$(cd "$(dirname "$gate")" && pwd -P)/$(basename "$gate")"
fail=0
for dir in fixtures/*/; do
  name="$(basename "$dir")"
  expect="$(cat "$dir/expect.txt")"
  fixture_abs="$(cd "$dir" && pwd -P)"
  # Optional per-fixture env.sh: sourced in a subshell to set env vars
  # (e.g. ARCH_SEQUENCE_GATE_OFF) scoped to just this fixture's run.
  event_json="$(cat "$dir/event.json")"
  # Minimal {{ABS}} substitution: replaced with the fixture's own absolute
  # path so a fixture can exercise an absolute file_path that normalizes
  # to the same target as the relative form.
  event_json="${event_json//\{\{ABS\}\}/$fixture_abs}"
  if [ -f "$dir/env.sh" ]; then
    out="$(
      CLAUDE_PROJECT_DIR="$fixture_abs" bash -c '. "$1/env.sh"; printf "%s" "$2" | bash "$3"' _ "$fixture_abs" "$event_json" "$gate_abs" 2>&1
    )"
    rc=$?
  else
    out="$(printf '%s' "$event_json" | CLAUDE_PROJECT_DIR="$fixture_abs" bash "$gate" 2>&1)"
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
