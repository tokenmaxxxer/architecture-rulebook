# architecture-rulebook

Rulebook for the `architecture` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 컴포넌트 경계·의존 방향
- **use_when**: 새 모듈 경계나 기존 경계 변경이 걸릴 때
- **produces**: ADR (context/decision/consequences/alternatives-considered), C4 context/container boundary diagram — see `docs/handbooks/architecture-methodology.md` for phase-1/phase-2 stage detail
- **write_scope**: ["docs/issue-<n>/decisions/**"]
- **hand-off**: 인터페이스 형태 세부는 → api-design; 성능 예산이 걸리면 → performance-engineering

## Install

```
claude plugin marketplace add tokenmaxxxer/architecture-rulebook
claude plugin install architecture
claude plugin install arch-sequence-gate
claude plugin install arch-citation-gate
claude plugin install arch-adr-content-gate
claude plugin install arch-phase1-checklist
claude plugin marketplace add tokenmaxxxer/tokenmaxxxer-core
claude plugin install core
claude plugin install warrant
```

`core` and `warrant` supply canon shared across every role: the
role-agnostic trailer/record-fields/handbook-trigger gates, the
`role-directive.sh` boilerplate this rulebook's `directive.sh` sources,
and the `warrant-hunter` subagent. This rulebook no longer vendors copies
of any of them.

## Layout

- `architecture/.claude-plugin/plugin.json` — plugin manifest
- `architecture/hooks/hooks.json` — `SessionStart` wiring only
  (`directive.sh`); this plugin owns role-boundary/directive concerns
  and no longer carries any `PreToolUse` gate of its own — phase-1/
  phase-2 enforcement moved to the four `arch-*` plugins below (issue-10)
- `architecture/hooks/directive.sh` — SessionStart role directive (stub:
  sources `core/hooks/lib/role-directive.sh`, supplies this role's four
  unique values, and points to `docs/handbooks/
  architecture-methodology.md` for phase-1/phase-2 stage detail)
- `arch-sequence-gate/`, `arch-citation-gate/`, `arch-adr-content-gate/`,
  `arch-phase1-checklist/` — independent, self-contained plugins, each
  owning exactly one methodology element of this role's phase-1/phase-2
  norm; each has its own `.claude-plugin/plugin.json`, `hooks/`,
  `tests/fixtures/` (where applicable), `README.md`, and marketplace
  entry. See `docs/issue-10/proposals/2026-07-31-architecture-enforcement.md`
  §0 for the full plugin list and how phase-1/phase-2 norms combine them,
  and `docs/handbooks/architecture-methodology.md` for the deepened
  stage/judgment-criteria/prohibition text. `arch-adr-content-gate`
  replaces the former `architecture/hooks/adr-gate.sh` (issue-1);
  `ARCHITECTURE_ADR_GATE_OFF=1` is honored there as a deprecated alias
  for one release.
- `tests/run-gate-tests.sh` — repo-root runner that discovers and invokes
  every plugin's own `tests/run.sh`
- stub-check for core canon files (`trailer-gate.sh`,
  `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
  `stub-check.sh`) runs only by reference against the `core` installation
  (`core/hooks/tests/stub-check.sh architecture/hooks`); this rulebook
  vendors none of them (issue-5).
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
