---
name: new-feature
description: WSS-iOS-V2 프로젝트에서, 새 Feature 화면을 처음부터 구현할 때 사용한다. 모듈명을 받아 ① new-module 스킬로 Feature 모듈 생성 → ② View/ViewModel·Factory 골격 작성 → ③ Figma URL을 받아 동작 계약(정적 디자인으로 안 잡히는 것)을 질문으로 확정한 뒤 WSS 디자인 시스템으로 UI 구현·스크린샷 대조 → ④ wss-feature-reviewer로 리뷰→수정을 Blocker·Warning이 0이 될 때까지 수렴, 까지 단계별 게이트로 진행한다. "새 화면 만들자", "Feature 구현 시작", 또는 "/new-feature <ModuleName> [FigmaURL]" 같은 요청에 트리거.
metadata:
  short-description: 새 Feature 화면 구현 (모듈 생성 → 골격 → 동작 계약 확정·Figma UI → 리뷰·수정 수렴), 단계별 게이트
---

# New Feature — 새 Feature 화면 구현 (WSS-iOS-V2)

새 Feature 화면을 처음부터 구현한다. 인자: `<ModuleName> [FigmaURL]` (예: `Home`, `Home https://figma.com/...`).
네 단계 — **① 모듈 생성 → ② View/ViewModel·Factory 골격 → ③ Figma → 동작 계약 확정 → UI 구현·대조 검증
→ ④ 리뷰·수정 수렴** — 을 **단계별 게이트**로 진행한다.

> ⚠️ **추측 금지 — 정본을 먼저 읽는다.** 값·패턴을 지어내지 말고 항상:
> `Projects/Feature/CLAUDE.md`(레이어 규칙·함정), `Projects/Feature/Docs/VIEWMODEL_TEMPLATE.md`·
> `VIEW_TEMPLATE.md`(골격 전문), 레퍼런스 `Projects/Feature/NovelReviewFeature/`(특히 `Project.swift`·
> `Factory/NovelReviewFactory.swift`)를 읽어 현재 패턴을 그대로 따른다.
>
> ⚠️ **모호하면 묻고, 확실하면 안 묻는다.** 각 단계에서 진행에 필요한 정보가 부족하거나 여러 해석으로
> 갈리면 **반드시 사용자에게 물어 하나로 확정한 뒤** 진행한다. 반대로 정본·컨벤션·디자인으로 이미
> 정해지는 것은 하나하나 되묻지 않는다(과잉 질문 금지).
> 단, 이 원칙을 **자기판정에 맡기면 실효가 없다**("충분히 명확하다"고 넘어간다) → UI는 3B에서
> [design-gap-checklist.md](design-gap-checklist.md) 판정이라는 **산출물로 강제**한다.
>
> ⚠️ **구현은 메인이 직접, 리뷰만 위임.** ①②③은 순차 의존·게이트가 사용자 상호작용이라 subagent
> 위임이 cold start 재독·핸드오프 손실로 손해다 → 메인이 직접 한다. **예외: ④ 리뷰는 격리 컨텍스트가
> 유리해 `wss-feature-reviewer` subagent에 위임**하고, 받은 리포트로 **수정은 다시 메인이** 한다.
>
> ⚠️ **단계 게이트 = 커밋 지점.** 각 단계 게이트에서 사용자가 진행을 승인하면, **그 단계 산출물을
> 커밋하고 넘어간다.** 이 스킬 안에서는 **게이트 승인이 곧 커밋 지시**다(전역 "지시 시에만 커밋"
> 규약의 명문화된 예외) — 이건 **타이밍**(승인 즉시 커밋해도 된다) 규칙이지, **개수** 규칙이 아니다.
> ⚠️ **"그 단계 = 한 커밋"이 아니다.** `commit-all`의 관심사 분리 원칙(`.claude/skills/commit-all/SKILL.md`
> "개념 그룹 판단 기준")은 단계 게이트 안에서도 그대로 적용된다 — 한 단계 안에서도 서로 다른 관심사가
> 섞이면(예: 새 WSSComponent 추가 vs 기존 화면을 그걸로 교체하는 리팩터, 골격 VM vs 그 위에 의존하는
> View/Factory/Demo) 그 단계 하나가 여러 커밋으로 나뉠 수 있다 — 실제로 자주 그렇다(2026-08-20, Feat/#199
> 재발: "골격" 하나로 뭉뚱그려 커밋했다가 "세부적으로 나누라"로 재지적, 6개 커밋으로 재분할).
> ⚠️ **조용히 커밋하지 않는다** — 게이트에서 진행을 물을 때 *이 단계를 승인하면 무엇을(파일별로) 몇 개의
> 커밋으로, 각각 어떤 Type·커밋 메시지로 나눌지* 를 함께 제시해, 사용자가 "승인=커밋"임을 알고 결정하게
> 한다. 커밋은 `commit` 스킬 규약을 따른다 — 양식 `[Type] #이슈 - 한글`,
> 이슈번호는 브랜치명에서 추출, **명시적 파일 경로**로만 스테이징(`git add -A` ❌), **push는 안 함**
> (사용자가 따로 지시할 때만). 단계별 **대표** Type: ① `[Setting]` ② `[Add]` ③ `[Design]` ④ 수정 성격
> (`[Fix]`/`[Refactor]`) — 그 단계에서 나온 커밋들의 **주된** 성격일 뿐, 관심사가 갈리면 개별 커밋마다
> 실제 성격에 맞는 Type을 고른다(위 예시처럼 `[Refactor]`가 섞여 나올 수 있음). 직전 단계가 이미
> 커밋돼 있어 그 단계의 새 변경분만 잡힌다.

