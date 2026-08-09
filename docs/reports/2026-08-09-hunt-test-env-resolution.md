---
proposal: docs/issue-22/proposals/2026-08-09-test-env-resolution.md
---

# Hunt record — test-env-resolution

## after-proposal — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list.

Verdict: NO FINDING
Seed: docs/issue-22/proposals/2026-08-09-test-env-resolution.md (write set: tests/run-gate-tests.sh, tests/lib/test_env_resolve.py, arch-adr-content-gate/tests/run.sh, arch-citation-gate/tests/run.sh, arch-sequence-gate/tests/run.sh)
cap_seconds: 120
tier: default
diff_stat_lines: ~203 (2 new doc files)
started_at: 2026-08-09T09:40:00Z
ended_at: 2026-08-09T09:58:00Z

Checked for an unlisted path the phase-2 build would actually need to touch:
- `find . -name run.sh`: only the three `arch-*-gate/tests/run.sh` scripts exist repo-wide (`arch-phase1-checklist` and `architecture` plugins have no `tests/` dir at all), so the write set's three run.sh entries are exhaustive — no fourth gate's run.sh is missing.
- `grep -rln "tests/run.sh|run-gate-tests" --include=*.md --include=*.json .` and a search for Makefile/package.json/justfile/.pre-commit-config/.github workflows: none exist in this repo, so there is no CI/build file elsewhere that hard-codes an exit-code contract (0/1) for these scripts that a new exit-75 SKIP would silently break.
- Compared the three run.sh files with `diff`: each has a genuinely different loop/subshell idiom (adr-content-gate uses `bash -c '. "$1"; exec bash "$2"'`, citation-gate uses `(. env.sh; ...)` in a plain subshell, sequence-gate pre-resolves `gate_abs` and pipes JSON via `printf`), confirming the preflight-check insertion point differs per file — but all three are already in the write set, so this isn't an omission.
- Confirmed `tests/lib/` doesn't exist yet (`ls tests/` shows only `run-gate-tests.sh`), but the new file's own directory creation is implied by creating `tests/lib/test_env_resolve.py` itself — not a separate path needing separate handling.
- Confirmed python3 is already a hard dependency of every gate itself (`command -v python3 >/dev/null || exit 2` in `arch-adr-content-gate/hooks/adr-content-gate.sh` and siblings), so the new resolver's python3 dependency isn't a newly-introduced, undeclared requirement.
- Ran `bash tests/run-gate-tests.sh` in the current sandbox: exit 0, all 42 fixtures PASS, because `CLAUDE_PLUGIN_ROOT_CORE` happens to be set in this spawn env (`/home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core`) — this doesn't match either of the proposal's example sibling candidates (`../../core`, `../../../tokenmaxxxer-core/core`), but that's irrelevant since step-1 (env var) always wins over the sibling fallback candidates the new preflight would pass.
- Checked `fail-missing-core` fixtures' `env.sh` (`export CLAUDE_PLUGIN_ROOT_CORE=/nonexistent-core-path-for-test`, sourced in a per-fixture subshell) against the plan's proposed pre-loop `export CLAUDE_PLUGIN_ROOT_CORE=<resolved>`: the per-fixture subshell override doesn't leak back to the parent's exported value, so the pre-existing missing-core fixture keeps working as the proposal claims — no separate fixture-format change needed.

No concrete reproduction of a missing write-set path was found; the three run.sh files plus the aggregator plus the new lib file appear to cover every location the plan requires touching, given the current repo layout (no CI, no cross-file exit-code contract, no fourth gate).

## before-landing — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: NO FINDING
Seed: arch-adr-content-gate/tests/run.sh, arch-citation-gate/tests/run.sh, arch-sequence-gate/tests/run.sh, tests/run-gate-tests.sh, tests/lib/test_env_resolve.py
cap_seconds: 120
tier: default
diff_stat_lines: 54 insertions(+), 3 deletions(-) across 4 files (+ new vendored file)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:05:00Z

Probed for state the pre-flight resolver/aggregator assumes but nothing maintains: (1) ran `bash tests/run-gate-tests.sh` in the actual spawn env — all three gates resolved CLAUDE_PLUGIN_ROOT_CORE and passed; (2) ran it again with `env -u CLAUDE_PLUGIN_ROOT_CORE` (no sibling `core`/`tokenmaxxxer-core/core` checkouts present) — all three sub-runners correctly emitted SKIP and the aggregator correctly exited 75 (all-skipped, none-ran, none-failed); (3) checked the `fail-missing-core` fixture's `env.sh` override (`CLAUDE_PLUGIN_ROOT_CORE=/nonexistent-core-path-for-test`) against the new global pre-flight export — the fixture-local override still shadows the pre-flight export correctly inside its own subshell, and the fixture still PASSes; (4) verified the `rc=$?` capture in `run-gate-tests.sh`'s `if bash "$runner"; then ... else rc=$? ...` correctly reads the sub-runner's real exit code, not some intermediate command's; (5) verified the sibling-candidate relative paths (`../../../core`, `../../../tokenmaxxxer-core/core`) are computed consistently at the same directory depth across all three gates. No mismatch between what the resolver/aggregator assumes exists and what actually exists (or is exercised) was found; the "state" it depends on (spawn-env var, or absence thereof triggering SKIP) is exactly what's live in each of the two runs performed. No reproduction of a wrong output.
