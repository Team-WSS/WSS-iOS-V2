---
name: make-PR
description: WSS-iOS-V2 프로젝트에서, 작업을 마치고 PR을 올릴 때 사용한다. ① wss-pr-reviewer로 변경 전체를 통합 리뷰→수정을 Blocker·Warning이 0이 될 때까지 수렴 → ② 이번 변경과 관련된 CLAUDE.md/docs 갱신 필요를 메인이 직접 판정해 필요한 것만 방향성과 함께 제시·반영 → ③ 문서 변경 커밋 → ④ 프로젝트 PR 템플릿대로 본문 작성·사용자 검토 → ⑤ 승인 후 gh로 GitHub PR 생성, 까지 단계별 게이트로 진행한다. "작업 마무리하자", "PR 올리자", 또는 "/make-PR" 같은 요청에 트리거. ⚠️ push·PR 생성은 외부로 나가는 비가역 작업 → 승인 후에만 실행한다. (머지 직전 rebase·force push·merge는 이 스킬 범위 밖.)
metadata:
  short-description: 작업 마무리 — 통합 리뷰 수렴 → 문서 동기화 → 문서 커밋 → PR 본문 검토 → GitHub PR 생성
---

# Make PR — 작업 완료 점검 + PR 올리기 (WSS-iOS-V2)

작업을 끝내고 PR을 올린다. 다섯 단계 — **① 통합 리뷰 수렴 → ② 관련 문서 갱신 확인 → ③ 문서 커밋 → ④ PR 본문 작성·검토 → ⑤ GitHub PR 생성** — 을 **단계별 게이트**로 진행한다.

> ⚠️ **책임 경계**: 이 스킬은 **PR 생성까지**만 한다. 머지 직전 단계(develop에 rebase → 충돌 해결 → force push → merge)는 별도 `ready-merge` 스킬의 몫이다.
>
> ⚠️ **추측 금지 — 정본을 먼저 읽는다.** PR 본문 골격은 `.github/pull_request_template.md`, 문서 갱신 기준은 루트 `CLAUDE.md`("문서 작성·유지 규칙")·각 `CLAUDE.md`, 커밋 양식은 `commit` 스킬·`commit-types.md`를 읽어 따른다. 지어내지 않는다.
>
> ⚠️ **모호하면 묻고, 확실하면 안 묻는다.** 진행에 필요한 정보가 갈리면 사용자에게 물어 하나로 확정한 뒤 진행한다. 정본·컨벤션으로 이미 정해지는 것은 되묻지 않는다.
>
> ⚠️ **구현은 메인이 직접, 리뷰만 위임.** 리뷰는 격리 컨텍스트가 유리해 `wss-pr-reviewer` subagent에 위임하고, 받은 리포트로 **수정은 메인이** 한다. 문서 갱신 판정·편집, PR 본문 작성도 메인이 직접 한다.
>
> ⚠️ **외부로 나가는 비가역 작업(push·`gh pr create`)은 승인 후에만.** ⑤에서 사용자 승인 전까지 어떤 외부 동작도 하지 않는다.

## 절차

### 0. 사전 점검 (읽기·취소 가능)
- **현재 브랜치 확인**: `git branch --show-current`. `develop`/`main`이면 **중단**하고 알린다(브랜치 보호 — 작업 브랜치에서만 PR을 만든다).
- **이슈 번호 추출**: 브랜치명 `<Type>/#<번호>`에서 추출한다(`commit` 스킬의 "이슈 번호 추출" 규칙 재사용 — `#` 뒤 숫자, 없으면 마지막 `/` 뒤 숫자, 그래도 모호하면 최근 커밋에서 재사용하거나 사용자에게 묻는다).
- **변경 범위 수집**: `git fetch origin develop` 후 `git diff --name-only origin/develop...HEAD`(머지베이스 기준). 비어 있으면 PR 만들 변경이 없으므로 중단.
- **상태 보고**: 미푸시 커밋(`git log --oneline origin/<branch>..HEAD` 또는 upstream 미설정 여부)·워킹트리 dirty 여부를 사용자에게 보고한다. **여기서는 아직 push·커밋하지 않는다.**

### 1. 통합 코드 리뷰 — `wss-pr-reviewer` 위임, 수정은 메인 (수렴 루프)
변경 전체를 레이어 가로질러 통합 리뷰한다. **리뷰는 위임, 수정은 메인이** 한다.

