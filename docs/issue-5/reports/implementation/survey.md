# Issue #5 — Current-state survey: stub-check.sh vendored copy

## Scope

Issue #5 asks to roll out the core #69 canon decision to this rulebook: `stub-check.sh`
must be run by reference from the core installation
(`core/hooks/tests/stub-check.sh`), never vendored (copied) into a rulebook.
This is a phase-1 survey only — no files were changed.

## Findings

### 1. Vendored copy of stub-check.sh

- **File:** `architecture/hooks/tests/stub-check.sh` (90 lines)
- This is a full, standalone copy of the stub-check script (shebang, `CANON_GATES`
  list, directive.sh structural check, etc.), not a reference/symlink to a core
  installation path.
- The file's own header (lines 1–25) documents that it is meant to be
  "distributed to every rulebook the way parse-check.sh already is ... dropped
  alongside it" and "every rulebook copies this file verbatim" — i.e. the copy
  itself asserts the now-superseded distribution model. Core #69 canon
  (per the issue-5 description) supersedes this: stub-check is to be referenced
  from `core/hooks/tests/stub-check.sh`, not copied.
- No other files named `stub-check.sh`, and no files containing equivalent
  `CANON_GATES` / stub-check logic, were found elsewhere in the repo.

### 2. hooks.json registration status

- **File:** `architecture/hooks/hooks.json`
- Contents register exactly one hook: `SessionStart` → `${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh`.
- **stub-check.sh is not referenced in hooks.json at all** — it is not wired
  into any hook event. It exists only as a standalone test script under
  `hooks/tests/`, presumably invoked manually or by an external test harness,
  not by the plugin's hook registration.
- Consequence: there is no hooks.json entry to "convert" from copy-registration
  to reference-registration — the only cleanup needed is removing/replacing the
  vendored file itself. (If a project-level test harness invokes this file by
  its vendored path, that invocation point should be checked in phase 2 before
  deletion — see proposal.)

### 3. Core #69 canon text (docs/handbooks/canon-scripts.md)

- No `docs/handbooks/canon-scripts.md` (or any `canon-scripts.md`) file exists
  in this repo. `docs/handbooks/` does not currently exist under `docs/` at all
  (only `docs/specs/` and per-issue `docs/issue-2/` are present).
- The canon rule text cited by issue #5 ("stub-check는 core 설치본에서 참조
  실행하며 룰북 복사는 금지") is therefore **not present locally** — it is
  referenced from core issue #69 and lives in core's own docs/handbooks tree,
  external to this rulebook repo. This survey treats the issue body's
  description of that canon as authoritative for scoping the proposal.

### 4. Other observations

- `architecture/hooks/hooks.json` has no other vendored-canon-file entries
  requiring similar treatment; the file registers only `directive.sh`, which
  per the vendored stub-check.sh's own comments (lines 15–20) is expected to
  remain a small per-role file, not something to dereference to core.
- `docs/specs/approvers.md` exists and lists rulebook approvers (relevant for
  phase 2 gating, not surveyed in detail here).

## Summary table

| Item | Path | Status |
|---|---|---|
| Vendored stub-check.sh | `architecture/hooks/tests/stub-check.sh` | Present, full copy — should be removed per core #69 |
| hooks.json stub-check entry | `architecture/hooks/hooks.json` | No entry exists — nothing to convert |
| Local canon text | `docs/handbooks/canon-scripts.md` | Not present in this repo |
