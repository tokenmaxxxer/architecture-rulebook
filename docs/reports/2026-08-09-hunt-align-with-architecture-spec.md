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
