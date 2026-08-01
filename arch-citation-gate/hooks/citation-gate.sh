#!/usr/bin/env bash
# PreToolUse gate — owns exactly one methodology: the sourcing norm
# (issue-1's citation-format rule, generalized and shared verbatim across
# both phase-1 proposals and the phase-2 record, per this proposal's
# combination table). Whenever the resulting content of a write asserts
# external/industry knowledge with phrasing like "industry practice" or
# "well-established", every occurrence of that phrasing must have a URL or
# a Sources: list entry in the SAME section (or, for headingless files, a
# sliding line-window around it) — not merely somewhere in the file. This
# gate fails closed.
#
# Fires on docs/issue-<n>/proposals/*.md and
# docs/issue-<n>/reports/architecture.md for Write|Edit|MultiEdit.
#
# issue-13 audit fixes: trap-at-top fail-closed, kill-switch allowlist
# (unrecognized value stays ACTIVE rather than silently disabling), JSON
# parsing, path normalization (absolute and relative file_path treated
# identically), and replace_all-correct Write/Edit/MultiEdit content
# reconstruction are now handled via core's shared
# core/hooks/lib/gate-lib.sh + gate-lib.py (core issue #72's gate-house
# standard), referenced (not vendored) per this repo's existing sourcing
# idiom (see architecture/hooks/directive.sh).
#
# issue-13 semantic fix: the old check was whole-file substring matching —
# a trigger phrase ANYWHERE in the file was exempted by a URL or
# "Sources:" line ANYWHERE else in the file, even in an unrelated section.
# The check below scopes each trigger-phrase occurrence to its own
# Markdown section (the block from its nearest preceding heading up to the
# next heading or EOF) and requires the citation to be in that same
# section; headingless files fall back to a bounded line-window around
# each occurrence.
#
# Kill switch: export ARCH_CITATION_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "arch-citation-gate: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${ARCH_CITATION_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || { echo "arch-citation-gate: fail-closed: python3 not on PATH" >&2; exit 2; }

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || { echo "arch-citation-gate: fail-closed: empty tool-use payload" >&2; exit 2; }

CG_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd -P)}" CG_PAYLOAD="$payload" python3 <<'PY'
import json, os, posixpath, re, sys
import importlib.util

_spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(gate_lib)

def deny(msg):
    sys.stderr.write("arch-citation-gate: refused — %s\n" % msg)
    sys.exit(2)

def fail_closed(msg):
    sys.stderr.write("arch-citation-gate: fail-closed: %s\n" % msg)
    sys.exit(2)

raw = os.environ.get("CG_PAYLOAD", "")
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

root = os.path.normpath(os.environ["CG_ROOT"])
rel = gate_lib.gate_normalize_path(root, path)

TARGET_RE = re.compile(r'^docs/issue-[0-9]+/(proposals/[^/]+\.md|reports/architecture\.md)$')
if rel is None or not TARGET_RE.match(rel):
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
        "whose old_string(s) match, so the sourcing norm can be checked." % (rel, tool)
    )

TRIGGER_PHRASES = ("industry practice", "well-established", "well established",
                    "widely used", "업계 표준", "널리 쓰이는")
# "일반적으로" alone is an ordinary connective ("일반적으로 이렇게 본다") and
# no longer triggers on its own (issue-16 fix design #4). It only triggers
# paired with a genuine adopted/used-as-practice claim verb form within the
# same clause (bounded window, no sentence boundary crossed) — narrowing the
# false-positive on bare "일반적으로" without weakening the citation norm for
# an actual "generally adopted practice" assertion in Korean.
KOREAN_CLAIM_VERB_FORMS = ("쓰이는", "쓰이다", "쓰인다", "사용되는", "사용되다",
                           "사용된다", "채택되는", "채택되다", "채택된다",
                           "알려진", "알려져", "알려지다", "받아들여지는",
                           "받아들여진다", "받아들여지다")
TRIGGER_RE = re.compile(
    "(" + "|".join(re.escape(p) for p in TRIGGER_PHRASES) + "|"
    + r"일반적으로[^.!?\n]{0,30}?(?:" + "|".join(KOREAN_CLAIM_VERB_FORMS) + ")"
    + ")",
    re.I,
)

trigger_matches = list(TRIGGER_RE.finditer(content))
if not trigger_matches:
    sys.exit(0)

HEADING_RE = re.compile(r'^#{1,6}\s.*$', re.M)
URL_RE = re.compile(r'https?://\S+')
SOURCES_RE = re.compile(r'^\s*sources:\s*\S', re.M | re.I)
WINDOW_LINES = 15

def has_citation_in_span(start, end):
    span = content[start:end]
    return URL_RE.search(span) is not None or SOURCES_RE.search(span) is not None

headings = list(HEADING_RE.finditer(content))

uncited = []

if headings:
    # Section blocks: [heading_i.start(), heading_{i+1}.start()) for each
    # heading (heading line itself included in its own block), plus a
    # headingless leading block [0, first_heading.start()) if the file has
    # text before its first heading.
    blocks = []
    if headings[0].start() > 0:
        blocks.append((0, headings[0].start(), None))
    for i, h in enumerate(headings):
        start = h.start()
        end = headings[i + 1].start() if i + 1 < len(headings) else len(content)
        heading_text = h.group(0).lstrip('#').strip()
        blocks.append((start, end, heading_text))

    def find_block(offset):
        for start, end, htext in blocks:
            if start <= offset < end:
                return start, end, htext
        return 0, len(content), None

    for m in trigger_matches:
        start, end, htext = find_block(m.start())
        if not has_citation_in_span(start, end):
            uncited.append((m, htext))
else:
    # No headings at all: fall back to a bounded line-window (N=15 lines
    # before/after the trigger match's own line) rather than a section
    # block.
    line_starts = [0]
    for idx, ch in enumerate(content):
        if ch == "\n":
            line_starts.append(idx + 1)
    total_lines = len(line_starts)  # number of line-start offsets == number of lines
    line_starts.append(len(content) + 1)  # sentinel for the "one past last line" window edge

    for m in trigger_matches:
        ln = content.count("\n", 0, m.start())  # 0-based line index of the match
        lo_line = max(0, ln - WINDOW_LINES)
        hi_line = min(total_lines - 1, ln + WINDOW_LINES)
        win_start = line_starts[lo_line]
        win_end = line_starts[hi_line + 1] if hi_line + 1 < len(line_starts) else len(content)
        if not has_citation_in_span(win_start, win_end):
            uncited.append((m, None))

if uncited:
    m, htext = uncited[0]
    line_no = content.count("\n", 0, m.start()) + 1
    phrase = m.group(0)
    if htext:
        deny(
            "line %d (section '%s') asserts external/industry knowledge ('%s') with no "
            "URL or Sources: entry in that same section. Per issue-1's citation-format "
            "rule, cite the claim or restate it as an assumption." % (line_no, htext, phrase)
        )
    else:
        deny(
            "line %d asserts external/industry knowledge ('%s') with no URL or Sources: "
            "entry within %d lines. Per issue-1's citation-format rule, cite the claim or "
            "restate it as an assumption." % (line_no, phrase, WINDOW_LINES)
        )
PY
