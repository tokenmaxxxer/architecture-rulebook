---
subject: issue-13
role: architecture
loop_state: scope-proposed
---

# Survey: current-state read against issue #13's "grade B" gate audit

Issue #13 is a 2026-08-01 code audit that graded this rulebook's three
`PreToolUse` gates (`arch-adr-content-gate/hooks/adr-content-gate.sh`,
`arch-citation-gate/hooks/citation-gate.sh`,
`arch-sequence-gate/hooks/sequence-gate.sh`) "B" and lists five alleged
defects. This survey reads each gate's actual code (as it stands after
issue-10's plugin-set migration, commit `1c9efd8`) line-by-line against
each claim.

## Blocker: core issue #72 ("게이트 하우스 표준") is still open

The issue asks remediation work to build on a shared library,
`core/hooks/lib/gate-lib.sh`, from the separate `tokenmaxxxer-core`
repo, tracked as that repo's issue #72. That issue is confirmed **still
open**, not merged/landed. `gate-lib.sh` does not exist anywhere in this
checkout:

```
$ find . -iname "*gate-lib*"
(no output)
```

This is a real precondition gap, not a formality: several of the fixes
below (trap-at-top wrapper, fail-closed helper conventions) are exactly
the kind of cross-cutting shell boilerplate a "gate house standard"
library is meant to hold, and issue #13 explicitly asks this rulebook to
**reference, not reimplement** it. Until #72 lands, this rulebook cannot
compliantly ship the trap-at-top fix in its intended form. See the
proposal's "Blocker" section for the two compliant paths forward.

## Defect-by-defect findings

### (a) No trap-at-top → internal errors fail-open instead of fail-closed

**Finding: CONFIRMED.**

None of the three gates has a `trap` command anywhere in the repo
(`grep -rn "trap " --include="*.sh" .` returns nothing). Each gate only
sets `set -uo pipefail` (`arch-adr-content-gate/hooks/adr-content-gate.sh:30`,
`arch-citation-gate/hooks/citation-gate.sh:16`,
`arch-sequence-gate/hooks/sequence-gate.sh:23`) — no `-e`, no trap.

The load-bearing logic runs inside `python3 <<'PY' ... PY` heredocs
(e.g. `adr-content-gate.sh:46-149`). Tracing what happens on an
*uncaught* Python exception (e.g. a `re.error` from a future regex edit,
or an unexpected `KeyError`): Python prints a traceback to stderr and
exits with status **1**. Bash's `set -uo pipefail` does not include
`-e`, but that's moot here — the heredoc `python3 ...` invocation is the
last statement in the script, so the gate script's own exit code
*becomes* Python's exit code (1) regardless of `-e`.

Per Claude Code's own hook exit-code contract (verified via WebSearch,
see scout-brief `Sources:`), **only exit code 2 blocks a `PreToolUse`
tool call; exit code 1 (or any non-2 non-zero code) is a non-blocking
error** — Claude Code logs the hook error but lets the tool call proceed
anyway. This means an uncaught Python exception inside any of these
three gates currently **fails open**: the write goes through with no
gate enforcement, and the operator sees only a logged error, not a
denial. This confirms the issue's claim precisely and is the single
most severe defect of the five.

Every explicit, anticipated failure path in the code (`fail_closed()`,
`deny()`, the `python3` PATH check, the empty-payload check) already
uses `exit 2` correctly — see e.g. `adr-content-gate.sh:41,44,53-55`.
The gap is specifically the *unanticipated*-error path, which has no
trap/wrapper forcing it to `exit 2`.

### (b) `ARCHITECTURE_CYCLE_OFF` documented but not implemented; existing kill switches use a backwards allowlist

**Finding: CONFIRMED (two distinct sub-issues).**

