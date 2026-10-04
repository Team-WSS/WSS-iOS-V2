---
name: make-release-PR
description: WSS-iOS-V2에서, develop의 최신 작업을 main으로 승격하는 릴리스를 진행할 때 사용한다. 흐름은 단방향 두 단계다 — ① 준비 PR: 새 버전 번호·릴리즈 노트를 물어 `Project.swift`의 `MARKETING_VERSION`과 `fastlane/metadata/ko/release_notes.txt`를 반영한 `Setting/#N` 브랜치로 `base=develop` PR을 올리고, ② 승격 PR: 그게 develop에 머지되면 `head=develop`, `base=main` PR을 올린다. main에만 들어가는 커밋은 만들지 않는다. "릴리스 PR 올리자", "main에 배포 PR 만들어줘", "이번 버전 릴리즈하자", 또는 "/make-release-PR" 같은 요청에 트리거. ⚠️ 이슈 생성·push·PR 생성은 외부로 나가는 비가역 작업 → 승인 후에만 실행한다. (`main` push 이후 실제 App Store 심사 제출은 `.github/workflows/release.yml`의 몫 — 이 스킬은 그 트리거가 되는 PR을 올리는 데까지만 한다.)
metadata:
  short-description: develop→main 릴리스 — 버전·릴리즈노트를 develop에 반영(준비 PR) 후 develop→main 승격 PR
---

# Make Release PR — develop → main 릴리스 (WSS-iOS-V2)

`develop`의 지금까지 작업을 `main`으로 승격한다. 판단(단계 판정·버전·릴리즈노트 질문·PR 본문
작성·승인·보고)은 이 스킬이, **기계적·비가역 구간은 `.claude/scripts/make-release-pr.sh`** 가
맡는다. 이슈·브랜치 생성은 새로 만들지 않고 **기존 `new-issue` 스킬을 그대로 재사용**한다.

## 릴리스 흐름 — 단방향 (사용자 확정, 2026-10-04 #284)

```
develop ──●──●──●(준비 PR: 버전·노트)──●──●──
                 \
main ─────────────●(승격 PR merge → tag vX.Y.Z)
```

- **버전·릴리즈노트는 develop에 먼저 반영**한다(준비 PR, `base=develop`). 그 뒤 **develop 자체를
  main으로 승격**한다(승격 PR, `head=develop`, `base=main`). 별도 릴리스 브랜치를 main에 넣지 않는다.
- **main에만 들어가는 커밋을 만들지 않는다**(핫픽스 포함 — develop에서 고쳐 승격한다). 그래야
  back-merge가 필요 없고 그래프가 한 방향으로 유지된다.