- **대상**: 0단계에서 수집한 develop 대비 변경 전체. 브랜치/세션 상태에 기대지 말고 prompt에 "develop 대비 브랜치 diff 전체 리뷰"임을 명시해 호출한다.
- **루프 (최대 3라운드)**:
  1. **리뷰** — `Agent` 도구로 `subagent_type: wss-pr-reviewer`를 호출한다.
  2. **판정** — 리포트의 🔴 Blocker·🟡 Warning이 **둘 다 0이면 수렴 → 루프 종료**.
  3. **수정** — 🔴는 전부 고친다. 🟡도 고치되, **정답을 임의로 못 정하는 항목**(설계 의도 불일치 등)은 사용자에게 확인한 뒤 반영한다. 라운드별 수정 요약을 한 줄로 보고.
  4. 수정이 새 위반을 부를 수 있으므로 **매 라운드 변경 전체를 다시 리뷰**(1로 돌아간다).
- **상한**: 3라운드 안에 🔴+🟡=0이 안 되면 **잔여 항목을 사용자에게 보고하고 멈춘다**(무한 루프 방지).
- **🔵 Nit**: 수렴 후 빠르게 고칠 수 있는 것만 한 번 정리하고, 남은 건 목록으로 보고(Nit은 수렴 기준 아님).
- 리뷰 수정으로 코드가 바뀌었으면, 그 수정분은 **이 단계에서 `commit` 스킬로 커밋**해 둔다(성격에 맞는 Type — 보통 `[Fix]`/`[Refactor]`). 수정이 없었으면 생략.

### 2. 관련 문서 갱신 확인 (살아있는 문서, 핵심)
에이전트 문서를 **이번 변경에 맞춰 살아있게** 유지한다. 떠넘기지 말고 **메인이 먼저 판정**한다.
- **대상 범위(에이전트 문서)** = co-located `CLAUDE.md` + 공통 `docs/*` + `Projects/Feature/Docs/*`(View/VM 골격 템플릿) + `.claude/agents/*`(리뷰어 정의) + `README.md`(모듈 현황). **CLAUDE.md만 보지 말 것.**

- **후보 매핑**: 변경 파일마다 **가장 가까운 상위 `CLAUDE.md`** + 위 공통/전역 문서를 찾는다. 매핑 힌트:
  - 새 UseCase/Entity/정책 → `Projects/Domain/<Module>/CLAUDE.md` "핵심 시나리오"
  - 새/변경 화면 → `Projects/Feature/<Module>/CLAUDE.md`
  - Repository 구현 로직 변경 → `Projects/Data/<Module>/CLAUDE.md`
  - 에러 변환/네이밍/비동기 규약 변경 → `docs/CONVENTIONS.md`
  - View/ViewModel 골격·규칙 변경(정본 `NovelReviewView`/`NovelReviewViewModel` 리팩터) → `Projects/Feature/Docs/VIEW_TEMPLATE.md`·`VIEWMODEL_TEMPLATE.md`
  - 리뷰가 검사하는 계약·규칙 변경(View↔VM 입력 규약·레이어 경계 등) → `.claude/agents/wss-feature-reviewer.md`·`wss-pr-reviewer.md`
  - 모듈 추가/삭제·이름 변경 → `ModuleType.swift`(진실) + 새 모듈 `CLAUDE.md` + `docs/ARCHITECTURE.md`(구현 현황) + `README.md`(모듈 현황/개수)
  - 아키텍처·데이터 흐름·레이어 규약 변경 → `docs/ARCHITECTURE.md`
  - 새 제품 용어 → `docs/GLOSSARY.md` / 테스트·CI·워크플로우 규약 변경 → `docs/TESTING.md`·`docs/WORKFLOW.md`
  - 커밋 Type·브랜치·스킬 절차 변경 → 해당 `.claude/skills/*`·`commit-types.md`
- **메인이 스스로 판정한다 (핵심)**: 각 후보 문서의 **현재 내용을 읽고 이번 diff와 직접 대조**해, 갱신이 *실제로* 필요한지 판단한다. 기준은 루트 `CLAUDE.md` 규칙 — "코드/디렉토리만 봐도 아는 것은 적지 않는다 → **코드만 봐선 모르는 것(새 시나리오·숨은 의존·함정·왜)**만". 문서가 이미 충분하거나 변경이 자명한 구성요소 나열뿐이면 **후보에서 제외**한다(노이즈 금지).
- **수정이 필요하다고 판정한 것만** 사용자에게 제시한다. 항목마다 함께 적는다:
  - *무엇을 / 왜* 갱신해야 하는지(어떤 diff 때문에 문서가 뒤처졌는지)
  - **구체적 방향성**: 어느 문서의 어느 절에 무엇을 추가·수정할지(예: "`NovelData/CLAUDE.md` 주의사항 절에 userID fallback 분기 한 줄 추가").
