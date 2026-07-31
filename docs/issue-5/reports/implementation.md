---
subject: issue-5
role: implementation
loop_state: landed
---

# Phase-2 record: remove vendored stub-check.sh (issue #5)

Executes `docs/issue-5/proposals/stub-check-dedup.md` after phase-2
approval (issue comment `APPROVE issue-5/implementation`, JiwonJung94,
2026-07-31). See `docs/issue-5/reports/implementation/survey.md` for the
phase-1 current-state survey.

## Why

core #69 confirmed canon: `stub-check.sh` must run only from the core
installation (`core/hooks/tests/stub-check.sh`); a rulebook must never
vendor its own copy. `architecture/hooks/tests/stub-check.sh` was exactly
such a vendored copy — the drift pattern the canon decision exists to
eliminate. Issue #5 asks this rulebook to roll out that canon: delete the
copy, remove any `hooks.json` registration for it, and record a passing
stub-check run executed by reference against core.

## What was done

1. Deleted `architecture/hooks/tests/stub-check.sh` (the vendored copy).
   The `architecture/hooks/tests/` directory was left empty and was
   removed along with it.
2. No `architecture/hooks/hooks.json` edit was needed: it registers only
   `SessionStart` -> `directive.sh` and never had a stub-check entry
   (confirmed in the phase-1 survey and reconfirmed by inspection before
   deletion).
3. Ran the core-canon `stub-check.sh` by reference — invoking
   `tokenmaxxxer-core/core/hooks/tests/stub-check.sh` directly, never
   copying it into this repo — against `architecture/hooks`, once before
   deletion (to confirm the FAIL this issue was opened to fix) and once
   after (to confirm the pass).

### stub-check run, before deletion (baseline)

Command: `bash <core>/core/hooks/tests/stub-check.sh architecture/hooks`
(`<core>` = `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core`)

```
stub-check: ok — no vendored 'trailer-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'parse-check.sh' under architecture/hooks
stub-check: FAIL — vendored copy of core canon file 'stub-check.sh' found:
architecture/hooks/tests/stub-check.sh
  This file is now a core hook (core/hooks/hooks.json), fired for
  every plugin install. A local copy is drift, not a stub — delete
  it and drop the file's own hooks.json entry, if any (issue-66).
stub-check: ok — architecture/hooks/directive.sh is a role-directive stub
```

Exit code: 1.

### stub-check run, after deletion (delivered state)

Same command, same core path, run again after `git rm` of the vendored
file:

```
stub-check: ok — no vendored 'trailer-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under architecture/hooks
stub-check: ok — no vendored 'parse-check.sh' under architecture/hooks
stub-check: ok — no vendored 'stub-check.sh' under architecture/hooks
stub-check: ok — architecture/hooks/directive.sh is a role-directive stub
```

Exit code: 0.

stub-check passes cleanly when run by reference against the core
installation; this rulebook no longer carries any copy of the script.

## Verification

- `grep -rn "stub-check" architecture/` finds no remaining vendored file
  and no `hooks.json` entry.
- `architecture/hooks/` now contains only `directive.sh` and
  `hooks.json`.

## Open findings

None. The proposal's scope (delete the vendored copy; no hooks.json
change needed; record a reference-run pass) is fully executed, and no new
vendored-copy or registration issues were found during verification.
