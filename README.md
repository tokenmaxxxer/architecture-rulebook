# architecture-rulebook

Rulebook for the `architecture` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 컴포넌트 경계·의존 방향
- **use_when**: 새 모듈 경계나 기존 경계 변경이 걸릴 때
- **produces**: ADR (context/decision/consequences), boundary diagram
- **write_scope**: ["docs/issue-<n>/decisions/**"]
- **hand-off**: 인터페이스 형태 세부는 → api-design; 성능 예산이 걸리면 → performance-engineering

## Install

```
claude plugin marketplace add tokenmaxxxer/architecture-rulebook
claude plugin install architecture
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
- `architecture/hooks/hooks.json` — SessionStart wiring (PreToolUse gates
  now fire from `core`'s own global registration)
- `architecture/hooks/directive.sh` — SessionStart role directive (stub:
  sources `core/hooks/lib/role-directive.sh`, supplies this role's four
  unique values)
- `architecture/hooks/tests/stub-check.sh` — drift check (byte-identical
  copy of `core/hooks/tests/stub-check.sh`); run as
  `architecture/hooks/tests/stub-check.sh architecture/hooks`
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
