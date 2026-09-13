---
name: make-release-PR
description: WSS-iOS-V2에서, develop의 최신 작업을 main으로 승격하는 릴리스 PR을 올릴 때 사용한다. origin/main과 origin/develop을 비교해 이번에 승격될 커밋을 보여주고, 새 버전 번호와 릴리즈 노트 내용을 물어본 뒤, `Project.swift`의 `MARKETING_VERSION`과 `fastlane/metadata/ko/release_notes.txt`를 반영한 릴리스 브랜치를 만들어 `base=main` PR을 올린다. "릴리스 PR 올리자", "main에 배포 PR 만들어줘", "이번 버전 릴리즈하자", 또는 "/make-release-PR" 같은 요청에 트리거. ⚠️ 이슈 생성·push·PR 생성은 외부로 나가는 비가역 작업 → 승인 후에만 실행한다. (`main` push 이후 실제 App Store 심사 제출은 `.github/workflows/release.yml`의 몫 — 이 스킬은 그 트리거가 되는 PR을 올리는 데까지만 한다.)
metadata:
  short-description: develop→main 릴리스 PR — 버전·릴리즈노트 반영 후 base=main PR 생성
---

# Make Release PR — develop → main 릴리스 PR (WSS-iOS-V2)

`develop`의 지금까지 작업을 `main`으로 승격하는 PR을 만든다. 판단(버전·릴리즈노트 질문·PR 본문
작성·승인·보고)은 이 스킬이, **기계적·비가역 구간은 `.claude/scripts/make-release-pr.sh`** 가
맡는다. 이슈·브랜치 생성은 새로 만들지 않고 **기존 `new-issue` 스킬을 그대로 재사용**한다.

> ⚠️ **이 스킬은 App Store 제출을 실행하지 않는다.** main에 push되면 `.github/workflows/release.yml`이
> `CUTOVER_READY` repo variable + `app-store-release` Environment 승인 게이트를 거쳐 별도로 처리한다
> (`docs/WORKFLOW.md`의 "배포" 절). 이 스킬은 그 트리거가 되는 **PR을 올리는 데까지만** 한다.
>
> ⚠️ **리뷰 범위**: 이 PR에 담기는 코드는 develop에 들어가기 전 각 feature PR에서 이미 검증됐다 —
> `make-PR`의 wss-pr-reviewer 통합 리뷰 라운드를 **여기서 다시 돌리지 않는다**(중복). main의
> required status check(`All Tests Passed`)가 회귀를 잡고, 사람이 PR 본문의 커밋 롤업을 눈으로
> 확인하는 걸로 충분하다(사용자 확정).
>
> ⚠️ **버전 동기화**: 버전(`MARKETING_VERSION`)·릴리즈노트 커밋은 **릴리스 브랜치 → main에만**
> 들어간다. `develop`은 별도로 동기화하지 않는다(사용자 확정 — 다음 릴리스 때 새 값을 입력하면서
> 자연히 갱신됨).

## 절차

### 1. 사전 점검 (읽기 전용, 취소 가능)
- `bash .claude/scripts/make-release-pr.sh preflight`
  - `gh auth status` + `origin/main`·`origin/develop` fetch 후:
    `AHEAD=<n>`(승격될 커밋 수), 커밋 롤업(제목 목록), `CURRENT_MAIN_VERSION=<현재 main 버전>`,
    `WORKTREE=CLEAN|DIRTY`를 출력한다.
  - 비정상 종료(exit≠0)면 출력 그대로 보고하고 중단.
  - **`AHEAD=0`**이면 승격할 게 없다는 뜻 — 그 사실을 알리고 종료(굳이 진행하지 않음).
  - **`AHEAD`가 크면(80 초과, 예: 첫 릴리즈처럼 main이 오래 방치됐던 경우)** 커밋 하나하나 대신
    PR 병합 단위(`Merge pull request #…`/`[Merge] #…`)로 압축된 롤업 + `COMPARE_URL`이 나온다 —
    이 경우 5단계 PR 본문의 `Key Changes`도 압축 롤업 + `COMPARE_URL` 링크로 채운다(수천 줄 나열
    금지).
  - **`CURRENT_MAIN_VERSION=NONE`**이면 main에 아직 버전 자체가 없다는 뜻(App 모듈이 main에
    없던 시절 — 첫 릴리즈 케이스). 대신 나온 `REFERENCE_DEVELOP_VERSION`을 참고용으로만 보여주고,
    "이번이 사실상 첫 App Store 심사 제출이니 신중하게 버전을 골라달라"고 안내한다.
  - `WORKTREE=DIRTY`면 사용자에게 알리고 커밋/stash 여부를 확인한다(브랜치 분기 시 그대로 따라감 —
    `new-issue`와 동일 원칙).
  - 롤업과 버전 정보를 사용자에게 보여준다 — "이번에 이런 커밋들이 승격돼요, 지금 main 버전은
    X예요(또는: main엔 아직 버전이 없어요)."

### 2. 버전 · 릴리즈노트 질문 (일반 대화 — AskUserQuestion 아님)
- 개방형 텍스트라 선택지 UI가 안 맞는다. 1단계에서 보여준 `CURRENT_MAIN_VERSION`을 참고해 **새
  버전 번호**를 묻고, 이어서 **이번 릴리즈 노트**(App Store 심사에 올라가는 "새로운 기능" 문구,
  한국어)를 묻는다. 형식 강제(semver 등)는 하지 않는다 — 사용자가 정하는 값을 그대로 쓴다.

