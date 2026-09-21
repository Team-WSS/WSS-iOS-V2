#!/usr/bin/env bash
#
# swift-format 스타일 게이트 — "이번 브랜치가 건드린/추가한 .swift 파일만" 린트한다.
#
# 왜 "변경 파일만"인가 (코드만 봐선 모르는 배경):
#   swift-format의 `lint`는 rule 몇 개만 보는 게 아니라 "이 파일을 format하면 바뀌는가?"를
#   묻는 **전체 포매터 diff**다. indentation·spacing·blank-line·trailing-whitespace 같은
#   pretty-printer 진단은 `rules`와 무관하게 항상 켜지며 끌 수 없다. 그래서 이 레포의
#   886개 레거시 파일을 통째로 게이트하면 ~3,400건(대부분 레이아웃)이 쏟아진다.
#   A3의 목적은 "앞으로 새로 짜는 코드의 스타일을 CI가 검사"하는 것이므로, base(develop)
#   대비 이번 브랜치가 실제로 건드린/추가한 파일만 본다. 레거시 백로그는 건드리지 않는다.
#   (건드린 레거시 파일은 그 파일 전체가 clean해야 하므로 점진적으로 수렴한다.)
#
# 설정: 레포 루트 `.swift-format`을 swift-format이 각 파일 기준으로 자동 발견해 쓴다.
#
# 사용:
#   Tooling/SwiftFormat/lint-changed.sh [--strict] [--base <ref>]
#     --strict : 위반이 있으면 종료코드 1로 실패 (게이트를 required로 승격한 뒤 사용).
#                기본은 report-only — 위반을 출력만 하고 항상 0으로 끝난다.
#     --base   : 비교 기준 ref (기본: origin/develop, 없으면 develop).
#
set -euo pipefail

STRICT=0
BASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --base)   BASE="${2:-}"; shift 2 ;;
    *) echo "알 수 없는 인자: $1" >&2; exit 2 ;;
  esac
done

# base 결정: 인자 > origin/develop > develop
if [ -z "$BASE" ]; then
  if git rev-parse --verify -q origin/develop >/dev/null; then
    BASE="origin/develop"
  else
    BASE="develop"
  fi
fi

# 전제 검증(추측 금지): swift format이 실제로 있는지 먼저 확인한다.
# 없으면 여기서 명확히 실패해 "폴백 필요" 신호를 준다.
if ! swift format --version >/dev/null 2>&1; then
  echo "::error::'swift format'을 찾을 수 없습니다 — 이 툴체인에 swift-format이 없습니다. SwiftLint 폴백을 검토하세요." >&2
  exit 3
fi

# 3-dot diff: merge-base(BASE,HEAD)..HEAD → PR가 develop에서 갈라진 뒤 자기 쪽 변경만.
# --diff-filter=ACMR: 추가/수정/이름변경/복사만(삭제 제외 → 목록 파일은 HEAD에 존재).
FILES_TMP="$(mktemp)"
trap 'rm -f "$FILES_TMP"' EXIT

# ⚠️ git diff 실패(잘못된 base 등)를 "변경 0개"로 착각하면 게이트가 **거짓 초록**이 된다.
# 그래서 diff를 먼저 잡아 실패면 fail-loud로 멈춘다(| grep ... || true 뒤에 두면 실패가 묻힌다).
if ! CHANGED="$(git diff --name-only --diff-filter=ACMR "${BASE}...HEAD" -- '*.swift')"; then
  echo "::error::git diff 실패 — base '${BASE}'가 유효한지 확인하세요(fetch 누락 등). 게이트를 통과시키지 않습니다." >&2
  exit 4
fi

# 생성물만 제외: Derived(tuist generate 산출물) / .build(SPM·Tuist/.build 포함).
# Tuist/의 매니페스트(ProjectDescriptionHelpers/*, Package.swift, Config.swift)는 실제 관리 소스라
# 제외하지 않는다 — Projects/**/Project.swift가 이미 대상인 것과 일관.
# (grep은 "매치 0"에도 종료코드 1이라 여기서만 || true로 정상 처리.)
printf '%s\n' "$CHANGED" | grep -vE '(^|/)(Derived|\.build)/' > "$FILES_TMP" || true

# 이식성(bash 3.2엔 mapfile 없음): while-read로 배열 구성 + 존재 확인
FILES=()
while IFS= read -r line; do
  [ -n "$line" ] || continue
  [ -f "$line" ] || continue
  FILES+=("$line")
done < "$FILES_TMP"

if [ ${#FILES[@]} -eq 0 ]; then
  echo "✅ 변경된 .swift 파일 없음 — swift-format 검사 생략. (base: ${BASE})"
  exit 0
fi

echo "🔎 swift-format lint 대상 ${#FILES[@]}개 파일 (base: ${BASE}, mode: $([ $STRICT -eq 1 ] && echo strict || echo report-only))"

LINT_ARGS=(--parallel)
[ "$STRICT" -eq 1 ] && LINT_ARGS+=(--strict)

set +e
swift format lint "${LINT_ARGS[@]}" "${FILES[@]}"
CODE=$?
set -e

if [ "$STRICT" -eq 0 ]; then
  [ "$CODE" -ne 0 ] && echo "ℹ️ (report-only) 위반이 있지만 게이트를 실패시키지 않습니다."
  exit 0
fi
exit "$CODE"
