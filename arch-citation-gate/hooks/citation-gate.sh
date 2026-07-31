#!/usr/bin/env bash
# PreToolUse gate — owns exactly one methodology: the sourcing norm
# (issue-1's citation-format rule, generalized and shared verbatim across
# both phase-1 proposals and the phase-2 record, per this proposal's
# combination table). Whenever the resulting content of a write asserts
# external/industry knowledge with phrasing like "industry practice" or
# "well-established" without a nearby URL or a Sources: list entry, this
# gate fails closed.
#
# Fires on docs/issue-<n>/proposals/*.md and
# docs/issue-<n>/reports/architecture.md for Write|Edit|MultiEdit.
# Resulting-content computation follows the same pattern core canon's
# record-fields-gate.sh uses (pointer-referenced, not copied).
#
# Kill switch: export ARCH_CITATION_GATE_OFF=1
set -uo pipefail

case "${ARCH_CITATION_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || { echo "arch-citation-gate: fail-closed: python3 not on PATH" >&2; exit 2; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "arch-citation-gate: fail-closed: empty tool-use payload" >&2; exit 2; }

CG_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" CG_PAYLOAD="$payload" python3 <<'PY'
import json, os, posixpath, re, sys

def deny(msg):
    sys.stderr.write("arch-citation-gate: refused — %s\n" % msg)
    sys.exit(2)

def fail_closed(msg):
    sys.stderr.write("arch-citation-gate: fail-closed: %s\n" % msg)
    sys.exit(2)

raw = os.environ.get("CG_PAYLOAD", "")
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

root = os.path.normpath(os.environ["CG_ROOT"])
n = path.replace("\\", "/")
abs_path = n if posixpath.isabs(n) else posixpath.join(root, n)
abs_path = posixpath.normpath(abs_path)
rel = os.path.relpath(abs_path, root).replace("\\", "/")

TARGET_RE = re.compile(r'^docs/issue-[0-9]+/(proposals/[^/]+\.md|reports/architecture\.md)$')
if not TARGET_RE.match(rel):
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
        "tool=%r input. Use Write, or an Edit/MultiEdit whose old_string matches, so "
        "the sourcing norm can be checked." % (rel, tool)
    )

TRIGGER_PHRASES = ("industry practice", "well-established", "well established",
                    "widely used", "업계 표준", "일반적으로", "널리 쓰이는")
low = content.lower()
if not any(p in low for p in TRIGGER_PHRASES):
    sys.exit(0)

has_url = re.search(r'https?://\S+', content) is not None
has_sources = re.search(r'^\s*sources:\s*\S', content, re.M | re.I) is not None
if has_url or has_sources:
    sys.exit(0)

deny(
    "content asserts external/industry knowledge (phrasing like 'industry practice' or "
    "'well-established') with no URL and no Sources: entry anywhere in the file. Per "
    "issue-1's citation-format rule, cite the claim or restate it as an assumption."
)
PY
