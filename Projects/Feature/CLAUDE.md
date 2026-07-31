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

> **화면의 동작 계약은 모듈 `CLAUDE.md`의 `## 화면 동작 계약` 절이 정본이다.** 정적 Figma로는 안 잡혀
> 사람에게 확인받은 것(스크롤 고정 영역·로딩/빈/실패 분화·탭 결과·말줄임 줄 수 등)이 거기 쌓인다.
> 화면을 수정할 때 **디자인만 보고 추측하지 말고 그 절을 먼저 읽는다**. 새 화면은 `new-feature` 3B가
> 채운다([design-gap-checklist.md](../../.claude/skills/new-feature/design-gap-checklist.md) — 기존 화면
> 수정 시에도 갭 점검용으로 쓸 수 있다).

**레퍼런스는 단일 정본이 아니라 "성격별 대표"다** — 뼈대(MARK 순서·State/Action·얇은 VM·Factory)는 어느 쪽이든 같으니, 만들 화면에 **가까운 쪽의 얹는 패턴**을 본다.
| 만들 화면 성격 | 볼 정본 | 그 정본이 대표하는 얹는 패턴 |
|---|---|---|
| 입력 폼(로드+저장, 자기완결 dismiss) | `NovelReviewFeature` | 폼 검증 throw→토스트, 뼈대 풀세트 |
| 순수 입력(UseCase 없음) | `ReadingPeriodSheet`(+VM) | `Action Handling`만, 결과는 `onApply` 등으로 상위 발화 |
| 복합 조회(리스트·탭·헤더) | `NovelDetailFeature` | 지연 로드·커서 페이지네이션, 낙관 업데이트/롤백, **전면 실패 뷰↔토스트 분화**, 화면 전환 콜백 다수 위임 |

인증 만료→로그인 라우팅(`requiresAuthentication` 신호 + `onAuthenticationRequired` 콜백)은 **두 모듈 공통**이라 성격과 무관하게 서버 호출이 있으면 넣는다.

### ViewModel 표준 구조 (마크주석 순서를 그대로 따른다)

**새 Feature VM은 아래 `// MARK:` 순서·역할을 그대로 따른다.** 순서를 바꾸거나 섹션을 임의로 추가하지 않는다.
정본 레퍼런스: `NovelReviewViewModel`(섹션 풀세트·폼) / `ReadingPeriodSheetViewModel`(UseCase 없는 순수 입력 변형) / `NovelDetailViewModel`(복합 — 리스트·페이지네이션·낙관 업데이트/롤백·에러 분화). → 성격별 선택은 위 "코드 규칙" 표 참고.

> **골격 전문(복붙용): [Docs/VIEWMODEL_TEMPLATE.md](Docs/VIEWMODEL_TEMPLATE.md)** — `// MARK:` 순서(State / Derived / Action / Output / Property / Dependency / Init / handle → Action Handling / UseCase Handling / Error Mapping)와 각 섹션 주석이 거기 있다.

**파생값 분류 — `Derived`냐 `Property`냐:**
- **View가 보고 VM이 계산하는 값** → `Derived`(State 바로 아래). 예: `editingDate`, `result`.
- **View가 보지 않는 내부 판단 파생** → `Property`. 예: `hasUnsavedChanges`(닫기 알럿 판단용).
- **View가 알아서 포맷/계산할 표기값**(날짜 문자열, "평점 없음" 등)은 VM에 두지 않는다(얇은 VM, "View를 모른다").
- UseCase가 없는 **순수 입력 VM**은 `Action Handling`만 두고 `UseCase Handling`/`Error Mapping`을 생략한다(예: `ReadingPeriodSheetViewModel`).

### View 표준 구조 (마크주석 순서를 그대로 따른다)

**새 Feature View는 아래 `// MARK:` 순서·역할·규칙을 그대로 따른다.**
정본 레퍼런스: `NovelReviewView`(툴바·섹션·Presentation 풀세트) / `ReadingPeriodSheet`(시트, 툴바 없는 변형) / `NovelDetailView`(복합 — 스티키 탭·리스트·콜백 위임. 단 몰입형 헤더·스크롤 트릭은 그 화면 특유라 참고 시 취사선택).

> **골격 전문(복붙용): [Docs/VIEW_TEMPLATE.md](Docs/VIEW_TEMPLATE.md)** — 선언 순서(VM → View 전용 상태 → @Environment → 주입 let), body=조립+modifier, 그리고 `// MARK:` Toolbar / Sections / Presentation / Preview 골격이 거기 있다.

**규칙 (코드만 봐선 모르는 것):**
- **View→VM 입력은 오직 `viewModel.handle(.xxx)`** (생명주기도 액션: `onAppear → .load`). `state`는 `private(set)` → 직접 변경 ❌.
- **표시 상태 소유 구분**: VM 처리가 필요 없는 순수 표시 상태(시트 bool 등)는 View가 `@State`로. **VM이 판단을 소유한 표시 상태(alert/toast)는 `Binding(get:set:)`** 으로 만들고 set을 `handle` 경유.
  - ⚠️ **시트에 "진입 파라미터"를 넘길 땐 `isPresented:` + 별도 State 조합을 쓰지 말고 `.sheet(item:)`으로 그 값을 넘긴다.** `bool = true`와 파라미터 State를 같이 세팅하면 **앱 실행 후 첫 표시에서만** 파라미터가 무시된다 — SwiftUI가 시트 콘텐츠를 미리 평가하면서 시트 뷰의 `@State`(VM 등) 저장소를 그때의 값으로 굳혀, 나중에 바뀐 값이 반영되지 않는다. 두 번째부터는 이전 값이 맞아떨어져 정상처럼 보이니 **재현이 "첫 진입"에만 걸린다**(서재 필터 시트에서 실제 발생 — 어느 칩을 눌러도 첫 번엔 읽기상태 탭). `item:`은 값이 확정된 뒤 그것을 인자로 받아 콘텐츠를 만들어 이 틈이 없다(파라미터 타입에 `Identifiable` 필요).
