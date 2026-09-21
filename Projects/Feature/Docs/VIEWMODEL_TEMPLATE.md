# ViewModel 표준 구조 — 골격 템플릿

새 Feature ViewModel을 만들 때 여는 골격. **아래 `// MARK:` 순서·역할을 그대로 따른다**(순서 변경·임의 섹션 추가 ❌).
규칙(파생값 분류 등 "코드만 봐선 모르는 것")은 [../CLAUDE.md](../CLAUDE.md)의 "ViewModel 표준 구조" 절에 있다.
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
