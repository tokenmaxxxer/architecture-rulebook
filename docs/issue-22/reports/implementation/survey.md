# Survey — issue #22

## Write set (expected)
- `tests/run-gate-tests.sh` (aggregator)
- `arch-adr-content-gate/tests/run.sh`
- `arch-citation-gate/tests/run.sh`
- `arch-sequence-gate/tests/run.sh`
- a new vendored resolver module (shared by the three `run.sh` files)
- `.env.example` — not touched; the resolver reads no new secret/config, only `CLAUDE_PLUGIN_ROOT_CORE` which already exists

## Current state, confirmed by running the tests
On a plain checkout with `CLAUDE_PLUGIN_ROOT_CORE` unset and no sibling
`../../core` checkout, `bash tests/run-gate-tests.sh` produces real FAIL
lines for fixtures whose name starts `pass-` (e.g. `pass-sourced`,
`pass-full-sequence`, `pass-plain-edit`, `pass-multiedit-resolvable`,
`pass-scout-skip-justified`, `pass-options-unreachable-skips-check`,
`pass-bash-unrelated-command`, `pass-decision-not-ripe-skips-check`,
`pass-kill-switch-recognized-off`) across all three gates. The failure
is `cannot source gate-lib.sh` (rc=2) inside each gate script
(`arch-*-gate/hooks/*.sh`), not a real regression in gate logic — the
fixture's `fail-missing-core/env.sh` already deliberately points
`CLAUDE_PLUGIN_ROOT_CORE` at a nonexistent path to test exactly this
failure mode, and that fixture correctly reports PASS because its
`expect.txt` says `fail`. The bug is that every *other* fixture, which
expects the gate to actually run, breaks the same way when core just
isn't reachable in the current checkout.

The three gate scripts (`arch-adr-content-gate/hooks/adr-content-gate.sh:36`,
`arch-citation-gate/hooks/citation-gate.sh:34`,
`arch-sequence-gate/hooks/sequence-gate.sh:43`) already resolve core via
`${CLAUDE_PLUGIN_ROOT_CORE:-<sibling ../../core>}` and exit 2 with a
message on failure — that resolution belongs to the *gate*, and per the
issue ("Do not weaken any assertion that runs when core IS reachable")
is out of scope to touch. The fix is entirely in the *test* layer: the
`run.sh` files need to know, before invoking the gate, whether core is
reachable at all, and if not, print the convention's SKIP message and
exit 75 for the whole file — instead of letting individual fixture
comparisons produce misleading FAIL lines. `tests/run-gate-tests.sh`
then needs to treat a 75 from a sub-runner as SKIP, not FAIL.

## The convention (on-the-record, docs/specs/test-env-resolution.md, issue #551)
Fetched from `tokenmaxxxer/on-the-record` — this repo has no local copy.
Resolution order: `$CLAUDE_PLUGIN_ROOT_CORE` (if it contains
`hooks/lib/gate-lib.sh`, size > 0) → first caller-supplied sibling
candidate containing the same file → SKIP, print
`SKIP: core plugin unreachable — unverifiable outside spawn env` to
stderr, exit `75` (`EX_TEMPFAIL`, distinct from a gate's own 0/1/2).
Reference implementation is a Python module,
`gates/test_env_resolve.py`, invoked by bash test runners as a CLI:
`python3 -m gates.test_env_resolve <candidate1> <candidate2> ...`,
branching on exit code (0 = resolved, prints path to stdout; 75 = skip).
The doc explicitly names this "Bash test runner" shape as the intended
consumption path for exactly this repo's kind of `run.sh`.

Empty-state exception named in the convention doc: a pytest suite with
no core dependency at all is out of scope. Not applicable here — all
three `run.sh` files in this repo test gates that DO depend on core.

## Existing local patterns worth reusing
All three `run.sh` files already share near-identical structure: `cd`
to their own dir, loop `fixtures/*/`, optionally source a fixture-local
`env.sh`, run the gate, compare rc against `expect.txt`. None currently
do any core-reachability check up front — each just lets the gate's own
internal `cannot source gate-lib.sh` exit 2 propagate into the
PASS/FAIL comparison, which is what turns "core missing" into "test
FAILED" for every `pass-*` fixture. `tests/run-gate-tests.sh` treats
any nonzero `run.sh` exit as `fail=1` — no distinction for skip today.

The `fail-missing-core` fixtures (one per gate) exist specifically to
test the *gate's* own missing-core message and are unaffected by this
change — they should still exercise a scenario where
`CLAUDE_PLUGIN_ROOT_CORE` is deliberately broken (this proves the
convention's own env var still overrides candidate resolution when set,
even to a bad value — matching resolution order step 1).

## Alternatives visible from this survey
1. **Vendor the Python reference module verbatim** (as the convention
   doc's "Bash test runner" section describes) and have each `run.sh`
   shell out to it via `python3 -m ...`.
2. **Re-implement the same resolution order directly in bash**, inline
   in each `run.sh` or as one sourced `tests/lib/resolve-core.sh` — no
   Python dependency, but duplicates the convention's tested resolver
   as a bash port rather than reusing the on-the-record reference.
3. **Only fix `tests/run-gate-tests.sh`** (the aggregator) and leave
   each gate's own `run.sh` unchanged — cheaper, but fails the issue's
   check that scripts reference the convention doc and that the
   per-gate `run.sh` files (runnable standalone, e.g. by a developer
   `cd`-ed into one plugin) also SKIP correctly rather than fail.

These are weighed in the proposal's Rationale section.
