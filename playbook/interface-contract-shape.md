---
axis: interface-contract-shape
rule_count_floor: 12
---

# Interface Contract Shape

Operational decision rules for the architecture role on choosing the SHAPE of a
boundary contract: sync vs async, shared-kernel vs published-language,
orchestration vs choreography, and interface surface area. Scope is
architecture-level shape, not API field-level design.

Layers researched this turn: (1) practitioner writeups on sync/async and
orchestration/choreography, (2) named DDD context-mapping patterns (Eric
Evans) and the Saga pattern and Interface Segregation Principle, (3)
academic/theory sources on information hiding (Parnas) and
consistency/latency tradeoffs (CAP/PACELC) in distributed systems.

### 1. Downstream call sits on the critical path of a user-facing request
- condition: A service must call another service synchronously to produce a response the caller is waiting on in real time.
- choice: Use synchronous request-response (REST/gRPC) only for this real-time, client-facing case; do not default every internal call to sync.
- why: Practitioner consensus is sync fits real-time scenarios where the caller needs an immediate result.
- source: https://antondevtips.com/blog/synchronous-vs-asynchronous-communication-in-microservices

### 2. Long-running or non-critical workflow chained across services (e.g. order fulfillment, notifications)
- condition: A multi-step business process spans services but the caller does not need to block on completion.
- choice: Route the workflow through asynchronous messaging (queue/event bus) instead of a synchronous call chain.
- why: Async maximizes service independence and resilience for non-critical, long-running work.
- source: https://antondevtips.com/blog/synchronous-vs-asynchronous-communication-in-microservices

### 2b. Existing synchronous call chain crosses multiple services and a downstream outage cascades upward
- condition: A request path currently makes nested synchronous calls (A calls B calls C) purely to relay eventual results, and a slow/failing C degrades A.
- choice: **REMOVAL** — Remove the synchronous hop between A and B/C in favor of publishing an event B/C can consume asynchronously; collapse the chain to one direct sync call plus async fan-out.
- why: Synchronous chains leave upstream services susceptible to cascading failure; Netflix migrated viewing-history writes off sync request-response for this reason.
- source: https://antondevtips.com/blog/synchronous-vs-asynchronous-communication-in-microservices

### 3. Distributed transaction spans several services and needs a single coordinator's view of state
- condition: A business transaction (e.g. checkout) must roll through multiple services with compensating actions on failure, and the team needs central visibility/control.
- choice: Use Saga orchestration with an explicit orchestrator service issuing commands and handling compensation.
- why: Orchestration gives centralized control, clearer flow, and is easier to build and test from the start.
- source: https://temporal.io/blog/to-choreograph-or-orchestrate-your-saga-that-is-the-question

### 4. Distributed transaction's participants are numerous, evolve independently, and no team wants to own a coordinator
- condition: Many autonomous services each need to react to state changes without a single team owning cross-service orchestration logic.
- choice: Use Saga choreography — each service publishes/reacts to domain events with no central coordinator.
- why: Choreography reduces coupling and increases scalability/availability of independently evolving services, at the cost of reduced visibility.
- source: https://temporal.io/blog/to-choreograph-or-orchestrate-your-saga-that-is-the-question

### 5. A choreography-based saga's event chain has grown past the point anyone can trace it end to end
- condition: Debugging a business process requires reconstructing a causal chain across five or more event handlers with no single place documenting the flow.
- choice: Introduce an orchestrator to reclaim explicit flow ownership for that specific saga, or add a dedicated process tracker; do not keep adding choreography links to a chain nobody can trace.
- why: Choreography's own documented drawback is reduced visibility and increased coordination complexity as chains grow.
- source: https://medium.com/@sinrajat43/demystifying-the-saga-pattern-in-microservices-orchestration-vs-choreography-fb669831f925

