# architecture-rulebook

Rulebook for the `architecture` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-3 promotion and
generated as skeleton scaffolding by issue-170.

- **decides**: 컴포넌트 경계·의존 방향
- **use_when**: 새 모듈 경계나 기존 경계 변경이 걸릴 때
- **produces**: ADR (context/decision/consequences/alternatives-considered), C4 context/container boundary diagram — see `docs/handbooks/architecture-methodology.md` for phase-1/phase-2 stage detail
- **write_scope**: targets the existing `docs/issue-<n>/reports/architecture.md`
  record (not a new `docs/issue-<n>/decisions/**` tree — see
  `docs/handbooks/architecture-methodology.md`'s "Spec alignment"
  section for why that split is deferred, per issue-19)
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

### Gate-house standard (`core`'s `gate-lib.sh`, issue-13/72)

All three `PreToolUse` gates (`arch-sequence-gate`, `arch-citation-gate`,
`arch-adr-content-gate`) source `core/hooks/lib/gate-lib.sh` (+
`gate-lib.py`, loaded via `importlib` off `$GATE_LIB_PY`) by reference —
this repo vendors none of it. Each gate now carries:

- **trap-at-top fail-closed**: `gate_trap_fail_closed` is the first
  statement after the shebang, before `set -uo pipefail`. Any internal
  error (a stray uncaught Python exception, a syntax slip) is now remapped
  to `exit 2` (blocking) instead of falling through to a non-2 exit code,
  which Claude Code treats as non-blocking/fail-open. The guarantee now
  starts at the source line itself (issue-16): the `gate-lib.sh` source
  line carries an `||` guard (`|| { echo ... >&2; exit 2; }`), so a
  missing/unreachable `core` fails closed (`exit 2`) instead of fail-open
  (`exit 127`, with `gate_trap_fail_closed` never having had a chance to
  install) — a `fail-missing-core` fixture proves this per gate.
  `arch-sequence-gate`'s matcher additionally covers `Bash`, matching its
  gate code's existing Bash-write-bypass branch (previously advertised/
  tested but unreachable in production).
- **`loop_state` vocabulary** (issue-19, aligned with
  `roles/specs/architecture.spec.json`): `drafting`/`reviewing`/`landed`/
  `decision-not-ripe`/`options-unreachable`. `drafting`/`reviewing`
  replace the prior `scope-proposed`/`proposed` progress states in this
  rulebook's live/prescriptive vocabulary (handbook, gate scripts, gate
  test fixtures); historical `docs/issue-<n>/...` record frontmatter
  keeps its original values. `decision-not-ripe` and
  `options-unreachable` are new refusal/error states — see
  `docs/handbooks/architecture-methodology.md`.
- **required record fields** (issue-19): `decision_id` and `outcome`
  (`accepted`/`rejected`/`superseded`) are now required frontmatter on a
  decision-bearing `docs/issue-<n>/reports/architecture.md`, enforced by
  `arch-adr-content-gate`; `decision_drivers` is spec-optional and never
  enforced as required. `context` and `considered_options` map onto the
  existing `## Context` and "Alternatives Considered" sections.
- **allowlist kill-switches**: `ARCH_SEQUENCE_GATE_OFF`,
  `ARCH_CITATION_GATE_OFF`, `ARCH_ADR_CONTENT_GATE_OFF` (plus the
  deprecated alias `ARCHITECTURE_ADR_GATE_OFF`) only disable their gate
  on a recognized on-spelling (`1`/`true`/`yes`/`on`, case-insensitive).
  Every other value — including an unrecognized typo — leaves the gate
  ACTIVE (`gate_kill_switch_active`), the reverse of the pre-issue-13
  denylist behavior.
- **`replace_all`-correct `Write`/`Edit`/`MultiEdit` reconstruction** via
  `gate_lib.gate_reconstruct_write`: an `Edit`/per-`MultiEdit`-edit
  `"replace_all": true` now replaces every occurrence instead of always
  the first.
- **malformed-JSON deny** and **absolute/relative-path normalization**
  via `gate_lib.gate_parse_json_or_deny`/`gate_lib.gate_normalize_path`.
- `arch-sequence-gate` additionally carries a narrow, bounded Bash-write
  heuristic: a `Bash` command containing a literal `>`, `>>`, or `tee`
  redirect to a path that normalizes into one of this role's gated globs
  is treated as an unresolvable write and denied. Command substitution,
  `eval`, chained commands (`&&`/`;`), heredocs, and `python3 -c` writes
  are explicitly **not** covered by this heuristic (deferred; see
  `docs/issue-13/reports/architecture.md`).
- `arch-citation-gate`'s sourcing-norm check is now section/adjacency
  scoped: a trigger phrase and its citation (URL or `Sources:` line) must
  fall in the same Markdown heading block (or, for files with no heading
  structure, within a 15-line window) — a citation anywhere else in the
  file no longer exempts an unrelated, uncited occurrence.

`docs/issue-13/reports/architecture.md` is the phase-2 record for this
remediation; the per-gate mandatory test matrix (plain `Edit`, resolvable
`MultiEdit`, `replace_all`, malformed JSON, both kill-switch states,
absolute `file_path`, plus the citation section-adjacency regression and
the Bash-write-bypass regression) lives under each plugin's
`tests/fixtures/`, discovered generically by `tests/run-gate-tests.sh`.
- stub-check for core canon files (`trailer-gate.sh`,
  `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `parse-check.sh`,
  `stub-check.sh`) runs only by reference against the `core` installation
  (`core/hooks/tests/stub-check.sh architecture/hooks`); this rulebook
  vendors none of them (issue-5).
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
