---
axis: coupling-classification
rule_count_floor: 12
---

# Coupling Classification — Operational Decision Rules

Scope: how to identify and classify coupling between components (afferent/efferent,
temporal, data, control coupling, connascence) and what corrective action to take.
Sources span three layers: practitioner writeups, named methodology (Constantine &
Yourdon structured design, Robert Martin's instability metric, Page-Jones/Weirich
connascence), and academic/theory (Stevens, Myers & Constantine 1974).

## Cross-source conflicts and resolution

1. **Instability metric vs. dependency quality.** Robert Martin's `I = Ce/(Ca+Ce)`
   ranks components purely by dependency *count*. coupling.dev's critique notes a
   component with 1 outgoing and 100 incoming dependencies scores as "stable"
   (I≈0.01) even if that one outgoing dependency is a content-coupling violation
   that makes the component fragile. **Resolution: use I as a triage signal to find
   candidate components, then classify each dependency by connascence
   strength/Constantine coupling type before deciding severity.** Never treat a low
   I score as proof of health.
2. **"Reduce coupling" vs. "coupling is unavoidable."** Fowler's structured-design
   lineage and connascence both agree coupling cannot be eliminated, only shaped:
   Weirich's rule is to convert strong forms of connascence into weaker forms and to
   only tolerate strong connascence when locality is high (same function/class). No
   real conflict here — both traditions converge on "minimize strength, especially
   across module/service boundaries," which is the operative rule below.
3. **Microservice writeups vs. classical structured-design vocabulary.** Modern
   distributed-monolith/shared-database writeups use different words (service
   coupling, chatty calls) for the same underlying types Stevens/Myers/Constantine
   named in 1974 (common coupling via shared data store = their "common coupling";
   synchronous call chains = temporal/control coupling). Resolution: this file maps
   modern service-level smells onto the 1974 taxonomy so classification stays
   consistent from function-level to service-level.

## Rules

### 1. Two modules share a mutable global or a shared database table/schema
- condition: Two or more components read and write the same global variable, shared
  memory region, or database table/schema directly (not through an owned API).
- choice: Classify as **common coupling** (Constantine/Yourdon). Assign single
  ownership of the data to one component; all others must access it only through
  that owner's published interface. **REMOVAL**
- why: Common coupling lets any writer silently break every reader; it is the
  highest-severity type after content coupling in the original taxonomy.
- source: https://medium.com/@subham11/the-shared-database-anti-pattern-c87013d2dcb2

### 2. Microservices share one physical database
- condition: Two independently-deployed services query or write the same database
  instance/schema instead of going through each other's APIs.
- choice: Split the schema so each service owns its own tables; replace direct
  cross-service queries with an API call or an event the owning service publishes.
  **REMOVAL**
- why: Shared databases turn independently deployable services into a distributed
  monolith — deployments and schema changes must be coordinated even though the
  processes are separate.
- source: https://vfunction.com/blog/distributed-monolith-architecture/

### 3. Deploy order or release timing between two services is coordinated by hand
- condition: Team must deploy service A before service B (or in lockstep) for the
  system to keep working, e.g. because B assumes A's schema/contract version.
- choice: Classify as **temporal coupling**. Introduce a versioned/backward-compatible
  contract (e.g. additive schema changes, consumer-driven contract tests) so either
  side can deploy independently.
- why: Coordinated deploys eliminate the core benefit of splitting into services and
  reintroduce monolith-style release trains.
- source: https://www.gremlin.com/blog/is-your-microservice-a-distributed-monolith

### 4. One function takes a boolean/enum "mode" flag that changes callee behavior
- condition: A function or module accepts a control flag (e.g. `mode`, `isAdmin`,
  `skipValidation`) whose value the caller sets to steer internal branching in the
  callee.
- choice: Classify as **control coupling** (Constantine/Yourdon). Split the function
  into separate functions per behavior, or invert control so the callee doesn't
  need to know the caller's intent; delete the flag parameter. **REMOVAL**
- why: Control coupling means the caller must know the callee's internal logic
  structure to use it correctly, which is exactly the encapsulation break structured
  design was created to catch.
- source: https://gist.github.com/Momus/4e42f6e5ca3e4658cb5033145c5a80e1

### 5. A function passes a whole record/struct when it only uses one field
- condition: Caller passes an entire data structure (DTO, struct, hash) to a callee
  that reads only one or two of its fields.
- choice: Classify as **stamp coupling**. Narrow the parameter to just the field(s)
  used, or if the structure is a legitimate shared concept, keep stamp coupling but
  document the schema as a contract owned by one side.
- why: Stamp coupling forces the callee to depend on the whole shape of a structure
  it barely uses, so unrelated field changes can break it; a scalar parameter (data
  coupling) is strictly safer when sufficient.
- source: https://mrpicky.dev/six-shades-of-coupling/

### 6. Module directly reaches into another module's internals (private fields, patched code)
- condition: Code reads/writes another module's private state, monkey-patches its
  internals, or relies on its undocumented implementation details rather than its
  public interface.
- choice: Classify as **content coupling**, the worst type in the 1974 taxonomy.
  Refactor to go only through the module's declared public interface; remove any
  direct reach-through. **REMOVAL**
- why: Content coupling means any internal refactor of the depended-on module can
  silently break the dependent, with no compiler/interface signal.
- source: https://gist.github.com/Momus/4e42f6e5ca3e4658cb5033145c5a80e1

### 7. A component has very high afferent coupling (Ca) and also changes often
- condition: Static analysis shows a component/package has many incoming
  dependents (high Ca) yet its change history shows frequent modification.
- choice: Flag as an instability violation — per Robert Martin's Stable Dependencies
  Principle, high-Ca components should be the most stable (I near 0). Freeze its
  interface, push volatile logic out into a new component behind it, and route new
  dependents to the stable interface only.
