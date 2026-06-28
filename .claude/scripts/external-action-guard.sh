#!/usr/bin/env bash
# PreToolUse(Bash) 가드: 외부로 나가는·비가역 작업을 캡슐화한 "스크립트의 실행 호출"에 승인(ask)을 강제한다.
#
# stdin 으로 PreToolUse hook JSON 을 받아 .tool_input.command 를 검사한다.
#   - new-issue.sh run    (이슈 생성 + 브랜치 push)        → permissionDecision=ask → 사용자 승인 프롬프트.
#   - ready-merge.sh push (--force-with-lease 강제 푸시)    → permissionDecision=ask → 사용자 승인 프롬프트.
#   - *.sh preflight/rebase(읽기·로컬) / 그 외 명령         → 빈 출력 → 기본 권한 흐름(가드 개입 없음).
#
# 설계 메모: 직접 gh 명령(gh pr create 등)은 일부러 가드하지 않는다.
#   외부작업은 가드된 스크립트를 통해서만 한다는 규율을 전제로, 그 스크립트의 비가역 서브커맨드 실행만 게이트한다.
#   향후 외부작업 스크립트가 늘면 아래 패턴에 추가한다.
set -euo pipefail

cmd="$(cat | jq -r '.tool_input.command // ""')"

# 외부작업 스크립트의 비가역 서브커맨드 호출
NEW_ISSUE_RE='(^|[^[:alnum:]_-])new-issue\.sh[[:space:]]+run([[:space:]]|$)'
READY_MERGE_RE='(^|[^[:alnum:]_-])ready-merge\.sh[[:space:]]+push([[:space:]]|$)'

if printf '%s' "$cmd" | grep -qE "$NEW_ISSUE_RE"; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"외부로 나가는 비가역 작업 스크립트입니다(new-issue.sh run: 이슈 생성·push). 승인이 필요합니다."}}'
elif printf '%s' "$cmd" | grep -qE "$READY_MERGE_RE"; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"외부로 나가는 비가역 작업입니다(ready-merge.sh push: --force-with-lease 강제 푸시로 원격 브랜치를 덮어씁니다). 승인이 필요합니다."}}'
fi
exit 0
