#!/usr/bin/env bash
# Stop 훅: 모듈 코드(Projects/<Layer>/<Module>/Sources/**.swift)를 바꿨는데 그 모듈의 CLAUDE.md
# "주의사항"을 안 건드린 채 작업을 끝내려 하면, 해당 모듈 가이드를 점검하라고 에이전트를 한 번 되돌린다.
#
# 흐름: stdin 으로 Stop hook JSON 수신 → 미커밋 변경에서 "코드 바뀐 모듈 ∧ 그 CLAUDE.md 는 안 바뀜"
#   후보를 뽑는다 → 같은 후보 집합엔 한 번만(마커로 중복 억제, stop_hook_active 로 루프 차단)
#   → 후보가 있으면 decision:block 으로 점검을 강제한다.
# 설계 메모: "이 함정을 적을 가치가 있나"는 모델(에이전트)이 판단·편집한다. 훅은 트리거만 보장한다.
#   "적을 게 없다"고 결론지으면 후보 집합이 유지돼도 마커가 같아 다시 띄우지 않는다.
#
# 안전 제일(fail-open): git 아님·오류·후보 없음이면 빈 출력 + exit 0. 절대 사용자 작업을 막지 않는다.
set -uo pipefail

input="$(cat)"

# 루프 차단: 이미 stop 훅 때문에 이어가는 중이면 개입하지 않는다.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

proj="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)}"
[ -n "$proj" ] || exit 0
cd "$proj" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

marker=".git/caution-check.marker"

# 미커밋 변경 경로(스테이지+워킹+미추적). 상태 접두 3글자 제거, 리네임은 도착 경로만 남긴다.
changed="$(git status --porcelain=v1 2>/dev/null | sed -e 's/^...//' -e 's/.* -> //')"
[ -n "$changed" ] || { rm -f "$marker" 2>/dev/null; exit 0; }

# 코드가 바뀐 모듈 루트(Projects/<Layer>/<Module>) 수집
code_modules="$(printf '%s\n' "$changed" \
  | grep -E '^Projects/[^/]+/[^/]+/Sources/.*\.swift$' \
  | sed -E 's#^(Projects/[^/]+/[^/]+)/.*#\1#' \
  | sort -u)"
[ -n "$code_modules" ] || { rm -f "$marker" 2>/dev/null; exit 0; }

# 후보 = 코드 바뀐 모듈 중, CLAUDE.md 가 존재하고 그 CLAUDE.md 는 안 바뀐 모듈
candidates=""
while IFS= read -r m; do
  [ -n "$m" ] || continue
  [ -f "$m/CLAUDE.md" ] || continue
  printf '%s\n' "$changed" | grep -qxF "$m/CLAUDE.md" && continue
  candidates="${candidates}${m}
"
done <<EOF
$code_modules
EOF

candidates="$(printf '%s' "$candidates" | sed '/^$/d' | sort -u)"
[ -n "$candidates" ] || { rm -f "$marker" 2>/dev/null; exit 0; }

# 중복 억제: 같은 후보 집합이면 한 번만 띄운다.
sig="$(printf '%s' "$candidates" | shasum | awk '{print $1}')"
[ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$sig" ] && exit 0
printf '%s' "$sig" > "$marker" 2>/dev/null || true

list="$(printf '%s\n' "$candidates" | sed -e 's#^#  - #' -e 's#$#/CLAUDE.md#')"
reason="코드를 바꿨는데 다음 모듈의 CLAUDE.md \"주의사항\"을 아직 점검하지 않았습니다:
${list}

각 파일을 열어, 이번 코드 변경에서 '코드만 봐선 모르는 것'(숨은 의존·함정·예외·왜)이 새로 생겼으면 \"주의사항 (작업 중 발견 시 누적)\" 절에 한 줄 누적하세요. 코드/디렉토리만 봐도 아는 자명한 나열은 적지 말 것(노이즈 금지). 점검 결과 적을 게 없다고 판단하면 그 결론만 밝히면 됩니다(그러면 다시 묻지 않습니다)."

# Stop 훅 block: 에이전트를 되돌려 점검을 강제한다(reason 이 모델에 전달됨).
jq -n --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