## 절차

### 0. 인자 파싱
- `<ModuleName>` 확보(필수). 비면 사용자에게 묻는다. 예: `Home` → 모듈명 `HomeFeature`(suffix는 `ModuleType`이 붙인다).
- `[FigmaURL]`은 선택 — 없으면 3단계에서 받는다.
- ⚠️ **대응 `<ModuleName>Domain`이 있는지 먼저 확인**한다. 없으면 Feature가 주입받을 UseCase가 없다 →
  사용자에게 알리고 (a) domain부터 만들지, (b) UseCase 없는 **순수 입력 화면**인지 확인하고 진행한다.

### 1. 모듈 생성 — `new-module` 재사용
- **Skill 도구로 `new-module`을 `feature <ModuleName>` 인자로 호출**한다. 모듈 생성 절차를 여기서 복제하지 않는다(단일 진실 소스).
- ⚠️ `new-module`의 feature 기본값은 정본(`NovelReviewFeature/Project.swift`) 패턴으로 맞춰져 있지만
  drift할 수 있다 → 생성된 `Project.swift`를 **정본과 직접 대조**해 확인/조정한다:
  - `internalDependencies = [.module(.domain(.base)), .module(.domain(.<name>)), .module(.ui(.designSystem)), .module(.ui(.wssComponent)), .module(.core(.logger))]`
  - `demoDependencies = [.module(.data(.<name>)), .module(.data(.base)), .module(.core(.networking))]`
  - `targets: [.sources, .demo, .tests]`
  - 0단계에서 "순수 입력 화면"으로 정했으면 `domain(.<name>)`을 빼고 `demoDependencies`는 통째로 `[]`(정확한 규칙은 `new-module` 3단계가 정본). 그 이유를 한 줄 보고.
- 완료 후: 등록된 `ModuleType.feature` case·생성 파일·**선택한 의존성과 근거**를 보고 → **확인 게이트**.
  승인 시 모듈 생성분을 `[Setting]`으로 커밋(push ❌)하고 2단계로.

