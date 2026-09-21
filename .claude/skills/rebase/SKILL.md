---
name: rebase
description: WSS-iOS-V2에서, 작업 브랜치를 다른 브랜치 위로 rebase할 때 사용한다(머지 직전이 아니어도, 작업 중 최신 변경을 끌어올 때도). 기본 후보는 develop이고, 감지된 다른 후보(스택 베이스 브랜치·직전 체크아웃 브랜치)도 함께 제시해 사용자가 고르며, 목록에 없으면 직접 브랜치명을 입력할 수도 있다. ① base 선택 → ② preflight → ③ rebase(충돌 시 멈추고 사용자와 함께 해결) → ④ 승인 후 force-with-lease push, 순으로 진행한다. "리베이스 해줘", "브랜치 최신화", "develop 반영해줘", 또는 "/rebase [base브랜치]" 같은 요청에 트리거. 머지 직전 정리는 대신 `ready-merge`를 쓴다. ⚠️ force-push는 외부로 나가는 비가역 작업 → 승인 후에만 실행한다.
metadata:
  short-description: 작업 브랜치를 사용자가 고른 base(기본 develop) 위로 rebase + 승인 시 force-with-lease push
---

# Rebase — 작업 브랜치를 base 위로 리베이스 (WSS-iOS-V2)

작업 브랜치를 **사용자가 고른 base**(기본값 `develop`) 위로 rebase하고, 승인 시 **`--force-with-lease`로 원격을 갱신**한다.
판단(base 선택·충돌 해결·보고)은 이 스킬이, **기계적·비가역 구간은 `.claude/scripts/rebase.sh`** 가 맡는다.

> 머지 직전에 "develop 위로 올리고 PR을 머지 가능 상태로 만드는" 용도는 대신 **`ready-merge`** 를 쓴다.
> 이 스킬은 그보다 범용이다 — 작업 도중 base의 최신 변경을 끌어오고 싶을 때, 또는 develop이 아닌
> 다른 브랜치(스택된 base 등) 위로 옮겨 타고 싶을 때 쓴다.
>
> ⚠️ **force-push는 외부로 나가는 비가역 작업** → 사용자 승인 후에만(아래 4단계 게이트, PreToolUse 훅이 캐치). 항상 `--force-with-lease`(스크립트가 강제) — 남의 push를 날리지 않는다.
>
> ⚠️ **보호 브랜치 금지**: `develop`/`main`·분리 HEAD에서는 실행하지 않는다(스크립트가 거부). 반드시 작업 브랜치에서.

## 절차

### 1. Base 브랜치 선택
- 인자로 base가 이미 주어졌으면(`/rebase develop` 등) 이 단계를 건너뛰고 2단계로.
- 없으면 후보를 감지한다: `bash .claude/scripts/rebase.sh candidates`
  - `STACK_BASE=`: 현재 브랜치가 스택되어 있는 것으로 보이는 로컬 브랜치(있으면).
  - `PREV_BRANCH=`: 직전에 체크아웃했던 브랜치(있으면).
  - 둘 다 참고용 휴리스틱이다 — 다음 preflight 단계가 실제 존재·최신 여부를 확정한다.
- `develop` + 감지된 후보(중복 제거)를 **AskUserQuestion**으로 제시한다:
  - 1번은 항상 `develop`(추천·기본값으로 표시).
  - `STACK_BASE`가 있으면 2번으로, `PREV_BRANCH`가 있고 앞의 후보와 다르면 다음 번호로 추가.
  - 목록에 없는 브랜치를 원하면 "기타"로 직접 입력할 수 있다(도구가 자동 제공 — 별도 옵션을 만들지 않는다).
  - **감지된 후보가 develop 하나뿐이면** 질문을 띄우지 않고 "develop 외 다른 후보가 없어 develop 기준으로 진행합니다"라고 짧게 확인만 한다(원하면 사용자가 즉시 다른 브랜치명을 부를 수 있다).

