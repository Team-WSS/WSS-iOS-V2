# Feature 레이어

실제 **기능·화면**을 구현하는 레이어 (UI 포함). Domain UseCase를 호출해 사용자 시나리오를 완성한다.

- 모듈 식별자: `ModuleType.feature(.xxx)` → 모듈명 `XxxFeature`
- 디렉토리: `Projects/Feature/<Module>Feature/`
- 상태: **SwiftUI Observation** — ViewModel은 `@Observable`(iOS 17+, `Observation` import), 상태는 단일 `private(set) var state`로 노출. View는 `@State`로 VM을 보유한다. (`ObservableObject`/`@Published`/`@StateObject` ❌ — Combine 아님.)
  async UseCase 호출은 `@MainActor` + `Task` 경계에서 받아 `state`에 반영한다.

## 의존 규칙

- ✅ `Domain`(UseCase·Entity), `UI`(`DesignSystem`·`WSSComponent`), `BaseDomain`, `Core`(횡단 기술만 — 예: `Logger`).
  - Core는 기반 기술이라 의존 가능하나 **횡단 관심사로 한정**(로깅 등). 비즈니스 흐름은 여전히 UseCase 경유.
  - **로깅**: Core의 `Logger` 프로토콜을 `logger: Logger? = nil`(옵셔널·nil 기본값)로 Factory→ViewModel 주입한다. 실제 인스턴스는 App(DI)이, Demo/테스트는 nil(로깅 off). 호출은 `logger?.error(...)`. (Data 레이어의 `DataLogger?` 컨벤션과 동일 형태.)
- ❌ `Data` 직접 import 금지 — Data 조립은 App(DI)이 담당하고, Feature는 UseCase/Repository 프로토콜만 받는다.
- ❌ 다른 Feature 모듈 직접 의존 지양 (화면 간 이동은 App/조정 계층에서).

## 코드 규칙 (첫 모듈 `NovelReviewFeature`에서 확정한 MVVM 패턴)

파일 배치: `Sources/XxxView.swift`, `Sources/XxxViewModel.swift`, `Sources/Factory/XxxFactory.swift`(하위 폴더), `Demo/XxxFeatureDemoApp.swift`.

### ViewModel 표준 구조 (마크주석 순서를 그대로 따른다)

**새 Feature VM은 아래 `// MARK:` 순서·역할을 그대로 따른다.** 순서를 바꾸거나 섹션을 임의로 추가하지 않는다.
정본 레퍼런스: `NovelReviewViewModel`(섹션 풀세트) / `ReadingPeriodSheetViewModel`(UseCase 없는 순수 입력 변형).

```swift
import Foundation
import Observation                                     // @Observable 매크로. VM은 SwiftUI를 import하지 않으므로 명시 필요

@MainActor
@Observable
final class XxxViewModel {                            // 프로토콜·typealias·Default 접두 없음(ObservableObject ❌)

    // MARK: - State
    // 화면 상태를 한곳에. 도메인 엔티티를 그대로 들 수 있음(별칭 ❌). 표시 에러는 의미값 enum으로(카피·표현은 View).
    struct State {
        var draft: SomeEntity
        var isLoading = false
        var presentedError: PresentedError?
    }
    enum PresentedError: Equatable { case somethingLimit(max: Int), unknown }

    // MARK: - Derived
    // (필요할 때만, State 바로 아래) State로부터 파생되는 계산값.
    // View가 보면서 VM이 계산을 책임지는 값만. View 편의용 표기/포맷은 ❌(얇은 VM). 없으면 이 섹션 생략.
    var someComputed: Something { /* state로 계산 */ }

    // MARK: - Action
    // 사용자가 가능한 행동 기반 — 명령형 동사+명사(did~ · ~Tapped ❌)
    enum Action { case load, selectSomething(Something), save, dismissError }

    // MARK: - Output
    private(set) var state: State                      // View가 보는 단일 관찰 대상. 외부는 handle로만 변경(@Published ❌)

    // MARK: - Property
    // ViewModel 내부 전용 값. 저장 프로퍼티는 @ObservationIgnored — View가 안 보는 내부 상태라 관찰 대상에서 뺀다.
    // View가 보지 않는 파생 computed도 여기(예: hasUnsavedChanges). computed는 저장이 없어 애너테이션 불필요.
    @ObservationIgnored private var baseline: SomeEntity
    private var hasUnsavedChanges: Bool { state.draft != baseline }

    // MARK: - Dependency
    // init에 주입되는 외부 요소. 일반 값 → (줄바꿈) → Domain별 UseCase 그룹 순으로 둔다.
    // 여러 Domain의 UseCase를 쓰면 Domain별로 줄바꿈해 묶는다. UseCase는 프로토콜·lowerCamelCase 그대로(DI는 App).
    // 모두 let이라 @Observable이 관찰하지 않음 → @ObservationIgnored 불필요.
    private let someID: SomeID
    private let logger: Logger?                         // 로깅은 옵셔널·nil 기본값

    // SomeDomain
    private let someUseCase: SomeUseCase

    // OtherDomain
    private let otherUseCase: OtherUseCase

    // MARK: - Init
    init(someID: SomeID, someUseCase: SomeUseCase, otherUseCase: OtherUseCase, logger: Logger? = nil) {
        self.someID = someID
        self.someUseCase = someUseCase
        self.otherUseCase = otherUseCase
        self.logger = logger
        let initial = SomeEntity(/* ... */)
        self.state = State(draft: initial)
        self.baseline = initial
    }

    // MARK: - handle
    func handle(_ action: Action) {                    // 유일한 입력 진입점, action→state
        switch action {
        case .load:                   load()                    // async는 아래 함수가 Task 경계
        case .selectSomething(let x): state.draft.change(x)     // 정책은 엔티티에 위임
        case .save:                   save()
        case .dismissError:           state.presentedError = nil
        }
    }
}

// MARK: - Action Handling
// action별 함수. 동기 상태 변경 + async는 Task로 감싸 UseCase Handling을 호출.
private extension XxxViewModel { /* func load(), func save() ... */ }

// MARK: - UseCase Handling
// async UseCase로 외부 데이터를 가져오는 곳(구 "Async Work").
private extension XxxViewModel { /* func loadDraft() async { ... } */ }

// MARK: - Error Mapping
// 각 catch에서 도메인/Repository 에러를 State의 의미 에러로 변환. handle(_:)과 이름이 겹치지 않게(presentError 등).
private extension XxxViewModel { /* func presentError(_ error: Error) { ... } */ }
```