`ARCHITECTURE_CYCLE_OFF` appears in exactly two places, both prose, zero
implementation:
- `architecture/hooks/directive.sh:4-5` — a comment: `# Kill switch:
  export ARCHITECTURE_CYCLE_OFF=1`, but `directive.sh` (a `SessionStart`
  hook, not `PreToolUse`) never reads this env var anywhere in its body
  (`architecture/hooks/directive.sh:6-7` is the entire executable
  content — a `source` line and one `core_role_directive` call, no
  `case`/`if` on `ARCHITECTURE_CYCLE_OFF` at all).
- `docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md:88,103` —
  the same string appears in a prior proposal's design text.

No gate script in this repo (`adr-content-gate.sh`, `citation-gate.sh`,
`sequence-gate.sh`) reads `ARCHITECTURE_CYCLE_OFF`. It is documentation
of an intent, never wired to an actual check. Confirmed as alleged.

Separately, the three kill switches that *do* exist
(`ARCH_ADR_CONTENT_GATE_OFF`, `ARCH_CITATION_GATE_OFF`,
`ARCH_SEQUENCE_GATE_OFF`, plus the deprecated alias
`ARCHITECTURE_ADR_GATE_OFF`) all share the identical pattern:

```bash
case "${ARCH_CITATION_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac
```
(`arch-citation-gate/hooks/citation-gate.sh:18-21`; same shape at
`arch-adr-content-gate/hooks/adr-content-gate.sh:32-39` and
`arch-sequence-gate/hooks/sequence-gate.sh:25-28`.)

This is a **denylist, not an allowlist**: only a short, fixed list of
values keeps the gate active; any *other* value — including a typo like
`ARCH_CITATION_GATE_OFF=1x`, or any truthy-looking string not in the
list, or simply a value nobody anticipated — falls into the `*)`
branch and **disables the gate**. This is exactly backwards from
fail-secure kill-switch design (see scout-brief) and from what issue
#13 demands: "unrecognized kill-switch value = gate stays ACTIVE."
Confirmed as a real defect in all three existing kill switches.

### (c) citation-gate's semantic check is substring matching; one URL anywhere exempts the whole file

**Finding: CONFIRMED, both halves.**

`arch-citation-gate/hooks/citation-gate.sh:105-108`:
```python
TRIGGER_PHRASES = ("industry practice", "well-established", "well established",
                    "widely used", "업계 표준", "일반적으로", "널리 쓰이는")
low = content.lower()
if not any(p in low for p in TRIGGER_PHRASES):
    sys.exit(0)
```
This is plain `in` substring matching against the *entire* file's
lowercased content, with no word-boundary, no proximity, no
part-of-speech distinction. `일반적으로` ("generally/commonly") is a
common Korean adverb that appears in ordinary prose unrelated to any
"industry practice" claim (e.g. "일반적으로 이 값은 기본값을 쓴다" —
"generally this value uses the default" — a purely local statement,
not an external-knowledge claim). Any document containing this word
anywhere triggers the check, confirming the false-positive risk named
in the issue.

`citation-gate.sh:111-114`:
```python
has_url = re.search(r'https?://\S+', content) is not None
has_sources = re.search(r'^\s*sources:\s*\S', content, re.M | re.I) is not None
if has_url or has_sources:
    sys.exit(0)
```
`has_url`/`has_sources` are computed against `content` (the whole
resulting file), not scoped anywhere near the matched trigger phrase.
So one URL or one `Sources:` line *anywhere in the file* — including in
a section discussing something completely unrelated to the flagged
claim — exempts every trigger-phrase occurrence in that file. Confirmed
exactly as alleged: this is a whole-file OR, not a per-claim adjacency
check.

### (d) absolute-path normalization

**Finding: ALREADY-FIXED — not a defect, do not treat as one.**

