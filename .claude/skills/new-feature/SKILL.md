---
name: new-feature
description: WSS-iOS-V2 프로젝트에서, 새 Feature 화면을 처음부터 구현할 때 사용한다. 모듈명을 받아 ① new-module 스킬로 Feature 모듈 생성 → ② View/ViewModel·Factory 골격 작성 → ③ Figma URL을 받아 WSS 디자인 시스템으로 UI 구현, 까지 단계별 게이트로 진행한다. "새 화면 만들자", "Feature 구현 시작", 또는 "/new-feature <ModuleName> [FigmaURL]" 같은 요청에 트리거.
metadata:
  short-description: 새 Feature 화면 구현 (모듈 생성 → 골격 → Figma UI), 단계별 게이트
---

# New Feature — 새 Feature 화면 구현 (WSS-iOS-V2)

새 Feature 화면을 처음부터 구현한다. 인자: `<ModuleName> [FigmaURL]` (예: `Home`, `Home https://figma.com/...`).
세 단계 — **① 모듈 생성 → ② View/ViewModel·Factory 골격 → ③ Figma → WSS UI 구현** — 을 **단계별 게이트**로 진행한다.

> ⚠️ **추측 금지 — 정본을 먼저 읽는다.** 값·패턴을 지어내지 말고 항상:
> `Projects/Feature/CLAUDE.md`(레이어 규칙·함정), `Projects/Feature/Docs/VIEWMODEL_TEMPLATE.md`·
> `VIEW_TEMPLATE.md`(골격 전문), 레퍼런스 `Projects/Feature/NovelReviewFeature/`(특히 `Project.swift`·
> `Factory/NovelReviewFactory.swift`)를 읽어 현재 패턴을 그대로 따른다.
>
> ⚠️ **모호하면 묻고, 확실하면 안 묻는다.** 각 단계에서 진행에 필요한 정보가 부족하거나 여러 해석으로
> 갈리면 **반드시 사용자에게 물어 하나로 확정한 뒤** 진행한다. 반대로 정본·컨벤션·디자인으로 이미
> 정해지는 것은 하나하나 되묻지 않는다(과잉 질문 금지).
>
> ⚠️ **메인이 직접 수행한다.** 단계가 순차 의존이고 게이트가 사용자 상호작용이라 subagent 위임은
> cold start 재독·핸드오프 손실로 손해다. (무거운 단계의 위임은 그때그때 판단.)

## 절차

### 0. 인자 파싱
- `<ModuleName>` 확보(필수). 비면 사용자에게 묻는다. 예: `Home` → 모듈명 `HomeFeature`(suffix는 `ModuleType`이 붙인다).
- `[FigmaURL]`은 선택 — 없으면 3단계에서 받는다.
- ⚠️ **대응 `<ModuleName>Domain`이 있는지 먼저 확인**한다. 없으면 Feature가 주입받을 UseCase가 없다 →
  사용자에게 알리고 (a) domain부터 만들지, (b) UseCase 없는 **순수 입력 화면**인지 확인하고 진행한다.

### 1. 모듈 생성 — `new-module` 재사용
- **Skill 도구로 `new-module`을 `feature <ModuleName>` 인자로 호출**한다. 모듈 생성 절차를 여기서 복제하지 않는다(단일 진실 소스).
- ⚠️ `new-module`의 feature 의존성 기본값은 "미검증"으로 표시돼 있다 → **`NovelReviewFeature/Project.swift`를
  진실로** 삼아 생성된 `Project.swift`를 확인/조정한다:
  - `internalDependencies = [.module(.domain(.base)), .module(.domain(.<name>)), .module(.ui(.designSystem)), .module(.ui(.wssComponent)), .module(.core(.logger))]`
  - `demoDependencies = [.module(.data(.<name>)), .module(.data(.base)), .module(.core(.networking))]`
  - `targets: [.sources, .demo, .tests]`
  - 0단계에서 "순수 입력 화면"으로 정했으면 `domain(.<name>)`·`data(.<name>)` 의존을 빼고, 그 이유를 한 줄 보고.
- 완료 후: 등록된 `ModuleType.feature` case·생성 파일·**선택한 의존성과 근거**를 보고 → **확인 게이트**.

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
  코드 서명/교차 모듈 의존으로 실패한다. → **확인 게이트**.

### 3. Figma → WSS 구현
- URL이 없으면 받는다(또는 Figma Dev Mode에서 선택된 노드).
- `mcp__plugin_figma_figma__get_screenshot`(시각 확인) + `get_design_context`(구조/레이아웃) +
  `get_variable_defs`(디자인 변수)로 컨텍스트를 확보한다.
- ⚠️ **인터랙션 확정 게이트**: 디자인은 정적이라 *동작*이 안 보인다. 탭/스와이프 결과, 빈·로딩·에러 상태,
  화면 전환 등이 디자인만으로 안 잡히거나 여러 해석으로 갈리면 **하나로 확정될 때까지 사용자에게 묻는다**
  (임의로 정하지 않는다). 정적 레이아웃·치수·디자인 시스템 매핑처럼 디자인으로 이미 정해진 것은 되묻지 않는다.
- ⚠️ **raw 출력(hex 색·시스템 폰트·인라인 SVG)을 그대로 쓰지 않는다.** WSS 디자인 시스템에 매핑한다:
  - 색 = `Color.wssXxx`, 폰트 = `.applyWSSFont(.xxx)`, 아이콘 = `WSSImage`
  - 컴포넌트 = `WSSComponent` (CTA = `WSSCTAButton`, 오버레이 = `.showWSSAlert`/`.showWSSToast` 등)
  - 도메인 라벨·아이콘·색은 `WSSComponent`의 `DomainPresentation/` 확장 재사용(Feature 중복 매핑 ❌).
  - **없거나 수정이 필요한 컴포넌트는 먼저 허락**을 받는다(임의 추가·수정 ❌).
- 간격은 stack `spacing: 0` + `Spacer().frame(height:/width:)`. 커스텀 탭 영역엔 `.contentShape(Rectangle())`.
- View→VM 입력은 오직 `viewModel.handle(.xxx)`(생명주기도 액션). 시뮬레이터로 빌드/렌더 확인 → **종합 보고**.

## 원칙

- **정본 우선(추측 ❌)**: 의존성 = `NovelReviewFeature/Project.swift`, 골격 = `Docs/*_TEMPLATE.md`, 규칙 = `Feature/CLAUDE.md`.
- 모듈 생성은 `new-module`에 위임(중복 ❌). Figma는 **디자인 시스템 매핑이 핵심**(raw 출력 ❌).
- 모호하면 묻고(이해될 때까지 / 여러 해석은 하나로 확정), 정본·컨벤션·디자인으로 확실하면 되묻지 않는다.
- 각 단계 후 보고하고 사용자 확인 뒤 다음으로. 커밋은 사용자가 지시할 때만(규약은 docs/WORKFLOW.md).