**파생값 분류 — `Derived`냐 `Property`냐:**
- **View가 보고 VM이 계산하는 값** → `Derived`(State 바로 아래). 예: `editingDate`, `result`.
- **View가 보지 않는 내부 판단 파생** → `Property`. 예: `hasUnsavedChanges`(닫기 알럿 판단용).
- **View가 알아서 포맷/계산할 표기값**(날짜 문자열, "평점 없음" 등)은 VM에 두지 않는다(얇은 VM, "View를 모른다").
- UseCase가 없는 **순수 입력 VM**은 `Action Handling`만 두고 `UseCase Handling`/`Error Mapping`을 생략한다(예: `ReadingPeriodSheetViewModel`).

### View 표준 구조 (마크주석 순서를 그대로 따른다)

**새 Feature View는 아래 `// MARK:` 순서·역할·규칙을 그대로 따른다.**
정본 레퍼런스: `NovelReviewView`(툴바·섹션·Presentation 풀세트) / `ReadingPeriodSheet`(시트, 툴바 없는 변형).

```swift
import SwiftUI

import BaseDomain
import DesignSystem
import SomeDomain
import WSSComponent

// 화면 책임 한 줄. "얇은 VM": 카피·포맷·색은 전부 View가 결정한다.
struct XxxView: View {

    // 선언 순서: VM → View 전용 상태 → @Environment → 주입 let
    @State private var viewModel: XxxViewModel           // @Observable VM은 @State로(@StateObject ❌)
    @State private var isSomeSheetPresented = false       // VM이 처리할 필요 없는 순수 View 표시 상태만 @State
    @Environment(\.dismiss) private var dismiss
    private let title: String                             // 진입 이전 화면이 주입

    init(viewModel: XxxViewModel, title: String) {
        self._viewModel = State(initialValue: viewModel)
        self.title = title
    }

    // body = 조립 + 화면 modifier만(navigation/toolbar/sheet/alert/toast/onAppear/onChange).
    // 실제 레이아웃은 content로 분리.
    var body: some View {
        content
            .toolbar { toolbarContent }
            .onAppear { viewModel.handle(.load) }           // 생명주기도 액션
            .sheet(isPresented: $isSomeSheetPresented) { /* ... */ }
            .showWSSToast(isPresented: toastBinding, type: toastType)
            .onChange(of: viewModel.state.shouldDismiss) { _, v in if v { dismiss() } }
    }

    // 레이아웃 + 공용 leaf
    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {                            // stack spacing은 항상 0
                someSection
                Spacer().frame(height: 24)                 // 고정 간격은 Spacer().frame으로
                otherSection
            }
        }
    }
}

// MARK: - Toolbar
// 툴바 내용물은 @ToolbarContentBuilder 분리 프로퍼티로. body엔 `.toolbar { toolbarContent }`만.
private extension XxxView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent { /* ToolbarItem들 */ }
}

// MARK: - Sections
// 섹션은 var xxxSection: some View. 각 섹션에 의도/함정 doc comment.
private extension XxxView { /* var someSection: some View { ... } */ }

// MARK: - Presentation
// 의미값(VM enum) → 컴포넌트 타입/카피/색 매퍼 + VM이 소유한 표시상태 Binding(get:set:)(set은 handle 경유).
private extension XxxView {
    var toastBinding: Binding<Bool> {
        Binding(get: { viewModel.state.presentedError != nil },
                set: { if !$0 { viewModel.handle(.dismissError) } })
    }
    var toastType: WSSToastType { /* state.presentedError → 토스트 타입 */ }
}

// MARK: - Preview
// #Preview는 Sources 내부(internal). mock UseCase는 private.
```