- why: When many components depend on something that keeps changing, every change
  ripples outward; the Stable Dependencies Principle exists to prevent this.
- source: https://coupling.dev/posts/related-topics/afferent-and-efferent-coupling/

### 8. A component depends on something less stable than itself
- condition: Computing I = Ce/(Ca+Ce) for component X and its dependency Y shows
  I(X) < I(Y) — X is more stable than the thing it depends on.
- choice: This violates Martin's Stable Dependencies Principle. Insert an
  abstraction (interface/port) that X depends on instead, with Y implementing it
  (dependency inversion), so the concrete unstable code no longer sits upstream of
  the stable component.
- why: A stable component depending on an unstable one inherits that instability —
  every change to Y forces X to change too, defeating the point of X being stable.
- source: https://en.wikipedia.org/wiki/Efferent_coupling

### 9. Two classes reference each other only by a shared literal (magic string/number/name)
- condition: Two components must agree on an implicit convention — e.g. both hard-code
  the same string key, event name, or column order — with no shared symbol/constant
  enforcing it.
- choice: Classify as connascence of Name/Meaning (or worse, connascence of
  Position if order-dependent). Replace the duplicated literal with a single shared
  constant, enum, or schema both sides import, converting it to a weaker, checked
  form of connascence.
- why: Weirich's guidance is to convert strong/implicit forms of connascence into
  weaker/explicit ones; an unenforced shared literal is a silent way for one side's
  edit to break the other with no compiler error.
- source: https://connascence.io/pages/about.html

### 10. Two services rely on identical startup/shutdown ordering or shared runtime timing
- condition: Service B only behaves correctly if it starts after service A, or a
  batch job depends on another job finishing within a specific time window with no
  explicit signal.
- choice: Classify as connascence of Timing / temporal coupling. Replace implicit
  ordering with an explicit readiness check, event, or queue-based handoff so
  correctness doesn't depend on wall-clock ordering.
- why: Timing-based coupling is invisible in the code and only fails under load or
  in a different environment, making it one of the hardest defects to reproduce.
- source: https://mrpicky.dev/a-brief-history-of-coupling-and-cohesion/

### 11. A shared "god" configuration object is threaded through many unrelated modules
- condition: A large shared config/context object is passed into many components
  that each use only a small, non-overlapping subset of its fields, and any addition
  to the object requires touching every consumer's type signature.
- choice: Classify as stamp coupling at architectural scale. Split the object into
  per-consumer config slices owned by the modules that actually need them; delete
  the single shared god-object parameter. **REMOVAL**
- why: A single shared config aggregate makes every consumer transitively coupled
  to every other consumer's configuration needs, even though they don't interact.
- source: https://mrpicky.dev/six-shades-of-coupling/

### 12. A circular import/dependency exists between two modules or services
- condition: Module A imports from module B and module B (directly or transitively)
  imports from module A, or service A calls service B which calls back into A.
- choice: Classify as a violation of Martin's Acyclic Dependencies Principle (a
  degenerate, maximal form of control/common coupling). Break the cycle by
  extracting the shared piece both sides need into a new lower-level module that
  both depend on one-way, and delete the back-edge import. **REMOVAL**
- why: Cycles make Ca/Ce and instability undefined for the whole cycle and force the
  two components to always be built/deployed/tested together, eliminating any
  independent-change benefit.
- source: https://www.martinfowler.com/ieeeSoftware/coupling.pdf

### 13. Chatty synchronous call chains across service boundaries
- condition: Fulfilling one user-facing request requires several services to call
  each other synchronously in sequence (A→B→C→D), with each hop adding latency and
  a shared-failure blast radius.
- choice: Classify as efferent coupling concentrated in one orchestrating service
  plus temporal coupling across the chain. Either consolidate the chain behind one
  API composed by an aggregator, or convert non-critical-path calls to async
  events so downstream failures don't propagate synchronously.
- why: Chatty synchronous chains are a hallmark "distributed monolith" smell — they
  add distributed-systems complexity (latency, partial failure) while keeping
  monolith-style tight coupling between hops.
- source: https://www.gremlin.com/blog/is-your-microservice-a-distributed-monolith

### 14. Cohesion/coupling metrics used as the sole gate for a design review
- condition: A team wants to approve or reject a design purely on a coupling/cohesion
  metric threshold (e.g. "instability under 0.3", or module coupling count) without
  human review of what the dependency actually does.
- choice: Do not gate on the metric alone — academic research found difficulties
  using cohesion and coupling metrics as standalone quality indicators; treat
  metrics as a triage signal that must be paired with a human classification of
  coupling *type* (content/common/control/stamp/data, or connascence
  strength/locality) before deciding to act.
- why: Metrics like Ca/Ce/I are counts, not judgments of harm; the same count can
  represent benign data coupling or dangerous content coupling.
- source: https://link.springer.com/article/10.1007/BF00590439

### 15. Structural coupling severity and actual change cost diverge
- condition: A component ranks moderate under afferent/efferent or connascence classification
  alone, but version-control history shows it and its dependents are edited together far more
  often than structurally-similar components, or it is high-severity but essentially frozen.
- choice: Reprioritize remediation order by pairing the structural classification (rules 1-14)
  with observed co-change frequency from commit history; a frequently-co-changed pair outranks
  a statically "worse" but rarely-touched pair, and a structurally severe but frozen pair can
  wait.
- why: static structural severity doesn't tell you which coupling is actually costing the team
  time today; the same connascence type can be dormant or a daily source of ripple failures
  depending on how often the coupled code actually changes and how far a change to it actually
  propagates.
- source: https://github.com/Egonex-AI/Understand-Anything
