#!/usr/bin/env bash
# rebase: 현재 브랜치를 임의의 base 브랜치 위로 rebase하고, 승인 시 --force-with-lease로
# 원격을 갱신하는 기계적·비가역 구간을 결정론적으로 강제하는 헬퍼.
# 판단(base 선택·충돌 해결·보고)은 스킬(LLM)이 한다.
#
# 사용법:
#   rebase.sh candidates          # base 후보 감지: STACK_BASE=, PREV_BRANCH=
#   rebase.sh preflight <base>    # 안전 확인 + behind/ahead 출력 (되돌릴 수 있음)
#   rebase.sh rebase <base>       # rebase 실행 (충돌이면 REBASE=CONFLICT, exit 2)
#   rebase.sh push                # git push --force-with-lease (외부 비가역 — 훅이 승인 게이트)
set -euo pipefail

# repo 루트 고정 (어디서 호출하든 동일하게 동작)
cd "$(git rev-parse --show-toplevel)"

die() { echo "❌ $*" >&2; exit 1; }

# 보호 브랜치(develop/main)·분리 HEAD에서 실행 금지 → 현재 작업 브랜치명을 stdout으로.
assert_work_branch() {
  local cur; cur="$(git branch --show-current)"
  [[ -n "$cur" ]] || die "분리 HEAD 상태입니다. 작업 브랜치에서 실행하세요."
  case "$cur" in
    develop|main) die "보호 브랜치($cur)에서는 rebase 대상이 될 수 없습니다. 작업 브랜치로 이동하세요." ;;
  esac
  printf '%s' "$cur"
}

# base가 origin에 있으면 fetch해 "origin/<base>"를, 로컬 전용 브랜치면 "<base>"를 stdout으로.
resolve_target() {
  local base="$1"
  if git ls-remote --exit-code --heads origin "$base" >/dev/null 2>&1; then
    git fetch origin "$base" >&2 || die "git fetch origin '$base' 실패."
    printf 'origin/%s' "$base"
  else
    git rev-parse --verify "$base" >/dev/null 2>&1 \
      || die "브랜치 '$base'를 찾을 수 없습니다(로컬·원격 모두 없음)."
    printf '%s' "$base"
  fi
}

# ── candidates: base 후보 감지 (되돌릴 수 있음, 참고용 — preflight가 최종 검증) ──────────
cmd_candidates() {
  local cur; cur="$(assert_work_branch)"

  # 스택 베이스: HEAD의 조상이면서 아직 develop엔 없는(=develop에 안 합쳐진) 로컬 브랜치 중
  # 가장 최근 커밋(=스택에서 가장 가까운 부모) 하나. 여러 단계로 스택된 브랜치를 감지한다.
  local stack_base="" best_date=0
  while IFS= read -r b; do
    [[ -z "$b" || "$b" == "$cur" || "$b" == "develop" || "$b" == "main" ]] && continue
    git merge-base --is-ancestor "$b" "$cur" 2>/dev/null || continue
    git merge-base --is-ancestor "$b" develop 2>/dev/null && continue
    local d; d="$(git log -1 --format=%ct "$b" 2>/dev/null || echo 0)"
    if (( d > best_date )); then best_date=$d; stack_base="$b"; fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

  # 직전 체크아웃 브랜치 (reflog 기준) — 스택 감지가 놓친 케이스의 보조 후보.
  local prev_branch
  prev_branch="$(git rev-parse --abbrev-ref '@{-1}' 2>/dev/null || true)"
  [[ "$prev_branch" == "$cur" || "$prev_branch" == "@{-1}" || "$prev_branch" == "HEAD" ]] && prev_branch=""
  git rev-parse --verify "$prev_branch" >/dev/null 2>&1 || prev_branch=""

  echo "STACK_BASE=${stack_base:-NONE}"
  echo "PREV_BRANCH=${prev_branch:-NONE}"
}

# ── preflight: 안전·되돌릴 수 있음 ─────────────────────────────────────────────────
cmd_preflight() {
  local base="${1:-}"
  [[ -n "$base" ]] || die "preflight: base 인자가 필요합니다. 예) preflight develop"
  local cur; cur="$(assert_work_branch)"

  # 1. 워킹트리 clean (rebase는 dirty에서 위험)
  [[ -z "$(git status --porcelain)" ]] || die "워킹트리가 dirty합니다. 커밋 또는 stash 후 다시 시도하세요."

  # 2. 이미 진행 중인 rebase가 있으면 중단
  if [[ -d "$(git rev-parse --git-path rebase-merge 2>/dev/null)" ]] || [[ -d "$(git rev-parse --git-path rebase-apply 2>/dev/null)" ]]; then
    die "이미 rebase가 진행 중입니다. 해결하거나 'git rebase --abort' 후 다시 시도하세요."
  fi

  # 3. base 해석(원격 있으면 fetch 후 origin/<base>, 로컬 전용이면 <base>) + 존재 확인
  local target; target="$(resolve_target "$base")"

  # 4. 열린 PR 확인 (있다면 push가 갱신할 대상 — gh 미인증/미설치면 조용히 건너뜀)
  local pr=""
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    pr="$(gh pr view --json number,state,url --jq '"PR=#\(.number) PR_STATE=\(.state) PR_URL=\(.url)"' 2>/dev/null || true)"
  fi
  [[ -n "$pr" ]] && echo "$pr" || echo "PR=none"

  # 5. target 대비 behind/ahead (rebase로 끌어올 양 / push로 보낼 양)
  local counts
  counts="$(git rev-list --left-right --count "$target...HEAD" 2>/dev/null || printf '0\t0')"
  echo "BRANCH=$cur"
  echo "TARGET=$target"
  echo "BEHIND=$(printf '%s' "$counts" | awk '{print $1}')"
  echo "AHEAD=$(printf '%s' "$counts" | awk '{print $2}')"
  echo "WORKTREE=CLEAN"
  exit 0
}

# ── rebase: 로컬 히스토리 재작성. 승인 후 호출 ──────────────────────────────────────
cmd_rebase() {
  local base="${1:-}"
  [[ -n "$base" ]] || die "rebase: base 인자가 필요합니다. 예) rebase develop"
  assert_work_branch >/dev/null

  local target; target="$(resolve_target "$base")"

  if git rebase "$target"; then
    echo "REBASE=OK"
  else
    echo "REBASE=CONFLICT"
    echo "── 충돌 파일 ──" >&2
    git diff --name-only --diff-filter=U >&2 || true
    echo "해결 후: git add <파일> && git rebase --continue   /   중단: git rebase --abort" >&2
    exit 2
  fi
}

# ── push: 외부 비가역. 훅 승인 게이트 후 호출 ───────────────────────────────────────
cmd_push() {
  local cur; cur="$(assert_work_branch)"
  # --force-with-lease: 원격이 '내가 마지막으로 본 상태'일 때만 덮어쓴다(남의 push를 날리지 않음).
  git push --force-with-lease origin "$cur" \
    || die "force-with-lease push 실패. 원격이 더 앞서 있을 수 있습니다 — 'git fetch' 후 상태를 확인하세요."
  echo "PUSHED=$cur"
}

# ── 디스패치 ────────────────────────────────────────────────────────────────────
sub="${1:-}"; shift || true
case "$sub" in
  candidates) cmd_candidates "$@" ;;
  preflight)  cmd_preflight "$@" ;;
  rebase)     cmd_rebase "$@" ;;
  push)       cmd_push "$@" ;;
  *)          die "사용법: rebase.sh {candidates | preflight <base> | rebase <base> | push}" ;;
esac
