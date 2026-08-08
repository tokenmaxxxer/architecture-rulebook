# arch-sequence-gate

Owns exactly one methodology: **phase ordering** for the `architecture`
role's contract-v3 loop — survey -> scout-brief (or justified skip) ->
proposal -> record.

## What it checks

- `docs/issue-<n>/proposals/*.md` writes require `docs/issue-<n>/
  reports/architecture/survey.md` to already exist.
- `docs/issue-<n>/reports/architecture.md` writes, once the resulting
  `loop_state` leaves the in-progress states (`drafting`/`reviewing`) or
  the refusal/error states (`decision-not-ripe`/`options-unreachable`,
  which do not assert a decision and so are exempt too), require both
  `survey.md` and `scout-brief.md` to exist — unless a proposal for the
  same issue carries an explicit skip-justification phrase for the
  scout-brief step.

Existence-only, no content re-parsing (see `arch-citation-gate` and
`arch-adr-content-gate` for content checks). Resulting content is
computed for `Write`/`Edit`/`MultiEdit`; when it cannot be determined,
the gate fails closed.

## Kill switch

`export ARCH_SEQUENCE_GATE_OFF=1`

## Canon pointer

Layered additively on core canon's generic `record-fields-gate.sh`
(referenced by pointer, never vendored — see `core/hooks/
record-fields-gate.sh` in the `core` plugin for the shared
resulting-content-computation shape this script follows independently).
