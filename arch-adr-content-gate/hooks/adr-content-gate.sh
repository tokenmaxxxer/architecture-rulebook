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
# states (scope-proposed/proposed) — i.e. once the record is
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
# Kill switch: export ARCH_ADR_CONTENT_GATE_OFF=1
# (ARCHITECTURE_ADR_GATE_OFF=1 honored too, deprecated alias, one release)
set -uo pipefail

case "${ARCH_ADR_CONTENT_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
case "${ARCHITECTURE_ADR_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) echo "arch-adr-content-gate: ARCHITECTURE_ADR_GATE_OFF is a deprecated alias for ARCH_ADR_CONTENT_GATE_OFF; honoring it for this release." >&2; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || { echo "arch-adr-content-gate: fail-closed: python3 not on PATH" >&2; exit 2; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "arch-adr-content-gate: fail-closed: empty tool-use payload" >&2; exit 2; }

AG_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" AG_PAYLOAD="$payload" python3 <<'PY'
import json, os, posixpath, re, sys

def deny(msg):
    sys.stderr.write("arch-adr-content-gate: refused — %s\n" % msg)
    sys.exit(2)

def fail_closed(msg):
    sys.stderr.write("arch-adr-content-gate: fail-closed: %s\n" % msg)
    sys.exit(2)

raw = os.environ.get("AG_PAYLOAD", "")
try:
    ev = json.loads(raw)
except Exception as e:
    fail_closed("unparseable tool-use payload: %r" % (e,))
if not isinstance(ev, dict):
    fail_closed("tool-use payload is not a JSON object")

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
n = path.replace("\\", "/")
abs_path = n if posixpath.isabs(n) else posixpath.join(root, n)
abs_path = posixpath.normpath(abs_path)
rel = os.path.relpath(abs_path, root).replace("\\", "/")

if not re.match(r'^docs/issue-[0-9]+/reports/architecture\.md$', rel):
    sys.exit(0)

current = None
if os.path.isfile(abs_path):
    try:
        with open(abs_path, encoding="utf-8-sig") as fh:
            current = fh.read(1 << 20)
    except OSError:
        fail_closed("%s exists but cannot be read" % rel)

if tool == "Write":
    c = ti.get("content")
    content = c if isinstance(c, str) else None
elif tool == "Edit":
    o, n2 = ti.get("old_string"), ti.get("new_string")
    content = current.replace(o, n2, 1) if (isinstance(o, str) and isinstance(n2, str) and current is not None and o in current) else None
else:  # MultiEdit
    edits = ti.get("edits")
    text = current
    content = None
    if isinstance(edits, list) and text is not None:
        ok = True
        for e in edits:
            if not isinstance(e, dict):
                ok = False; break
            o, n2 = e.get("old_string"), e.get("new_string")
            if not isinstance(o, str) or not isinstance(n2, str) or o not in text:
                ok = False; break
            text = text.replace(o, n2, 1)
        if ok:
            content = text

if content is None:
    fail_closed(
        "this write targets %s but the resulting content cannot be determined from "
        "tool=%r input (MultiEdit with an unresolvable edit, or an Edit whose "
        "old_string does not match current content). Use Write, or an Edit/MultiEdit "
        "whose old_string(s) match, so ADR+C4 sections can be checked." % (rel, tool)
    )

m_ls = re.search(r'^\s*loop_state:\s*([A-Za-z0-9_-]+)\s*$', content, re.M)
loop_state = m_ls.group(1).strip().lower() if m_ls else ""
if loop_state in ("", "scope-proposed", "proposed"):
    sys.exit(0)

low = content.lower()
missing = []
if not (re.search(r'##\s*context', low) or "**context**" in low):
    missing.append("Context")
if not (re.search(r'##\s*decision', low) or "**decision**" in low):
    missing.append("Decision")
if not (re.search(r'##\s*consequences', low) or "**consequences**" in low):
    missing.append("Consequences")
if "alternatives considered" not in low:
    missing.append("Alternatives-Considered")
if not (re.search(r'```mermaid', low) or re.search(r'c4\s+context', low) or
        re.search(r'c4\s+container', low) or "context diagram" in low or "container diagram" in low):
    missing.append("C4-diagram")

if missing:
    deny(
        "%s is missing required ADR/C4 elements: %s. Per docs/issue-1/proposals/"
        "2026-07-31-architecture-norms.md, a decision-bearing record needs Context/"
        "Decision/Consequences/Alternatives Considered sections plus a Context or "
        "Container level C4 boundary diagram." % (rel, ", ".join(missing))
    )
PY
