# arch-phase1-checklist

A checklist artifact, not a tool-use subagent — read before opening a
phase-1 PR for the `architecture` role. This role's `YOU DECIDE` does not
involve a bounded search/hunt task the way a real subagent (e.g.
`warrant-hunter`) does, so a checklist document provides the needed
proportion of enforcement without subagent overhead.

## Ordered steps

1. **Survey exists and cites sources** — `docs/issue-<n>/reports/
   architecture/survey.md` names the current-state read, and every claim
   sourced from outside this repo carries a URL or a `Sources:` entry
   (`arch-citation-gate` mechanizes this for the proposal; the survey
   itself is convention, not gated).
2. **Scout-brief exists, or a skip is justified** — `docs/issue-<n>/
   reports/architecture/scout-brief.md` exists, or the proposal text
   states the skip condition explicitly (issue-1's skip-condition
   language: the spec leaves no design decision open). `arch-sequence-
   gate` mechanizes the existence/skip-justification check before the
   phase-2 record can leave `scope-proposed`/`proposed`.
3. **Proposal cites both by path and states Files/How-success** —
   `docs/issue-<n>/proposals/*.md` links the survey and scout-brief by
   path, and includes a `Files (write set)` section and a `How success
   will be judged` section (this repo's existing proposal shape,
   `docs/issue-1/proposals/2026-07-31-architecture-norms.md` and
   `docs/issue-10/proposals/2026-07-31-architecture-enforcement.md` as
   examples).
4. **Ready for `APPROVE issue-<n>/architecture`** — once 1-3 hold, the
   proposal is ready for phase-2 approval per `docs/specs/approvers.md`
   and `role-handoff-contract.md` §19.

## Relationship to the gates

This checklist is the human-facing ordered procedure that
`arch-sequence-gate` and `arch-citation-gate` mechanize (existence and
sourcing respectively); it does not duplicate their logic and is not
itself enforced by a hook.
