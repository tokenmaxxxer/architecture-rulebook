---
axis: decomposition-strategy
rule_count_floor: 12
---

# Decomposition Strategy Playbook

Operational decision rules for whether to split a system into more services/modules or
keep it consolidated. Synthesized from practitioner postmortems, named methodology
(Fowler, Newman, DDD, Conway), and academic research on decomposition cost and
subtraction neglect.

### 1. Greenfield project, no proven domain model yet
- condition: You are starting a new product or system and the domain boundaries are not yet validated by real usage.
- choice: Build a single deployable monolith, organized internally into modules with clean API boundaries.
- why: Almost all successful microservice systems started as a monolith that outgrew itself; almost all systems built as microservices from day one got into serious trouble because stable service boundaries require a matured domain model.
- source: https://sdtimes.com/continuous-integration/martin-fowler-monolithic-apps-first-microservices-later/

### 2. Team is small (roughly under ~20-30 engineers) on one product
- condition: A single team or a small number of tightly coordinated teams owns the whole codebase.
- choice: Prefer a "majestic monolith" — one codebase, one deploy pipeline, one test suite — over splitting into services per team.
- why: For a small team, the operational overhead of running many services (deploy pipelines, service discovery, cross-service debugging) outweighs any isolation benefit.
- source: https://newsletter.techworld-with-milan.com/p/inside-shopifys-modular-monolith

### 3. Monolith has grown large but still has one team/small set of owners
- condition: Codebase is large (hundreds of thousands+ LOC) but organizational boundaries between domains are still fuzzy.
- choice: Decompose the monolith into enforced internal modules ("packs"/bounded modules with explicit public interfaces and automated boundary linting) before extracting any network service.
- why: Shopify scaled a 2.8M-LOC Ruby monolith to hundreds of engineers using Packwerk-enforced module boundaries instead of network splits, keeping deploy/test simplicity while gaining code-level decoupling.
- source: https://shopify.engineering/deconstructing-monolith-designing-software-maximizes-developer-productivity

### 4. A module has a genuinely independent scaling or deployment cadence
- condition: One module's load profile, release cadence, or failure-isolation needs diverge sharply from the rest of the system, and this divergence has been observed operationally (not hypothesized).
- choice: Extract that module into its own service using the Strangler Fig pattern — route calls through a facade/proxy and migrate functionality incrementally while the old and new implementations coexist.
- why: Strangler Fig lets you cut over externally-routable, well-isolated functionality with a working rollback at every step, rather than a risky big-bang rewrite.
- source: https://samnewman.io/patterns/refactoring/strangler-fig-application/

### 5. Extracting deeply embedded functionality that cannot be routed externally
- condition: The functionality to be split out is not cleanly reachable via an external call boundary (e.g., internal library, shared in-process module) and requires code-level refactoring.
- choice: Use Branch by Abstraction — introduce a single abstraction point, build the new implementation behind it, cut over via a feature toggle, then delete the old path.
- why: Branch by Abstraction lets old and new implementations coexist inside the same running process, avoiding a long-lived divergent branch and giving a safe rollback switch.
- source: https://samnewman.io/patterns/architectural/branch-by-abstraction/

### 6. Deciding where the seams of a new service should be
- condition: You've concluded a split is warranted and need to choose the boundary.
- choice: Draw the boundary at a bounded context from domain-driven design — a sub-domain with its own explicit domain model and ubiquitous language — not at a technical layer (e.g., "all validation logic") or an arbitrary code size threshold.
- why: Academic and industrial decomposition literature converges on bounded contexts as the unit that keeps cohesion inside the service and coupling between services low; technical-layer splits reliably produce chatty distributed systems.
- source: https://www.mdpi.com/1999-5903/17/7/303

