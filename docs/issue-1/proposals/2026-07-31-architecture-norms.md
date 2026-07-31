---
subject: issue-1
role: architecture
loop_state: scope-proposed
---

# Proposal: mature architecture-role governance with ADR + C4 norms

## Request (paraphrased intent)

Issue #1 asks this rulebook to grow up: today the `architecture` role's
only methodology guidance is two words in a directive string ("ADR
(context/decision/consequences), boundary diagram") with nothing
enforced beyond generic contract-record shape. The issue asks for (a)
phase-1 proposal norms — what this repo's own future proposals/surveys
must contain and how they must cite evidence, (b) phase-2 deliverable
norms — what an architecture decision produced by this role must
actually contain, (c) the logical rationale connecting each adopted
methodology to what this role's `YOU DECIDE` structurally needs (not
"it's popular"), and (d) a precise plugin-reflection plan for how (a)/
(b) become enforceable text in `directive.sh` and, eventually, a gate
check — specified now, implemented in phase 2 only.

See `docs/issue-1/reports/architecture/survey.md` for the current-state
read and domain research, and `docs/issue-1/reports/architecture/
scout-brief.md` for the scouted axes/pattern choice this proposal builds
on.

## Constraints

- Phase-1 only — no code, no hook changes, no gate changes ship in this
  PR. Everything under "Plugin-reflection plan" below is a precise spec
  for phase 2, not an applied change.
- `architecture/agents/warrant-hunter.md` is out of scope entirely —
  per issue-2's already-landed migration, warrant-hunter is a core-canon
  reference only in this repo now; this proposal does not touch it and
  does not recreate any vendored copy.
- Nothing here may weaken this repo's existing record-discipline. The
  survey confirms core canon's generic `record-fields-gate` (five
  contract §19/§20 sections) already applies to this role's phase-2
  record via core's global `hooks.json` registration; this proposal adds
  *additional* required structure inside that record's content, it does
  not remove or loosen anything already enforced.
- No genuine per-role `loop_state` terminal-state precedent exists in
  this repo (confirmed by the issue-2 survey); this proposal does not
  introduce one.

## Methodology adopted for phase-1 proposals (this repo's own norms)

Future `docs/issue-<n>/proposals/*.md` and
`docs/issue-<n>/reports/architecture/survey.md` documents in this repo
must follow the same shape this proposal and its survey already use,
made explicit here so it is a checkable norm rather than an implicit
convention copied from issue-2's example:

1. **Survey precedes proposal, always.** A `reports/architecture/
   survey.md` documenting current-state (what this repo enforces today,
   read from the actual files, not assumed) plus external research must
   exist before a `proposals/*.md` is written, and the proposal must
   cite the survey by path rather than restate its findings inline.
2. **Citation format.** Any claim sourced from external research must
   carry either (a) an inline URL in prose, or (b) a `Sources:` list at
   the end of the document (the format `WebSearch`'s own tool contract
   already requires, which this repo inherits rather than invents). A
   claim about "industry practice" or "well-established" without a
   traceable source is not permitted in a survey or proposal — the
   issue-1 survey and scout-brief in this PR are themselves the worked
   example.
3. **Required proposal sections:** frontmatter (`subject`, `role`,
   `loop_state`), Request (paraphrased), Constraints, the substantive
   decision content, Rationale (explicit, connecting the decision back
   to this role's `YOU DECIDE`/`USE_WHEN` — not popularity alone), Open
   questions for the human approver, How success will be judged, Files
   (write set). This mirrors `docs/issue-2/proposals/2026-07-31-switch-
   to-core-canon.md`'s structure exactly; this proposal is itself
   compliant with the norm it names.
4. **Scout brief required unless skip conditions are met.** Per this
   project's scout-directive skip conditions, a scout brief may be
   omitted only when the spec leaves no design decision open at all. Any
   proposal touching this role's methodology (i.e. any proposal like
   this one) is presumptively in-scope for scouting; the issue-2
   proposal's "scout skipped" note documented why skipping was valid
   *there* (fully-specified mechanical migration) — that reasoning does
   not transfer to open methodology questions like this one, where a
   scout-brief is required and is included in this PR.