- **처리 게이트** — 항목마다 셋 중 하나로 확정한 뒤 진행:
  - **(a) 사용자가 직접 수정** — 이 경우에도 위 방향성을 그대로 제시해 사용자가 바로 손댈 수 있게 한다.
  - **(b) 메인이 수정** — 제시한 방향대로 메인이 문서를 편집한다.
  - **(c) 불필요로 합의** — 메인 판단이 과했거나 사용자가 불필요하다고 보면 제외한다.
- 작업 중 함정이 있었으면 **`learn` 스킬 연계**("주의사항" 절 누적)도 후보로 함께 판정·제시한다.
- 갱신 후보가 하나도 없다고 판정되면 그 사실(왜 불필요한지)을 한 줄로 보고하고 다음 단계로.

### 3. 문서 변경 커밋
- 2단계에서 발생한 문서 수정을 **`commit` 스킬 재사용**으로 커밋한다. 양식 `[Type] #이슈 - 한글`(문서면 보통 `[Docs]`), 명시적 파일 경로로만 스테이징(`git add -A` ❌), **push는 안 함**.
- 문서 변경이 없으면 이 단계를 건너뛴다.

### 4. PR 본문 작성 + 사용자 검토 (게이트)
- `.github/pull_request_template.md`를 **읽어** 그 섹션 구조 그대로 채운다(하드코딩 금지). 현재 6섹션:
  - `💡 Issue` → `closed #<번호>` (0단계에서 추출한 번호)
  - `💭 Summary` → 작업 한 줄 소개
  - `🔑 Key Changes` → 커밋·diff 기반 구체적 변경 요약(레이어 가로지른 흐름이 있으면 그 흐름으로)
  - `📱 Simulation` → UI(Feature) 변경이면 **시뮬레이터 스크린샷/녹화 첨부를 사용자에게 요청**한다(자동 첨부 불가 → 플레이스홀더로 두고 안내). 비-UI 변경이면 "해당 없음" 표시.
  - `🧑‍🧒‍🧒 To Reviewer` → 리뷰어가 봐야 할 포인트(통합 리뷰에서 논의된 것·확인 필요 항목)
  - `※ Reference` → 참고 자료(있으면)
- **제목**: `[Type] #이슈 - 한글 설명`. base=`develop`, head=현재 브랜치를 함께 명시.
- 채운 본문·제목·base/head를 보여주고 **검토 게이트**. 사용자가 수정·승인할 때까지 다음으로 넘어가지 않는다.

### 5. GitHub PR 생성 (외부 비가역, 승인 게이트)
- ⚠️ **사용자 승인 전까지 어떤 외부 동작(push·PR 생성)도 하지 않는다.** 승인 시:
  1. **미푸시 커밋이 있으면 먼저 push**한다. upstream이 없으면 `git push -u origin <branch>`, 있으면 `git push`.
  2. 4단계에서 승인된 **본문을 스크래치패드 임시 파일에 기록**(멀티라인 인자 회피)한 뒤:
     ```bash
     gh pr create --base develop --head <branch> \
       --title "[Type] #<번호> - 한글 설명" --body-file <스크래치패드_본문_경로>
     ```
  - 계정/소유자/레포는 하드코딩하지 않는다 — 현재 레포로 자동 감지된다.
- 생성된 **PR URL을 보고**한다. `gh` 실패(인증 누락·remote 없음 등)는 출력 그대로 보고하고 안내(`gh auth login` 등).

## 원칙
- **정본 우선(추측 ❌)**: PR 골격 = `.github/pull_request_template.md`, 문서 기준 = 루트·각 `CLAUDE.md`, 커밋 = `commit` 스킬·`commit-types.md`.
- **리뷰만 위임, 나머지는 메인.** 완성 = 코드 작성이 아니라 **리뷰 수렴 + 문서 동기화**: `wss-pr-reviewer`의 🔴+🟡=0 + 관련 문서가 변경을 반영해야 PR을 올린다.
- **문서는 떠넘기지 않는다.** 메인이 diff와 대조해 갱신 필요를 판정하고, 필요한 것만 방향성과 함께 제시한다(불필요한 것까지 나열 ❌).
- **외부 비가역(push·PR 생성)은 승인 후.** 커밋 규약은 `commit` 스킬 / `docs/WORKFLOW.md`.
- 머지 직전 흐름(rebase·force push·merge)은 이 스킬이 하지 않는다.
