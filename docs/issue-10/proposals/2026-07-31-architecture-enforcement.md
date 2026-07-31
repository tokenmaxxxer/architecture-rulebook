---
subject: issue-10
role: architecture
loop_state: scope-proposed
---

# Proposal: turn issue-1's adopted methodology into an enforcement mechanism

## Revision note (2026-07-31, phase-1 rework)

This revision replaces the original "one directive-deepening + one
monolithic `phase1-gate.sh`" design with the structure the PR approver's
`요구 정정` (requirement correction) comment on issue #10 mandates:

> 단일 게이트/디렉티브 심화가 아니라 **플러그인 세트**로 체계화한다 —
> 채택 방법론 각각을 독립 플러그인으로(core의 freelunch/scout처럼,
> 룰북당 여러 개, freelunch 수준의 완성도), 기획서(phase 1)/산출물
> (phase 2) 규범도 각각을 플러그인 조합으로 풀어내며, 각 플러그인은
> 자기 완결(디렉티브/게이트/에이전트/테스트 포함 가능)에 marketplace
> 등록·단일 방법론 담당을 요구하고, proposal에는 플러그인 목록(이름·
> 담당 방법론·구성요소·조합 관계)이 필수다.

Every "Design" section below is rewritten against this mandate. The
**required deliverable is now a plugin set**, not a single gate file:
each adopted methodology element becomes its own independent,
self-contained plugin (own directive/hooks/tests, own `plugin.json`,
own `marketplace.json` entry), and the phase-1 (기획서) norm and the
phase-2 (산출물) norm are each expressed as which of those plugins
combine, not as one gate script doing everything. See "§0 Plugin list
(required)" for the mandatory inventory, and `core`'s `freelunch`/
`scout` plugins (`/home/jwjung/claude-plugins/freelunch`,
`/home/jwjung/claude-plugins/scout` on this checkout) for the
one-methodology-one-plugin reference shape this proposal follows.

## Request (paraphrased intent)