### 6. Two bounded contexts need to integrate and one team controls the domain model, the other must comply
- condition: A downstream context has no leverage to negotiate the model shape of an upstream context it depends on.
- choice: Adopt the Conformist pattern — downstream fully adapts to the upstream model rather than building a translation layer it cannot sustain.
- why: Conformist is the named DDD pattern for exactly this power asymmetry, avoiding wasted translation effort against an unresponsive upstream.
- source: https://contextmapper.org/docs/language-model/

### 7. Downstream context's domain concepts would otherwise be corrupted by an external system's model
- condition: A team must integrate with a legacy or third-party system whose model does not match the local domain and direct coupling would leak that model inward.
- choice: Build an Anticorruption Layer (ACL) that translates the external system's interface into the local domain's own terms.
- why: The ACL is the named DDD pattern for protecting a domain model from an incompatible external one via an isolating translation layer.
- source: https://contextmapper.org/docs/language-model/

### 8. A context wants to expose functionality to arbitrary, unknown consumers rather than one negotiated partner
- condition: Multiple current and future clients need to integrate with a context and one-off point-to-point contracts would multiply per client.
- choice: Expose an Open Host Service with a documented Published Language (well-defined shared schema/protocol) instead of bespoke per-consumer contracts.
- why: OHS + Published Language gives a stable contract consumers can build against independently of the provider's internals — the named DDD pattern for this case.
- source: https://contextmapper.org/docs/language-model/

### 9. Two teams share a subset of code/model between two bounded contexts to avoid duplication
- condition: Two contexts have significant model overlap and duplicating it would cause drift, so a Shared Kernel is proposed to hold the common part.
- choice: Adopt Shared Kernel only with explicit joint ownership, a change-review process between both teams, and a small, deliberately bounded surface.
- why: A shared kernel that grows without coordination is a documented risk — it recreates tight coupling under a different name.
- source: https://contextmapper.org/docs/language-model/

### 9b. Shared Kernel has been growing without coordination and both teams now fight over changes to it
- condition: A Shared Kernel's surface has expanded past its original scope and either team's changes now routinely break the other, or releases are blocked waiting on cross-team sign-off.
- choice: **REMOVAL** — Remove the Shared Kernel; split it, or replace it with a Published Language contract each side owns independently (Customer-Supplier or Conformist as appropriate), even though this means duplicating some code.
- why: An uncoordinated, growing shared kernel is a named anti-pattern risk in context mapping; once coordination cost exceeds duplication cost, subtract the shared dependency.
- source: https://contextmapper.org/docs/language-model/

### 10. Two contexts have fully diverged in domain concepts and integration cost now exceeds its value
- condition: An Anticorruption Layer or integration contract exists between two contexts whose models have converged so much that the translation layer just passes values through unchanged, or diverged so much that no meaningful data crosses the boundary.
- choice: **REMOVAL** — If models converged, collapse the ACL and merge the contexts' integration into a plain Conformist/shared type; if models are irrelevant to each other now, cut the integration and mark the contexts Separate Ways.
- why: Context mapping treats Separate Ways as a legitimate named outcome — removing integration is cheaper than maintaining a translation layer nobody needs.
- source: https://contextmapper.org/docs/language-model/

### 11. A module's interface exposes many fine-grained methods but each consumer only uses a handful
- condition: Clients of a module interface are forced to depend on (implement or stub) methods irrelevant to their use case, or a mock for testing must implement unused methods.
- choice: Split the fat interface into smaller, client-specific interfaces per the Interface Segregation Principle; expose only the operations a given consumer set needs.
- why: ISP: "clients should not be forced to depend on methods they do not use" — reduces unnecessary coupling and churn from unrelated interface changes.
- source: https://medium.com/@ramdhas/4-interface-segregation-principle-isp-solid-principle-39e477bae2e3

