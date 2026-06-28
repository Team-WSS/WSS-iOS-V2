#!/usr/bin/env bash
# ready-merge: 작업 브랜치를 origin/<base> 위로 rebase하고 --force-with-lease로 원격을 갱신하는
# 기계적·비가역 구간을 결정론적으로 강제하는 헬퍼. 판단(승인·충돌 해결·보고)은 스킬(LLM)이 한다.
# ⚠️ 이 스크립트는 머지하지 않는다 — 머지 버튼은 사람이 GitHub에서 누른다(브랜치 보호·리뷰·CI 통과 후).
#
# 사용법:
#   ready-merge.sh preflight <base>   # 안전 확인 + PR/behind/ahead 출력 (되돌릴 수 있음)
#   ready-merge.sh rebase <base>      # git rebase origin/<base> (충돌이면 REBASE=CONFLICT, exit 2)
#   ready-merge.sh push               # git push --force-with-lease (외부 비가역 — 훅이 승인 게이트)
set -euo pipefail

# repo 루트 고정 (어디서 호출하든 동일하게 동작)
cd "$(git rev-parse --show-toplevel)"

die() { echo "❌ $*" >&2; exit 1; }

# 보호 브랜치(develop/main)·분리 HEAD에서 실행 금지 → 현재 작업 브랜치명을 stdout으로.
assert_work_branch() {
  local cur; cur="$(git branch --show-current)"
  [[ -n "$cur" ]] || die "분리 HEAD 상태입니다. 작업 브랜치에서 실행하세요."
  case "$cur" in
    develop|main) die "보호 브랜치($cur)에서는 ready-merge를 실행하지 않습니다. 작업 브랜치로 이동하세요." ;;
  esac
  printf '%s' "$cur"
}

# ── preflight: 안전·되돌릴 수 있음 ─────────────────────────────────────────────────
cmd_preflight() {
  local base="${1:-}"
  [[ -n "$base" ]] || die "preflight: base 인자가 필요합니다. 예) preflight develop"
  local cur; cur="$(assert_work_branch)"

  # 1. 인증
  gh auth status >/dev/null 2>&1 || die "gh 미인증 상태입니다. 'gh auth login' 후 다시 시도하세요."

  # 2. 워킹트리 clean (rebase는 dirty에서 위험)
  [[ -z "$(git status --porcelain)" ]] || die "워킹트리가 dirty합니다. 커밋 또는 stash 후 다시 시도하세요."

  # 3. 이미 진행 중인 rebase가 있으면 중단
  if [[ -d "$(git rev-parse --git-path rebase-merge 2>/dev/null)" ]] || [[ -d "$(git rev-parse --git-path rebase-apply 2>/dev/null)" ]]; then
    die "이미 rebase가 진행 중입니다. 해결하거나 'git rebase --abort' 후 다시 시도하세요."
  fi

  # 4. base 최신화 + 존재 확인
  git fetch origin "$base" || die "git fetch origin '$base' 실패."
  git rev-parse --verify "origin/$base" >/dev/null 2>&1 \
    || die "origin/$base 를 찾을 수 없습니다. base 브랜치명을 확인하세요."

  # 5. 열린 PR 확인 (force-push가 갱신할 대상)
  local pr
  pr="$(gh pr view --json number,state,url --jq '"PR=#\(.number) PR_STATE=\(.state) PR_URL=\(.url)"' 2>/dev/null || true)"
  [[ -n "$pr" ]] && echo "$pr" || echo "PR=none"

  # 6. base 대비 behind/ahead (rebase 필요 여부·force-push로 보낼 양)
  local counts
  counts="$(git rev-list --left-right --count "origin/$base...HEAD" 2>/dev/null || printf '0\t0')"
  echo "BRANCH=$cur"
  echo "BEHIND=$(printf '%s' "$counts" | awk '{print $1}')"   # origin/base에 있고 내겐 없는 커밋 = rebase로 끌어올 것
  echo "AHEAD=$(printf '%s' "$counts" | awk '{print $2}')"    # 내게만 있는 커밋 = force-push로 보낼 것
  echo "WORKTREE=CLEAN"
  exit 0
}

# ── rebase: 로컬 히스토리 재작성. 승인 후 호출 ──────────────────────────────────────
cmd_rebase() {
  local base="${1:-}"
  [[ -n "$base" ]] || die "rebase: base 인자가 필요합니다. 예) rebase develop"
  assert_work_branch >/dev/null

  git fetch origin "$base" || die "git fetch origin '$base' 실패."

  if git rebase "origin/$base"; then
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
  preflight) cmd_preflight "$@" ;;
  rebase)    cmd_rebase "$@" ;;
  push)      cmd_push "$@" ;;
  *)         die "사용법: ready-merge.sh {preflight <base> | rebase <base> | push}" ;;
esac