### 2. View/ViewModel·Factory 골격
- ⚠️ **기능 명세 확인 게이트(먼저)**: 이 화면이 *무엇을 하는지* — 상태, 사용자 액션, 필요한 UseCase,
  진입/종료 조건 — 가 골격을 확정할 만큼 분명한가? 모호하면 **이해해서 구현할 수 있을 때까지 물어**
  State/Action/Dependency를 확정한 뒤 작성한다. 추측으로 골격을 만들지 않는다.
- `Docs/VIEWMODEL_TEMPLATE.md`·`VIEW_TEMPLATE.md`를 **그대로** 따라 채운다. `// MARK:` 순서
  (State / Derived / Action / Output / Property / Dependency / Init / handle → Action Handling /
  UseCase Handling / Error Mapping)와 선언 순서(VM → View 전용 상태 → `@Environment` → 주입 let)를
  바꾸지 않는다. 규칙(파생값 분류·간격·표시상태 소유·`contentShape` 트랩)은 `Feature/CLAUDE.md`가 정본.
- 파일 배치(**화면=영역별 폴더**, 타입별 분리 ❌):
  - `Sources/<Screen>/<Screen>View.swift` + `<Screen>ViewModel.swift` (+ 화면 전용 서브뷰 동거)
  - `Sources/Factory/<Module>Factory.swift` — **유일한 public 진입점**. opaque `some View` 반환, View/VM은 internal.
- **UseCase 없는 순수 입력 화면**이면 `UseCase Handling`/`Error Mapping` 섹션을 생략한다(레퍼런스: `ReadingPeriodSheetViewModel`).
- **Demo 앱**: `Demo/<Module>FeatureDemoApp.swift` — Factory를 `NavigationStack`에 띄워 단독 실행.
  - ⚠️ `init()`에서 `DesignSystemFontFamily.registerAllCustomFonts()`를 **반드시** 호출한다. 누락 시
    `applyWSSFont`가 `UIFont(name:)!` 강제 언래핑으로 **런타임 SIGTRAP 크래시**(프리뷰도 같이 죽음).
- **빌드 확인은 시뮬레이터 대상 워크스페이스 스킴으로.** 실기기(`generic/platform=iOS`)·단일 `-target ...Demo`는
  코드 서명/교차 모듈 의존으로 실패한다. → **확인 게이트**. 승인 시 골격을 `[Add]`로 커밋(push ❌)하고 3단계로.

### 3. Figma → WSS 구현

**정적 스냅샷으로는 동작을 알 수 없다**는 게 이 단계의 근본 제약이다 → `3A 수집 → 3B 동작 계약·질문 →
3C 구현 → 3D 대조 검증` 순으로 간다. **3B의 ❓미결이 0이 되기 전에 UI 코드를 한 줄도 쓰지 않는다.**

#### 3A. 컨텍스트 수집 (묻기 전에 Figma를 최대한 캔다)
- URL이 없으면 받는다(또는 Figma Dev Mode에서 선택된 노드).
- **`get_design_context` 호출 전에 `figma:figma-design-to-code`와 `figma:figma-swiftui`를 `Skill`로 로드**한다
  (MANDATORY). 힌트 우선순위·에셋 규칙·SwiftUI 매핑은 **그 스킬들이 정본**이라 여기 복제하지 않는다.
- `get_design_context`가 주력. 보조로 `get_screenshot`(3D 대조용 원본), `get_variable_defs`,
  그리고 **`get_metadata`로 부모·형제 노드명 훑기** — `Empty`/`Loading`/`Selected` 같은 상태 프레임 단서가
  거기 있어서, 먼저 캐면 3B의 ❓가 줄고 질문이 진짜 미결에만 집중된다.

#### 3B. 동작 계약 게이트 — 이 단계가 결과물 품질을 정한다
- **[design-gap-checklist.md](design-gap-checklist.md)를 읽고 A~F 전 항목을 판정**한다. 항목을 임의로
  건너뛰지 않는다(그 목록이 곧 정적 스냅샷의 blind spot이다).
