# arch-citation-gate

Owns exactly one methodology: the **sourcing norm** (issue-1's
citation-format rule, generalized) — every claim phrased as external or
industry knowledge carries a URL or a `Sources:` entry.

## What it checks

Fires on `docs/issue-<n>/proposals/*.md` and `docs/issue-<n>/reports/
architecture.md` writes. Whenever the resulting content contains
trigger phrasing (`industry practice`, `well-established`, `widely
used`, and Korean equivalents) with no URL and no `Sources:` line
anywhere in the file, the gate refuses. Shared unchanged across phase-1
and phase-2 per this rulebook's combination table — one script, two
globs, not two implementations.

## Kill switch

`export ARCH_CITATION_GATE_OFF=1`

## Canon pointer

Layered additively on core canon's generic `record-fields-gate.sh`
(referenced by pointer, never vendored).
