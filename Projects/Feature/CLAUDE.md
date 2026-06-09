# Feature 레이어

실제 **기능·화면**을 구현하는 레이어 (UI 포함). Domain UseCase를 호출해 사용자 시나리오를 완성한다.

- 모듈 식별자: `ModuleType.feature(.xxx)` → 모듈명 `XxxFeature`
- 디렉토리: `Projects/Feature/<Module>Feature/`
- 비동기/상태: **Combine** — ViewModel을 `ObservableObject`로 두고 상태는 단일 `@Published var state`로 노출(둘 다 Combine).
  async UseCase 호출은 `@MainActor` + `Task` 경계에서 받아 `state`에 반영한다.

## 의존 규칙

- ✅ `Domain`(UseCase·Entity), `UI`(`DesignSystem`·`WSSComponent`), `BaseDomain`, `Core`(횡단 기술만 — 예: `Logger`).
  - Core는 기반 기술이라 의존 가능하나 **횡단 관심사로 한정**(로깅 등). 비즈니스 흐름은 여전히 UseCase 경유.
  - **로깅**: Core의 `Logger` 프로토콜을 `logger: Logger? = nil`(옵셔널·nil 기본값)로 Factory→ViewModel 주입한다. 실제 인스턴스는 App(DI)이, Demo/테스트는 nil(로깅 off). 호출은 `logger?.error(...)`. (Data 레이어의 `DataLogger?` 컨벤션과 동일 형태.)
- ❌ `Data` 직접 import 금지 — Data 조립은 App(DI)이 담당하고, Feature는 UseCase/Repository 프로토콜만 받는다.
- ❌ 다른 Feature 모듈 직접 의존 지양 (화면 간 이동은 App/조정 계층에서).

## 코드 규칙 (첫 모듈 `NovelReviewFeature`에서 확정한 MVVM 패턴)

파일 배치: `Sources/XxxView.swift`, `Sources/XxxViewModel.swift`, `Sources/Factory/XxxFactory.swift`(하위 폴더), `Demo/XxxFeatureDemoApp.swift`. 골격을 그대로 따른다:

```swift
@MainActor
final class XxxViewModel: ObservableObject {          // 프로토콜·typealias·Default 접두 없음
    struct State {                       // 화면 상태를 한곳에. 도메인 엔티티를 그대로 들 수 있음
        var draft: SomeEntity           // 표현값 소스 — View가 state.draft.…로 직접 읽음(별칭 ❌)
        var isLoading = false
        var errorMessage: String?
    }
    enum Action { case load, selectSomething(Something), save, dismissError }  // 명령형 동사+명사(did~·~Tapped ❌)

    @Published private(set) var state: State           // 외부는 handle로만 변경
    private let someUseCase: SomeUseCase              // UseCase는 프로토콜 생성자 주입(DI는 App)

    init(someUseCase: SomeUseCase) {
        self.someUseCase = someUseCase
        self.state = State(draft: SomeEntity(...))     // 초기 상태 구성
    }

    func handle(_ action: Action) {                    // 유일한 입력 진입점
        switch action {
        case .load:                   Task { await loadDraft() }   // async는 Task 경계
        case .selectSomething(let x): state.draft.change(x)        // 정책은 엔티티에 위임
        case .save:                   Task { await saveDraft() }
        case .dismissError:           state.errorMessage = nil
        }
    }
    // 엔티티 throws(검증 실패)는 handle 안 do-catch로 잡아 state.errorMessage로 변환.
    // 매퍼 이름은 handle(_action:)과 겹치지 않게(presentError 등, handle(error:) ❌).
}

struct XxxView: View {                  // 제네릭 없음. state 읽기 / handle 쓰기
    @StateObject private var viewModel: XxxViewModel
    // 예: Button("저장"){ viewModel.handle(.save) }.disabled(viewModel.state.isLoading)
    //     .onAppear { viewModel.handle(.load) }      // 생명주기도 액션으로
}

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