Issue #10 says issue-1's maturation left the adopted methodology as one
directive summary line plus a phase-2-only content gate
(`adr-gate.sh`) — real, but partial. It asks this role to (1) deepen the
directive text per phase into stages/judgment-criteria/prohibitions at
facet granularity, (2) add a **methodology gate** that mechanically
checks the required PRODUCES elements of the approved norm, with state
tracking if the methodology has an order constraint (survey → evidence →
proposal, in this role's case), (3) add gate tests under a `tests/`
directory, and (4) add agents/checklists if a repeated procedure is
warranted — matched to the rigor level the issue calls "hook-machine,"
and constrained to reference core's canon only, never vendor it.

See `docs/issue-10/reports/architecture/survey.md` for the current-state
read and `docs/issue-10/reports/architecture/scout-brief.md` for the
scouted pattern this proposal builds on.

## Constraints

- **Phase-1 only.** This document is a design spec. No hook file, no
  test file, no directive-text edit ships in this PR. Everything under
  "Design (for phase 2)" below is a precise spec for phase 2, applied
  only after a human `APPROVE issue-10/architecture`.
- **Canon-reference only, never vendor** (issue body's `캐논 참조만·복사
  금지`, and this repo's own issue-5 precedent). The new phase-1 gate
  must cite `core`'s canon location/mechanism by pointer (e.g.
  `core/hooks/tests/stub-check.sh`, `core`'s generic
  `record-fields-gate.sh`) and must not copy either their code or the
  external `pricing-rulebook`'s `methodology-gate.sh` code — only its
  *shape* is adopted, per the scout-brief.
- **`write_scope` and role boundary are unchanged.** This proposal does
  not touch `WRITE_SCOPE: ["docs/issue-<n>/decisions/**"]`, the
  `HAND-OFF`/`BOUNDARY CASE` text, or any other role's territory.
- **Additive to `adr-gate.sh`, not a replacement.** The existing
  phase-2 gate stays; this proposal only adds phase-1 coverage and
  closes one phase-2 gap the scout-brief names (resulting-content
  computation for `MultiEdit`/unresolvable edits).
- **Naming discipline.** Any new gate filename must avoid
  `stub-check.sh`'s reserved core-canon names (`record-fields-gate.sh`,
  `trailer-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
  `stub-check.sh` itself), per issue-1's already-hit collision.

## §0 Plugin list (required)

The approver's correction makes this the design's body: **which
independent plugins exist, which single methodology each owns, what
each plugin is made of, and how the phase-1/phase-2 norms combine
them.** Every plugin below is self-contained (own `.claude-plugin/
plugin.json`, own `hooks/`, own directive text where applicable, own
`tests/fixtures/`) at the completeness level `freelunch` and `scout`
demonstrate, is registered as its own entry in
`.claude-plugin/marketplace.json`, and owns exactly one methodology
element — never a bundle of unrelated checks.

| # | Plugin (dir) | Methodology it owns | Self-contained components | Kill switch |
|---|---|---|---|---|
| 1 | `arch-sequence-gate/` | Phase ordering: survey → scout-brief (or justified skip) → proposal → record, enforced before any `docs/issue-<n>/reports/architecture.md` write leaves `loop_state: scope-proposed`/`proposed`. | `hooks/sequence-gate.sh` (PreToolUse, file-existence + `loop_state` precondition check), `hooks/hooks.json`, `tests/fixtures/{pass-full-sequence,fail-missing-survey,fail-missing-scout-brief}/`, `README.md` stating the one methodology it owns. | `ARCH_SEQUENCE_GATE_OFF=1` |
| 2 | `arch-citation-gate/` | Sourcing norm: every phase-1 proposal claim sourced from outside this repo carries a URL or `Sources:` entry (issue-1's citation-format rule, made mechanical and reusable across both phases). | `hooks/citation-gate.sh` (PreToolUse on `docs/issue-<n>/proposals/*.md` and `docs/issue-<n>/reports/architecture.md`, resulting-content computation per the scout-brief's adopted pattern, fail-closed on unresolvable `MultiEdit`), `hooks/hooks.json`, `tests/fixtures/{pass-sourced,fail-unsourced-claim}/`, `README.md`. | `ARCH_CITATION_GATE_OFF=1` |
| 3 | `arch-adr-content-gate/` | ADR+C4 required-element norm for the phase-2 record itself (context/decision/consequences/alternatives-considered sections, C4 diagram presence) — this is today's `adr-gate.sh` re-homed as its own plugin rather than a script embedded in the general `architecture` plugin, so it can be versioned/tested/registered independently of directive/sequence concerns. | `hooks/adr-content-gate.sh` (migrated from `architecture/hooks/adr-gate.sh`, MultiEdit resulting-content gap closed here), `hooks/hooks.json`, `tests/fixtures/{pass-all-sections,fail-missing-alternatives,fail-multiedit-unresolvable}/`, `README.md`. | `ARCH_ADR_CONTENT_GATE_OFF=1` (keeps today's env-var name as a deprecated alias for one release, per this repo's own no-silent-break precedent) |
| 4 | `arch-phase1-checklist/` | The repeated survey→scout-brief→proposal procedure issue #10 flags as agent/checklist-worthy — one plugin, one methodology (procedural checklist), not folded into a gate. | `agents/phase1-checklist.md` (a checklist artifact read before opening a phase-1 PR — not a tool-use subagent, matching this role's proportionality call), `README.md` naming the ordered steps (survey cites sources → scout-brief exists or skip is justified → proposal cites both by path and states Files/How-success). | n/a (documentation-only plugin, no hook to disable) |

Each plugin gets its own `.claude-plugin/plugin.json` (`name`,
`description` naming its single methodology, matching the shape of
`architecture/.claude-plugin/plugin.json` and `freelunch`'s/`scout`'s)
and its own entry in this repo's root `.claude-plugin/marketplace.json`,
sibling to the existing `architecture` entry — none of the four replace
or fold into that entry; `architecture` keeps owning
`directive.sh`/role-boundary concerns only.

### Combination: how phase-1 (기획서) and phase-2 (산출물) norms compose

Neither phase's norm is one plugin's job; each is the **combination**
of plugins firing on that phase's write surface:

- **Phase-1 (기획서/proposal) norm** = `arch-sequence-gate` (survey
  and, unless justified-skip, scout-brief must exist before/alongside
  the proposal write) **combined with** `arch-citation-gate` (every
  proposal claim sourced) **combined with** `arch-phase1-checklist`
  (the human-facing ordered procedure the two gates above mechanize).
  All three fire on `docs/issue-<n>/proposals/*.md` writes; none of the
  three alone expresses the full 기획서 norm.
- **Phase-2 (산출물/record) norm** = `arch-sequence-gate` (all
  phase-1 artifacts for the same `issue-<n>` must already exist before
  `loop_state` can leave `scope-proposed`) **combined with**
  `arch-adr-content-gate` (the record's own ADR+C4 sections)
  **combined with** `arch-citation-gate` (reused unchanged — the
  record inherits the same sourcing norm, not a re-implementation).
  All three fire on `docs/issue-<n>/reports/architecture.md` writes.

This is the structural change from the prior revision: previously one
`phase1-gate.sh` tried to own ordering, sourcing, and section-structure
checks together; now each concern is a separate, independently
testable, independently versioned plugin, and the phase's norm is
legible as *which plugins are wired to that file glob*, not as one
script's internal branches.

## Design (for phase 2 — spec only)

### 1. Directive deepening (facet-level, phase-split)

Today's single `PRODUCES` string in `directive.sh` stays as the
one-line summary `core_role_directive` already expects (its signature is
fixed by core canon and this proposal does not ask core to change it).
What deepens is a **new phase-1/phase-2 facet document**,
`docs/handbooks/architecture-methodology.md` (this rulebook's own
handbook, not a core-canon file — handbooks are per-role per
`core`'s handbook-trigger-gate convention already referenced in the
README), containing:

- **Phase 1 facet** — stages: (a) survey current-state +external
  research, (b) scout-brief (skip only if the spec leaves no design
  decision open — issue-1's own skip-condition text, carried forward
  verbatim), (c) proposal citing both by path. Judgment criteria: a
  proposal is "ready" only if every claim sourced from outside this repo
  carries a URL or a `Sources:` entry (issue-1's citation-format rule,
  now generalized to this role's every future proposal, including this
  one). Prohibitions: no proposal may restate survey findings inline
  instead of citing the survey path; no phase-1 PR may contain any hook,
  gate, or test file edit (draft text only).
- **Phase 2 facet** — stages: (a) write the ADR-shaped
  `docs/issue-<n>/reports/architecture.md` record with the four required
  ADR sections plus a C4-level diagram, (b) run the phase-1-gate and
  phase-2-gate (`adr-gate.sh`) locally before requesting merge, (c) note
  in the record's "Open findings" any known gate limitation (mechanical,
  not semantic checks — proportionality already established in
  issue-1). Judgment criteria: a record is "landed"-ready only once both
  gates pass with no bypass env var set. Prohibitions: no phase-2 record
  may set `loop_state: landed` while a required phase-1 artifact
  (survey/scout-brief/proposal) for the same `issue-<n>` is absent —
  this is the new ordering rule the phase-1 gate (below) will enforce
  mechanically, not just document.

Before/after snippet (`directive.sh`'s `PRODUCES` argument — unchanged
text, since the facet detail lives in the new handbook, not this string;
listed here to make explicit that *no* directive.sh edit is proposed):

```
# unchanged:
"PRODUCES (required record fields): ADR (context/decision/consequences/alternatives-considered), C4 context/container boundary diagram. WRITE_SCOPE: [\"docs/issue-<n>/decisions/**\"]"
```

A new fifth `core_role_directive` argument does not exist in core's
current call signature; rather than requesting a cross-repo core-canon
change (out of scope, same reasoning issue-1's proposal used for its
option (b)), this proposal keeps the deepened stage/criteria/prohibition
text in the handbook file, and has `directive.sh`'s existing text
(unchanged) point to it by adding one clause: `"...WRITE_SCOPE: [...].
See docs/handbooks/architecture-methodology.md for phase-1/phase-2
stage detail."` — the only `directive.sh` line-text change this proposal
asks for.

### 2. Methodology gates = the plugin set (§0), not one file

Superseded by §0: what was a single `architecture/hooks/phase1-gate.sh`
in the prior revision is now split across `arch-sequence-gate`,
`arch-citation-gate`, and `arch-adr-content-gate` (§0's table), each
independently registered and independently testable. The mechanics
each plugin's gate script must implement carry over unchanged from the
prior design, redistributed as follows:

- **`arch-sequence-gate/hooks/sequence-gate.sh`** owns everything the
  prior design called "state tracking for ordering": fires on
  `Write|Edit|MultiEdit` to `docs/issue-<n>/reports/architecture.md`
  (phase-2 side) and, per §0's phase-1 combination, also fires on
  `docs/issue-<n>/proposals/*.md` (phase-1 side, checking survey
  existence before/alongside the proposal itself). Checks that
  `docs/issue-<n>/reports/architecture/survey.md` and
  `docs/issue-<n>/reports/architecture/scout-brief.md` (unless the
  proposal text carries an explicit skip-justification string, per
  issue-1's skip-condition language) exist on disk before allowing
  `loop_state` to leave `scope-proposed|proposed`. Existence-only, not
  content re-parsing — content is `arch-adr-content-gate`'s and
  `arch-citation-gate`'s job, kept as separate plugins precisely so this
  one stays a single-purpose ordering check. Reuses the existing
  `loop_state` frontmatter convention rather than inventing a new
  state-machine file, per issue-1's "no genuine per-role terminal-state
  precedent" finding.
- **`arch-citation-gate/hooks/citation-gate.sh`** owns the sourcing
  check: requires a `Sources:` list or inline URL whenever proposal or
  record text contains phrases like "industry practice" or
  "well-established" (issue-1's citation-format rule, made mechanical
  and now shared verbatim by both phases per §0's combination table,
  instead of re-implemented per phase).
- **`arch-adr-content-gate/hooks/adr-content-gate.sh`** owns the
  required-sections list (Request, Constraints, substantive content,
  Rationale, Open questions, How success will be judged, Files for
  proposals; context/decision/consequences/alternatives-considered plus
  C4 diagram for the phase-2 record) — this is today's `adr-gate.sh`
  moved into its own plugin directory, not rewritten in substance.
- **Resulting-content computation**, adopted by all three gate scripts
  per the scout-brief's pattern: compute the resulting text for
  `Write`/`Edit`/`MultiEdit` before judging it, and **fail closed**
  (non-zero exit) when the resulting content cannot be determined. This
  closes `adr-gate.sh`'s current `MultiEdit` gap inside
  `arch-adr-content-gate` specifically, as part of its migration, not as
  a separate patch to a file that no longer exists at its old path.
- **Where each hooks in**: each plugin ships its own
  `hooks/hooks.json` with its own `PreToolUse` entries — not one shared
  `hooks.json` — so a plugin can be enabled/disabled/tested
  independently, matching `freelunch`'s and `scout`'s per-plugin
  `hooks.json` shape. None of the four plugins is a pre-commit or CI
  step; this repo has no CI config today and introducing one stays out
  of scope.
- **Canon pointer, not vendor**: each gate script's header comment
  cites `core`'s generic `record-fields-gate.sh` (referenced via
  `core`'s own global `hooks.json` registration, per README) as the
  layer it sits additively on top of — no core script body is copied by
  any of the three.
- **Kill switches**: per §0's table — one env var per plugin, not one
  shared switch, so disabling ordering enforcement does not also
  disable sourcing or content checks.

### 3. Gate test design — one `tests/fixtures/` set per plugin

Superseded by §0: each of the three gate-bearing plugins owns its own
`tests/fixtures/` (freelunch-level self-containment — a plugin's tests
travel with it, not in one shared repo-root directory keyed by gate
name), plus a thin shared runner at repo-root `tests/run-gate-tests.sh`
that discovers and invokes every plugin's fixtures (so there is still
one command that runs everything, without any plugin depending on
another's test harness):

- `arch-sequence-gate/tests/fixtures/pass-full-sequence/` — survey.md +
  scout-brief.md + proposal.md all present, report `loop_state: landed`
  → gate must exit 0.
- `arch-sequence-gate/tests/fixtures/fail-missing-survey/` — no
  survey.md, report `loop_state: landed` → gate must exit non-zero,
  naming `survey.md` as missing.
- `arch-sequence-gate/tests/fixtures/fail-missing-scout-brief-no-skip-note/`
  — survey.md present, no scout-brief.md, no skip-justification string
  → gate must fail.
- `arch-sequence-gate/tests/fixtures/pass-scout-skip-justified/` — no
  scout-brief.md, but proposal text contains the skip-justification
  language → gate must exit 0.
- `arch-citation-gate/tests/fixtures/pass-sourced/` and
  `arch-citation-gate/tests/fixtures/fail-unsourced-claim/` — a proposal
  with "industry practice" phrasing, with and without a `Sources:` line.
- `arch-adr-content-gate/tests/fixtures/pass-all-sections/` and
  `arch-adr-content-gate/tests/fixtures/fail-missing-alternatives/` —
  regression fixtures for the migrated `adr-gate.sh` logic, since no
  test currently exists for it at all (survey finding).
- `arch-adr-content-gate/tests/fixtures/fail-multiedit-unresolvable/` —
  exercises the scout-brief's adopted "cannot determine resulting
  content → deny" fix.
- `tests/run-gate-tests.sh` (repo root) — a small runner that globs
  `*/tests/fixtures/*/` across all four plugin directories and invokes
  each plugin's own gate script against its own fixtures, asserting exit
  codes; it does not embed any plugin's check logic itself.

Phase 2 must decide the exact JSON payload shape/harness language
(bash+jq vs. a small python harness, matching whichever plugin's gate
script itself ends up using) — not fixed here.

### 4. Agents/checklists

Already covered structurally by §0's fourth plugin,
`arch-phase1-checklist/`: the survey→scout-brief→proposal sequence is
the "repeated procedure" issue #10 flags as agent/checklist-worthy, and
per the approver's correction it ships as its own independent,
marketplace-registered plugin — not a loose handbook file folded into
the general `architecture` plugin. `arch-phase1-checklist/agents/
phase1-checklist.md` holds the short ordered checklist (survey exists
and cites sources → scout-brief exists or skip is justified → proposal
cites both by path and states Files/How-success sections → ready for
APPROVE). It stays a checklist document, not a tool-use subagent — this
role's `YOU DECIDE` does not involve a bounded search/hunt task the way
`warrant-hunter` does, so a full subagent would be overhead beyond what
a checklist doc provides (matches the proportionality argument issue-1's
proposal already used against TOGAF/arc42 weight) — the change from the
prior revision is only that this checklist is now its own plugin
directory with its own `plugin.json`/marketplace entry, per the "each
plugin self-contained, marketplace-registered" requirement.

## Rationale

The phase-2 gate (`adr-gate.sh`) already proved this repo's gate style
works and is cheap; the honest gap issue #10 is pointing at is that the
*same* rigor was never extended to phase-1, and nothing enforces that
phase-1 happened at all before a phase-2 record can claim `landed`.
Reusing `loop_state` + file-existence checks (rather than inventing a
new state-machine or importing the external pricing-rulebook's full
path-resolution scaffolding) keeps each gate's mechanism proportionate
to what this repo actually needs, per the scout-brief's explicit
"pattern to skip" call — new machinery should close a real gap
(ordering, sourcing, section-structure, tests), not add generality this
repo has no use for.

The approver's correction adds a second rationale on top of that one:
proportionality inside a single gate script is not the only axis that
matters — **legibility of which methodology owns which enforcement**
matters just as much, and a single `phase1-gate.sh` doing ordering +
sourcing + section-structure in one file hides that mapping inside
internal branches. Splitting into `arch-sequence-gate`/
`arch-citation-gate`/`arch-adr-content-gate`/`arch-phase1-checklist`
(§0) costs four `plugin.json`s and four marketplace entries instead of
one gate file, but buys back exactly what the correction asks for: each
plugin is independently readable, independently testable, independently
disableable, and its `marketplace.json` description alone states which
one methodology it owns — matching the `freelunch`/`scout` reference
shape rather than this repo's own single `architecture` plugin's
everything-in-one-role-plugin shape, which is the shape issue #10 is
asking this proposal to move away from at the gate level.

## Open questions for the human approver

1. **Whether `phase1-gate.sh`'s existence check should also validate
   survey/scout-brief *content* (not just existence)**, or whether
   content validation of those two files is deferred to a later issue.
   This proposal recommends existence-only for phase 2's first cut,
   content-checking as a stated future enhancement, to keep phase 2's
   scope bounded.
2. **Whether the scout-brief skip-justification string match should be
   a fixed phrase list (cheap, brittle) or left to human review at
   APPROVE time (no mechanical check at all for the skip path).** This
   proposal recommends the fixed phrase-list approach for consistency
   with every other gate in this repo, but flags that it is the
   weakest-verified part of the design.
3. **Whether closing `adr-gate.sh`'s `MultiEdit` resulting-content gap
   belongs in the same phase-2 PR that migrates it into
   `arch-adr-content-gate/` or a separate one**, since it touches an
   already-landed file's logic rather than only adding new plugin
   directories.
4. **Whether the four plugins in §0 should each get their own git
   remote/repo (matching how `pricing-rulebook`'s external sibling is a
   separate checkout) or stay as four sibling directories inside this
   same `architecture-rulebook-issue-10-architecture` repo, each with
   its own `.claude-plugin/plugin.json` and a shared root
   `.claude-plugin/marketplace.json`.** This proposal recommends the
   latter (four sibling directories, one marketplace file) since none of
   the four plugins has a use case outside this rulebook and a
   multi-repo split would add distribution overhead the approver's
   correction did not ask for — only independent *packaging*
   (`plugin.json`/marketplace entry), not independent *hosting*.
5. **Whether `arch-citation-gate` firing on both phase-1 proposals and
   the phase-2 record (per §0's combination table) should be one shared
   gate script parameterized by glob, or two thin scripts sharing a
   common library file inside the same plugin.** This proposal
   recommends one shared script matched against both globs in its own
   `hooks.json`, to avoid duplicating the sourcing-check logic across
   two files inside the same plugin.

## How success will be judged

- All four plugins in §0 exist as sibling directories, each with its own
  `.claude-plugin/plugin.json` naming exactly one methodology, and each
  has its own entry in the root `.claude-plugin/marketplace.json`
  alongside (not folded into) the existing `architecture` entry.
- `arch-sequence-gate`, `arch-citation-gate`, and `arch-adr-content-gate`
  each cite `core`'s canon location by pointer only (grep shows no core
  script body duplicated anywhere across the four plugins), and each
  demonstrably fails closed against its own class of violation (missing
  phase-1 artifact, unsourced claim, missing ADR section) per §0's
  combination table, and passes once its condition is satisfied.
- `tests/run-gate-tests.sh` discovers and runs every plugin's own
  `tests/fixtures/**` and reports pass/fail per fixture; at least one
  pass and one fail fixture exists per gate-bearing plugin (three of the
  four; `arch-phase1-checklist` is documentation-only).
- `arch-phase1-checklist/agents/phase1-checklist.md` exists and is
  cited from `directive.sh`'s (unchanged-shape) `PRODUCES` string,
  alongside a pointer to the new deepened phase facet document.
- This proposal's own phase-1 artifacts (this file, the survey, the
  scout-brief) satisfy the very citation/structure norm they describe —
  self-applying, per issue-1's precedent.
- A reviewer can answer "which plugin enforces X" and "which plugins
  combine to make up the phase-1/phase-2 norm" by reading §0 alone,
  without opening any gate script — this is the correction's own bar,
  restated as a success criterion.

## Files (write set, once approved — phase 2 only)

- `arch-sequence-gate/.claude-plugin/plugin.json`,
  `arch-sequence-gate/hooks/sequence-gate.sh`,
  `arch-sequence-gate/hooks/hooks.json`,
  `arch-sequence-gate/tests/fixtures/**`,
  `arch-sequence-gate/README.md` (new plugin)
- `arch-citation-gate/.claude-plugin/plugin.json`,
  `arch-citation-gate/hooks/citation-gate.sh`,
  `arch-citation-gate/hooks/hooks.json`,
  `arch-citation-gate/tests/fixtures/**`,
  `arch-citation-gate/README.md` (new plugin)
- `arch-adr-content-gate/.claude-plugin/plugin.json`,
  `arch-adr-content-gate/hooks/adr-content-gate.sh` (migrated from
  `architecture/hooks/adr-gate.sh`, MultiEdit resulting-content gap
  closed during the move), `arch-adr-content-gate/hooks/hooks.json`,
  `arch-adr-content-gate/tests/fixtures/**`,
  `arch-adr-content-gate/README.md` (new plugin; `architecture/hooks/
  adr-gate.sh` removed from `architecture/` once migrated)
- `arch-phase1-checklist/.claude-plugin/plugin.json`,
  `arch-phase1-checklist/agents/phase1-checklist.md`,
  `arch-phase1-checklist/README.md` (new plugin)
- `.claude-plugin/marketplace.json` (four new entries, sibling to the
  existing `architecture` entry)
- `tests/run-gate-tests.sh` (new, repo-root discovery runner only)
- `architecture/hooks/hooks.json`, `architecture/hooks/directive.sh`,
  `architecture/README.md` (small edits: drop the migrated
  `adr-gate.sh` entry, add the "See arch-* plugins for phase-1/phase-2
  enforcement" pointer — `architecture` keeps owning role-boundary/
  directive concerns only, per §0)
- `docs/issue-10/reports/architecture.md` (phase-2 record, not created by
  this PR)

## PHASE-1 STATUS

This proposal is **phase-1 output**. It awaits a human
`APPROVE issue-10/architecture` (per `docs/specs/approvers.md`) before
any phase-2 implementation — hook script, test file, or handbook file —
is written.