### 3. 이슈 + 브랜치 (기존 `new-issue` 스킬 재사용)
- **`new-issue` 스킬을 호출**한다 — Type `Setting`(프로젝트·환경 세팅), base `develop`, 제목은
  `[Setting] vX.Y.Z 릴리즈 준비` 형태(X.Y.Z는 2단계에서 받은 새 버전). 본문은 이번 릴리즈에 뭘
  반영하는지(버전 갱신 + 릴리즈노트 갱신) 짧게.
- 승인 게이트는 `new-issue` 스킬 자체가 이미 갖고 있다 — 여기서 중복으로 다시 묻지 않는다.
- 끝나면 `ISSUE_NUMBER`/`BRANCH`를 확보한 상태(그 스킬의 마무리 보고 형식).

### 4. 버전 · 릴리즈노트 반영 + 커밋 (승인 후, 비가역이지만 새 브랜치라 안전)
- `Projects/App/Project.swift`에서 `"MARKETING_VERSION": "..."` 값을 2단계에서 받은 새 버전으로
  **Edit**한다. 그 문자열을 못 찾으면 **추측하지 말고 중단**하고 사용자에게 보고(파일 구조가
  바뀌었을 수 있음).
- `fastlane/metadata/ko/release_notes.txt`를 2단계에서 받은 릴리즈노트로 **Write**(덮어쓰기)한다.
- `tuist generate` 1회 실행(일관성 — 다른 스킬들도 `Project.swift` 변경 후 항상 재생성한다).
- 두 파일만 명시적으로 스테이징(`git add -A` ❌):
  ```bash
  git add Projects/App/Project.swift fastlane/metadata/ko/release_notes.txt
  git commit -m "[Setting] #<N> - vX.Y.Z 릴리즈 버전·릴리즈노트 반영"
  git push
  ```
  (commit-msg 훅이 이 양식을 검증한다 — Type은 3단계와 같은 `Setting`.)

### 5. PR 본문 작성 (게이트)
- `.github/pull_request_template.md`를 **읽어** 그 섹션 구조 그대로 채운다(하드코딩 금지).
  어투는 **해요체**(합쇼체 금지), 소제목으로 관심사를 나누고 문장은 짧게 — `make-PR` 4단계와
  같은 규칙.
  - `💡 Issue` → `- closed #<N>`
  - `💭 Summary` → "vX.Y.Z 릴리즈 — develop 작업을 main으로 승격해요."
  - `🔑 Key Changes` → 1단계 커밋 롤업(압축된 경우 `COMPARE_URL` 링크 포함) + "버전
    `<현재 또는 NONE>→<새 버전>`, 릴리즈 노트 갱신" 한 줄.
  - `📱 Simulation` → "해당 없음"(버전/릴리즈노트 텍스트 변경뿐, UI 변경 없음).
  - `🧑‍🧒‍🧒 To Reviewer` → 버전 번호·릴리즈노트 문구가 맞는지 확인 요청 + "merge되면
    `CUTOVER_READY`가 `true`일 때만 `app-store-release` 승인 요청이 뜬다"는 안내(오발동 걱정
    방지 — `docs/WORKFLOW.md`의 "배포" 절 링크).
  - `※ Reference` → 없으면 생략.
- **제목**: `[Setting] #<N> - vX.Y.Z 릴리즈`. base=`main`, head=3단계 브랜치를 함께 명시.
- 채운 본문·제목·base/head를 보여주고 **검토 게이트** — 사용자가 수정·승인할 때까지 다음으로
  넘어가지 않는다.

### 6. PR 생성 (외부 비가역, 승인 게이트)
- ⚠️ **사용자 승인 전까지 실행하지 않는다.** 승인 시, 5단계에서 승인된 본문을 스크래치패드 임시
  파일에 기록한 뒤:
  ```bash
  bash .claude/scripts/make-release-pr.sh pr-create \
    --head "<branch>" --title "[Setting] #<N> - vX.Y.Z 릴리즈" --body-file <스크래치패드_본문_경로>
  ```
- `PR_URL=...` 출력을 그대로 보고. `gh` 실패는 출력 그대로 보고(인증 누락 등).

### 7. 마무리 보고
- PR URL을 보고하고, **"merge되면 `CUTOVER_READY` 상태에 따라 자동 제출 워크플로우가
  대기하거나 skip돼요"** 라고 안내한다(사용자가 오발동을 걱정하지 않게).

## 원칙
- **이슈·브랜치는 재발명하지 않는다** — `new-issue` 스킬(Type `Setting`, base `develop`)을 그대로 쓴다.
- **PR 본문 골격은 정본 우선** — `.github/pull_request_template.md`를 읽어 따른다(하드코딩 금지).
- **버전·릴리즈노트는 자유 입력** — AskUserQuestion(선택지 UI)이 아니라 일반 대화로 받는다.
- **리뷰 라운드는 생략** — 코드는 이미 검증됐다, main의 required status check + 사람의 커밋 롤업
  확인으로 충분(사용자 확정, 중복 리뷰 방지).
- **develop 버전 동기화는 하지 않는다**(사용자 확정) — 버전/릴리즈노트 커밋은 릴리스 브랜치 →
  main에만 들어간다.
- **외부 비가역(이슈 생성·push·PR 생성)은 승인 후에만.**
- `Project.swift`의 `MARKETING_VERSION` 문자열을 못 찾으면 추측 편집하지 않고 중단·보고한다.