- 판정은 **✅확인됨(Figma 근거) / ⚙️기본값(정본 근거 — 파일·화면명 필수) / ❓미결 / ➖해당없음**.
  ⚠️ **근거를 못 적으면 ⚙️가 아니라 ❓다.** 추측이 새는 구멍은 여기 하나뿐이라 엄격히 판정한다.
- **출력은 압축**한다 — ✅·❓만 표로, ⚙️·➖는 `ID 나열 + 근거` 한 줄씩. 판정 자체는 전 항목을 하되
  화면을 표로 다 채우지 않는다.
- ⚠️ **❓미결은 `AskUserQuestion`으로 확정하고, 0이 되기 전에는 UI 코드를 한 줄도 쓰지 않는다.**
  4개씩 묶어 라운드를 줄이고, 선택지는 *이 프로젝트에서 실제로 가능한 구현*으로, 레이아웃·문구가 갈리면 `preview`로.
- ⚙️기본값과 ②에서 확정한 State/Action/UseCase는 되묻지 않는다(과잉 질문 금지). ②는 *무엇을 하는 화면인가*,
  3B는 *어떻게 보이고 반응하나* 레벨이다.
- **확정 결과를 모듈 `CLAUDE.md`의 `## 화면 동작 계약` 절에 기록**한다 — ✅ 중 비자명한 것 + 물어서 확정한
  것만(⚙️는 정본 중복이라 제외). ④ 리뷰어와 이후 세션이 보는 근거가 된다.
- 데이터에 따라 갈리는 항목은 **Demo Mock 시나리오 축 후보**로 표시한다(3D에서 렌더 확인할 대상).

#### 3C. 구현
- **디자인 시스템 매핑이 핵심** — raw hex·시스템 폰트·손으로 그린 SVG ❌. 매핑 규칙(색·폰트·아이콘·오버레이·
  `DomainPresentation` 재사용·간격·`contentShape`)은 `Feature/CLAUDE.md` "View 표준 구조"가 정본이다.
  상태 표현엔 기존 컴포넌트를 먼저 찾는다(로딩 `LoadingView` / 실패 `NetworkErrorView` / 빈 `WSSEmptyView`).
- ⚠️ **없거나 수정이 필요한 WSSComponent·에셋은 먼저 허락**을 받는다(임의 추가·수정 ❌).
- 3B에서 확정한 데이터 분기는 **Demo Mock 시나리오로도 만든다**(버튼 하나 = 데이터 조건 하나 —
  `NovelDetailFeature/CLAUDE.md` 정본). 3D에서 눈으로 확인할 수단이다.

#### 3D. 대조 검증
- 시뮬레이터로 빌드·실행(절차·함정은 `Feature/CLAUDE.md` "UI 검증") 후 **`screenshot`을 3A의 Figma
  스크린샷과 나란히 대조**한다 — 간격·정렬·폰트·색·잘린 텍스트를 훑어 **어긋난 목록을 뽑고 고친다**
  (빌드 성공 ≠ 디자인 일치).
- 3B에서 확정한 **주요 상태(빈·실패·조건부)는 Demo Mock을 전환해 최소 1회 렌더 확인** — 구현했지만 한 번도
  눈으로 못 본 상태가 남지 않게.
- **확인 게이트**: 대조 결과·고친 항목·확인한 상태를 보고하고, 승인 시 UI 구현분 + `화면 동작 계약` 문서를
  `[Design]`으로 커밋(push ❌)하고 **④로 진입**.

### 4. 자동 리뷰·수정 수렴 루프

③까지 끝나면 자동으로 진입한다. **리뷰는 `wss-feature-reviewer`에 위임, 수정은 메인이** 한다.

