#!/usr/bin/env bash
# PreToolUse: role-specific check for this role's phase-2 record
# (docs/issue-<n>/reports/architecture.md). Layered ADDITIVELY on top of
# core canon's generic record-fields-gate — this file is NOT a vendored
# copy of any core canon script (deliberately not named
# "record-fields-gate.sh", which core's stub-check.sh treats as a
# reserved core-canon filename; see docs/issue-1/proposals/
# 2026-07-31-architecture-norms.md "Where this check registers").
#
# Fires on Write/Edit to docs/issue-<n>/reports/architecture.md once the
# record's frontmatter loop_state leaves the proposal-only states
# (scope-proposed/proposed) — i.e. once the record is decision-bearing —
# and requires four ADR section markers plus a C4-level diagram marker.
# Cheap literal-substring matching, consistent with this repo's existing
# gate style (no semantic review). Kill switch: export ARCHITECTURE_ADR_GATE_OFF=1

set -euo pipefail

[ -n "${ARCHITECTURE_ADR_GATE_OFF:-}" ] && exit 0

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
case "$tool_name" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
case "$file_path" in
  */docs/issue-*/reports/architecture.md) ;;
  *) exit 0 ;;
esac

content="$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')"
[ -z "$content" ] && exit 0

loop_state="$(printf '%s' "$content" | grep -m1 '^loop_state:' | sed 's/^loop_state: *//')"
case "$loop_state" in
  ""|scope-proposed|proposed) exit 0 ;;
esac

missing=""
printf '%s' "$content" | grep -qi -- '## Context\|\*\*Context\*\*' || missing="$missing Context"
printf '%s' "$content" | grep -qi -- '## Decision\|\*\*Decision\*\*' || missing="$missing Decision"
printf '%s' "$content" | grep -qi -- '## Consequences\|\*\*Consequences\*\*' || missing="$missing Consequences"
printf '%s' "$content" | grep -qi -- 'Alternatives Considered' || missing="$missing Alternatives-Considered"
printf '%s' "$content" | grep -qi -- '```mermaid\|C4 [Cc]ontext\|C4 [Cc]ontainer\|Context diagram\|Container diagram' || missing="$missing C4-diagram"

if [ -n "$missing" ]; then
  echo "adr-gate: docs/issue-<n>/reports/architecture.md is missing required ADR/C4 elements:$missing" >&2
  echo "  Per docs/issue-1/proposals/2026-07-31-architecture-norms.md, a decision-bearing" >&2
  echo "  record needs Context/Decision/Consequences/Alternatives Considered sections plus" >&2
  echo "  a Context or Container level C4 boundary diagram." >&2
  exit 1
fi

exit 0