### 7. Team org structure doesn't match the desired architecture
- condition: You want service boundaries to stay stable and independently ownable, but today's team structure requires cross-team coordination to ship a single feature.
- choice: Apply the Inverse Conway Maneuver — restructure teams (e.g., into Team Topologies' stream-aligned teams) to mirror the target bounded contexts *before* or *alongside* the technical split, not after.
- why: Conway's Law means the shipped architecture will mirror communication structure regardless of the diagram you drew; splitting services without splitting/aligning teams reliably produces a distributed monolith (network calls, monolith coupling).
- source: https://agileanalytics.cloud/blog/team-topologies-the-reverse-conway-manoeuvre

### 8. A service's deploys are ~100% correlated with one specific caller's deploys — **REMOVAL**
- condition: Telemetry shows a service is deployed in lockstep with a single upstream/downstream caller and has no independent release cadence or independent failure domain over a meaningful observation window.
- choice: Merge the service back into its caller (or into the module it was split from), deleting the network boundary between them. **REMOVAL**
- why: A service with no independent deploy cadence pays full distributed-systems tax (network calls, serialization, separate on-call surface) for zero isolation benefit; subtraction is systematically under-considered as a fix compared to adding more tooling around the split, per subtraction-neglect research (people default to additive fixes and overlook removing the change that caused the problem).
- source: https://www.nature.com/articles/s41586-021-03380-y

### 9. Premature split made before the domain model stabilized — **REMOVAL**
- condition: A service was extracted early (e.g., during a greenfield "microservices-first" attempt) based on a guessed domain boundary that later proved wrong — evidenced by constant cross-service schema changes or >1 PR pair touching both services per feature.
- choice: Fold the prematurely-split service back into the monolith or into the correct bounded-context service, and re-extract later only once the corrected boundary has held stable for multiple release cycles. **REMOVAL**
- why: Segment's ~140 microservices experience shows early over-decomposition produces exploding defect rates and plummeting velocity; merging back into one repo produced measurably higher productivity (46% more library improvements) even though it sacrificed some fault isolation.
- source: https://www.twilio.com/en-us/blog/developers/best-practices/goodbye-microservices

### 10. Distributed orchestration between components dominates cost, not the components' compute — **REMOVAL**
- condition: Cost/latency analysis shows the majority of spend or latency is in cross-component orchestration and data transfer (e.g., Step Functions invocations, S3 round-trips between stages) rather than the actual processing work.
- choice: Collapse the multi-service pipeline into a single process/task where data moves through memory instead of the network, removing the intermediate services and their orchestration layer. **REMOVAL**
- why: Amazon Prime Video's video-quality-analysis team cut AWS cost by 90% by merging a distributed serverless step-function pipeline into one monolithic ECS task, eliminating orchestration overhead and inter-service data transfer.
- source: https://www.thestack.technology/amazon-prime-video-microservices-monolith/

### 11. Uncertain whether a proposed split is needed at all
- condition: A proposal to add a new service exists, but no operational evidence (scaling divergence, team ownership conflict, deploy cadence mismatch) has been collected — the case rests on anticipated future need.
- choice: Default to not splitting; keep the functionality as a module in the existing deployable and revisit only when concrete operational friction (not speculation) appears.
- why: Fowler's MonolithFirst explicitly frames premature splitting as the dominant failure mode; additive architectural decisions (new service) are the path of least cognitive resistance and get proposed more often than the harder subtractive analysis of "should this even be separate," per subtraction-neglect research applied to system design choices.
- source: https://sdtimes.com/continuous-integration/martin-fowler-monolithic-apps-first-microservices-later/

### 12. Choosing decomposition granularity by workload/actor pattern, not just domain shape
- condition: A candidate bounded-context service is used by very different actor types with non-uniform load, risking hot spots that force whole-context replication.
- choice: When defining the service boundary, factor in actor-driven load patterns alongside domain cohesion — split further only if a sub-capability has both a distinct domain boundary AND a distinct load profile; a distinct load profile alone is not sufficient justification.
- why: Research on microservice decomposition shows bounded-context-only decomposition can create hot spots from non-uniform actor workloads that force costly full-context replication if load is not also considered.
- source: https://dl.acm.org/doi/10.1145/3583563

### 13. A shared library is being reimplemented independently in each service after a split
- condition: Post-split, multiple services have each grown their own divergent copy of what was originally one shared module (e.g., auth, formatting, validation), producing drift and duplicated bugs.
- choice: Extract the duplicated logic back into one shared internal package/module consumed by all services, rather than accepting N independent copies; do not re-decompose the shared logic into its own microservice unless it has independent deploy/scale needs (see rule 4).
- why: Decomposition without a plan for shared-kernel code reliably regresses into duplicated, drifting logic — a known DDD bounded-context pitfall of over-eager decomposition; the correct fix is a shared module, not either duplication or a needless new service.
- source: https://arxiv.org/pdf/2310.01905

## Conflicts and resolution

1. **Fowler/MonolithFirst vs. DDD/bounded-context-driven design** appear to conflict: Fowler says decompose late (rule 1, 11); DDD-flavored academic guidance says decompose along bounded contexts as the correct unit *when* you do decompose (rule 6). Resolution: these are not opposed — Fowler is about *timing* (wait for domain stability), DDD is about *shape* (once you decompose, cut along contexts, not layers). Both rules are kept, addressing different decision axes.
2. **Sam Newman's decomposition patterns (rules 4, 5) vs. Segment/Prime Video REMOVAL rules (8, 9, 10)** are in tension on direction: Newman's patterns assume the split is justified and describe *how* to execute it safely; the REMOVAL rules describe *when the justification turns out to be wrong after the fact* and how to safely reverse it. Resolution: both are needed — Strangler Fig / Branch by Abstraction are the correct execution mechanism in either direction (splitting out OR merging back), so rule 4/5's mechanics apply symmetrically to rules 8-10's merge-back cases.
3. **Conway's Law / Inverse Conway Maneuver (rule 7) vs. monolith-first defaults (rules 1, 2, 11)**: a naive reading suggests team-topology alignment argues for early service splits to match team boundaries. Resolution: rule 7 only applies once a split has already been independently justified (rules 4, 6); it is guidance on *how* to align teams to a split you're doing, not a reason to split earlier. Order of application: justify the split first (operational evidence), then align teams to it.
