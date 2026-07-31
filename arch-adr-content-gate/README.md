# arch-adr-content-gate

Owns exactly one methodology: the **ADR+C4 required-element norm** for
this role's own phase-2 record (`docs/issue-<n>/reports/architecture.md`)
— Context/Decision/Consequences/Alternatives-Considered sections plus a
C4-level diagram.

Migrated from `architecture/hooks/adr-gate.sh` (issue-1) into its own
plugin per issue-10's plugin-set mandate, so it can be versioned, tested,
and disabled independently of directive/sequence concerns. The migration
also closes `adr-gate.sh`'s `MultiEdit` resulting-content gap: an
unresolvable `MultiEdit` now fails closed instead of passing unchecked.

## What it checks

Fires on `Write|Edit|MultiEdit` to `docs/issue-<n>/reports/
architecture.md`. Once the resulting content's `loop_state` leaves
`scope-proposed`/`proposed`, requires literal-substring markers for
Context, Decision, Consequences, and Alternatives Considered, plus a
C4-level diagram marker (a ```` ```mermaid ```` fence or `C4 Context`/`C4
Container`/`Context diagram`/`Container diagram` text). Cheap,
mechanical, no semantic review — matching this repo's existing gate
style.

## Kill switch

`export ARCH_ADR_CONTENT_GATE_OFF=1`
(`ARCHITECTURE_ADR_GATE_OFF=1` is honored as a deprecated alias for one
release, since that was the pre-migration env var name.)

## Canon pointer

Layered additively on core canon's generic `record-fields-gate.sh`
(referenced by pointer, never vendored; deliberately not named
`record-fields-gate.sh` itself, which `stub-check.sh` treats as a
reserved core-canon filename).
