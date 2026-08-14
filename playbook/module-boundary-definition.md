---
axis: module-boundary-definition
rule_count_floor: 12
---

# Module Boundary Definition

Operational decision rules for where to draw a module/component/service boundary:
cohesion criteria, what belongs together, and — just as important — when to stop
splitting and merge things back. Sourced from practitioner writeups (layer 1),
named methodologies (layer 2), and academic/theoretical grounding (layer 3).

Where sources conflict — most sharply "always favor small, single-purpose
services" (microservices advocacy) vs. "avoid premature decomposition, start
monolith-first" (Fowler, and the growing body of monolith-reversion case
studies) — the conflict is called out explicitly in the affected rules rather
than silently picking a side.

### 1. Hide a design decision likely to change
- condition: a design decision (data format, algorithm, storage choice) is likely to change during the system's life and multiple modules would otherwise need to know about it
- choice: pick the module boundary so that decision is hidden entirely inside one module, exposing only a stable interface
- why: information hiding is the original, still-canonical criterion for where a module boundary should fall — not "flowchart" step order
- source: https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf

### 2. Do not decompose by processing step / technical layer
- condition: a team is tempted to draw a module boundary between parsing/validation/storage/output stages of one process
- choice: keep those steps in one module unless a real hidden-decision boundary separates them; do not split purely by flowchart phase
- why: Parnas showed step-by-step decomposition ("classical" decomposition) produces modules that all break together when the shared assumption changes, defeating the point of a boundary
- source: https://blog.acolyer.org/2016/09/05/on-the-criteria-to-be-used-in-decomposing-systems-into-modules/

### 3. Organize components by domain concept, not technical role
- condition: defining component boundaries in a large application (e.g. Rails-style app with models/views/controllers spanning many business areas)
- choice: split components along real-world business concepts (orders, shipping, inventory, billing), each owning its own data, instead of along MVC-style technical layers
- why: Shopify's modular-monolith retrofit found domain-organized boundaries are what let 100+ engineers work without stepping on each other; layer-organized boundaries didn't reduce coupling
- source: https://shopify.engineering/deconstructing-monolith-designing-software-maximizes-developer-productivity

### 4. Give every component exactly one public interface and forbid direct data reach-through
- condition: two components need to interact with each other's state
- choice: require the interaction go through an explicit public API; treat any cross-component association or direct data access as a boundary violation to fix, not a shortcut to allow
- why: Shopify's enforcement tooling (Wedge/Packwerk) found that "just this once" cross-component field access is precisely what erodes a boundary until it's fictional
- source: https://shopify.engineering/deconstructing-monolith-designing-software-maximizes-developer-productivity

### 5. Use bounded contexts, not database schemas, as the seam
- condition: decomposing an existing monolith and looking for where the seams should be
- choice: identify bounded contexts by where the ubiquitous language changes (the same word means a different thing to different teams), and place the boundary there rather than at a table or schema line
- why: Evans/Fowler's DDD guidance treats a bounded context as defined by a consistent model and language, which is a better predictor of a durable boundary than storage layout
- source: https://martinfowler.com/bliki/BoundedContext.html

### 6. Model the whole bounded context as one service first (REMOVAL applies at finer grain)
- condition: decomposing a monolith into services around a newly identified bounded context
- choice: keep the whole bounded context as a single service initially; only split it further into smaller services around aggregates later, and only if a concrete need (independent scaling, ownership, deploy cadence) appears
- why: Sam Newman's guidance is to minimize the number of services at first cut — over-splitting on day one is harder to reverse than splitting later from evidence
- source: https://eddmann.com/posts/notes-monolith-to-microservices-by-sam-newman/

### 7. Do not decompose into services before the domain model is understood
- condition: a new system is being designed from scratch and there is pressure to start with a microservices architecture "to avoid a rewrite later"
- choice: build it as a monolith first; defer service-boundary decomposition until real usage has revealed where the seams actually are
- why: Fowler's MonolithFirst observation — almost all successful microservice systems started as monoliths that outgrew a boundary, while systems built as microservices from day one tend toward serious trouble because premature boundaries get drawn in the wrong place and are expensive to move
- source: https://martinfowler.com/articles/break-monolith-into-microservices.html

