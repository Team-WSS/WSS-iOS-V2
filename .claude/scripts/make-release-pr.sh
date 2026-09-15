#!/usr/bin/env bash
# make-release-pr 커맨드의 기계적·비가역 구간을 결정론적으로 강제하는 헬퍼.
# 판단(버전·릴리즈노트 질문·PR 본문 작성·승인·보고)은 커맨드(LLM)가, 여기서는 안 한다.
# ⚠️ 이슈·브랜치 생성은 이 스크립트가 하지 않는다 — 기존 new-issue 스킬(new-issue.sh)을 그대로 재사용한다.
#
# 사용법:
#   make-release-pr.sh preflight
#   make-release-pr.sh pr-create --head <branch> --title <전체제목> --body-file <path>
set -euo pipefail

# repo 루트 고정 (커맨드가 어디서 호출하든 동일하게 동작)
cd "$(git rev-parse --show-toplevel)"

die() { echo "❌ $*" >&2; exit 1; }

# ── preflight: 안전·되돌릴 수 있음 ─────────────────────────────────────────────────
cmd_preflight() {
  # 1. 인증
  gh auth status >/dev/null 2>&1 || die "gh 미인증 상태입니다. 'gh auth login' 후 다시 시도하세요."

  # 2. 두 브랜치 모두 최신화
  git fetch origin main || die "git fetch origin main 실패."
  git fetch origin develop || die "git fetch origin develop 실패."
  git rev-parse --verify origin/main >/dev/null 2>&1 || die "origin/main 을 찾을 수 없습니다."
  git rev-parse --verify origin/develop >/dev/null 2>&1 || die "origin/develop 을 찾을 수 없습니다."

  # 3. develop이 main보다 앞선 커밋(= 이번에 승격될 것들)
  local ahead
  ahead="$(git rev-list --count origin/main..origin/develop)"
  echo "AHEAD=$ahead"

  # ⚠️ main이 아주 오래 방치됐던 경우(컷오버 전 첫 릴리즈 등) AHEAD가 수천 단위로 뛸 수 있다 —
  # 커밋 하나하나를 다 나열하면 PR 본문·터미널 모두 못 쓸 정도로 길어진다. 임계값을 넘으면
  # PR 단위 병합 커밋("Merge pull request #…"/"[Merge] #…")만 골라 압축 롤업으로 대체한다.
  local ROLLUP_THRESHOLD=80
  if [[ "$ahead" == "0" ]]; then
    echo "COMMITS="
  elif (( ahead > ROLLUP_THRESHOLD )); then
    echo "── 커밋 롤업 압축(PR 병합 단위만, 전체 $ahead 개 중) ──"
    git log origin/main..origin/develop --pretty=format:'- %s' --reverse \
      | grep -E '^- (Merge pull request #|\[Merge\] #)' || echo "(PR 병합 커밋 패턴을 찾지 못했습니다 — 아래 COMPARE_URL로 직접 확인하세요.)"
    echo ""
    local remote_url owner_repo
    remote_url="$(git remote get-url origin)"
    owner_repo="$(printf '%s' "$remote_url" | sed -E 's#^.*[:/]([^/]+/[^/]+)\.git$#\1#')"
    echo "COMPARE_URL=https://github.com/${owner_repo}/compare/main...develop"
  else
    echo "── 커밋 롤업 (origin/main..origin/develop) ──"
    git log origin/main..origin/develop --pretty=format:'- %s' --reverse
    echo ""
  fi

  # 4. main이 현재 들고 있는 MARKETING_VERSION (사용자가 새 버전을 정할 때 참고)
  # ⚠️ main이 App 모듈 도입 이전 상태(컷오버 전 첫 릴리즈)면 이 파일/키 자체가 없을 수 있다 —
  # 그건 에러가 아니라 "아직 main에 버전이 없다"는 정상 케이스이므로 fail-loud 하지 않고
  # develop의 현재 값을 참고용으로 대신 보여준다.
  local proj_swift="Projects/App/Project.swift"
  local main_version
  main_version="$(git show "origin/main:$proj_swift" 2>/dev/null \
    | grep -oE '"MARKETING_VERSION": *"[^"]+"' \
    | grep -oE '[0-9][^"]*' || true)"
  if [[ -n "$main_version" ]]; then
    echo "CURRENT_MAIN_VERSION=$main_version"
  else
    echo "CURRENT_MAIN_VERSION=NONE"
    local develop_version
    develop_version="$(git show "origin/develop:$proj_swift" 2>/dev/null \
      | grep -oE '"MARKETING_VERSION": *"[^"]+"' \
      | grep -oE '[0-9][^"]*' || true)"
    [[ -n "$develop_version" ]] || die "origin/develop:$proj_swift 에서도 MARKETING_VERSION을 찾지 못했습니다 — 파일 구조가 바뀌었을 수 있습니다. 직접 확인하세요."
    echo "REFERENCE_DEVELOP_VERSION=$develop_version"
    echo "NOTE=main에 아직 MARKETING_VERSION이 없습니다(첫 릴리즈 — App 모듈 자체가 main에 없던 시절 상태). develop의 현재 값을 참고만 하세요."
  fi

  # 5. 워킹트리 상태
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "WORKTREE=DIRTY"
  else
    echo "WORKTREE=CLEAN"
  fi
  exit 0
}

# ── pr-create: 외부 비가역. 승인 후 호출 ────────────────────────────────────────────
cmd_pr_create() {
  local head="" title="" body_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --head)      head="${2:-}"; shift 2 ;;
      --title)     title="${2:-}"; shift 2 ;;
      --body-file) body_file="${2:-}"; shift 2 ;;
      *)           die "pr-create: 알 수 없는 인자 '$1'" ;;
    esac
  done

  [[ -n "$head" ]] || die "pr-create: --head 가 필요합니다."
  [[ -n "$title" ]] || die "pr-create: --title 이 필요합니다."
  [[ -n "$body_file" && -f "$body_file" ]] || die "pr-create: --body-file 경로가 없거나 존재하지 않습니다."

  # base는 항상 main으로 고정 — 이 스크립트의 존재 이유(다른 곳엔 base=main PR 생성이 없다).
  local url
  url="$(gh pr create --base main --head "$head" --title "$title" --body-file "$body_file" --assignee @me)" \
    || die "gh pr create 실패. 출력을 확인하세요."

  echo "PR_URL=$url"
}

# ── 디스패치 ────────────────────────────────────────────────────────────────────
sub="${1:-}"; shift || true
case "$sub" in
  preflight) cmd_preflight "$@" ;;
  pr-create) cmd_pr_create "$@" ;;
  *)         die "사용법: make-release-pr.sh {preflight | pr-create --head <branch> --title <제목> --body-file <path>}" ;;
esac
