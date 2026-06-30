---
name: ready-merge
description: WSS-iOS-V2에서, PR을 올린 뒤 머지 직전에 작업 브랜치를 최신 develop 위로 rebase하고 --force-with-lease로 원격 PR을 갱신해 "머지 가능 상태"로 만들 때 사용한다. ① preflight 안전 확인 → ② origin/develop 위로 rebase(충돌 시 멈추고 사용자와 해결) → ③ 승인 후 force-with-lease push, 까지 한다. 실제 머지 버튼은 사람이 GitHub에서 누른다(이 스킬은 머지하지 않는다). "머지 준비", "develop에 리베이스", "force push로 PR 갱신", 또는 "/ready-merge" 같은 요청에 트리거. ⚠️ force-push는 외부로 나가는 비가역 작업 → 승인 후에만 실행한다.
metadata:
  short-description: 작업 브랜치를 develop 위로 rebase + force-with-lease push로 PR을 머지 가능 상태로 (머지는 사람이)
---

# Ready Merge — 머지 직전 rebase + force-push (WSS-iOS-V2)

PR을 올린 뒤, 머지 직전에 작업 브랜치를 **최신 `develop` 위로 rebase**하고 **`--force-with-lease`로 원격을 갱신**해 머지 가능 상태로 만든다. 판단(승인·충돌 해결·보고)은 이 스킬이, **기계적·비가역 구간은 `.claude/scripts/ready-merge.sh`** 가 맡는다.

> ⚠️ **이 스킬은 머지하지 않는다.** rebase + force-push로 PR을 갱신해 "머지 가능 상태"까지만 만든다. 실제 머지 버튼은 CI·리뷰 승인 확인 후 **사람이 GitHub에서** 누른다(브랜치 보호 규칙). PR 생성은 `make-PR` 스킬이 먼저 한다.
>
> ⚠️ **force-push는 외부로 나가는 비가역 작업** → 사용자 승인 후에만(아래 3단계 게이트, PreToolUse 훅이 캐치). 항상 `--force-with-lease`(스크립트가 강제) — 남의 push를 날리지 않는다.
>
> ⚠️ **보호 브랜치 금지**: `develop`/`main`·분리 HEAD에서는 실행하지 않는다(스크립트가 거부). 반드시 작업 브랜치에서.

## 절차

### 1. 사전 점검 (안전·되돌릴 수 있음)
- `bash .claude/scripts/ready-merge.sh preflight develop`
  - 인증·워킹트리 clean·진행 중 rebase·base 존재를 확인하고(비정상 종료면 출력 그대로 보고·중단), 다음을 출력한다:
    `PR=...`(열린 PR / `none`), `BRANCH=`, `BEHIND=`(develop에 있고 내겐 없는 커밋 = rebase로 끌어올 것), `AHEAD=`(내게만 있는 커밋 = force-push로 보낼 것), `WORKTREE=CLEAN`.
- 해석·보고:
  - **PR=none**이면 아직 PR이 없으니 알리고, 먼저 `make-PR`로 PR을 올릴지 사용자에게 확인한다(머지 준비의 전제).
  - **BEHIND=0**이면 이미 develop 최신 위라 rebase가 불필요하다 → 그 사실을 알리고, 굳이 force-push 하지 않고 종료한다(사용자가 명시적으로 원하면 진행).
  - 그 외에는 BEHIND/AHEAD를 보고하고 **rebase 진행 게이트**로 넘어간다.

### 2. Rebase (사용자 승인 후)
- ⚠️ rebase는 히스토리를 재작성한다 → preflight 결과를 보여주고 **승인받은 뒤** 실행한다.
- `bash .claude/scripts/ready-merge.sh rebase develop`
  - **`REBASE=OK`**: 깔끔히 올라갔다 → 3단계로.
  - **`REBASE=CONFLICT`(exit 2)**: 스크립트가 충돌 파일을 출력하고 멈춘다. 충돌을 **사용자와 함께 해결**한다:
    - 충돌 내용을 확인·해결한다(메인이 도울 수 있음) → `git add <해결한 파일>` → `git rebase --continue`.
    - 커밋이 여럿이면 충돌이 여러 번 날 수 있다 — rebase가 끝날 때까지 반복한다.
    - 중단하려면 `git rebase --abort`(원래 상태로 복귀) 후 종료한다.
  - rebase가 끝나면(`git status`로 rebase 진행 중이 아님을 확인) 3단계로.

### 3. Force Push (외부 비가역, 승인 게이트)
- ⚠️ **승인 전까지 push하지 않는다.** 승인 시:
  - `bash .claude/scripts/ready-merge.sh push`
  - 스크립트가 `git push --force-with-lease origin <branch>`를 실행한다(원격이 내가 본 상태일 때만 덮어쓴다 — 실패하면 원격이 앞서 있다는 뜻이니 `git fetch`로 확인하라고 안내). PreToolUse 훅이 이 호출에 승인 프롬프트를 띄운다.
  - `PUSHED=<branch>` 출력.

### 4. 마무리 보고
- 갱신된 PR이 이제 `develop` 위에 올라가 머지 가능 상태임을 보고하고, **PR URL과 함께 "CI/리뷰 승인 확인 후 GitHub에서 머지하세요(머지는 사람이)"** 라고 안내한다.

## 원칙
- **머지는 안 한다** — rebase + force-push로 머지 가능 상태까지만. 머지는 사람이 GitHub에서.
- **force-push는 승인 후, 항상 `--force-with-lease`**(스크립트 강제). 보호 브랜치·분리 HEAD 금지(스크립트 강제).
- **충돌은 멈추고 사용자와 해결** — 스크립트가 임의로 해결하지 않는다.
- rebase 순서·`--force-with-lease`·브랜치 검증 같은 반복 함정은 손으로 git 명령을 재구성하지 말고 **스크립트를 호출**한다.
- 계정/소유자/레포를 하드코딩하지 않는다 — 현재 레포로 자동 감지된다(스크립트가 처리).