### 2. Preflight (안전·되돌릴 수 있음)
- `bash .claude/scripts/rebase.sh preflight <base>`
  - 워킹트리 clean·진행 중 rebase 없음·base 존재(원격에 있으면 fetch해 `origin/<base>`, 로컬 전용이면 그대로)를 확인하고(비정상 종료면 출력 그대로 보고·중단), 다음을 출력한다:
    `PR=...`(열린 PR / `none`, gh 미인증이면 조용히 `none`), `BRANCH=`, `TARGET=`(실제 rebase 대상), `BEHIND=`(target에 있고 내겐 없는 커밋), `AHEAD=`(내게만 있는 커밋), `WORKTREE=CLEAN`.
- 해석·보고:
  - **BEHIND=0**이면 이미 target 최신 위라 rebase가 불필요하다 → 알리고, 사용자가 명시적으로 원하지 않는 한 종료한다.
  - 그 외에는 BEHIND/AHEAD를 보고하고 **rebase 진행 게이트**로 넘어간다.

### 3. Rebase (사용자 승인 후)
- ⚠️ rebase는 히스토리를 재작성한다 → preflight 결과를 보여주고 **승인받은 뒤** 실행한다.
- `bash .claude/scripts/rebase.sh rebase <base>`
  - **`REBASE=OK`**: 깔끔히 올라갔다 → 4단계로.
  - **`REBASE=CONFLICT`(exit 2)**: 스크립트가 충돌 파일을 출력하고 멈춘다. **직접 해결하지 말고** 충돌 파일 목록을 보여주며 **사용자와 함께** 해결한다:
    - 충돌 내용을 함께 확인한다(메인이 상황 설명·제안은 할 수 있으나 최종 해결은 사용자가 함) → `git add <해결한 파일>` → `git rebase --continue`.
    - 커밋이 여럿이면 충돌이 여러 번 날 수 있다 — rebase가 끝날 때까지 반복한다.
    - 중단하려면 `git rebase --abort`(원래 상태로 복귀) 후 종료한다.
  - rebase가 끝나면(`git status`로 rebase 진행 중이 아님을 확인) 4단계로.

### 4. Force Push (외부 비가역, 승인 게이트)
- ⚠️ **승인 전까지 push하지 않는다.** rebase로 로컬 히스토리가 바뀌었으므로, 이 브랜치를 이미 원격에 push한 적이 있다면 이후 일반 `git push`는 거부된다 — force-push가 필요한 이유를 설명하고 승인받는다.
- 승인 시: `bash .claude/scripts/rebase.sh push`
  - 스크립트가 `git push --force-with-lease origin <branch>`를 실행한다(원격이 내가 본 상태일 때만 덮어쓴다 — 실패하면 원격이 앞서 있다는 뜻이니 `git fetch`로 확인하라고 안내). PreToolUse 훅이 이 호출에 승인 프롬프트를 띄운다.
  - `PUSHED=<branch>` 출력.
- 이 브랜치가 원격에 아직 없거나(신규 브랜치) 사용자가 push를 원치 않으면 이 단계는 건너뛴다 — 3단계에서 로컬 rebase만 하고 종료해도 된다.

### 5. 마무리 보고
- 어떤 base 위로 rebase했는지, BEHIND/AHEAD가 어떻게 반영됐는지, push 여부(및 PR이 있었다면 그 PR이 갱신됐음)를 요약한다.

## 원칙
- **base는 항상 사용자가 고른다** — develop을 기본값으로 제안하되 강제하지 않는다. 감지 로직은 후보를 좁혀줄 뿐 최종 선택은 아니다.
- **force-push는 승인 후, 항상 `--force-with-lease`**(스크립트 강제). 보호 브랜치·분리 HEAD 금지(스크립트 강제).
- **충돌은 멈추고 사용자와 해결** — 스크립트도, 메인도 임의로 충돌을 해결하지 않는다.
- rebase 순서·`--force-with-lease`·브랜치 검증 같은 반복 함정은 손으로 git 명령을 재구성하지 말고 **스크립트를 호출**한다.
- 머지 직전 정리(PR을 머지 가능 상태로) 용도는 `ready-merge`가 이미 있다 — 겹치지 않게 그쪽으로 안내한다.