**규칙 (코드만 봐선 모르는 것):**
- **View→VM 입력은 오직 `viewModel.handle(.xxx)`** (생명주기도 액션: `onAppear → .load`). `state`는 `private(set)` → 직접 변경 ❌.
- **표시 상태 소유 구분**: VM 처리가 필요 없는 순수 표시 상태(시트 bool 등)는 View가 `@State`로. **VM이 판단을 소유한 표시 상태(alert/toast)는 `Binding(get:set:)`** 으로 만들고 set을 `handle` 경유.
- **표현은 View가**: 의미값(VM enum) → 컴포넌트 타입/카피/색 매핑은 View. 날짜 포맷·"평점 없음" 등 표기도 View(얇은 VM).
- **간격**: stack `spacing: 0` 고정, **모든 고정 간격은 `Spacer().frame(height:/width:)` 빈 뷰로**(ScrollView 안에서도 동작). 예외: `ForEach` + `.frame(maxWidth:.infinity)` 균등 분배 행, 그리고 별점 같은 **leaf 컴포넌트의 고정 간격 행**은 spacing 0만/leaf-local로 둔다.
- **Toolbar는 `@ToolbarContentBuilder`** 분리 프로퍼티로.
- **WSSComponent / DesignSystem 우선**: 색=`Color.wssXxx`, 폰트=`.applyWSSFont(.xxx)`, 아이콘=`WSSImage`(raw hex·시스템 폰트 ❌). 오버레이=`showWSSAlert`/`showWSSToast`, CTA=`WSSCTAButton` 등. **없거나 수정이 필요하면 먼저 허락**.
- **도메인 라벨·아이콘·색은 WSSComponent `DomainPresentation` 확장 재사용**(`status.statusName`, `point.iconImage`). Feature 중복 매핑 ❌.
- **커스텀 탭 영역은 `.contentShape(Rectangle())`** — 없으면 라벨의 비투명 픽셀만 탭된다(빈 영역·패딩 탭 안 됨). 보통 `.buttonStyle(.plain)`과 함께.
- 화면 전용 서브뷰는 화면 폴더 동거. 여러 화면 재사용 시 WSSComponent로 승격(허락 후).

### Factory 골격

```swift
public enum XxxFactory {                // 유일한 public 진입점. opaque 반환 → View/VM은 internal 유지
    @MainActor
    public static func makeView(someUseCase: SomeUseCase) -> some View {
        XxxView(viewModel: XxxViewModel(someUseCase: someUseCase))
    }
}
```

- **Demo·Preview 필수**: `.demo` 타깃의 Demo 앱이 Factory를 `NavigationStack`에 띄워 단독 실행. Preview는 Sources 내부(internal 접근).
- **⚠️ Demo 앱 `init()`에서 `DesignSystemFontFamily.registerAllCustomFonts()` 호출.** `applyWSSFont`가 `UIFont(name:)!`를 강제 언래핑 → 폰트 미등록 시 **런타임 크래시(SIGTRAP)**. 프리뷰도 Demo 앱을 호스트로 띄우므로 같이 죽는다.
- 테스트는 mock UseCase 주입으로 충분. View에 가짜 VM을 통째로 주입할 일이 생기면 그때 가벼운 프로토콜을 다시 얹는다.

## 주의사항 (작업 중 발견 시 누적)

- 화면 라벨/아이콘 표현은 **WSSComponent의 `DomainPresentation/` 확장**(`public`)을 재사용한다 — Feature에서 중복 매핑하지 말 것.
- `ModuleType.feature` enum에 선언만 있고 디스크 폴더가 없는 case(`home`, `feed`)는 아직 미구현. 실제 모듈은 `NovelReviewFeature`뿐.
