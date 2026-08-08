#!/usr/bin/env bash
# PreToolUse: role-specific check for this role's phase-2 record
# (docs/issue-<n>/reports/architecture.md). Layered ADDITIVELY on top of
# core canon's generic record-fields-gate — this file is NOT a vendored
# copy of any core canon script (deliberately not named
# "record-fields-gate.sh", which core's stub-check.sh treats as a
# reserved core-canon filename; see docs/issue-1/proposals/
# 2026-07-31-architecture-norms.md "Where this check registers").
#
# Migrated from architecture/hooks/adr-gate.sh into its own plugin per
# issue-10's plugin-set mandate (docs/issue-10/proposals/
# 2026-07-31-architecture-enforcement.md §0). Logic carried over
# unchanged in substance except for the fix below.
#
# Fires on Write/Edit/MultiEdit to docs/issue-<n>/reports/architecture.md
# once the record's frontmatter loop_state leaves the proposal-only
# states (drafting/reviewing) — i.e. once the record is
# decision-bearing — and requires four ADR section markers plus a
# C4-level diagram marker. Cheap literal-substring matching, consistent
# with this repo's existing gate style (no semantic review).
#
# Fix over the migrated original: resulting content is now computed for
# MultiEdit too (the original only handled Write/Edit's .content/
# .new_string field and treated an unresolvable MultiEdit as "no content
# to check", i.e. passed it open — this closes that gap by failing
# closed instead).
#
# issue-13 audit fixes: trap-at-top fail-closed, kill-switch allowlist,
# JSON parsing, path normalization, and replace_all-correct content
# reconstruction are now handled via core's shared
# core/hooks/lib/gate-lib.sh + gate-lib.py, referenced (not vendored) per
# this repo's existing sourcing idiom (see architecture/hooks/directive.sh).
#
# Kill switch: export ARCH_ADR_CONTENT_GATE_OFF=1
# (ARCHITECTURE_ADR_GATE_OFF=1 honored too, deprecated alias, one release)
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "arch-adr-content-gate: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${ARCH_ADR_CONTENT_GATE_OFF:-}" || { trap - EXIT; exit 0; }
if [ -n "${ARCHITECTURE_ADR_GATE_OFF:-}" ]; then
  gate_kill_switch_active "${ARCHITECTURE_ADR_GATE_OFF:-}" || {
    echo "arch-adr-content-gate: ARCHITECTURE_ADR_GATE_OFF is a deprecated alias for ARCH_ADR_CONTENT_GATE_OFF; honoring it for this release." >&2
    trap - EXIT; exit 0
  }
fi

command -v python3 >/dev/null 2>&1 || { echo "arch-adr-content-gate: fail-closed: python3 not on PATH" >&2; exit 2; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "arch-adr-content-gate: fail-closed: empty tool-use payload" >&2; exit 2; }

AG_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" AG_PAYLOAD="$payload" python3 <<'PY'
import json, os, posixpath, re, sys
import importlib.util

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

def deny(msg):
    sys.stderr.write("arch-adr-content-gate: refused — %s\n" % msg)
    sys.exit(2)

def fail_closed(msg):
    sys.stderr.write("arch-adr-content-gate: fail-closed: %s\n" % msg)
    sys.exit(2)

raw = os.environ.get("AG_PAYLOAD", "")
ev = gate_lib.gate_parse_json_or_deny(raw, deny)

tool = ev.get("tool_name")
ti = ev.get("tool_input")
if tool not in ("Write", "Edit", "MultiEdit"):
    sys.exit(0)
if not isinstance(ti, dict):
    fail_closed("tool_input missing or not an object")

path = ti.get("file_path")
if not isinstance(path, str) or not path:
    sys.exit(0)

root = os.path.normpath(os.environ["AG_ROOT"])
rel = gate_lib.gate_normalize_path(root, path)

if rel is None or not re.match(r'^docs/issue-[0-9]+/reports/architecture\.md$', rel):
    sys.exit(0)

abs_path = posixpath.join(root.replace("\\", "/"), rel)
current = None
if os.path.isfile(abs_path):
    try:
        with open(abs_path, encoding="utf-8-sig") as fh:
            current = fh.read(1 << 20)
    except OSError:
        fail_closed("%s exists but cannot be read" % rel)

content, ok = gate_lib.gate_reconstruct_write(tool, ti, current)

if not ok:
    fail_closed(
        "this write targets %s but the resulting content cannot be determined from "
        "tool=%r input (MultiEdit with an unresolvable edit, or an Edit whose "
        "old_string does not match current content). Use Write, or an Edit/MultiEdit "
        "whose old_string(s) match, so ADR+C4 sections can be checked." % (rel, tool)
    )

m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', content, re.M)
loop_state = m_ls.group(1).strip().lower() if m_ls else ""
# drafting/reviewing: still phase-1/phase-2-in-progress, not yet decision-bearing.
# decision-not-ripe/options-unreachable: refusal/error states — a record parked
# there is explicitly not asserting a decision, so it is exempt from the same
# required-section check as a proposal-only record.
if loop_state in ("", "drafting", "reviewing", "decision-not-ripe", "options-unreachable"):
    sys.exit(0)

low = content.lower()
missing = []
if not (re.search(r'##\s*context', low) or "**context**" in low):
    missing.append("Context")
if not (re.search(r'##\s*decision', low) or "**decision**" in low):
    missing.append("Decision")
if not (re.search(r'##\s*consequences', low) or "**consequences**" in low):
    missing.append("Consequences")
if not ("alternatives considered" in low or "considered_options" in low):
    missing.append("Alternatives-Considered")
if not (re.search(r'```mermaid', low) or re.search(r'c4\s+context', low) or
        re.search(r'c4\s+container', low) or "context diagram" in low or "container diagram" in low):
    missing.append("C4-diagram")
if not re.search(r'^\s*decision_id:\s*\S+\s*$', content, re.M):
    missing.append("decision_id")
if not re.search(r'^\s*outcome:\s*(accepted|rejected|superseded)\s*$', content, re.M):
    missing.append("outcome")

if missing:
    deny(
        "%s is missing required ADR/C4 elements: %s. Per docs/issue-1/proposals/"
        "2026-07-31-architecture-norms.md and docs/issue-19's architecture.spec.json "
        "alignment, a decision-bearing record needs Context/Decision/Consequences/"
        "Alternatives Considered (considered_options) sections, a Context or "
        "Container level C4 boundary diagram, and decision_id/outcome frontmatter."
        % (rel, ", ".join(missing))
    )
PY
