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

파일 배치: `Sources/XxxView.swift`, `Sources/XxxViewModel.swift`, `Sources/Factory/XxxFeatureFactory.swift`(하위 폴더), `Demo/XxxFeatureDemoApp.swift`.

> **화면의 동작 계약은 모듈 `CLAUDE.md`의 `## 화면 동작 계약` 절이 정본이다.** 정적 Figma로는 안 잡혀
> 사람에게 확인받은 것(스크롤 고정 영역·로딩/빈/실패 분화·탭 결과·말줄임 줄 수 등)이 거기 쌓인다.
> 화면을 수정할 때 **디자인만 보고 추측하지 말고 그 절을 먼저 읽는다**. 새 화면은 `new-feature` 3B가
> 채운다([design-gap-checklist.md](../../.claude/skills/new-feature/design-gap-checklist.md) — 기존 화면
> 수정 시에도 갭 점검용으로 쓸 수 있다).
> 같은 모듈의 `V1_BEHAVIOR_CONTRACT.md`는 이름이 비슷하지만 **V2 정본이 아니라 V1(구 앱) parity 판정 기록**이다 —
> "V1은 이랬는데 V2가 왜 다른가"가 궁금할 때 읽고, 화면 동작의 기준으로 삼지 않는다.

**레퍼런스는 단일 정본이 아니라 "성격별 대표"다** — 뼈대(MARK 순서·State/Action·얇은 VM·Factory)는 어느 쪽이든 같으니, 만들 화면에 **가까운 쪽의 얹는 패턴**을 본다.
| 만들 화면 성격 | 볼 정본 | 그 정본이 대표하는 얹는 패턴 |
|---|---|---|
| 입력 폼(로드+저장, 자기완결 dismiss) | `NovelReviewFeature` | 폼 검증 throw→토스트, 뼈대 풀세트 |
| 순수 입력(UseCase 없음) | `ReadingPeriodSheet`(+VM) | `Action Handling`만, 결과는 `onApply` 등으로 상위 발화 |
| 복합 조회(리스트·탭·헤더) | `NovelDetailFeature` | 지연 로드·커서 페이지네이션, 낙관 업데이트/롤백, **전면 실패 뷰↔토스트 분화**, 화면 전환 콜백 다수 위임 |

인증 만료→로그인 라우팅(`requiresAuthentication` 신호 + `onAuthenticationRequired` 콜백)은 **두 모듈 공통**이라 성격과 무관하게 서버 호출이 있으면 넣는다.

### 인증 만료 처리 계약 (화면 성격과 무관한 앱 전체 규칙 — 여기가 정본)

- **catch에서 실패 플래그·토스트보다 먼저 걸러 `return`한다**(`routeToLoginIfAuthenticationRequired`). 순서를 뒤집어 `loadFailed = true`를 먼저 세우면 로그인 라우팅과 전면 실패 뷰가 **동시에** 걸린다.
- **전면 실패 뷰(`NetworkErrorView`)로 덮지 않는다.** 세션이 죽은 상태라 "페이지 다시 불러오기"가 같은 `.authenticationRequired`로 되돌아와 **탈출구가 되지 못하고**, 문구도 원인을 네트워크 오류라고 잘못 말한다.
- ⚠️ **"push 화면이라 `onAppear` 재발화 복구가 없다"는 이유로 예외를 만들지 말 것.** 타유저 서재가 실제로 그 예외를 뒀다가 #166에서 되돌렸다 — 방어하려던 건 Feature가 아니라 App 배선의 문제였다(아래).
- **인증 만료 뒤 화면을 치우는 건 콜백을 받은 App의 책임이다.** Feature는 신호만 올리고 목록은 빈 채 남으므로 빈 상태("서재가 비어있어요" 등)가 비칠 수 있다 — 이걸 Feature에서 가리려 하면 위의 "갇히는 실패 뷰"로 되돌아간다. `onAuthenticationRequired`는 **화면(또는 루트)을 교체하는 배선**이어야 하고, **idempotent해야 한다**(한 화면에서 로드가 여러 개면 시간차로 2회 발화할 수 있다).
- 신호를 **소진**할지(`.consumeAuthenticationRequired`)는 VM 수명에 달렸다 — 탭 콘텐츠처럼 VM이 앱 세션 내내 살면 소진해야 2회차 만료가 삼켜지지 않는다(→ [LibraryFeature](LibraryFeature/CLAUDE.md)).

### 로드 실패 표현 계약 (#195에서 정리 — 여기가 정본)

