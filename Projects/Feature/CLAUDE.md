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

> **골격 전문(복붙용): [Docs/VIEWMODEL_TEMPLATE.md](Docs/VIEWMODEL_TEMPLATE.md)** — `// MARK:` 순서(State / Derived / Action / Output / Property / Dependency / Init / handle → Action Handling / UseCase Handling / Error Mapping)와 각 섹션 주석이 거기 있다.

**파생값 분류 — `Derived`냐 `Property`냐:**
- **View가 보고 VM이 계산하는 값** → `Derived`(State 바로 아래). 예: `editingDate`, `result`.
- **View가 보지 않는 내부 판단 파생** → `Property`. 예: `hasUnsavedChanges`(닫기 알럿 판단용).
- **View가 알아서 포맷/계산할 표기값**(날짜 문자열, "평점 없음" 등)은 VM에 두지 않는다(얇은 VM, "View를 모른다").
- UseCase가 없는 **순수 입력 VM**은 `Action Handling`만 두고 `UseCase Handling`/`Error Mapping`을 생략한다(예: `ReadingPeriodSheetViewModel`).

### View 표준 구조 (마크주석 순서를 그대로 따른다)

**새 Feature View는 아래 `// MARK:` 순서·역할·규칙을 그대로 따른다.**
정본 레퍼런스: `NovelReviewView`(툴바·섹션·Presentation 풀세트) / `ReadingPeriodSheet`(시트, 툴바 없는 변형).

> **골격 전문(복붙용): [Docs/VIEW_TEMPLATE.md](Docs/VIEW_TEMPLATE.md)** — 선언 순서(VM → View 전용 상태 → @Environment → 주입 let), body=조립+modifier, 그리고 `// MARK:` Toolbar / Sections / Presentation / Preview 골격이 거기 있다.

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

## UI 검증 (시뮬레이터 — XcodeBuildMCP)

화면을 띄워 확인할 땐 **Feature 모듈 스킴**으로 Demo 앱을 실행한다(자세히 → [docs/BUILD_AND_TEST.md](../../docs/BUILD_AND_TEST.md)).
- **실행 스킴은 `XxxFeature`** (별도 `XxxFeatureDemo` 스킴은 없다). 이 스킴의 LaunchAction이 `XxxFeatureDemo.app`을 띄운다 → `build_run_sim(scheme: "NovelReviewFeature")`.
- **`launch_app_sim`용 bundleId는 `kr.websoso.app.XxxFeatureDemo`** — `build_run_sim`이 보고하는 건 framework(`...XxxFeature`)라 그대로 launch하면 실패.
- **별점 등 커스텀 드로잉은 접근성 tap 타겟으로 안 잡힌다** → `snapshot_ui`에 안 뜨면 좌표 탭. 표준 버튼/세그먼트/매력포인트는 `elementRef`로 잡힌다.
- **Demo `Mock` 모드는 일부 화면 미연결**(예: 키워드 입력) — 네트워크 의존 플로우는 `실서버` 토글이 필요.
- **`build_run_sim`은 이 스킴에서 install이 framework를 잡아 실패**할 수 있다("installable app 없음") → `build_sim`(컴파일) 후 `install_app_sim`+`launch_app_sim`(bundleId `...XxxFeatureDemo`)이 안정적.

## 주의사항 (작업 중 발견 시 누적)

- 화면 라벨/아이콘 표현은 **WSSComponent의 `DomainPresentation/` 확장**(`public`)을 재사용한다 — Feature에서 중복 매핑하지 말 것.
- `ModuleType.feature` enum에 선언만 있고 디스크 폴더가 없는 case(`home`, `feed`)는 아직 미구현. 실제 모듈은 `NovelReviewFeature`뿐.