### 8. CONFLICT — reconcile "many small services" advice against "avoid premature decomposition" **REMOVAL**
- condition: a team already has more services than its current team/traffic can justify, each one thin and mostly passing calls through to another (a "distributed monolith")
- choice: merge over-decomposed services back into fewer, coarser-grained ones until each surviving boundary corresponds to an independently-changing, independently-owned concern; do not keep a split alive just because "smaller services are best practice"
- why: this directly resolves the conflict between microservices advocacy (small, single-purpose services) and Fowler/Newman's monolith-first caution — the resolution favored here is Fowler's: a split earns its keep only when it removes real coupling, and if it doesn't, undo it; InVision, Amazon Prime Video's monitoring service, and Istio's control plane all reverted splits for this reason
- source: https://www.bennadel.com/blog/3944-why-ive-been-merging-microservices-back-into-the-monolith-at-invision.htm

### 9. Merge a service back when its boundary no longer hides anything **REMOVAL**
- condition: two services always deploy together, share a release train, and neither can change its interface without the other changing in lockstep the same day
- choice: merge them into one module/service and delete the network boundary between them
- why: a boundary that no longer hides an independent design decision (Parnas's own test) is pure overhead — network hops, retries, and duplicated ops burden with none of the benefit
- source: https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf

### 10. Let team communication boundaries and reverse-Conway maneuvers set the boundary, not vice versa
- condition: a proposed module boundary requires two teams to coordinate on every change (constant cross-team PRs, shared release windows)
- choice: either redraw the module boundary to match a single team's ownership, or restructure the teams to match the desired architecture (reverse-Conway) — do not leave a boundary standing that forces permanent cross-team synchronization
- why: MIT/HBS research on the mirroring hypothesis found system modularity closely tracks organizational coupling; a boundary fighting the org chart stays leaky regardless of how it's documented
- source: https://martinfowler.com/bliki/ConwaysLaw.html

### 11. Split a module when its cohesion type is coincidental or logical, not when it merely feels "big"
- condition: a module's internal functions are grouped only by being triggered at the same time, or by superficial similarity (e.g. "all the utility functions"), rather than by contributing to one well-defined task
- choice: split the module along the seam where cohesion changes from functional/sequential to coincidental/logical; do not split solely because line count crossed an arbitrary threshold
- why: Stevens/Myers/Constantine's structured-design cohesion taxonomy (coincidental through functional) is the original, still-cited criterion distinguishing a boundary that improves maintainability from one that's cosmetic
- source: https://mrpicky.dev/a-brief-history-of-coupling-and-cohesion/

### 12. Don't split further just because a module is large — check coupling first **REMOVAL**
- condition: a module is large by line count or file count but has low coupling to the rest of the system and its internals change together as a unit
- choice: leave it as one module; do not split it merely to satisfy a size guideline
- why: coupling/cohesion research (and later replications) found size alone is a weak and sometimes misleading quality indicator — splitting a cohesive-but-large module can raise coupling and hurt maintainability rather than help it
- source: https://link.springer.com/article/10.1007/BF00590439

### 13. Use C4 container/component levels to decide which granularity a "boundary" question is even about
- condition: a discussion about "where the boundary should go" is stalling because participants are conflating a deployable-unit decision (container level) with an internal-code-organization decision (component level)
- choice: separate the two: pick container boundaries (independently deployable units — services, databases) first from ownership/scaling/deploy-cadence needs, then pick component boundaries (internal groupings behind an interface) inside each container from cohesion — don't force one decision to answer both questions
- why: the C4 model's explicit level separation exists because conflating "what deploys separately" with "what's grouped behind an interface" produces boundaries that are wrong at one level to satisfy the other
- source: https://c4model.com/

### 14. Draw the boundary where a difficult-to-predict change is most likely to land
- condition: two plausible boundary placements exist and it's unclear which is more "correct"
- choice: prefer the placement that isolates the assumption most likely to change (data source, third-party API, regulatory rule) inside a single module, over the placement that merely looks tidier structurally
- why: Parnas's central finding — decomposition driven by anticipated change, not by current structure, is what actually reduces the cost of the next modification
- source: https://wstomv.win.tue.nl/edu/2ip30/references/criteria_for_modularization.pdf

### 15. A C4-level boundary diagram exists only as a pasted image, not as a versioned model
- condition: a container/component boundary diagram for a decision record is a screenshot or hand-drawn image pasted into the record, with no text source a reviewer can diff against the prior version
- choice: produce the diagram from a single text-based model (one DSL/model file that generates the context/container/component views), and check that source into the record's write scope so the diagram diffs like code across revisions; do not treat a hand-maintained image as satisfying the C4-diagram requirement
- why: an image can silently drift from the actual decision with no reviewable diff; a single text model generating multiple views also keeps the context/container/component levels (rule 13) consistent with each other by construction instead of being drawn independently and drifting apart
- source: https://github.com/cheriftj/c4-model-skill
