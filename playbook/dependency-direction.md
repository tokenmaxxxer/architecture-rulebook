---
axis: dependency-direction
rule_count_floor: 12
---

# Dependency Direction Playbook

Decision rules for which way a dependency arrow should point between modules, layers, or
components, and when a dependency is a violation to be corrected. Sourced from practitioner
writeups, named methodologies/standards, and academic/theory literature, each fetched or
searched this session.

## Conflicts and how resolved

- **Clean/Onion/Hexagonal all mandate strict inward pointing, but real systems (e.g. ArchUnit
  layered examples) often tolerate "skip-layer" reads for performance.** Resolved by treating
  the strict inward rule as the default (rules 1, 3, 8) and layer-skipping as an explicit,
  documented exception rather than a silent violation (rule 9).
- **DIP says depend on abstractions; ADP's alternative cycle-break tactic is to introduce a new
  shared package instead of an interface.** These are not contradictory but are different tools
  for the same problem (breaking a cycle) — resolved by presenting both as CHOICE options gated
  on different conditions (rule 6 uses interface extraction, rule 7 uses package extraction).
- **SDP/SAP (stability-and-abstraction direction) vs. the Dependency Rule (layer direction)**
  can conflict when a "stable" concrete infrastructure package is depended on by many things.
  Resolved by noting that under Clean/Onion/Hexagonal, infrastructure must be made unstable-by-
  design (behind ports) specifically so SDP's "point toward stability" doesn't pull dependencies
  outward into infrastructure (rule 4).

### 1. Business/domain logic must not import framework or infrastructure code
- condition: A use-case, entity, or domain-service module imports a database driver, HTTP
  framework, ORM, or other infrastructure-layer symbol directly.
- choice: Introduce an interface (port) owned by the domain module; move the concrete
  infrastructure import behind an adapter that implements that interface, so the arrow points
  from infrastructure toward the domain, not the reverse.
- why: The Dependency Rule requires source-code dependencies to point only inward, toward
  higher-level policy.
- source: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html

### 2. Choosing between abstraction-via-interface and abstraction-via-inheritance to invert a dependency
- condition: A high-level module currently instantiates or calls a low-level module directly
  (e.g. `OrderService` calls `MySQLOrderRepository` concretely).
- choice: Have the high-level module depend only on an abstraction (interface/protocol) that it
  or its layer owns; make the low-level module implement that abstraction, inverting the
  compile-time dependency relative to the runtime call direction.
- why: DIP: high-level modules should not depend on low-level modules — both should depend on
  abstractions.
- source: https://arthcruz.dev/en/posts/demystifying_the_dependency_inversion_principle_in_clean_architecture/

### 3. Adapters must depend on ports defined by the core, never the reverse
- condition: You are wiring a driving adapter (e.g. REST controller) or driven adapter (e.g.
  database repository) into an application core in a hexagonal/ports-and-adapters design.
- choice: Define the port (interface) inside the application core; require both driving and
  driven adapters to depend on that port. Never let the core import a concrete adapter type.
- why: In Hexagonal Architecture, the core sits inside the hexagon and depends on nothing
  external; adapters depend on ports, not vice versa.
- source: https://alistair.cockburn.us/hexagonal-architecture

### 4. Infrastructure that appears "stable" must still not pull dependencies outward
- condition: An infrastructure package (e.g. a shared database access layer) is depended upon by
  many other packages and looks stable by the Stable Dependencies Principle's own metric, tempting
  the domain layer to depend on it directly for convenience.
- choice: Keep the domain layer depending only on interfaces it owns; force the "stable"
  infrastructure package to implement those interfaces rather than becoming a dependency target
  for domain code, even though SDP alone would call it a safe, stable dependency.
- why: SDP's abstractness-vs-stability metric (via SAP) is necessary but not sufficient when it
  conflicts with the layering Dependency Rule; layering takes precedence for direction across
  architectural boundaries.
- source: https://link.springer.com/chapter/10.1007/978-1-4842-4119-6_11

### 5. Outer (unstable) layers must never be imported by inner (stable) layers
- condition: A domain/application-core class needs data that currently lives in a
  UI/presentation or infrastructure class, and the easy fix is to import that outer-layer class
  directly.
- choice: Push the needed data or behavior down into the core (as a value object, parameter, or
  port), and have the outer layer supply it through that port — do not add an inward import from
  the core to the outer layer.
- why: Onion Architecture's single governing rule: dependencies always point inward; outer
  layers adapt to inner layers, never the reverse.
- source: https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/

### 6. Two same-level modules directly reference each other (import cycle) and one owns a clear abstraction boundary
- condition: Package A imports Package B and Package B imports Package A (a cycle), and one of
  the two directions represents a natural policy/implementation split.
- choice: Extract an interface for the capability the "implementation" side needs to expose,
  place it in the policy side, and have the implementation side depend on (implement) that
  interface — inverting one edge to break the cycle. [**REMOVAL**] (the direct A→B or B→A edge
  that created the cycle is deleted, replaced by an inverted interface dependency)
- why: ADP: the dependency graph of packages must have no cycles; dependency inversion is the
  standard tactic to break one.
- source: https://en.wikipedia.org/wiki/Acyclic_dependencies_principle

### 7. Two packages depend on each other only because they share a few common types
- condition: A cycle exists between Package A and Package B, but investigation shows the mutual
  dependency is caused by a handful of shared types/utilities rather than a clean policy/impl
  split.