All three gates compute the path the same way (e.g.
`adr-content-gate.sh:76-80`):
```python
root = os.path.normpath(os.environ["AG_ROOT"])
n = path.replace("\\", "/")
abs_path = n if posixpath.isabs(n) else posixpath.join(root, n)
abs_path = posixpath.normpath(abs_path)
rel = os.path.relpath(abs_path, root).replace("\\", "/")
```
This already handles both relative and absolute `file_path` values from
`tool_input`: if `path` is already absolute (`posixpath.isabs`), it is
used as-is; otherwise it's joined onto `root` first. `posixpath.normpath`
collapses `..`/`.`/duplicate slashes, and `os.path.relpath` re-derives
the root-relative form the glob checks match against
(`adr-content-gate.sh:82`, `citation-gate.sh:64-65`,
`sequence-gate.sh:71-78`). An absolute path like
`/home/.../docs/issue-13/proposals/x.md` and a relative path
`docs/issue-13/proposals/x.md` (with `CLAUDE_PROJECT_DIR` set to the
repo root) both resolve to the same `rel` and are matched identically.
No fixture currently exercises this path (see test-matrix note below),
but the logic itself is already correct — issue #13's demand for
"absolute-path normalization" is satisfied by existing code; the gap is
test coverage, not behavior. Recording this as ALREADY-FIXED so
phase-2 does not spend effort re-deriving something that already works,
and instead only adds the missing test fixture.

### (e) Bash-tool write bypass

**Finding: CONFIRMED — real gap, not explicitly named in issue #13's five-point list but directly relevant to "fail-closed everywhere."**

All three gates gate exclusively on `tool_name in ("Write", "Edit",
"MultiEdit")` (`adr-content-gate.sh:67`, `citation-gate.sh:49`,
`sequence-gate.sh:56`) and `sys.exit(0)` (allow, unconditionally) for
any other `tool_name`. A `Bash` tool call such as
`echo "..." > docs/issue-13/proposals/x.md` or
`tee docs/issue-13/reports/architecture.md <<< "..."` never reaches any
of the three Python bodies at all — the PreToolUse event fires with
`tool_name: "Bash"`, which none of the three `TARGET_RE`/`tool not in
(...)` checks recognize, so the write proceeds with **zero** gate
coverage. This is a real, confirmed gap: every one of the sourcing,
ordering, and section-structure norms this rulebook enforces can be
bypassed today by using the `Bash` tool instead of `Write`/`Edit`/
`MultiEdit`. Full shell-command parsing to close this generally is out
of scope for a proportionate fix here (see proposal's conservative
scope).

## Baseline test result

`bash tests/run-gate-tests.sh` (repo root, run 2026-08-01): **9/9
fixtures PASS, exit 0** — all three plugins' existing fixture sets are
green on this checkout, confirming none of the findings above are
regressions from a currently-broken baseline; they are genuine
never-covered gaps/behaviors.

```
== arch-adr-content-gate ==
PASS fail-missing-alternatives
PASS fail-multiedit-unresolvable
PASS pass-all-sections
== arch-citation-gate ==
PASS fail-unsourced-claim
PASS pass-sourced
== arch-sequence-gate ==
PASS fail-missing-scout-brief-no-skip-note
PASS fail-missing-survey
PASS pass-full-sequence
PASS pass-scout-skip-justified
```

None of the fixtures above exercise: a plain `Edit` (only `Write`-shaped
and `MultiEdit`-shaped fixtures exist per plugin), `replace_all`,
malformed JSON, any kill-switch value (recognized or unrecognized), or
an absolute `file_path`. See the proposal's mandatory test matrix.

## Prior art consulted

- `docs/issue-1/proposals/2026-07-31-architecture-norms.md` — origin of
  the citation-format rule this repo's `arch-citation-gate` mechanizes,
  and of the ADR/C4 required-section norm `arch-adr-content-gate`
  checks.
- `docs/issue-10/proposals/2026-07-31-architecture-enforcement.md` —
  origin of the current three-plugin gate split, the
  resulting-content-computation pattern all three gates share, and the
  explicit "canon-reference only, never vendor" constraint this survey's
  #72 blocker section applies.
