---
subject: issue-10
role: architecture
loop_state: scope-proposed
---

# Scout brief: comparable in-repo-ecosystem hook-machine gates (issue #10)

Field: internal governance tooling (no external product field applies;
comparable systems are sibling rulebooks on this same repo family, per
the survey's skip-record).

## Must-bes (what a real hook-machine gate needs)

- An actual executable check (shell/python), not prose — wired into
  `hooks.json` as a real `PreToolUse` matcher, not a doc saying "should
  check."
- Fail-closed on ambiguity: cannot-determine-content → deny, not skip
  (this repo's own `adr-gate.sh` already fails on missing sections but
  does not yet fail-closed on internal/parse error — a gap vs. the
  pattern below).
- Pass/fail state that is inspectable (exit code + stderr message naming
  exactly what's missing), plus a kill switch env var, matching this
  repo's existing convention (`ARCHITECTURE_ADR_GATE_OFF`).
- Tested: at least one fixture that must pass and one that must fail,
  runnable outside an interactive session.

## Performance axes

- **Strictness vs usability**: a phase-1 gate that blocks *every*
  proposals-directory write until survey+scout-brief exist is stricter
  but risks blocking legitimate early drafts; a gate that only fires once
  a proposal reaches a certain marker (e.g. non-empty "Decision" content)
  is more usable but weaker. Trade this explicitly in the proposal.
- **Canon-reference vs vendoring**: every new check must cite
  `core`'s canon location and stay additive, per issue-5's precedent —
  never re-copy core's generic `record-fields-gate` logic.
- **File-count cost vs enforcement strength**: issue-2 removed
  role-specific gates in favor of core-generic ones; issue-1 already
  reversed that once (`adr-gate.sh`) for phase-2. Issue #10 asks to
  reverse it again for phase-1 — each new gate file is a real,
  named cost the proposal must own, not a free addition.

## Pattern to adopt

From `pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh`
(external sibling, pattern only, not vendored): the
"required-element checklist over the *new resulting content*, not the
existing file" technique — it computes what Write/Edit/MultiEdit would
produce before allowing it, and denies when it cannot compute that
resulting text rather than guessing. This directly closes a gap
`adr-gate.sh` currently has (it reads `tool_input.content // new_string`
without handling MultiEdit or a not-yet-determinable result).

## Pattern to deliberately skip

The pricing gate's fully custom python-in-heredoc JSON/path-resolution
scaffolding (root-detection via `CLAUDE_PROJECT_DIR`/git-toplevel
fallback, `_plausible`/`_under` sandboxing checks) — that generality
solves a multi-repo-root ambiguity this single-plugin repo does not have
(`adr-gate.sh` already assumes a simple relative `file_path` match, and
that assumption has held for issue-1's landed gate). Reproducing that
scaffolding here would add ~150 lines with no incremental compliance
correctness for this repo's simpler layout — pure overhead.

## Gap line

This plugin already has phase-2 element-checking (`adr-gate.sh`) at
roughly pricing-methodology-gate.sh's *checklist* rigor, but has zero
phase-1 coverage, zero ordering/state enforcement across the
survey→scout→proposal→approve→phase-2 sequence, and zero tests. Parity
requires: a phase-1 gate (new file, additive, canon-referencing only),
some ordering signal (state file or frontmatter convention, not full
state-machine complexity per pricing's scope), and a `tests/` directory
exercising both gates with pass/fail fixtures.

Sources:
- `architecture/hooks/adr-gate.sh` (this repo)
- `pricing-rulebook-issue-1-pricing/pricing/hooks/methodology-gate.sh` (external sibling checkout, read on local disk)
- `docs/issue-1/proposals/2026-07-31-architecture-norms.md` (this repo)
- `docs/issue-2/proposals/2026-07-31-switch-to-core-canon.md` (this repo)