- **왜**: 예전엔 버전·릴리즈노트 커밋이 릴리스 브랜치 → main에만 들어가고 develop은 동기화하지
  않았다. main이 develop에 없는 커밋을 계속 들고 있게 돼 릴리스마다 `MARKETING_VERSION` 줄에서
  충돌이 났고(v1.10.2 PR #285에서 실측), 그래프도 양방향으로 꼬였다. #284에서 main 전용 커밋을
  develop으로 1회 흡수하고 이 흐름으로 바꿨다.

> ⚠️ **이 스킬은 App Store 제출을 실행하지 않는다.** main에 push되면 `.github/workflows/release.yml`이
> `CUTOVER_READY` repo variable + `app-store-release` Environment 승인 게이트를 거쳐 별도로 처리한다
> (`docs/WORKFLOW.md`의 "배포" 절). 이 스킬은 그 트리거가 되는 **PR을 올리는 데까지만** 한다.
>
> ⚠️ **리뷰 범위**: 이 PR들에 담기는 코드는 develop에 들어가기 전 각 feature PR에서 이미 검증됐다 —
> `make-PR`의 wss-pr-reviewer 통합 리뷰 라운드를 **여기서 다시 돌리지 않는다**(중복). required
> status check(`All Tests Passed`)가 회귀를 잡고, 사람이 PR 본문의 커밋 롤업을 눈으로 확인하는
> 걸로 충분하다(사용자 확정).

## 절차

### 1. 사전 점검 + 단계 판정 (읽기 전용, 취소 가능)
- `bash .claude/scripts/make-release-pr.sh preflight`
  - `gh auth status` + `origin/main`·`origin/develop` fetch 후:
    `AHEAD=<n>`(승격될 커밋 수), 커밋 롤업(제목 목록), `MAIN_ONLY_COMMITS=<n>`(+ 목록),
    `CURRENT_MAIN_VERSION=<main 버전>`, `CURRENT_DEVELOP_VERSION=<develop 버전>`,
    `WORKTREE=CLEAN|DIRTY`를 출력한다.
  - 비정상 종료(exit≠0)면 출력 그대로 보고하고 중단.
  - **`AHEAD=0`**이면 승격할 게 없다는 뜻 — 그 사실을 알리고 종료.
  - **`AHEAD`가 크면(80 초과)** 커밋 하나하나 대신 PR 병합 단위로 압축된 롤업 + `COMPARE_URL`이
    나온다 — 승격 PR 본문의 `Key Changes`도 압축 롤업 + `COMPARE_URL` 링크로 채운다.
  - **`CURRENT_MAIN_VERSION=NONE`**이면 main에 아직 버전이 없다는 뜻(첫 릴리즈 케이스) — 대신 나온
    `REFERENCE_DEVELOP_VERSION`을 참고용으로 보여주고 신중하게 버전을 골라달라고 안내한다.
  - **`MAIN_ONLY_COMMITS`가 0이 아니면** 단방향 흐름이 깨진 상태다(누가 main에 직접 넣었거나 옛 흐름의
    잔재). 목록을 보여주고, 준비 PR 브랜치에서 `git merge origin/main`으로 develop에 흡수해야 한다고
    알린다(4단계에서 함께 처리). 그대로 승격 PR을 올리면 충돌하거나 main 전용 변경이 계속 남는다.
  - `WORKTREE=DIRTY`면 사용자에게 알리고 커밋/stash 여부를 확인한다.
- **단계 판정**:
  - `CURRENT_DEVELOP_VERSION`이 `CURRENT_MAIN_VERSION`과 **같으면** → 아직 준비 전. **2단계부터**(준비 PR).
  - **다르면**(develop에 새 버전이 이미 머지됨) → "develop에 vX.Y.Z가 준비돼 있어요, 바로 승격할까요?"를
    확인하고 **6단계로 건너뛴다**(승격 PR). 릴리즈 노트를 더 고쳐야 하면 준비 PR을 다시 탄다.
- 롤업과 두 버전을 사용자에게 보여준다.

### 2. 버전 · 릴리즈노트 질문 (일반 대화 — AskUserQuestion 아님)
- 개방형 텍스트라 선택지 UI가 안 맞는다. `CURRENT_MAIN_VERSION`을 참고해 **새 버전 번호**를 묻고,
  이어서 **이번 릴리즈 노트**(App Store "새로운 기능" 문구, 한국어)를 묻는다. 형식 강제는 하지 않는다.
- 사용자가 릴리즈 노트를 직접 쓰겠다고 하면 파일을 건드리지 않고 버전만 반영한다(준비 PR 머지 전에
  사용자가 같은 브랜치에 커밋하도록 안내).

### 3. 이슈 + 브랜치 (기존 `new-issue` 스킬 재사용)
- **`new-issue` 스킬을 호출**한다 — Type `Setting`, base `develop`, 제목 `[Setting] vX.Y.Z 릴리즈 준비`.
  본문은 버전 갱신 + 릴리즈노트 갱신을 짧게.
- 승인 게이트는 `new-issue` 스킬 자체가 갖고 있다 — 여기서 중복으로 묻지 않는다.

### 4. 버전 · 릴리즈노트 반영 + 커밋
- `Projects/App/Project.swift`의 `"MARKETING_VERSION": "..."` 값을 새 버전으로 **Edit**한다. 그 문자열을
  못 찾으면 **추측하지 말고 중단**·보고.
- (받았으면) `fastlane/metadata/ko/release_notes.txt`를 **Write**(덮어쓰기)한다.
- `tuist generate` 1회 → 곧바로 `Scripts/patch-spm-deployment-target.sh`(루트 `CLAUDE.md` 비협상).
- 두 파일만 명시적으로 스테이징(`git add -A` ❌):
  ```bash
  git add Projects/App/Project.swift fastlane/metadata/ko/release_notes.txt
  git commit -m "[Setting] #<N> - vX.Y.Z 릴리즈 버전·릴리즈노트 반영"
  ```
- **`MAIN_ONLY_COMMITS`가 0이 아니었으면** 이어서 `git merge origin/main`으로 흡수한다. 충돌(대개
  `MARKETING_VERSION` 한 줄)은 새 버전으로 정리하고, merge 커밋 메시지도 컨벤션을 따른다
  (`[Setting] #<N> - main 릴리스 커밋 develop 동기화를 위해 origin/main 병합` — 기본
  "Merge remote-tracking branch …" 메시지로 두지 않는다).
- `git push`(일반 push — force 불필요).

### 5. 준비 PR (base=develop, 게이트)
- `.github/pull_request_template.md`를 **읽어** 섹션 구조 그대로 채운다(하드코딩 금지). 어투는 **해요체**.
  - `💡 Issue` → `- closed #<N>`
  - `💭 Summary` → "vX.Y.Z 버전·릴리즈 노트를 develop에 반영해요."(main 흡수가 있었으면 그 사실도)
  - `🔑 Key Changes` → 버전 `<main 버전>→<새 버전>`, 릴리즈 노트 갱신 여부, (있으면) 흡수한 main 전용 커밋 목록.
  - `📱 Simulation` → "해당 없음".
  - `🧑‍🧒‍🧒 To Reviewer` → 버전 번호·릴리즈노트 문구 확인 요청 + "머지되면 develop→main 승격 PR을 따로 올려요".
- **제목**: `[Setting] #<N> - vX.Y.Z 버전 반영`. 본문·제목·base/head를 보여주고 **검토 게이트**.
- 승인 시 본문을 스크래치패드 임시 파일에 쓰고:
  ```bash
  bash .claude/scripts/make-release-pr.sh pr-create --base develop \
    --head "<branch>" --title "[Setting] #<N> - vX.Y.Z 버전 반영" --body-file <본문_경로>
  ```
- `PR_URL=...`을 보고하고 **여기서 멈춘다** — 준비 PR 머지는 사람이 한다. "머지되면 다시 불러주세요,
  바로 승격 PR을 올릴게요"라고 안내한다(재호출 시 1단계 판정이 6단계로 보낸다).

### 6. 승격 PR (head=develop, base=main, 게이트)
- 1단계 preflight를 다시 돌려 `MAIN_ONLY_COMMITS=0`이고 `CURRENT_DEVELOP_VERSION`이 새 버전인지 확인한다.
  `MAIN_ONLY_COMMITS`가 0이 아니면 승격하지 말고 준비 PR 단계로 되돌린다.
- 템플릿대로 채운다:
  - `💡 Issue` → `- #<N>`(준비 PR이 이미 닫음 — 참조만, 번호를 모르면 생략)
  - `💭 Summary` → "vX.Y.Z 릴리즈 — develop 작업을 main으로 승격해요."
  - `🔑 Key Changes` → 1단계 커밋 롤업(압축된 경우 `COMPARE_URL` 포함) + 버전 `<main>→<새 버전>` 한 줄.
  - `📱 Simulation` → "해당 없음".
  - `🧑‍🧒‍🧒 To Reviewer` → "merge되면 `CUTOVER_READY`가 `true`일 때만 `app-store-release` 승인 요청이
    뜬다"는 안내(`docs/WORKFLOW.md`의 "배포" 절 링크). **머지 방식은 "Create a merge commit"**(squash ❌ —
    squash하면 main에 develop에 없는 커밋이 생겨 단방향이 깨진다).
