#!/usr/bin/env bash
# PreToolUse(Bash) 가드: "정말 위험한" 외부 작업 하나 — 원격 히스토리를 덮어쓰는 force-push — 에만
# 승인(ask)을 강제한다. stdin 으로 PreToolUse hook JSON 을 받아 .tool_input.command 를 검사한다.
#   - ready-merge.sh push (--force-with-lease 강제 푸시) → permissionDecision=ask → 사용자 승인 프롬프트.
#   - 그 외 전부                                          → 빈 출력 → 기본 권한 흐름(가드 개입 없음).
#
# 설계 메모(가드 범위를 좁게 유지하는 이유 — 팀 결정):
#   훅 게이트를 늘릴수록 승인 프롬프트가 겹겹이 쌓여 흐름이 불편해진다. 그래서 "복구 불가능하게
#   위험한 것"만 훅으로 잡고, 나머지는 스킬의 승인 게이트 + 기본 권한 흐름에 맡긴다:
#   - new-issue.sh run: 실행 전에 스킬이 이슈 초안(제목·본문·Type·base)을 보여주고 승인받는 게이트가
#     이미 있다 → 훅 이중 게이트 불필요. (이슈는 생성돼도 close로 수습 가능)
#   - raw `git push` / `gh pr create`: 잘못 나가도 revert·PR close로 수습 가능한 수준 → 게이트 없음.
#   - force-push 만은 원격 브랜치를 덮어써 복구가 어렵다 → 유일하게 훅으로 강제한다.
set -euo pipefail

cmd="$(cat | jq -r '.tool_input.command // ""')"

READY_MERGE_RE='(^|[^[:alnum:]_-])ready-merge\.sh[[:space:]]+push([[:space:]]|$)'

if printf '%s' "$cmd" | grep -qE "$READY_MERGE_RE"; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"외부로 나가는 비가역 작업입니다(ready-merge.sh push: --force-with-lease 강제 푸시로 원격 브랜치를 덮어씁니다). 승인이 필요합니다."}}'
fi
exit 0