## Methodology adopted for phase-2 deliverables (what this role produces)

Every architecture decision this role records in
`docs/issue-<n>/reports/architecture.md` (the phase-2 record; not
created by this PR) must ship as:

### 1. An ADR with four required sections (Nygard core + one MADR addition)

- **Context** — the situation forcing a decision (what changed, what
  constraint surfaced).
- **Decision** — the boundary/dependency-direction choice made, stated
  as a decision, not a description of the current state.
- **Consequences** — what becomes easier/harder as a structural result,
  including any acknowledged debt.
- **Alternatives Considered** — at minimum one rejected option and why
  it was rejected. This is the one MADR-derived addition on top of
  Nygard's original three sections (see survey §1); full MADR's
  decision-drivers table and per-option pros/cons list are explicitly
  **not** adopted — see Rationale below.

Status/Title fields are not separately mandated as record structure
beyond what the record file's own contract-required fields already
provide (subject/loop_state in frontmatter functions as status).

### 2. A boundary diagram at C4 Context and/or Container level

- Required whenever the decision changes or introduces a
  system/module boundary (i.e. essentially every decision this role
  records, since `USE_WHEN` is already scoped to boundary changes).
- **Context level**: required when the change affects how the system as
  a whole relates to external actors/systems.
- **Container level**: required when the change affects the internal
  application/service/data-store boundary structure.
- **Component and Code levels are explicitly out of scope for this
  role** — see Rationale.
- Notation is not mandated to a specific tool; plain-text/mermaid/ASCII
  diagrams embedded in the record file are acceptable as long as they
  are legibly labeled at the Context or Container level. No requirement
  to use a specific diagramming product.

### 3. Bounded-context reasoning inside the Context/Decision sections, not as a separate artifact

DDD's bounded-context vocabulary is adopted as the *reasoning language*
expected inside the ADR's Context and Decision prose (e.g. "this boundary
separates the X context from the Y context because their models diverge
on <term>") — it does not become a fifth required section or a separate
document. This keeps the required-artifact count at two (ADR + diagram),
not three.

### Explicitly not adopted

- **TOGAF ADM** — rejected as out of scope for this role's altitude; see
  survey §4 and scout-brief.
- **arc42's full 12-section template** — rejected; this role emits one
  decision at a time, not a whole architecture document.
- **Full MADR** (decision-drivers table, per-option pros/cons list) —
  rejected as overhead beyond what a single-repo-scoped boundary
  decision needs; the "Alternatives Considered" section is the one piece
  of MADR judged worth the overhead.

## Rationale for each adoption

**Why ADR (Nygard core + Alternatives Considered), not something
heavier or lighter:** This role's entire `YOU DECIDE` is a *decision* —
"component boundaries / dependency direction" — not a description of
current state or a whole-system document. ADR's four sections map
directly onto what a decision fundamentally is: the situation that
forced it (Context), the choice (Decision), the effect (Consequences),
and — critically for a role whose job is picking a dependency direction
among plausible alternatives — what else was on the table and why it
lost (Alternatives Considered). Without that fourth section, a future
reader cannot distinguish "the only option" from "the option we picked
over a real alternative," which is exactly the ambiguity a boundary
decision needs resolved. Full MADR's decision-drivers table adds
structure for *multi-criteria* tradeoffs; this role's decisions are
typically dominated by one or two structural forces (coupling, team
ownership, existing dependency direction) where forcing a formal
drivers table would cost more agent-cycle time than it returns in
reader clarity — hence "one alternative minimum," not "full MADR."
ThoughtWorks Radar's Adopt rating and AWS's >200-ADR field experience
(survey §1, §7) are evidence this format holds up at scale in the wider
industry, not the reason it's chosen here — the reason is the structural
match to what a decision-recording role needs.