- **대상**: 방금 만든 `Projects/Feature/<ModuleName>Feature/` 전체. 브랜치·세션 상태에 기대지 말고 **모듈 경로를 prompt에 명시**해 호출한다.
- **루프 (최대 3라운드)**:
  1. **리뷰** — `Agent` 도구로 `subagent_type: wss-feature-reviewer`를 호출하고, 대상 모듈 경로를 prompt에 적는다.
     **3B의 `## 화면 동작 계약`을 근거로 검사하라고 prompt에 명시**한다 — 없으면 리뷰어가 의도를 몰라 오판한다.
     (검사는 격리 컨텍스트가 유리 → ①②③과 달리 위임. 모듈 생성을 `new-module`에 위임하는 것과 같은 "단일 진실 소스" 철학.)
  2. **판정** — 리포트의 🔴 Blocker·🟡 Warning이 **둘 다 0이면 수렴 → 루프 종료**.
  3. **수정** — 🔴는 전부 고친다. 🟡도 고치되, **정답을 임의로 못 정하는 항목**(코드 vs 디자인/문서 의도 불일치, WSSComponent 신규·수정 필요 등)**은 사용자에게 확인한 뒤** 반영한다(추측으로 결정 ❌ — "모호하면 묻는다" 원칙). 라운드별 수정 요약을 한 줄로 보고.
  4. 수정이 새 위반을 부를 수 있으므로 **매 라운드 모듈 전체를 다시 리뷰**(1로 돌아간다).
- **상한**: 3라운드 안에 🔴+🟡=0이 안 되면 **잔여 항목을 사용자에게 보고하고 멈춘다**(무한 루프·토큰 폭주 방지).
- **🔵 Nit**: 수렴 후 빠르게 고칠 수 있는 것만 한 번 정리하고, 남은 건 목록으로 보고한다(Nit은 수렴 기준 아님).
- **최종 빌드**: 수정으로 코드가 바뀌었으니 **수렴 후 1회** 시뮬레이터 대상 워크스페이스 스킴으로 빌드 확인(매 라운드 빌드는 불필요 — 리뷰는 정적 분석). 실기기·단일 `-target ...Demo`는 서명/교차 모듈 의존으로 실패.
- **종합 보고 → 커밋**: 라운드 수 / 수정한 항목 / 잔여 Nit / 빌드 결과를 보고하고, 승인 시 리뷰 수정분을
  수정 성격에 맞는 Type(`[Fix]`/`[Refactor]` 등)으로 **수렴 후 1회** 커밋(push ❌). 수정이 없었으면 커밋 생략.

## 원칙

- **정본 우선(추측 ❌)**: 의존성 = `NovelReviewFeature/Project.swift`, 골격 = `Docs/*_TEMPLATE.md`, 규칙 = `Feature/CLAUDE.md`.
- 모듈 생성은 `new-module`에 위임(중복 ❌). Figma는 **디자인 시스템 매핑이 핵심**(raw 출력 ❌).
- 모호하면 묻고(이해될 때까지 / 여러 해석은 하나로 확정), 정본·컨벤션·디자인으로 확실하면 되묻지 않는다.
- **정적 디자인은 동작을 담지 못한다** → 갭을 체크리스트로 *열거*해 드러내고(3B), ❓는 물어 확정한 뒤 구현하며,
  확정한 것은 모듈 `CLAUDE.md` `## 화면 동작 계약`에 남긴다. **빌드 성공 ≠ 디자인 일치** → 스크린샷 대조(3D)까지가 ③이다.
- **완성 = 코드 작성이 아니라 리뷰 수렴**: ④에서 `wss-feature-reviewer`의 🔴+🟡가 0이 될 때까지가 한 화면의 끝. 검사는 리뷰어, 수정은 메인.
- 각 단계 후 보고→사용자 확인 뒤 진행하며, **그 승인 시 단계 산출물을 커밋**한다(게이트 승인=커밋 지시,
  단계별 Type ①`[Setting]` ②`[Add]` ③`[Design]` ④`[Fix]`/`[Refactor]`). **push는 사용자가 따로 지시할 때만.**
  커밋 규약은 `commit` 스킬 / docs/WORKFLOW.md.
