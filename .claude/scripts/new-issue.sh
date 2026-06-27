#!/usr/bin/env bash
# new-issue 커맨드의 기계적·비가역 구간을 결정론적으로 강제하는 헬퍼.
# 판단(설명 수집·Type 추론·본문 작성·승인·dirty 선택·보고)은 커맨드(LLM)가, 여기서는 안 한다.
#
# 사용법:
#   new-issue.sh preflight <base>
#   new-issue.sh run --type <Type> --base <base>
#                    (--title <전체제목> --body-file <path> | --num <n>)
#                    [--stash] [--dry-run]
set -euo pipefail

# repo 루트 고정 (커맨드가 어디서 호출하든 동일하게 동작)
cd "$(git rev-parse --show-toplevel)"

# 브랜치 정규형 Type 허용 집합 (commit 표에서 AD 제외). 소문자/`Feat#92` 류 위반 차단용.
ALLOWED_TYPES="Design Feat Network Add Del Fix Refactor Chore Docs Setting Test Merge"

die() { echo "❌ $*" >&2; exit 1; }

# ── preflight: 안전·되돌릴 수 있음. 승인/드래프트 전 언제든 호출 가능 ──────────────
cmd_preflight() {
  local base="${1:-}"
  [[ -n "$base" ]] || die "preflight: base 인자가 필요합니다. 예) preflight develop"

  # 1. 인증 — 미인증이면 여기서 fail-fast
  if ! gh auth status >/dev/null 2>&1; then
    die "gh 미인증 상태입니다. 'gh auth login'으로 로그인 후 다시 시도하세요."
  fi

  # 2. base 최신화 + 존재 확인
  git fetch origin "$base" || die "git fetch origin '$base' 실패."
  git rev-parse --verify "origin/$base" >/dev/null 2>&1 \
    || die "origin/$base 를 찾을 수 없습니다. base 브랜치명을 확인하세요."

  # 3. 워킹트리 상태 → LLM이 stash 여부 결정
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "WORKTREE=DIRTY"
  else
    echo "WORKTREE=CLEAN"
  fi
  exit 0
}

# ── run: 비가역 기계 시퀀스. 승인 후 호출 ──────────────────────────────────────────
cmd_run() {
  local type="" base="" title="" body_file="" num="" stash=0 dry=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type)      type="${2:-}"; shift 2 ;;
      --base)      base="${2:-}"; shift 2 ;;
      --title)     title="${2:-}"; shift 2 ;;
      --body-file) body_file="${2:-}"; shift 2 ;;
      --num)       num="${2:-}"; shift 2 ;;
      --stash)     stash=1; shift ;;
      --dry-run)   dry=1; shift ;;
      *)           die "run: 알 수 없는 인자 '$1'" ;;
    esac
  done

  # 필수 인자 검증
  [[ -n "$type" ]] || die "run: --type 이 필요합니다."
  [[ -n "$base" ]] || die "run: --base 가 필요합니다."

  # Type 정규형 강제 — 허용 집합에 정확히 대문자 매칭
  local ok=0 t
  for t in $ALLOWED_TYPES; do [[ "$type" == "$t" ]] && ok=1 && break; done
  (( ok )) || die "run: '$type' 는 허용된 Type이 아닙니다(대문자 정규형). 허용: $ALLOWED_TYPES"

  # 이슈 지정: 생성(--title+--body-file) 또는 기존(--num) 중 하나
  local creating=0
  if [[ -n "$num" ]]; then
    [[ "$num" =~ ^[0-9]+$ ]] || die "run: --num 은 숫자여야 합니다."
  elif [[ -n "$title" && -n "$body_file" ]]; then
    creating=1
    [[ -f "$body_file" ]] || die "run: --body-file '$body_file' 가 없습니다."
  else
    die "run: 새 이슈는 --title 과 --body-file 을, 기존 이슈는 --num 을 지정하세요."
  fi

  # dry-run 명령 출력 헬퍼
  run_cmd() {
    if (( dry )); then echo "[dry-run] $*"; else eval "$*"; fi
  }

  # 1. stash (선택) — 브랜치 체크아웃 전에 워킹트리 정리
  if (( stash )); then
    run_cmd "git stash push -m 'new-issue: pre-branch'"
  fi

  # 2. 이슈 생성 또는 기존 번호 사용
  local url=""
  if (( creating )); then
    if (( dry )); then
      echo "[dry-run] gh issue create --title \"$title\" --body-file \"$body_file\" --assignee @me"
      num="<n>"; url="<dry-run-url>"
    else
      url="$(gh issue create --title "$title" --body-file "$body_file" --assignee @me)"
      num="$(grep -oE '[0-9]+$' <<<"$url")"
      [[ -n "$num" ]] || die "이슈 URL에서 번호를 파싱하지 못했습니다: $url"
      echo "🔗 이슈 생성됨: $url"   # 이후 단계 실패해도 링크는 확보
    fi
  fi

  # 3. 브랜치 정규형 + --no-track 분기 (이 스크립트가 영구 보장하는 핵심)
  local branch="$type/#$num"
  run_cmd "git checkout -b \"$branch\" --no-track \"origin/$base\""

  # 4. stash 복원
  if (( stash )); then
    run_cmd "git stash pop"
  fi

  # 5. upstream을 자기 브랜치로 push
  run_cmd "git push -u origin \"$branch\""

  # 6. 프로젝트 생성
  run_cmd "tuist generate"

  # 7. 머신 파싱용 요약
  echo "ISSUE_NUMBER=$num"
  echo "ISSUE_URL=${url:-<existing>}"
  echo "BRANCH=$branch"
}

# ── 디스패치 ────────────────────────────────────────────────────────────────────
sub="${1:-}"; shift || true
case "$sub" in
  preflight) cmd_preflight "$@" ;;
  run)       cmd_run "$@" ;;
  *)         die "사용법: new-issue.sh {preflight <base> | run --type ... --base ... (--title --body-file | --num) [--stash] [--dry-run]}" ;;
esac
