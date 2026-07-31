# Scout brief — issue-1 (architecture-role methodology maturation)

**Category must-bes:** any adopted methodology must (1) produce a
record that core canon's generic `record-fields-gate` (contract §19/§20:
what-was-done/why/upstream-basis/loop_state/open-findings) can still
validate structurally — i.e. it augments the record's content, it does
not replace the record shape; (2) stay scoped to this role's `YOU
DECIDE` ("component boundaries / dependency direction") — nothing
enterprise-portfolio-wide; (3) be checkable by a cheap, mechanical
substring/structure gate (this repo's gates are shell scripts doing
literal-text/section checks, not semantic review) so phase-2 enforcement
is actually automatable, not aspirational.

**Performance axes chosen (2):**
1. **Decision traceability vs. documentation overhead** — how much
   forced structure (drivers, alternatives, consequences) buys future
   readers' ability to understand *why*, against how much writing burden
   it puts on the agent producing it each cycle.
2. **Diagram formality vs. speed of production** — how rigorous/notated
   a boundary diagram must be (full C4 four-level UML-adjacent notation)
   against how fast a one-cycle agent session can produce something
   legible (text-based/ASCII/mermaid context+container only).

**Pattern to adopt:** Nygard-style ADR core (Context/Decision/
Consequences) with an added **Alternatives Considered** section borrowed
from MADR — full MADR (decision drivers table + pros/cons per option) is
skipped as overkill for single-repo-scoped decisions; the four-section
version keeps required structure minimal while still forcing the
alternatives question, which is the single highest-value MADR addition
per the survey. Paired with **C4 Context + Container diagrams only**
(never Component/Code) — Context+Container is exactly the boundary/
dependency-direction altitude this role's `YOU DECIDE` operates at;
Component/Code diagrams describe internals of a single container, which
is a different role's altitude entirely.

**Pattern explicitly skipped:** TOGAF ADM and arc42's full 12-section
document — both solve a broader problem (enterprise EA governance;
whole-architecture-document structure) than "record one boundary
decision per issue," and both are criticized in sourced research as
heavyweight/costly when applied outside their native scope. Adopting
either here would add process weight this role's single-repo,
single-issue-scoped `YOU DECIDE` has no organizational surface to
justify.

**GAP LINE:** Current repo state already meets: a directive that *names*
two artifact categories (ADR, boundary diagram) and a generic
record-fields gate that checks record *shape* (five contract sections).
Missing: any required *internal* structure for the ADR content itself
(no Context/Decision/Consequences/Alternatives enforcement), any
required diagram notation or level (C4 vs. ad hoc), and any mechanical
gate check tying `PRODUCES` claims to what a phase-2 record actually
contains.

**Stage count / mode:** 7 WebSearch calls total, run as two batches (5
parallel, then 2 parallel) within this session — not sequential
one-at-a-time. Findings synthesized directly into
`docs/issue-1/reports/architecture/survey.md`; no fabricated sources —
every claim below and in the survey traces to a URL actually returned by
a search call.

Sources:
- https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- https://adr.github.io/madr/decisions/0000-use-markdown-architectural-decision-records.html
- https://www.thoughtworks.com/en-us/radar/techniques/lightweight-architecture-decision-records
- https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/best-practices.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html
- https://icepanel.io/blog/2024-07-18-what-is-the-c4-model
- https://c4model.com/
- https://c4model.com/faq
- https://lucid.co/blog/c4-model
- https://www.innoq.com/en/blog/2022/08/brief-introduction-to-arc42/
- https://github.com/arc42/arc42-template
- https://www.boc-group.com/en/blog/ea/ea-services-making-togaf-more-lightweight/
- https://medium.com/@digitalroadmap-management/what-is-the-togaf-architecture-development-method-adm-and-how-could-it-be-improved-64ab96ed5713
- https://martinfowler.com/bliki/BoundedContext.html