- **제목**: `[Setting] #<N> - vX.Y.Z 릴리즈`(N은 준비 PR의 이슈 번호).
- 보여주고 **검토 게이트** → 승인 시:
  ```bash
  bash .claude/scripts/make-release-pr.sh pr-create --base main \
    --head develop --title "[Setting] #<N> - vX.Y.Z 릴리즈" --body-file <본문_경로>
  ```
  (스크립트가 `base=main`이면 `head=develop`만 허용한다.)

### 7. 마무리 보고
- PR URL을 보고하고, **"merge되면 `CUTOVER_READY` 상태에 따라 자동 제출 워크플로우가 대기하거나
  skip돼요"** 라고 안내한다.

## 원칙
- **단방향**: develop → main만. main 전용 커밋 ❌, 릴리스 브랜치를 main에 직접 ❌, 승격 PR squash ❌.
- **이슈·브랜치는 재발명하지 않는다** — `new-issue` 스킬(Type `Setting`, base `develop`)을 그대로 쓴다.
- **PR 본문 골격은 정본 우선** — `.github/pull_request_template.md`를 읽어 따른다.
- **버전·릴리즈노트는 자유 입력** — 일반 대화로 받는다.
- **리뷰 라운드는 생략**(사용자 확정, 중복 리뷰 방지).
- **외부 비가역(이슈 생성·push·PR 생성)은 승인 후에만.**
- `Project.swift`의 `MARKETING_VERSION` 문자열을 못 찾으면 추측 편집하지 않고 중단·보고한다.
