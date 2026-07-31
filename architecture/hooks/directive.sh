#!/usr/bin/env bash
# SessionStart: architecture's role directive — sources core canon
# (core/hooks/lib/role-directive.sh) for the shared boilerplate and
# supplies only this role's four unique values. Kill switch:
# export ARCHITECTURE_CYCLE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 컴포넌트 경계·의존 방향" "USE_WHEN: 새 모듈 경계나 기존 경계 변경이 걸릴 때" "PRODUCES (required record fields): ADR (context/decision/consequences/alternatives-considered), C4 context/container boundary diagram. WRITE_SCOPE: [\"docs/issue-<n>/decisions/**\"]" "HAND-OFF: 인터페이스 형태 세부는 → api-design; 성능 예산이 걸리면 → performance-engineering. BOUNDARY CASE: 위 YOU DECIDE 범위를 벗어나면 멈추고 화살표대로 넘겨라 — 다른 역할의 범위를 조용히 흡수하지 마라; 다음 역할 세션을 열기 전에 이 역할의 기록에 hand-off 지점을 남겨라."
