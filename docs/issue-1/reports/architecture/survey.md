# Current-state survey — architecture-role methodology maturity (issue-1)

## Part I — what this repo enforces today

### `architecture/hooks/directive.sh` (read in full)

Post-issue-2 migration, this file is the core-canon stub form: a
`trap`/`set -uo pipefail` pair, one `source` line into
`core/hooks/lib/role-directive.sh`, and one `core_role_directive` call
with four arguments:

- `YOU DECIDE: 컴포넌트 경계·의존 방향` ("component boundaries / dependency
  direction")
- `USE_WHEN: 새 모듈 경계나 기존 경계 변경이 걸릴 때` ("when a new module
  boundary or a change to an existing boundary is at stake")
- `PRODUCES (required record fields): ADR (context/decision/consequences),
  boundary diagram. WRITE_SCOPE: ["docs/issue-<n>/decisions/**"]`
- `HAND-OFF: 인터페이스 형태 세부는 → api-design; 성능 예산이 걸리면 →
  performance-engineering. BOUNDARY CASE: ...`

The `PRODUCES` field names exactly two artifact types — "ADR
(context/decision/consequences)" and "boundary diagram" — with **no
further structure specified**: no required ADR sections beyond the three
named (no "alternatives considered", no "status", no "decision drivers"),
no naming/numbering scheme, no required diagram notation (C4? UML? ad
hoc boxes-and-arrows?), no required diagram levels (context only?
container too?). It is a one-line pointer, not a template.

### `architecture/.claude-plugin/plugin.json`

Mirrors the same four fields as static plugin metadata (`description`
field). No additional methodology content.

### Record-fields gate — confirmed absent as a vendored file, present via core canon

`grep -rn "record-fields-gate" .` (excluding `.git/`) returns only
prose references inside `README.md`, `docs/issue-5/reports/implementation.md`,
`docs/issue-2/reports/implementation.md`, `docs/issue-2/proposals/...`,
and `architecture/hooks/directive.sh`'s own comment — there is **no
`architecture/hooks/record-fields-gate.sh` file in this repo** (`find .
-iname "*record-fields*"` returns nothing). Per `docs/issue-2/reports/
implementation/survey.md` and `docs/issue-2/proposals/2026-07-31-switch-
to-core-canon.md`, this repo already completed the migration proposed in
issue-2: the three role-scoped gates (`trailer-gate.sh`,
`record-fields-gate.sh`, `handbook-trigger-gate.sh`) were dropped from
this repo and are now supplied globally by core's own `hooks.json`
(matcher `.*`, fires for every plugin install), which this repo depends
on rather than vendors.

Core canon's `record-fields-gate.sh` (per the issue-2 survey's reading of
it) enforces contract §19/§20 record-completeness generically: five
required sections (what-was-done / why / upstream-basis / `loop_state` /
open-findings) on any phase-2 record file, plus a conditional next-steps
requirement when `loop_state` is non-terminal. **It has no concept of
per-role artifact methodology** — it does not know that this role's
records should contain ADR-shaped content or diagrams; it only checks
that certain generic sections exist in the record's prose. So today,
nothing in this repo's enforced tooling checks that an architecture
decision was actually written as an ADR, in any specific format, or that
a diagram uses any specific notation. The `PRODUCES` line in
`directive.sh` is advisory text a human/agent reads at session start; it
is not machine-checked.

### Net finding

Today, this role's methodology enforcement is: **one line of directive
text naming two artifact categories, with no required internal structure
and no machine check on that structure.** This is the gap issue-1 asks
to close.

## Part II — domain research: architecture deliverable/methodology norms

Searches run (5 initial + 2 follow-up = 7 WebSearch calls, sequential
tool calls issued in two batches of 5-then-2 within this session):
"Architecture Decision Records ADR Michael Nygard original format MADR",
"C4 model Simon Brown context container component diagram software
architecture", "arc42 template software architecture documentation",
"TOGAF ADM architecture development method heavyweight criticism",
"Domain-Driven Design bounded context Eric Evans component boundaries",
"ThoughtWorks Technology Radar architecture decision records adopt",
"AWS Google architecture decision record lightweight practice review".

### 1. Architecture Decision Records (ADR) — Nygard original + MADR variant

- **What problem it solves:** captures a single architecturally
  significant decision — its context, the decision itself, and its
  consequences — as a short, durable, version-controlled artifact, so
  future readers understand *why* a structural choice was made, not just
  what it currently is.
- **Required components, original Nygard format (2011, "Documenting
  Architecture Decisions", Cognitect blog):** Title, Status, Context,
  Decision, Consequences. Minimal by design — "minimal structure with
  maximum clarity."
  (https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- **MADR variant** (adr.github.io/madr): adds explicit sections Nygard's
  format only implies — Decision Drivers, Considered Options (with
  pros/cons per option), Decision Outcome. More verbose; the tradeoff
  documented by MADR's own maintainers is that MADR forces explicit
  enumeration of alternatives, at the cost of overhead for teams that
  already write disciplined ADRs.
  (https://adr.github.io/madr/decisions/0000-use-markdown-architectural-decision-records.html)
- **Adoption evidence:** ThoughtWorks Technology Radar rates "Lightweight
  Architecture Decision Records" as **Adopt** — their strongest
  recommendation tier — stating "we see no reason why you wouldn't want
  to use this technique" for most projects, and recommends storing ADRs
  as markdown in source control alongside the code they describe, not in
  a wiki, so they stay in sync.
  (https://www.thoughtworks.com/en-us/radar/techniques/lightweight-architecture-decision-records)
  AWS Prescriptive Guidance documents ADR practice drawn from "lessons
  from implementing over 200 ADRs across numerous projects," recommends
  creating an ADR whenever a decision changes architecture, operations,
  security posture, or long-term maintenance cost, and recommends
  distributing ADR ownership to whoever makes the decision rather than
  centralizing it.
  (https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/best-practices.html)

### 2. C4 model (Simon Brown)

- **What problem it solves:** gives boundary/structure diagrams a fixed,
  small vocabulary of abstraction levels so diagrams are comparable
  across teams and legible to different audiences, replacing both
  "no standard notation" ad-hoc box diagrams and UML's much heavier
  notation.
- **Required components:** four levels — **Context** (system + external
  actors/systems, for non-technical/executive audiences), **Container**
  (deployable/runnable units — services, apps, databases — and how they
  communicate, for technical stakeholders), **Component** (internal
  structure of one container), **Code** (class/ER level, "optional and
  rarely used in practice").
  (https://icepanel.io/blog/2024-07-18-what-is-the-c4-model,
  https://c4model.com/)
- **Adoption evidence:** created 2006-2011, "used by thousands of teams
  worldwide" per multiple secondary sources; explicitly positioned by its
  creator as a lighter alternative to UML.
  (https://lucid.co/blog/c4-model, https://c4model.com/faq)

### 3. arc42 template

- **What problem it solves:** a full architecture-documentation
  structure (not just decisions or diagrams) — the shape of an entire
  architecture document, section by section, so nothing structurally
  important (constraints, quality requirements, risks, deployment view)
  gets silently omitted.
- **Required components:** 12 sections (introduction/goals, constraints,
  context & scope, solution strategy, building block view, runtime view,
  deployment view, cross-cutting concepts, architecture decisions, risks
  & technical debt, glossary, plus others per the template); every
  section is explicitly optional per-project.
  (https://www.innoq.com/en/blog/2022/08/brief-introduction-to-arc42/,
  https://github.com/arc42/arc42-template)
- **Adoption evidence:** created 2005 (Gernot Starke, Peter Hruschka),
  free/open-source, in active use with dedicated tooling and hundreds of
  "tips" documentation; positions itself explicitly as "pragmatic," i.e.
  a lighter-weight full-document template relative to heavier enterprise
  frameworks like TOGAF.

### 4. TOGAF ADM — heavyweight comparison point, explicitly considered and rejected for this role's scope

- **What problem it (attempts to) solve:** a complete enterprise
  architecture governance method spanning business, data, application,
  and technology architecture domains across an entire organization, not
  just software module boundaries.
- **Why rejected here:** multiple independent sources converge on the
  same criticism — "in practice, the TOGAF framework is often perceived
  as complex and heavyweight, making it difficult to apply effectively,"
  "it is complex and costly," and it is "consultant-centric" (benefits
  consultants who bill for tailoring it more than practitioners).
  (https://www.boc-group.com/en/blog/ea/ea-services-making-togaf-more-lightweight/,
  https://medium.com/@digitalroadmap-management/what-is-the-togaf-architecture-development-method-adm-and-how-could-it-be-improved-64ab96ed5713)
  TOGAF ADM operates at enterprise-portfolio scope; this role's `YOU
  DECIDE` scope is a single repo's component boundaries and dependency
  direction per issue, which is several orders of magnitude narrower
  than what ADM is built to govern. Adopting ADM-shaped process here
  would import governance overhead this role has no organizational
  surface to justify.

### 5. Domain-Driven Design — bounded context

- **What problem it solves:** gives a principled way to decide *where* a
  boundary should go — "a bounded context is the logical boundary around
  the code that represents the solution for [a] domain... where
  particular terms, definitions, and rules apply in a consistent way,"
  and DDD "advises us to divide a large domain into many bounded
  contexts with explicit relationships between them" rather than one
  unified model.
  (https://martinfowler.com/bliki/BoundedContext.html; concept
  originates in Eric Evans, *Domain-Driven Design: Tackling Complexity in
  the Heart of Software*, 2003)
- **Relevance to this role specifically:** this role's `YOU DECIDE` field
  is literally "component boundaries / dependency direction." Bounded
  context is the closest well-established conceptual vocabulary for
  *reasoning about where a boundary should be*, as distinct from ADR
  (how to *record* that a boundary decision was made) and C4 (how to
  *diagram* the boundary once decided). The three are complementary, not
  competing: DDD supplies the reasoning heuristic, ADR supplies the
  record format, C4 supplies the diagram notation.
- **Adoption evidence:** foundational text since 2003, cited across the
  industry as the standard vocabulary for domain/service boundary
  reasoning (Martin Fowler's bliki entry, still actively referenced,
  is one of the most commonly cited secondary explanations of the
  concept).

### 6. ThoughtWorks Technology Radar stance (industry lightweight-practice signal)

Already covered under ADR above — "Lightweight Architecture Decision
Records" holds ThoughtWorks Radar's **Adopt** rating, their strongest
tier, explicitly framed as "lightweight" in name. This is direct
evidence that the industry's own opinionated-but-widely-followed
technology-adoption signal favors exactly the lightweight-ADR direction
this survey's candidate list leans toward, not the heavier TOGAF-style
alternative.

### 7. AWS architecture-review norms

AWS Prescriptive Guidance's ADR best-practices doc (drawn from >200 ADRs
across real projects) recommends: start with a pilot team, use a clear
template, establish review cycles, and create an ADR specifically when a
decision changes architecture, operations, security posture, or
long-term maintenance cost — i.e. selectivity criteria for *when* an ADR
is warranted, not "record every decision."
(https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html)

## Summary table

| Candidate | Solves | Adoption evidence | Fit for this role |
|---|---|---|---|
| ADR (Nygard/MADR) | record a decision durably | ThoughtWorks Radar "Adopt"; AWS >200 ADRs in practice | direct match — already named in `PRODUCES`, needs structure |
| C4 (Context+Container) | diagram boundaries at right abstraction | "thousands of teams," explicit lighter-than-UML | direct match — already named as "boundary diagram", needs notation |
| arc42 | whole-document structure | active OSS since 2005 | too broad — this role emits decisions, not whole architecture docs; not adopted here |
| TOGAF ADM | enterprise EA governance | widely used but widely criticized as heavyweight | explicitly rejected — wrong scale for a single repo's module boundaries |
| DDD bounded context | reasoning heuristic for *where* boundaries go | foundational since 2003, industry-standard vocabulary | adopted as reasoning vocabulary inside ADR's Context/Decision sections, not a new artifact type |