- **화면의 주 콘텐츠를 세우는 로드가 실패하면 화면이 표현한다**(실패 뷰·실패 문구). 첫 페이지든 더보기든 갱신이든 가리지 않는다 — 사용자에겐 셋 다 "못 불러왔다"는 같은 사건이고, 몇 번째 페이지였는지는 앱 내부 사정이다.
- **화면이 표현했으면 토스트를 겹치지 않는다** — 에러 시그널 이중화. (`NovelDetail`이 첫 페이지 실패에 문구+토스트를 둘 다 띄우고 있었고 #195에서 정리했다.)
- **토스트로 남기는 건 둘뿐**: **사용자 액션 실패**(좋아요·삭제·신고·등록 — 콘텐츠는 멀쩡하고 그 행동만 실패), **부수 데이터 실패**(필터 시트 키워드 칩처럼 주 콘텐츠가 아닌 것).
- **인증 만료는 위 규칙 전부의 예외** — 실패 표현 없이 로그인 라우팅으로 일원화한다(위 "인증 만료 처리 계약").
- ⚠️ **핵심은 복구 수단이다.** 토스트는 알림이지 해결책이 아니다 — 사라지면 다시 부를 방법이 없다. 서재에서 실제로 "하단에서 더보기가 실패하면 그 뒤로 목록이 영영 안 채워지는" 상태를 만들었다(→ [LibraryFeature](LibraryFeature/CLAUDE.md)). 새 화면에서 목록 실패를 토스트로 처리하고 싶으면 **재시도 경로가 무엇인지 먼저 답할 것.**
- **표현은 `NetworkErrorView`(재시도 버튼 포함)로 통일한다.** 화면 전체를 덮을지 그 영역만 덮을지는 구조를 따른다 — 서재는 헤더 아래 전체, `NovelDetail` 피드는 스티키 탭 아래 탭 콘텐츠 자리. 목록이 남아 있어도(더보기 실패) 걷어내고 실패 뷰를 세운다.

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
  - ⚠️ **`applyWSSFont(_:color:)`의 `alignment` 기본값은 `.center`다** — 여러 줄 텍스트를 왼쪽 정렬하려면
    **`alignment: .leading`을 인자로 넘겨야** 한다. 밖에서 `.multilineTextAlignment(.leading)`을 덧붙이는 건
    **먹지 않는다**(정렬은 환경값이라 Text에 더 가까운 안쪽 값이 이긴다). `VStack(alignment: .leading)` 안에
    있어도 마찬가지 — 스택 정렬은 뷰의 배치를, 이건 뷰 *안의* 줄 정렬을 정한다. 한 줄짜리 텍스트에선 차이가
    안 보이다가 **실데이터에서 두 줄이 되는 순간 둘째 줄만 가운데로 몰려** 드러난다(#181 알림 목록에서 실측).
  - ⚠️ **컴포넌트가 안 맞으면 호출부에서 우회하지 말고 컴포넌트 수정을 제안한다.** 화면 쪽에
    **설명이 필요한 우회**(투명 뷰 트릭, modifier 순서 의존, 값 재계산)가 생기면 그건 그 화면의
    문제가 아니라 **컴포넌트 API가 부족하다는 신호**다. 우회는 그 자리에선 동작해도 같은 함정을
    쓰는 화면마다 반복되고, 매번 "왜 이렇게 쓰는지"를 주석으로 설명하게 된다.
    - 실제 사례: `WSSNovelCoverImage`는 표지가 `scaledToFill`이라 밖에서 `.aspectRatio`를 걸면
      충돌해 좁아진다 → 호출부 3곳이 `Color.clear.aspectRatio(...).overlay { 표지 }`로 우회하고
      있었다. 컴포넌트가 `aspectRatio:`를 받게 고치자 우회가 한 번에 사라지고 함정 설명도 한곳으로 모였다.
    - 고칠 땐 **기존 호출부가 안 깨지게 기본값을 두어 하위 호환**을 지키고, 같은 우회를 쓰던 **다른
      화면도 함께 옮길지** 물어본다. 한쪽만 새 API로 가면 같은 패턴이 두 벌로 갈린다.
- **도메인 라벨·아이콘·색은 WSSComponent `DomainPresentation` 확장 재사용**(`status.statusName`, `point.iconImage`). Feature 중복 매핑 ❌.
- **커스텀 탭 영역은 `.contentShape(Rectangle())`** — 없으면 라벨의 비투명 픽셀만 탭된다(빈 영역·패딩 탭 안 됨).
  - ⚠️ **히트영역을 넓히려 준 패딩을 `.offset`으로 상쇄하지 말 것** — `offset`은 그리기·히트 테스트만 옮기고
    **레이아웃·접근성 프레임에는 반영되지 않아**, 아이콘이 밀린 자리에 그대로 남는다(홈 알림 벨에서 실측 —
    `snapshot_ui` 탭 좌표가 되민 값이 아니라 원래 값으로 나와 발각됐다). 가장자리 아이콘이면
    **`.padding(.horizontal,)` 대신 컨테이너의 leading/trailing을 따로 주고 그중 한쪽만 인셋만큼 깎는다**
    (`.padding(.horizontal,)`은 양쪽에 걸려 반대편 요소까지 밀기 때문). 애플 권장 탭 타깃은 44×44.
  - ⚠️ **`.buttonStyle(.plain)`은 기본 눌림 피드백(누를 때 흐려짐)까지 없앤다** — "버튼인데 눌러도 반응이 없다"의 원인. 이 스타일이 필요한 건 label의 `Text`가 accent 색으로 물드는 걸 막을 때뿐이고, **아이콘·커스텀 뷰만 있는 버튼은 빼야** 눌린 게 보인다(서재 헤더 등록 버튼에서 제거). 습관적으로 `.contentShape`와 세트로 붙이지 말 것.
- **상태 기반 색·에셋 전환(토글·선택)엔 짧은 명시 애니메이션을 걸 것** — `.animation(.easeInOut(duration: 0.1), value: 상태)`. 미설정 시 기본 크로스페이드가 **느리게 번진다**(NovelReview 읽기 상태, NovelDetail 관심 버튼에서 재발 확인 — "토글이 굼뜨다"로 체감됨).
  - ⚠️ **단, 그 선택이 레이아웃까지 바꾸는 화면에선 이 규칙을 접는다** — 선택 즉시 다른 요소가 생겨(선택 칩 행 등장 등) 아래가 밀리면, 형제들은 즉시 새 자리로 가는데 **방금 누른 버튼 하나만 뒤늦게 미끄러져 내려온다**. 어디까지나 **그런 화면 한정 예외**이지 기본값을 뒤집는 게 아니다 — 레이아웃이 안 바뀌는 토글엔 위 규칙대로 애니메이션을 건다. 끄는 방법과 실측 근거는 [LibraryFeature](LibraryFeature/CLAUDE.md)의 필터 시트 항목이 정본.
- 화면 전용 서브뷰는 화면 폴더 동거. 여러 화면 재사용 시 WSSComponent로 승격(허락 후).

### Factory 골격

```swift
public enum XxxFeatureFactory {         // 유일한 public 진입점. opaque 반환 → View/VM은 internal 유지
    @MainActor
    public static func makeView(someUseCase: SomeUseCase) -> some View {
        XxxView(viewModel: XxxViewModel(someUseCase: someUseCase))
    }
}
```

- **접근제어(구조 강제)**: 모듈의 top-level public은 **`*Factory` 하나뿐**이어야 한다. View·ViewModel·상태 enum은 전부 `internal`로 두고, **Factory는 `some View`(opaque)로 반환**해 구체 타입을 숨긴다 — 구체 View 타입을 반환하면 그게 public으로 새고 VM·상태까지 끌려나온다. arch-lint `feature-exclusivity`(규칙⑬)가 CI에서 강제한다(→ `Tooling/ArchLint`). Factory 이름은 `XxxFeatureFactory`로 통일한다(Data의 `XxxDataFactory`와 대칭 — 규칙⑬이 `FeatureFactory` 접미사로 진입점을 식별).
- **조립 seam은 `Sources/Navigation/`에**: Feature 간 직접 의존 없이 App이 다른 Feature 콘텐츠를 주입해야 할 때(예: 상세탐색의 키워드 탭 → `KeywordTabContentBuilder`), 그 public 타입(주로 `typealias`)은 `Navigation/` 폴더에 둔다 — 규칙⑬이 이 폴더의 public만 진입점 외 예외로 허용한다. Factory·seam 외의 것을 public으로 열어야 할 것 같으면 배선을 다시 볼 신호다.
- **`makeView`는 모듈에 화면이 하나일 때만 쓴다** — 화면이 둘 이상이면 **전부** `makeXxxView`로 무엇을 만드는지 이름에 넣는다(`makeCreateFeedView`·`makeMyLibraryView`·`makeUserLibraryView`). 대등한 화면 중 하나만 `makeView`로 남기면 호출부에서 어느 화면인지 읽히지 않는다(`LibraryFeatureFactory`가 실제로 그랬다). 단 `SettingFeatureFactory`는 **메인 설정 화면 + 그 하위 상세들**이라 대표 화면이 `makeView`인 게 자연스러운 경우다 — 대등한지 종속인지로 판단할 것.
- **Demo·Preview 필수**: `.demo` 타깃의 Demo 앱이 Factory를 `NavigationStack`에 띄워 단독 실행. Preview는 Sources 내부(internal 접근).
- **⚠️ Demo 앱 `init()`에서 `DesignSystemFontFamily.registerAllCustomFonts()` 호출.** `applyWSSFont`가 `UIFont(name:)!`를 강제 언래핑 → 폰트 미등록 시 **런타임 크래시(SIGTRAP)**. 프리뷰도 Demo 앱을 호스트로 띄우므로 같이 죽는다.
- 테스트는 mock UseCase 주입으로 충분. View에 가짜 VM을 통째로 주입할 일이 생기면 그때 가벼운 프로토콜을 다시 얹는다.

## UI 검증 (시뮬레이터 — XcodeBuildMCP)

화면을 띄워 확인할 땐 **Feature 모듈 스킴**으로 Demo 앱을 실행한다(자세히 → [docs/BUILD_AND_TEST.md](../../docs/BUILD_AND_TEST.md)).
- **실행 스킴은 `XxxFeature`** (별도 `XxxFeatureDemo` 스킴은 없다). 이 스킴의 LaunchAction이 `XxxFeatureDemo.app`을 띄운다 → `build_run_sim(scheme: "NovelReviewFeature")`.
- **`launch_app_sim`용 bundleId는 `<env.organizationName>.XxxFeatureDemo`**(`ProjectEnvironment.swift`의 `organizationName` 참고) — `build_run_sim`이 보고하는 건 framework(`...XxxFeature`)라 그대로 launch하면 실패.
- **별점 등 커스텀 드로잉은 접근성 tap 타겟으로 안 잡힌다** → `snapshot_ui`에 안 뜨면 좌표 탭. 표준 버튼/세그먼트/매력포인트는 `elementRef`로 잡힌다.
- **Demo `Mock` 모드는 일부 화면 미연결**(예: 키워드 입력) — 네트워크 의존 플로우는 `실서버` 토글이 필요.
- **`build_run_sim`은 이 스킴에서 install이 framework를 잡아 실패**할 수 있다("installable app 없음") → `build_sim`(컴파일) 후 `install_app_sim`+`launch_app_sim`(bundleId `...XxxFeatureDemo`)이 안정적.
- ⚠️ **install할 `.app`은 `get_sim_app_path`가 알려주는 Products 디렉토리에서 고른다**(그 안의 `XxxFeatureDemo.app`). XcodeBuildMCP는 Xcode의 `~/Library/Developer/Xcode/DerivedData`가 **아니라 자체 `~/Library/Developer/XcodeBuildMCP/workspaces/<repo>/DerivedData/`** 에 빌드한다 — `find`로 Xcode DerivedData의 `.app`을 잡아 설치하면 **며칠 전 빌드가 조용히 올라가** 방금 고친 게 반영 안 된 화면을 보고 오진한다(실제 발생). 의심되면 `.app`의 mtime을 빌드 시각과 대조할 것.

## 주의사항 (작업 중 발견 시 누적)

- 화면 라벨/아이콘 표현은 **WSSComponent의 `DomainPresentation/` 확장**(`public`)을 재사용한다 — Feature에서 중복 매핑하지 말 것.
- `ModuleType.feature` enum의 **13개 모듈이 모두 실재**한다: `HomeFeature`, `NovelReviewFeature`, `FeedFeature`, `NovelDetailFeature`, `UserPageFeature`, `SettingFeature`, `SearchFeature`, `KeywordFeature`, `LibraryFeature`, `OnboardingFeature`, `NotificationFeature`, `CollectionFeature`(#199·#200·#201, 컬렉션 생성·"작품 추가"/"서재에서 추가"·컬렉션 목록·상세 화면까지 구현 완료, 마이페이지·타유저 프로필 연동 포함), `SplashFeature`(#225, 런치 스플래시 — `SplashFeature/CLAUDE.md` 참고). `SearchFeature`는 소소픽·최근 검색어·키워드 검색(인기 키워드)·자동완성·검색 실행/결과·장르·키워드 탭의 상세 검색 결과 화면까지 UseCase 연동 완료 — 자세한 내용은 `SearchFeature/CLAUDE.md` 참고. (디스크의 `MypageFeature/` 폴더는 `UserPageFeature`로 리네이밍된 뒤 남은 유령 폴더 — git 추적 밖이라 실재하지 않는다, 루트 `CLAUDE.md`의 유령 폴더 주의 참고.)
- **탭 콘텐츠는 탭 복귀마다 갱신한다** — 홈·마이페이지·서재 모두 밖에서 바뀐 값(추천·알림·프로필, 작품 상세에서 고친 별점·읽기상태)을 다시 비춰야 해서다. 구 WSSiOS도 `viewWillAppear`마다 다시 불렀다. **`.load`에 "최초 1회" 가드를 넣지 말 것**(서재가 `hasLoaded`로 그렇게 돼 있었으나 걷어냈다) — 중복 요청은 진행 중인 Task 가드가 막는다.
  - ⚠️ 대신 **갱신이 이미 그린 콘텐츠를 걷어내지 않게** 해야 한다 — 안 그러면 돌아올 때마다 화면이 깜빡이고 스크롤 위치가 초기화된다. 홈은 로딩 분기를 `isInitialLoading`(보여줄 게 없을 때만)으로 좁혔고, 서재는 갱신 경로가 아예 로딩 표시를 세우지 않는다. → [HomeFeature](HomeFeature/CLAUDE.md), [LibraryFeature](LibraryFeature/CLAUDE.md), [UserPageFeature](UserPageFeature/CLAUDE.md).
- ⚠️ **글자수 제한이 있는 `TextField`는 VM 상태에 직접 물리지 말 것.** `Binding(get:set:)`의 `set`에서 곧바로 clamp하면, `get`이 SwiftUI가 방금 그 필드에 마지막으로 써준 값과 같아져 "변화 없음"으로 판단되고 **네이티브 텍스트필드는 사용자가 입력한 초과분을 화면에 그대로 들고 있는다**(카운터는 맞는데 눈에 보이는 글자 수는 안 맞음). 로컬 `@State` 문자열에 물린 뒤 `.onChange`에서 "clamp → 다르면 로컬에 재대입(진짜 변경으로 인식돼 네이티브 필드가 강제로 되돌아감) → 같으면 VM에 전달"의 2단계로 처리해야 한다 → [UserPageFeature](UserPageFeature/CLAUDE.md)의 `MyPageEditView`(닉네임·소개글 필드)가 실측 사례.
- ⚠️ **전면 배경 이미지를 `resizable().scaledToFill()`로 쓸 땐 ZStack 형제가 아니라 `.background { }`로 깔 것.** scaledToFill은 오버플로된 크기를 자신의 레이아웃 크기로 보고해 ZStack이 화면보다 커지고, 그 중앙 기준으로 형제 콘텐츠가 배치되며 **하단 요소가 화면 밖으로 밀린다**(SplashFeature 워드마크가 실제로 사라졌다 — 시뮬레이터 실측, #225). `.background`는 콘텐츠 크기에 영향을 주지 않아 이 오염이 없다.
- ⚠️ **스크롤 반응형 네비 타이틀(`ToolbarItem(placement: .principal)` 안 `Text` + `.opacity(조건 ? 1 : 0)`)은 모디파이어 값만 바꿔선 안 보인다.** `.opacity`가 `isScrolledFromTop` 같은 상태값에 따라 바뀌어도 그 `Text`가 UIKit 브리지(`UINavigationItem.titleView`)에 갱신되지 않고 계속 숨어있는다 — `.animation(value:)`을 로컬에 걸든 body 루트에 걸든, 아예 안 걸든 증상이 같다(실측: `CollectionFeature.CollectionDetailView`에서 처음 발견, `UserPageFeature.UserPageView`도 동일 패턴이라 같이 고침, #201). **`opacity` 대신 `if 조건 { ToolbarItem(.principal) { Text(...) } }`로 뷰 자체를 구조적으로 넣고 뺄 것** — `ToolbarContentBuilder`가 진짜 다른 콘텐츠로 인식해야 브리지가 갱신된다. `NovelDetailFeature`의 몰입형 헤더는 시스템 툴바가 아니라 커스텀 오버레이라 이 함정 대상이 아니다(그쪽 `opacity` 페이드는 정상 동작) — **시스템 `.toolbar { }` + 조건부 `opacity` 조합에서만** 재현된다.