**Why C4 Context+Container, not full C4 or UML or ad hoc:** the role's
`YOU DECIDE` is explicitly "component boundaries / dependency
direction" at the level of *modules/systems*, not classes. C4's own four
levels are ordered by exactly this altitude axis (system↔external at
Context, deployable-unit↔deployable-unit at Container, internals of one
container at Component, class-level at Code). This role's boundary
decisions live precisely at the Context/Container altitude — a decision
about which module owns which responsibility, or which service calls
which, is a Container-level fact; a decision about which system talks to
which external system is Context-level. Component and Code levels
describe what happens *inside* one already-decided boundary, which is
implementation-level detail this role's own `HAND-OFF` line already
routes elsewhere ("인터페이스 형태 세부는 → api-design"). Requiring
Component/Code diagrams here would have this role reach into another
role's territory — the same "don't silently absorb another role's
scope" principle the existing `BOUNDARY CASE` line already states.

**Why bounded-context reasoning is folded into ADR prose, not a third
artifact:** DDD's bounded-context concept answers *where* a boundary
should go; ADR answers *how to record* that a boundary decision was
made; C4 answers *how to draw* it. These are three different questions,
not three competing methodologies — so the correct adoption shape is one
reasoning vocabulary (DDD) applied inside one record format (ADR),
diagrammed with one notation (C4), not three separate required
deliverables. Requiring a standalone "bounded context analysis" document
in addition to the ADR would duplicate content the ADR's own
Context/Decision sections should already carry, adding writing overhead
without adding information — directly against the "documentation
overhead" axis this proposal's scout-brief names.

**Why TOGAF/arc42 are out:** both solve a broader problem (whole
enterprise architecture governance; whole-project architecture
documentation) than "record one boundary decision, scoped to one repo,
per issue." Multiple independent sources (survey §4) converge on TOGAF
ADM being perceived as heavyweight/costly/consultant-centric when
applied outside enterprise-portfolio scope — importing that process
weight into a single-repo, per-issue role would violate the
proportionality this role's narrow `YOU DECIDE`/`USE_WHEN` scope
implies.

## Plugin-reflection plan (spec only — not applied in this PR)

### 1. `architecture/hooks/directive.sh` — `PRODUCES` argument change

Current `core_role_directive` call's third argument:

```
"PRODUCES (required record fields): ADR (context/decision/consequences), boundary diagram. WRITE_SCOPE: [\"docs/issue-<n>/decisions/**\"]"
```

Phase-2 replacement (exact new string, subject to open question 1
below):

```
"PRODUCES (required record fields): ADR (context/decision/consequences/alternatives-considered), C4 context/container boundary diagram. WRITE_SCOPE: [\"docs/issue-<n>/decisions/**\"]"
```

Change is additive to the existing field, not a restructuring: adds
`alternatives-considered` to the ADR field list and narrows "boundary
diagram" to "C4 context/container boundary diagram" so the required
notation/level is named in the directive text a session actually reads,
not left implicit. `WRITE_SCOPE` and `HAND-OFF`/`BOUNDARY CASE` text are
unchanged by this proposal.

### 2. New required record fields for a role-specific gate check

Core canon's generic `record-fields-gate` checks contract-shape fields
(what-was-done/why/upstream-basis/loop_state/open-findings) — it has no
per-role vocabulary. This proposal specifies, for phase 2 to implement
mechanically, a **new role-scoped check** (script name and exact
placement is a phase-2 implementation detail, not fixed here) that scans
`docs/issue-<n>/reports/architecture.md` for four case-insensitive
section markers once a record's `loop_state` reaches a decision-bearing
state:

- a `Context` or `## Context` heading (or equivalent bold-label line,
  matching whatever literal-match convention core's own gates already
  use — see survey's description of core's substring-match style)
