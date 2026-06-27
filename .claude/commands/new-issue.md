---
description: GitHub 이슈를 만들고 base(기본 develop) 기준 Type/#이슈 브랜치로 분기·이동 후 tuist generate까지 수행한다
---

작업 하나를 시작한다. 인자: `$ARGUMENTS` (작업 설명. 비면 사용자에게 묻는다).
GitHub 이슈 생성 → `Type/#이슈` 브랜치 분기·이동·push → `tuist generate`를 한 번에 처리한다.
판단(설명·Type·본문·승인·dirty 선택·보고)은 이 커맨드가, **기계적·비가역 구간은 `.claude/scripts/new-issue.sh`** 가 맡는다.

> 이 명령은 repo에 커밋되어 **팀원이 각자 쓴다.** 특정 gh 계정/소유자/레포를 박지 말 것 —
> 담당자는 `@me`(실행한 본인), 레포는 현재 디렉토리로 자동 감지된다.
> 외부로 나가는 작업(이슈 생성·push)은 **사용자 승인 후** 실행한다.

## Type 집합 (전역 `commit` 스킬 표에서 `[AD]`만 제외)

`AD`를 빼고 그대로 가져온다. 이 목록에 없는 Type은 만들지 않는다.

| Type | 언제 |
|---|---|
| `Design` | 뷰 레이아웃·UI 구조 작업 |
| `Feat` | 새로운 기능 구현 |
| `Network` | 네트워크 연결·API 통신 |
| `Add` | Feat 이외의 부수적인 코드 추가, 라이브러리 추가, 새 View 생성 |
| `Del` | 쓸모없는 코드·주석 삭제 |
| `Fix` | 버그·오류 해결, 코드 수정 |
| `Refactor` | 전면 수정 |
| `Chore` | 그 이외 자잘한 작업 |
| `Docs` | README 등 문서 개정 |
| `Setting` | 프로젝트·환경 세팅 |
| `Test` | 테스트 코드 |
| `Merge` | 브랜치 병합 |

## 절차

### 1. 작업 내용 파악
- `$ARGUMENTS`로 설명 확보. 비거나 이슈로 만들기에 모호하면 **무엇을 / 왜 / 완료 기준**을 한 번에 모아 묻는다.

### 2. Type 결정
- 설명에서 위 표의 Type 하나를 추론한다. 애매하면 사용자에게 확인한다.
- ⚠️ **브랜치명 정규형 = `<Type>/#<번호>`** — 슬래시(`/`)와 `#`이 **둘 다** 반드시 있어야 한다. 예: `Feat/#149`, `Docs/#130`.
- ⚠️ 레포에 `Feat#92`(슬래시·`#` 누락), 소문자 `chore`/`refactor` 같은 위반 사례가 섞여 있다. **절대 따라가지 말 것** — 항상 대문자 Type + `/` + `#` + 번호.

### 3. 이슈 초안 + base 확인 + 게이트 (필수)
- **제목**: `[Type] <한글 설명>`.
- **본문**: `.github/ISSUE_TEMPLATE/feature_request.md`를 **읽어** 그 섹션 구조 그대로(frontmatter 제거) 채운다 —
  `## Issue Title`에 한 줄 요약, `## Issue Content`에 작업 항목(`- [ ]` 체크리스트). 템플릿 파일이 없으면 이 2섹션 골격으로 폴백.
- **담당자**: `@me`.
- **base 브랜치**: `develop`을 기본으로 제시하되, 다른 base를 원하는지 사용자에게 묻는다.
- ⚠️ 이슈 생성은 외부로 나가는 비가역 작업 → **제목·본문·Type·담당자·base를 보여주고 승인받은 뒤** 다음으로 넘어간다.

> ⚙️ 4·5단계의 기계적·비가역 구간은 **`.claude/scripts/new-issue.sh`** 가 결정론적으로 강제한다.
> `--no-track`·`#` 따옴표·번호 파싱·Type 정규형 같은 반복 함정을 손으로 재구성하지 말고 스크립트를 호출한다.

### 4. 사전 점검 (이슈 생성 전 — 취소 가능하도록 먼저)
- **스크립트가 처리한다**: `bash .claude/scripts/new-issue.sh preflight <base>`
  - 이 한 줄이 `gh auth status`(미인증이면 비정상 종료) + `git fetch origin <base>`(base 최신화·존재 확인) + 워킹트리 상태 출력을 모두 수행한다.
  - **비정상 종료(exit≠0)면 출력 그대로 보고하고 중단** (미인증이면 `gh auth login` 안내).
  - 출력 마지막 줄이 `WORKTREE=DIRTY`면 새 브랜치로 변경사항이 따라가므로 알리고 선택받는다:
    (a) 그대로 가져가기 (b) `--stash` 사용(5단계에서 `--stash` 전달) (c) 취소. `CLEAN`이면 그대로 진행.

### 5. 이슈 생성 + 브랜치 분기·push + 프로젝트 생성 (한 번에)
3단계에서 작성·승인된 **본문을 스크래치패드 임시 파일에 먼저 기록**한다(멀티라인 인자 회피). 그 뒤 한 번 호출:

```bash
bash .claude/scripts/new-issue.sh run \
  --type <Type> --base <base> \
  --title "[Type] 한글 설명" --body-file <스크래치패드_본문_경로> \
  [--stash]   # 4단계에서 (b)를 골랐을 때만
```

- 스크립트가 순서대로 강제한다: (선택)`git stash` → `gh issue create --assignee @me`(현재 레포 자동) + URL에서 번호 파싱 → **`git checkout -b "<Type>/#<번호>" --no-track origin/<base>`**(`--no-track`·`#` 따옴표를 영구 보장 — IDE Push가 base로 새는 사고 방지) → (선택)`git stash pop` → `git push -u`(upstream을 자기 브랜치로) → `tuist generate`.
- `--type`은 위 Type 표에 **정확히 대문자 매칭**해야 통과한다 (`chore`/`Feat#92` 류는 거부됨).
- 이미 만들어둔 이슈로 시작할 땐 `--title/--body-file` 대신 `--num <번호>`.
- 끝에 `ISSUE_NUMBER` / `ISSUE_URL` / `BRANCH` 요약 블록이 출력된다. `tuist generate` 실패 등은 출력 그대로 보고(에셋/Derived 문제면 안내).

### 6. 마무리 보고
- 스크립트 요약 블록(이슈 번호·URL, 브랜치, push 결과)을 그대로 요약.
- 커밋은 사용자가 지시할 때만. (커밋 규약은 docs/WORKFLOW.md)

## 원칙

- 외부로 나가는 작업(이슈 생성·push)은 사용자 승인 후.
- 계정/소유자/레포를 하드코딩하지 않는다 — `@me` + 현재 레포 자동 감지(스크립트가 처리).
- 브랜치 정규형(대문자 Type + `/#` + 번호)·`#` 따옴표·`--no-track`·번호 파싱은 **스크립트(`run`)가 강제**한다 — 손으로 git 명령을 재구성하지 말 것.
- Type은 레포의 위반 사례(`Feat#92`, 소문자 `chore` 등)를 따라가지 말 것 — 스크립트가 정규형만 통과시킨다.
- 이슈 본문 골격은 레포 템플릿이 진실 — 하드코딩하지 말고 런타임에 읽어 따른다.
