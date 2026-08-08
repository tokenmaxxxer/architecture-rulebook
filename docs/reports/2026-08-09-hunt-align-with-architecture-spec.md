---
proposal: docs/issue-19/proposals/2026-08-09-align-with-architecture-spec.md
---

# Hunt record — align-with-architecture-spec

## after-proposal — stance 0: planned scope-proposed/proposed -> drafting/reviewing literal swap in adr-content-gate.sh and sequence-gate.sh opens a bypass for decision-bearing records

Verdict: NO FINDING
Seed: git diff --stat da8565d HEAD (commit a6fc532, 3 new docs files, 333 lines, all under docs/)
cap_seconds: 60
tier: default
diff_stat_lines: 333
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:02:00Z

Checked both gates' actual skip-set logic (not yet changed by this docs-only
commit; hooks are unmodified today):

- arch-adr-content-gate/hooks/adr-content-gate.sh:107-109
- arch-sequence-gate/hooks/sequence-gate.sh:161-163

Both do: `loop_state = <frontmatter value>.strip().lower()`, then
`if loop_state in ("", "scope-proposed", "proposed"): sys.exit(0)` (skip
enforcement). The proposal's planned phase-2 edit swaps the two literals for
`"drafting"`/`"reviewing"` — a straight 1:1 substitution of the exact-match
skip-set membership test, with no change to the matching mechanism (still
lowercased, still an exact-string set test, no regex/prefix/casing
weakening introduced). No loop_state value or casing exists that would land
in the post-swap skip set but not the pre-swap one (or vice versa) other
than the two swapped literals themselves — there's no ordering dependency
either (Python `in` on a tuple, order-independent).

Checked the historical-frontmatter half of the stance too: the proposal
explicitly leaves per-issue historical frontmatter values untouched
(Rationale c). If an old record still carrying `loop_state: scope-proposed`
or `proposed` is re-edited after phase 2 lands, it does NOT silently bypass
the gate — the opposite happens. `"scope-proposed"`/`"proposed"` fall out of
the post-swap skip set (which is now `("", "drafting", "reviewing")`), so
the gate treats the unmigrated old record as decision-bearing and enforces
the Context/Decision/Consequences/Alternatives-Considered/C4 sections
against it — over-enforcement/possible false-positive denial on old docs,
not a silent bypass of required-section checking. This is the reverse of
the failure mode the stance asked about, so it doesn't support the stance
either.

No reproduction of a bypass was found; the swap is semantics-preserving for
the skip/enforce decision.

## before-landing — stance 1: assume this change and another plugin's rule cancel each other — find the pair

Verdict: NO FINDING
Seed: git diff HEAD (staged, before-landing) touching arch-adr-content-gate/hooks/adr-content-gate.sh, arch-sequence-gate/hooks/sequence-gate.sh, docs/handbooks/architecture-methodology.md, README.md — loop_state vocabulary migrated scope-proposed/proposed -> drafting/reviewing, plus new skip-states decision-not-ripe/options-unreachable and new decision_id/outcome frontmatter checks in adr-content-gate.sh.
cap_seconds: 120
tier: default (size:21-200-line diff)
diff_stat_lines: 28 files changed, 129 insertions(+), 31 deletions(-)
started_at: 2026-08-09T05:53:56+09:00
ended_at: 2026-08-09T05:55:10+09:00

Checked for another gate/plugin in this repo hardcoding the old loop_state vocabulary (scope-proposed/proposed) that would now silently never fire against drafting/reviewing records: `grep -rln "loop_state" --include="*.sh" .` returns only arch-adr-content-gate/hooks/adr-content-gate.sh and arch-sequence-gate/hooks/sequence-gate.sh — the two files this diff itself edits in lockstep (both migrated together, same skip-state list added to both). No third gate (arch-citation-gate, arch-phase1-checklist) references loop_state or the old vocabulary at all — `grep -n "proposed\|scope-proposed\|drafting\|reviewing" arch-citation-gate/hooks/*.sh` is empty.

Also checked core's record-fields-gate.sh (/home/jwjung/tokenmaxxxer-core/core/hooks/record-fields-gate.sh), which independently reads loop_state and has its own TERMINAL-state logic (KIND_TERMINAL_DEFAULTS / ROLE_TO_KIND / docs/specs/record-fields-terminal-states.json override) — a plausible collision point for a "required field" or "terminal state" mismatch. Its ROLE_TO_KIND mapping has no "architecture" entry, and no docs/specs/record-fields-terminal-states.json override file exists in this repo, so it falls through to LEGACY_FALLBACK_TERMINAL / a self-declared `kind:` field — it does not hardcode or reference scope-proposed/proposed/drafting/reviewing anywhere, so it is not coupled to this repo's architecture loop_state vocabulary and cannot be cancelled by this rename.

Also checked adr-content-gate.sh's new decision_id/outcome frontmatter requirements against record-fields-gate.sh's own required-field list (what-was-done/why/upstream-basis/loop_state/open-findings/next-steps) — the two field sets are disjoint (decision_id/outcome vs. loop_state/next-steps/etc.), so a record satisfying one does not fail the other; no cancellation reproduced.

No reproduction found of two rules that individually pass but combine to silently disable each other. Stopping per the "no reproduction, no finding" rule.