- a `Decision` heading
- a `Consequences` heading
- an `Alternatives Considered` heading (new — this is the field that
  does not exist in today's directive text or any existing gate)
- at least one fenced code block or line matching a C4-level marker
  (`Context diagram` / `Container diagram`, or a mermaid block) when the
  record's content indicates a boundary/module change occurred

This mirrors the literal-text/section-substring-match style
`trailer-gate.sh`/`record-fields-gate.sh` already use per the issue-2
survey's description (cheap mechanical checks, not semantic review) —
it is designed to be implementable as a shell script consistent with
this repo's existing gate style, not a new class of tooling.

### 3. Where this check registers

Options for phase 2 to decide mechanically (not decided here): (a) a new
`architecture/hooks/record-fields-gate.sh` role-specific *addition*
layered on top of core's global gate (this repo would then carry one
role-specific gate file again, which issue-2's migration deliberately
removed — a tension phase 2 must resolve explicitly, likely by keeping
it as a separate, additively-registered `PreToolUse` hook rather than
reintroducing a full vendored copy of core's generic gate); or (b) a
request to core canon (a separate cross-repo issue, out of scope here)
to make `core_role_directive`'s `produces` argument itself
machine-parseable so `record-fields-gate.sh` could derive required
sections from it generically across all 43 rulebooks, avoiding
per-role gate proliferation entirely. This proposal recommends framing
phase 2's implementation as option (a) now, with option (b) flagged as a
future core-canon issue if other rulebooks converge on wanting the same
capability — not decided here, since it affects repos beyond this one.

## Open questions for the human approver

1. **Exact `PRODUCES` string wording.** The draft in section 1 above
   keeps the existing field structure and appends
   `/alternatives-considered` and `C4 context/container` inline; an
   alternative phrasing could separate these into a fifth
   `core_role_directive`-unsupported field the way issue-2's proposal
   flagged for `WRITE_SCOPE`/`BOUNDARY CASE` — but since `PRODUCES` is
   already one of the four sanctioned arguments, no `stub-check.sh` risk
   applies here and the inline-append form is recommended as the
   simpler option. Confirm or amend before phase 2.
2. **Whether the new role-specific gate is worth the file-count cost.**
   Issue-2 deliberately removed this repo's role-specific gates in favor
   of core's generic one. Reintroducing any role-specific `PreToolUse`
   hook — even a small additive one — is a real reversal of that
   direction, not a neutral addition. The approver should confirm this
   tradeoff is accepted (stronger methodology enforcement, at the cost
   of one role-specific gate file returning) versus the alternative of
   leaving the ADR/C4 requirement as directive-text-only (advisory, not
   gated) until/unless a cross-repo core-canon mechanism (option (b)
   above) exists.
3. **Whether Context-level diagrams should be mandatory or
   conditional.** This proposal makes Container-level diagrams the
   default expectation for any boundary decision and Context-level
   diagrams conditional on external-system-facing changes. If the
   approver wants Context-level diagrams unconditionally required
   alongside Container for every decision (heavier but simpler to gate
   mechanically — one condition instead of two), that should be stated
   before phase 2 fixes the gate's exact logic.

## How success will be judged

- `architecture/hooks/directive.sh`'s `PRODUCES` argument text matches
  the approved wording from open question 1, and still passes
  `stub-check.sh`'s structural check (plain `core_role_directive` call,
  no regrown boilerplate).
- The phase-2 implementation report documents which of options (a)/(b)
  in "Where this check registers" was chosen and why, with the new gate
  (if (a)) demonstrated against at least one real ADR-shaped record
  fixture (passing) and one incomplete record fixture (failing closed).
- A worked example architecture decision record exists (in a future
  issue's `docs/issue-<n>/reports/architecture.md`, not this PR) showing
  all four ADR sections plus a Container-level diagram, so the norm has
  at least one concrete instance, not just a spec.
- This proposal's own format is judged against the norms it states in
  "Methodology adopted for phase-1 proposals" — i.e. it is self-applying.

## Files (write set, once approved — phase 2 only)

- `architecture/hooks/directive.sh` (`PRODUCES` argument text)
- `architecture/hooks/record-fields-gate.sh` (new, if option (a) chosen)
- `architecture/hooks/hooks.json` (new `PreToolUse` entry, if option (a)
  chosen)
- `architecture/.claude-plugin/plugin.json` (`description` field, kept
  in sync with `directive.sh`'s wording)
- `README.md` (Layout section, if a new gate file is added)
- `docs/issue-1/reports/architecture.md` (phase-2 record)