### 11b. A public module interface carries methods with zero live callers after a feature removal or refactor
- condition: An audit (e.g. call-graph or usage telemetry) shows one or more exported interface methods have no remaining callers across the codebase.
- choice: **REMOVAL** — Delete the unused method(s) from the interface rather than leaving them "just in case"; do not keep dead surface area on a published contract.
- why: Parnas's information-hiding principle says a module should expose the user only what is needed and nothing more — dead surface violates this directly and increases what future maintainers must reason about.
- source: https://john.cs.olemiss.edu/~hcc/researchMethods/notes/ClassicParnas/ACMannotated/ClassicParnasRevisionAnnotated.pdf

### 12. Designing a new module boundary and deciding what the interface should reveal
- condition: A module is being carved out and the team must decide which internal decisions to expose through its interface versus hide behind it.
- choice: Hide design decisions that are likely to change or are difficult, and expose only the minimal contract needed for correct use (signature, meaning, restrictions, exceptions) — do not expose internal representation or implementation choices "for convenience."
- why: Parnas's information-hiding criterion: each module hides a "secret" — a design decision likely to change — behind a minimal, stable interface.
- source: https://john.cs.olemiss.edu/~hcc/researchMethods/notes/ClassicParnas/ACMannotated/ClassicParnasRevisionAnnotated.pdf

### 13. A single general-purpose backend API serves multiple very different client types (web, mobile, partner)
- condition: One shared API backend is accumulating client-specific branching/fields to satisfy divergent frontend needs, slowing changes for all clients.
- choice: Split into a Backend for Frontend (BFF) per client type, each with its own tailored contract aggregating downstream services.
- why: BFF (Sam Newman) limits the number of consumers a given backend supports, making each backend's contract easier to change without cross-client coordination.
- source: https://samnewman.io/patterns/architectural/bff/

### 14. Choosing sync vs async under latency/consistency pressure at scale
- condition: A boundary spans data centers or partition-prone network paths and the team must decide whether a call can afford to block for strong consistency or should tolerate staleness for lower latency/higher availability.
- choice: Prefer asynchronous, eventually-consistent contracts across wide-area or partition-prone boundaries; reserve synchronous strongly-consistent calls for boundaries within a single low-latency failure domain.
- why: PACELC formalizes that even absent partitions, there is a real consistency-vs-latency tradeoff; synchronous replication carries materially higher latency (50-100ms) than async alternatives.
- source: https://medium.com/@gurpreet.singh_89/incorporating-latency-into-cap-theorem-trade-offs-in-distributed-system-design-1de74896e29c

## Conflicts between sources and resolution

- **Orchestration-by-default vs choreography-for-decoupling** (rules 3-5): Temporal's writeup and the Medium saga comparison agree orchestration is easier to start with and gives central control, while choreography reduces coupling but hides flow. Resolution: default new sagas to orchestration for traceability (rule 3), switch to choreography only when the participant set is large/independently evolving (rule 4), and treat an untraceable choreography chain as a signal to reintroduce orchestration (rule 5) — the sources aren't contradictory once staged as a lifecycle decision rather than a one-time binary choice.
- **Shared Kernel vs Anticorruption Layer/Published Language** (rules 6-9): DDD context mapping presents Shared Kernel as a legitimate pattern for tightly-coordinated teams, but the same source flags uncoordinated growth of a shared kernel as a named risk. Resolution: rule 9 gates initial adoption on coordination discipline; rule 9b treats loss of that discipline as grounds for removal — the pattern isn't wrong, its maintenance regime is the deciding factor.
- **ISP's method-level "split interfaces" vs Parnas's information-hiding "minimal, stable interface"** (rules 11-12): ISP argues for splitting large interfaces per consumer; Parnas argues for hiding decisions behind one minimal contract. These are complementary, not conflicting, at the architecture-level scope of this axis: ISP addresses breadth (avoid forcing irrelevant methods on a consumer) while Parnas addresses depth (hide implementation secrets behind whatever surface is exposed). No resolution needed beyond noting the different axis each operates on.