- **표현은 View가**: 의미값(VM enum) → 컴포넌트 타입/카피/색 매핑은 View. 날짜 포맷·"평점 없음" 등 표기도 View(얇은 VM).
- **간격**: stack `spacing: 0` 고정, **모든 고정 간격은 `Spacer().frame(height:/width:)` 빈 뷰로**(ScrollView 안에서도 동작). 예외: `ForEach` + `.frame(maxWidth:.infinity)` 균등 분배 행, 그리고 별점 같은 **leaf 컴포넌트의 고정 간격 행**은 spacing 0만/leaf-local로 둔다.
- **Toolbar는 `@ToolbarContentBuilder`** 분리 프로퍼티로.
- **WSSComponent / DesignSystem 우선**: 색=`Color.wssXxx`, 폰트=`.applyWSSFont(.xxx)`, 아이콘=`WSSImage`(raw hex·시스템 폰트 ❌). 오버레이=`showWSSAlert`/`showWSSToast`, CTA=`WSSCTAButton` 등. **없거나 수정이 필요하면 먼저 허락**.
- **도메인 라벨·아이콘·색은 WSSComponent `DomainPresentation` 확장 재사용**(`status.statusName`, `point.iconImage`). Feature 중복 매핑 ❌.
- **커스텀 탭 영역은 `.contentShape(Rectangle())`** — 없으면 라벨의 비투명 픽셀만 탭된다(빈 영역·패딩 탭 안 됨).
  - ⚠️ **`.buttonStyle(.plain)`은 기본 눌림 피드백(누를 때 흐려짐)까지 없앤다** — "버튼인데 눌러도 반응이 없다"의 원인. 이 스타일이 필요한 건 label의 `Text`가 accent 색으로 물드는 걸 막을 때뿐이고, **아이콘·커스텀 뷰만 있는 버튼은 빼야** 눌린 게 보인다(서재 헤더 등록 버튼에서 제거). 습관적으로 `.contentShape`와 세트로 붙이지 말 것.
- **상태 기반 색·에셋 전환(토글·선택)엔 짧은 명시 애니메이션을 걸 것** — `.animation(.easeInOut(duration: 0.1), value: 상태)`. 미설정 시 기본 크로스페이드가 **느리게 번진다**(NovelReview 읽기 상태, NovelDetail 관심 버튼에서 재발 확인 — "토글이 굼뜨다"로 체감됨).
  - ⚠️ **단, 그 선택이 레이아웃까지 바꾸는 화면에선 이 규칙을 접는다** — 선택 즉시 다른 요소가 생겨(선택 칩 행 등장 등) 아래가 밀리면, 형제들은 즉시 새 자리로 가는데 **방금 누른 버튼 하나만 뒤늦게 미끄러져 내려온다**. 어디까지나 **그런 화면 한정 예외**이지 기본값을 뒤집는 게 아니다 — 레이아웃이 안 바뀌는 토글엔 위 규칙대로 애니메이션을 건다. 끄는 방법과 실측 근거는 [LibraryFeature](LibraryFeature/CLAUDE.md)의 필터 시트 항목이 정본.
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
- ⚠️ **install할 `.app`은 `get_sim_app_path`가 알려주는 Products 디렉토리에서 고른다**(그 안의 `XxxFeatureDemo.app`). XcodeBuildMCP는 Xcode의 `~/Library/Developer/Xcode/DerivedData`가 **아니라 자체 `~/Library/Developer/XcodeBuildMCP/workspaces/<repo>/DerivedData/`** 에 빌드한다 — `find`로 Xcode DerivedData의 `.app`을 잡아 설치하면 **며칠 전 빌드가 조용히 올라가** 방금 고친 게 반영 안 된 화면을 보고 오진한다(실제 발생). 의심되면 `.app`의 mtime을 빌드 시각과 대조할 것.

## 주의사항 (작업 중 발견 시 누적)

- 화면 라벨/아이콘 표현은 **WSSComponent의 `DomainPresentation/` 확장**(`public`)을 재사용한다 — Feature에서 중복 매핑하지 말 것.
- `ModuleType.feature` enum 중 `home`만 아직 미구현(`HomeFeature` 폴더는 있어도 `Project.swift` 없음). 나머지는 전부 실제 모듈: `NovelReviewFeature`, `FeedFeature`, `NovelDetailFeature`, `MypageFeature`, `SettingFeature`, `SearchFeature`, `KeywordFeature`, `LibraryFeature`. `SearchFeature`는 소소픽·최근 검색어·키워드 검색(인기 키워드)·자동완성·검색 실행/결과·장르·키워드 탭의 상세 검색 결과 화면까지 UseCase 연동 완료 — 자세한 내용은 `SearchFeature/CLAUDE.md` 참고.