- choice: Extract the shared types into a new, lower-level shared package that both A and B
  depend on; remove A's and B's direct dependency on each other. [**REMOVAL**] (delete the direct
  cross-edge between A and B once both point at the new shared package)
- why: ADP's alternate cycle-break tactic — introducing a common package — is preferred over
  interface extraction when the coupling is data-shape coupling, not behavioral coupling.
- source: http://nicolecarpenter.github.io/2016/05/11/acyclic-dependencies-principle.html

### 8. Enforcing a defined layered architecture in CI so violations aren't discovered by accident
- condition: A codebase has an intended layering (e.g. controller → service → repository) but no
  automated check, and reviewers are catching direction violations manually and inconsistently.
- choice: Write executable architecture tests (e.g. ArchUnit's `layeredArchitecture()`) that
  assert each layer may only access the layers it's permitted to, and run them in the build
  pipeline so a disallowed import fails the build.
- why: Architecture tests turn the informal dependency-direction rule into a fitness function
  checked on every change, catching violations before merge.
- source: https://reflectoring.io/enforce-architecture-with-arch-unit/

### 9. A layer-skipping read dependency is proposed for performance reasons
- condition: A controller wants to read directly from a repository/data-access layer, skipping
  the service layer, to avoid an unnecessary indirection hop for a simple lookup.
- choice: Only allow the skip if it is declared as an explicit, named exception in the
  architecture test suite (e.g. an allowlisted rule) — do not allow it as an undocumented ad hoc
  import; otherwise route through the service layer.
- why: Blanket strict layering (rule 1/3/5) is the default, but real systems need a controlled
  escape hatch that stays visible to fitness functions rather than silently eroding the rule.
- source: https://www.thoughtworks.com/radar/techniques/architectural-fitness-function

### 10. Tracking whether a dependency direction is drifting toward disallowed edges over time
- condition: A team has an intended dependency direction but no visibility into whether new code
  is gradually introducing disallowed edges (e.g. more and more inward-layer code creeping
  outward-layer knowledge).
- choice: Add a dependency-drift fitness function that runs on a schedule/CI and reports the
  trend of disallowed-edge counts, not just a pass/fail snapshot, so regressions are visible
  before they accumulate into erosion.
- why: A one-time check misses gradual drift; tracking trend data lets a team intervene before
  the architecture erodes.
- source: https://www.thoughtworks.com/radar/techniques/dependency-drift-fitness-function

### 11. Diagnosing whether existing violations represent real architecture erosion before deciding to fix them
- condition: A dependency-direction audit (e.g. via ArchUnit or a DSM tool) surfaces a large
  number of flagged edges, and it's unclear which are true erosion versus acceptable historical
  exceptions.
- choice: Build a Dependency Structure Matrix of the current codebase, visually cluster modules,
  and treat any flagged cell that falls outside the intended block-triangular (acyclic,
  inward-pointing) structure as a genuine violation to prioritize for remediation — don't fix
  edges that the DSM shows are actually contained within an already-accepted subsystem boundary.
- why: DSMs make it easy to pinpoint violations to design rules and distinguish real erosion from
  noise, per empirical software-architecture-management research.
- source: https://groups.csail.mit.edu/sdg/pubs/2005/oopsla05-dsm.pdf

### 12. A facade or intermediary layer was added "for future flexibility" but never varies
- condition: A code review finds a facade/wrapper interface sitting between two modules where
  only one concrete implementation has ever existed and no second implementation or seam is
  planned, yet all calls are forced through it, adding an indirection hop without inverting any
  real dependency.
- choice: Collapse the facade and let the caller depend directly on the single concrete
  module (or, if inversion is genuinely still needed, keep the interface but delete the
  pass-through facade class that adds no logic). [**REMOVAL**] (delete the no-op indirection
  layer)
- why: Practitioner architecture-erosion literature finds that unnecessary abstraction layers
  are a common erosion symptom that DSM/fitness-function audits should catch, since they add
  coupling surface without any corresponding direction benefit.
- source: https://arxiv.org/pdf/2103.11392

### 13. A module accumulates many inbound dependents while still being “abstract enough” only in theory
- condition: Package-level metrics (afferent/efferent coupling) show a package with many
  incoming dependencies (high stability, per SDP) but a low abstractness ratio — i.e. it is
  concrete, not interface-shaped, yet many other packages already depend on it.
- choice: Extract the parts of that package that other packages actually need into an abstract
  interface package, and have both the original concrete package and its dependents point at the
  new abstract package instead of the concrete one directly.
- why: SAP: stable packages should be as abstract as they are stable; a stable-but-concrete
  package is a candidate for "zone of pain" and should be pulled toward the main sequence.
- source: http://principles-wiki.net/collections:robert_c._martin_s_principle_collection

### 14. A layering/direction rule was decided and documented but nobody has generated the actual import graph to see if it currently holds
- condition: An ADR or code review establishes an intended dependency direction (e.g. domain
  must not import infra), but verification depends on reviewers remembering the rule during
  future PRs rather than a rendered, current view of the real import graph.
- choice: Generate the dependency graph directly from the codebase's actual imports (not
  hand-drawn) as part of closing the decision, and re-run it whenever verifying the rule still
  holds; treat any edge crossing the declared boundary as a finding to fix or explicitly
  re-litigate, not something to catch by memory in review.
- why: a graph rendered from real imports catches drift a text rule cannot — orphaned modules,
  unlisted/implicit dependencies, cycles, and the exact edges violating a declared direction are
  only visible once the actual graph is drawn, not asserted.
- source: https://lobehub.com/skills/blueraai-bluera-base-claude-code-graph
