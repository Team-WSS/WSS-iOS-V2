<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/UI/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# WSSComponent

웹소소 공용 SwiftUI 컴포넌트 — Alert, Toast, Button, FeedCell, SearchBar 등.

- 식별자: `ModuleType.ui(.wssComponent)` / 의존: SwiftUI, `DesignSystem`, `BaseDomain`

## 패턴

- **오버레이 UI(Alert/Toast)는 `ViewModifier` + `@Binding isPresented` + `View+` 확장**으로 제공. 예: `WSSAlertViewModifier`는 `isPresented`일 때 딤(`Color.black.opacity(0.6)`) + 알럿을 overlay, 전환 애니메이션 포함. 버튼 동작은 `buttonActions: [() -> Void]` 배열로 주입.
- 스타일/타입은 enum으로 분리 (`WSSAlertType`/`WSSAlertStyle`, `WSSToastType`/`WSSToastStyle`).
- 색·폰트는 전부 `DesignSystem` 토큰 사용.

## 주의사항 (작업 중 발견 시 누적)

- **`WSSNavigationBar(title:onBack:)`는 커스텀 헤더 화면의 공용 상단 바다**(#181에 승격 — 타유저 서재·알림 목록·알림 상세 3곳). 시스템 네비바를 안 쓰는 이유는 폰트·back 아이콘이 디자인과 달라서고, **호출부는 `.toolbar(.hidden, for: .navigationBar)` + `.enableSwipeBack()`을 함께 걸어야 한다**(컴포넌트가 대신 걸어주지 않는다 — 네비바 숨김은 화면 전체에 거는 modifier라 컴포넌트 소관 밖).
  - `onBack`은 보통 호출부의 `@Environment(\.dismiss)`를 넘긴다 — **어디로 가는지는 화면이 정한다**(UI 레이어는 내비게이션 정책을 모른다는 선).
  - 여기 모인 함정 3개를 화면마다 다시 만들지 말 것: ① `icNavigateLeft`는 원색이 연회색(#C7C7D0)이라 `renderingMode(.template)` + `wssBlack`으로 색을 입혀야 하고, ② 아이콘 24를 44 히트 영역 가운데 두며, ③ 타이틀은 `ZStack` 중앙에 둔다(`HStack`에 넣으면 뒤로가기 폭만큼 오른쪽으로 밀린다).
- **`WSSEmptyView`의 CTA는 선택이다** — `action`을 생략(nil)하거나 `type.buttonTitle`이 nil이면 **버튼과 그 위 간격(36)이 함께 사라진다**. 유도할 행동이 없는 빈 상태(`.notification` — 알림 목록)를 화면마다 다시 그리지 않으려고 #181에서 열었다. `action`에 기본값이 있어 기존 호출부는 그대로 동작한다.
  - ⚠️ **`LibraryFeature`의 `noMatchSection`(필터 0건)은 아직 이 컴포넌트로 옮기지 않았다** — 그쪽은 이미지를 39×48로 줄이고 상단 여백 120을 직접 잡는 등 **렌더가 달라서**, 옮기면 서재 화면 재검증이 필요하다. 옮길 거면 크기 파라미터를 열지 말고 **왜 두 빈 상태의 이미지 크기가 다른지부터** 디자인과 정할 것.
- **`WSSSelectionCheckIcon`(#188)** — `icSelectNovelDefault`/`icSelectNovelSelected` 체크 아이콘 전환을 크로스페이드+스케일 스프링(`.spring(response: 0.32, dampingFraction: 0.6)`)으로 통일한 공용 컴포넌트. 원래 `CreateFeedConnectNovelRow`(FeedFeature)에서 시작된 패턴이 `MyFeedFilterSheet`·`WithdrawReasonView`·`NovelNotificationRow`에 각자 손으로 복제(또는 애니메이션 없이 즉시 스냅 전환)돼 있던 걸 여기로 모았다 — `CreateFeedConnectNovelRow`는 이후 `#199`로 `WSSNovelSelectRow`로 승격되며 사라졌고, 그 승격된 파일에도 이 컴포넌트를 반영했다. **탭 제스처를 갖지 않는 순수 표시 컴포넌트**라 호출부가 `Button`이든 `onTapGesture`든 자유롭게 감싼다. 크기도 안 정하므로(`.frame` 없음) 호출부가 필요한 크기로 얹는다 — 콜사이트마다 44×44(히트 영역 포함)·24×24(순수 아이콘) 등으로 다르다. 이 아이콘 쌍을 새로 쓰는 화면은 직접 구현하지 말고 이 컴포넌트를 재사용할 것.
- **`WSSNovelGridCell`(작품 그리드 셀)의 계약 — "폭은 부모가, 높이는 컴포넌트가"**:
  - ⚠️ **표지 아래 정보 스택은 고정 높이(72)** 다. 제목이 1~2줄로 갈려 자연 높이로 두면 **`LazyVGrid` 행이
    어긋나** 목록이 삐뚤빼뚤해진다(홈·서재 양쪽에서 실제로 겪음). 스택 **안은 자연스럽게 흐르게** 두고
    (1줄 제목이면 작가가 바로 따라옴 — 디자인 의도) 스택 **자체만** 고정한다. 빈 자리를 채우거나 제목을
    2줄로 강제하지 말 것. **높이를 파라미터로 열지 않은 것도 의도** — 폰트·줄 수가 고정이라 값이 흔들리면
    행 정렬이라는 존재 이유가 깨진다.
  - **표지·제목·작가가 같은 폭을 공유한다**(모두 셀 폭). 홈 시안엔 제목만 140(셀 163)이었으나 표지와
    오른쪽 끝이 어긋나 걷어냈다 — **시안 값을 근거로 제목 폭을 다시 좁히지 말 것**.
  - 표지 비율은 `WSSNovelCoverImage(url:aspectRatio:)`에 **파라미터로 넘긴다**(아래 표지 항목 참고).
  - 기본 비율 상수가 `public`인 건 스타일이 아니라 **문법 제약**이다 — public `init`의 기본값 표현식은
    private 상수(`Metric`)를 참조할 수 없다.
- 컴포넌트가 아는 도메인은 **`BaseDomain`의 공통 값 타입까지**(`ReadingStatus`, `AttractivePoint`, `NovelGenre`, `SortType`, `KeywordCategory` 등). 이들의 라벨·색·아이콘 매핑을 `Sources/DomainPresentation/`(`+Presentation` 확장, public)에 한곳으로 모아 Feature가 중복 매핑하지 않게 한다. → 그 외 도메인 Entity·Repository나 상위 Feature 모델은 모른다(표시 데이터/콜백만 값으로 받음).
- 특정 화면 전용 **필터용 값 목록**(예: `NovelGenre.myFeedFilter`, 검색 화면 장르 그리드용 `NovelGenre.searchGenre`, 온보딩 3x3 그리드용 `.onboardingGenre`, 프로필 편집용 `.profileEditGenre`)도 라벨·색 매핑과 동일하게 `DomainPresentation` 확장에 둔다 — `BaseDomain`은 순수 enum만 갖고 화면별 부분집합/순서는 여기서 정의. 이 목록들은 각각 **의도적으로 다른 순서**의 별개 목록 — 하나를 고친다고 나머지까지 맞추지 말 것.
- `KeywordCategory+Presentation`의 아이콘(`icCategoryWorld` 등)은 `AttractivePoint`의 `icAttractiveXxx`와 **다른 에셋**이다 — 이름이 비슷한 "세계관/소재/캐릭터/관계/분위기" 라벨을 공유하지만(매력포인트엔 "필력"이 하나 더 있음) 서로 다른 제품 개념이라 아이콘을 섞어 쓰지 말 것.
- ⚠️ **테두리는 `.stroke`가 아니라 `.strokeBorder`로 그린다.** `.stroke`는 선을 shape 경로의 **중앙**에 그려 `lineWidth 1`이면 0.5pt가 뷰 프레임 **밖**으로 나간다 → 컴포넌트를 `ScrollView`(또는 클립하는 컨테이너) 안에 넣는 순간 그 바깥 절반이 클립돼 **테두리가 한쪽만 얇아지거나 잘려 보인다**(서재 필터 칩·필터 시트 키워드 칩에서 실제 발생, #166). `.strokeBorder`는 `InsettableShape`를 lineWidth만큼 안으로 inset한 뒤 그려 선 전체가 프레임 안에 들어온다 — 컴포넌트는 어디에 놓일지 모르니 **공용 컴포넌트일수록 기본값이 `strokeBorder`**여야 한다. `Capsule`/`RoundedRectangle` 모두 `InsettableShape`라 그대로 바꿔 쓸 수 있다.
- **`WSSRangeSlider`(범위 슬라이더, #185)는 `LibraryFeature`의 `LibraryRatingSlider`를 일반화해 승격한 것** — 트랙이 전체 폭이 아니라 **핸들 반지름만큼 안쪽**(x: 8 ~ width-8)에 놓인다. `position = fraction * width`로 두면 0.0/최댓값에서 핸들이 슬라이더 밖으로 반쪽 잘린다(값→좌표·좌표→값 두 함수 모두 같은 보정 필요). ⚠️ **어느 핸들을 움직일지는 드래그 시작(`translation == .zero`)에 한 번만 정한다** — 매 이벤트마다 "가까운 쪽"을 다시 고르면 두 핸들이 가까워진 순간 판정이 뒤집혀 반대편 핸들이 끌려온다. `bounds`/`step`을 파라미터로 열어뒀지만 지금 호출부(`LibraryFeature`·`SearchFeature`) 둘 다 기본값(0.0...5.0, 0.5)을 그대로 쓴다.
  - 스텝이 바뀔 때마다 `HapticManager.selection()`을 울린다(`lastHapticValue`로 "실제로 스텝이 바뀐 시점"만 골라낸다) — `onChanged`마다 울리면 손가락을 대고만 있어도 진동이 난다. 드래그 세션 시작 시 `lastHapticValue`를 **현재 prop 값**(그 핸들의 `min`/`max`)으로 시딩해, 처음 터치를 댄 순간(아직 안 움직임)에는 안 울리고 첫 스텝 이동부터 울리게 했다 — `nil`로 시딩하면 터치다운 자체가 "값이 바뀐 것"으로 오판돼 즉시 한 번 울려버린다.
- Alert 버튼은 인덱스 기반 `buttonActions` 배열 ↔ 버튼 개수 매칭에 주의.
- **Alert 버튼 탭은 `isPresented`를 자동으로 닫지 않는다**(SwiftUI `.alert`와 다름) — 취소 버튼 포함 **모든 buttonActions가 스스로 표시 상태를 되돌려야** 한다. 안 그러면 알럿이 안 닫힌다.
- **`isPresented`는 그대로 두고 `alertType`만 바뀌는 다단계 알럿**(예: "신고할까요?" 확인 → "신고 접수했습니다" 완료)은 `WSSAlertView`에 `.id(alertType)`를 걸어 뷰 정체성을 갈라야 `.transition`이 실제로 발동한다 — 안 걸면 SwiftUI가 "같은 뷰"로 보고 내용만 즉시 스냅 교체해버려 애니메이션이 없다(`WSSAlertType`을 `Hashable`로 만든 이유). `.animation(value:)`도 `isPresented`뿐 아니라 `alertType` 변화에도 걸어야 이 전환이 애니메이션된다.
- **`WSSAlertType`은 원래 전 케이스가 정적 카피라 `CaseIterable` 자동 합성이었지만, `deleteNovelNotificationSubscriptions(summary:)`(#188, "선택 N개 삭제할까요?" 류처럼 화면마다 문구가 달라지는 알럿)가 연관값을 가지면서 깨졌다** — `CaseIterable` 준수를 별도 `extension`으로 옮기고 `allCases`를 수동 나열한다(Demo 프리뷰 목록용, 동적 케이스는 샘플 문자열로 채움). 새 정적 케이스를 추가하면 이 수동 `allCases`에도 반드시 같이 넣을 것 — 안 넣으면 컴파일은 되지만 Demo에서 조용히 안 보인다. 문구 조합(예: "제목 외 N작품")은 컴포넌트가 판단하지 않고 **호출부가 완성된 문자열을 넘긴다**.
- **이미지 + `onTapGesture` 패턴은 접근성 트리에 안 잡힌다**(VoiceOver·UI 자동화 모두) — 탭 가능한 이미지에는 `.accessibilityLabel` + `.accessibilityAddTraits(.isButton)`을 같이 달거나 `Button`을 쓸 것(WSSFeadHeaderView의 프로필·threedots에서 발견).
- **`WSSAlertView`의 버튼(`WSSAlertButtonView` = `Text` + `.onTapGesture`)도 같은 이유로 접근성 트리에 안 잡힌다** — 앱 전체 알럿이 이 컴포넌트를 쓰므로, UI 자동화(XcodeBuildMCP `tap` 등)로는 알럿이 뜨는 것까지만 검증 가능하고 버튼 탭은 못 누른다(UserPageFeature #172에서 확인). 자동화로 알럿 버튼까지 검증해야 하면 `Button`으로 바꾸거나 접근성 트레잇을 추가해야 한다.
- **`scaledToFill().frame(...).clipShape(...)`는 그리기만 자르고 hit-test 영역은 스케일된 원본 크기로 남는다** — 프레임보다 세로로 긴 이미지(정사각 이상)면 보이지 않는 터치 영역이 위아래로 넘쳐 **형제 뷰의 버튼 탭을 가로챈다**(WSSFeedImageView가 WSSFeadView 헤더의 프로필·threedots를 죽이던 버그, #154에서 수정). 장식 이미지는 `.allowsHitTesting(false)`, 탭이 필요한 이미지는 clip 뒤 `.contentShape`로 hit 영역을 명시할 것.
- `WSSSearchBar`는 `isFocused: FocusState<Bool>.Binding? = nil`로 외부 포커스 제어를 선택적으로 받는다(기본 nil이면 내부 `@FocusState` 사용). 호출부가 포커스를 직접 제어하려면(자동 포커스, 바깥 탭 시 dismiss 등) 일반 `@State`가 아니라 **자체 `@FocusState` 프로퍼티**를 선언해 그 `$binding`을 넘겨야 한다 — 타입이 `FocusState<Bool>.Binding`이라 `Binding<Bool>`과 호환되지 않는다.
- ⚠️ **`WSSNovelCoverImage`에 `.aspectRatio`를 밖에서 걸지 말 것 — 비율은 `aspectRatio:` 파라미터로 넘긴다.**
  표지는 `scaledToFill`(= `aspectRatio(.fill)`)이라 밖에서 `.fit` 비율을 또 걸면 **둘이 충돌해 표지가 좁아진다**(실측).
  파라미터를 주면 컴포넌트가 내부에서 "투명 뷰가 비율을 잡고 그림은 overlay로 채운 뒤 `clipped()`" 구조로 처리한다
  — 호출부에서 `Color.clear.aspectRatio(...).overlay { ... }` 트릭을 다시 쓰지 말 것(그 트릭이 불편해서 컴포넌트로 넣었다).
  크기가 고정인 자리(추천글 행 썸네일 등)는 파라미터 없이 밖에서 `.frame(width:height:)`를 쓰면 된다.
  - `clipped()`는 **그리기만 자르고 hit-test 영역은 남긴다** → 탭이 필요한 표지는 호출부가 `.contentShape`를 얹어야 한다.
- **목록 표지·프로필처럼 반복 렌더되는 원격 이미지엔 `AsyncImage`를 직접 쓰지 말고 `WSSAsyncImage`(또는 표지 편의 래퍼 `WSSNovelCoverImage`)를 쓴다** — `AsyncImage`는 뷰 정체성이 바뀔 때마다 `.empty` phase부터 다시 시작해 **캐시 히트여도** placeholder가 한 프레임 번쩍인다(목록 셀 모드 전환·스크롤 재활용에서 매번 도짐). URLCache는 **응답 데이터**만 갖고 있어 재디코딩 틈이 남는다. `WSSAsyncImage`는 **디코딩된 `UIImage`를 인메모리 캐시(`WSSImageCache`, 화면 간 공유)에 두고 렌더 경로(`displayedImage`)에서 동기 조회** → 히트면 첫 프레임부터 실제 이미지(placeholder 프레임 자체가 안 생김). NovelDetail 대형 표지가 같은 함정을 prefetch로 풀었던 것을 컴포넌트로 일반화(#166).
  - ⚠️ **캐시 동기 조회는 `init`이 아니라 렌더 경로(`displayedImage`)에 있어야 한다.** `@State`는 저장소가 처음 만들어질 때만 초기값이 적용되고 `.task`는 **첫 렌더 뒤에** 도므로, 뷰 정체성이 유지된 채 url만 바뀌면(프로필 사진 교체 등) 첫 프레임에 **옛 이미지/placeholder가 한 번 스친다.** 그래서 `image`와 짝으로 `loadedURL`을 들고, `loadedURL != url`이면 렌더 시점에 캐시를 직접 조회한다 — 이 짝이 없으면 "캐시 히트면 첫 프레임부터 실제 이미지" 보장이 url 변경 케이스에서 깨진다(#166 2라운드 리뷰에서 발견).
  - ⚠️ "캐시 히트면 네트워크 안 감"을 `guard image == nil` 조기 리턴으로 구현하면 **새 url이 영영 로드되지 않는다** — 히트 판정은 `image`가 아니라 반드시 **`WSSImageCache` 조회 결과**로 할 것. 또한 취소 검사(`!Task.isCancelled`)를 `await` **재개 뒤에** 둬야 취소된 옛 요청이 새 url의 그림을 덮지 않는다.
  - ⚠️ **`loadedURL`은 이미지를 실제로 확보했을 때만 찍는다.** 네트워크 시작 전에 미리 찍으면 실패·취소 시 `loadedURL == url && image == nil`로 굳어, 다른 인스턴스가 나중에 같은 url을 공유 캐시에 넣어도 **placeholder에 갇힌다**(`.task`는 url이 바뀌어야 재실행되므로 스스로 못 빠져나온다). 실패 상태에선 `loadedURL != url`을 유지해 캐시 폴백 경로를 열어두는 게 안전하다.
- **커스텀 헤더는 `.toolbar(.hidden, for: .navigationBar)`로 만든다** — `.navigationBarBackButtonHidden(true)`로 만들면 아래 `hidesBackButton` 가드에 걸려 **`.enableSwipeBack()`이 조용히 안 먹는다**(증상은 "modifier를 걸었는데 스와이프백이 안 됨", 원인은 컴포넌트 안쪽이라 추적이 오래 걸린다).
- **커스텀 헤더 화면의 스와이프 뒤로가기는 `.enableSwipeBack()`(`Sources/Navigation/`)으로 되살린다** — 시스템 네비바를 숨기면(`.toolbar(.hidden, for: .navigationBar)`) iOS가 `interactivePopGestureRecognizer`도 함께 끄기 때문. 원래 `NovelDetailFeature`·`LibraryFeature`에 각각 복제돼 있었고, **한쪽만 고쳐져 갈라진 게 사고 원인이 됐다**(#166) → 여기로 통합.
  - ⚠️ **제스처 delegate는 반드시 `UINavigationController` 자신에게 맡긴다 — 별도 Coordinator에 맡기지 말 것.** `UIGestureRecognizer.delegate`는 **약한 참조**라 그 객체가 해제되면 nil이 되는데, UIKit은 nav controller를 만들 때 한 번만 delegate를 꽂으므로 **스스로 돌아오지 않는다** → `shouldBegin` 기본값(YES)이 적용돼 **되돌아갈 화면이 없는 루트에서도 pop 전환이 시작되고 내비게이션이 얼어붙는다**(앱 재시작 외 복구 불가).
    - "떠날 때 반납"(`dismantleUIView` → 원본 되돌리기)으로 막는 구조를 **한 번 만들었다가 걷어냈다** — 반납만으론 부족했다. `updateUIView`가 예약한 async 블록이 반납 **뒤에** 실행돼 방금 되돌린 원본을 재캡처하고 도로 가로채는 경합이 있었고(가드 플래그가 또 필요), 복제본이 하나라도 반납을 빠뜨리면 **다른 화면의 반납까지 무력화**됐다(nil을 "원본"으로 캡처). 네비게이션 컨트롤러는 **스택이 사는 내내 살아 있어** 이 수명 문제가 통째로 사라진다 — 반납도, 경합 가드도, 복제본 동기화도 필요 없다. 구 WSSiOS(UIKit)도 같은 이유로 반납 없이 각 뷰컨트롤러가 `delegate = self`를 꽂았다.
  - ⚠️ **delegate를 맡았으면 UIKit 기본 delegate가 하던 판단도 함께 가져와야 한다.** 이 delegate는 **스택 전체가 공유**하므로(제스처가 NavigationStack당 하나) 한 화면이 꽂는 순간 그 영향이 **그 스택의 모든 화면에, 영구히** 간다 — "커스텀 헤더 화면에만 적용된다"가 아니다. 그래서 `shouldBegin`은 루트 가드(`viewControllers.count > 1`) 외에 둘을 더 본다:
    - **전환 진행 중 차단**(`transitionCoordinator == nil`) — 없으면 셀을 탭해 push 애니메이션이 도는 중 엣지를 밀었을 때 그 위에 인터랙티브 pop이 겹쳐 스택·네비바가 깨진다.
    - **뒤로가기 버튼을 숨긴 화면 차단**(`hidesBackButton != true`) — `.navigationBarBackButtonHidden(true)`는 원래 스와이프백까지 함께 죽이고, **`NovelReviewView`가 바로 그 성질에 기대어** 닫기 전 "그만하기" 확인 알럿을 강제한다. 이 가드가 없으면 스와이프로 알럿 없이 빠져나가 **작성 중이던 초안이 확인 없이 사라진다.**
      - ✅ **양쪽 다 런타임 실측**(추측 아님): 커스텀 헤더 화면(`.toolbar(.hidden, for: .navigationBar)`)은 `hidesBackButton = **false**`(타유저 서재) → 가드가 본래 목적을 막지 않는다. `.navigationBarBackButtonHidden(true)` 화면은 `hidesBackButton = **true**`(NovelReview) → 가드가 실제로 발동한다. **두 modifier는 서로 다른 플래그를 건드린다.**
      - 참고로 UIKit 기본 delegate는 `leftBarButtonItems`가 있어도 막는데, **SwiftUI `ToolbarItem(placement: .cancellationAction)`은 `leftBarButtonItems`로 잡히지 않는다**(실측: `nil`) → 그 조건까지 흉내 낼 필요는 없었다.
  - ⚠️ **`extension UINavigationController: @retroactive UIGestureRecognizerDelegate`는 앱 전역에 단 하나만 존재해야 한다** — 같은 타입에 두 모듈이 각각 준수를 붙이면 런타임 동작이 정의되지 않는다. Feature로 다시 복제하지 말 것.
    - 이 준수는 전역이라 **pop 제스처가 아닌 recognizer가 물어올 수도 있다** → 그 경우 UIKit 기본값 `true`를 돌려준다. `false`로 답하면 남의 제스처를 막는다.
    - ⚠️ **`import`만으로 앱 전역에 런타임 side effect를 만드는 유일한 UI 자산**이다(다른 컴포넌트는 쓸 때만 영향). UI 레이어에 놓인 근거는 [상위 레이어 문서](../CLAUDE.md)의 예외 항목이고, **이 패턴을 늘리지 말 것** — 늘릴 이유가 생기면 그때 UI에 둘지부터 다시 판단한다.
  - 구 WSSiOS에는 `shouldReceive touch`로 **텍스트 입력(`UITextField`/`UITextView`) 위 터치를 무시**하는 규칙도 있었는데 **가져오지 않았다** — 지금 코드베이스엔 발화 지점이 없다(전면 `UITextView` 0건, `TextField`는 전부 좌우 패딩 안쪽이라 엣지 팬 구간에 안 걸린다). 전역 delegate에 검증 못 하는 규칙을 얹지 않으려는 판단이니, 화면 폭을 채우는 텍스트 에디터가 생기면 **그때 실제 증상을 확인하고** 넣을 것.
  - ⚠️ **이 제스처는 시뮬레이터 자동화로 검증할 수 없다** — XcodeBuildMCP `gesture(swipe-from-left-edge)`로는 `shouldBegin`이 아예 불리지 않는다. **사람이 직접 밀어서** 확인해야 한다.
- `WSSFlowLayout.sizeThatFits`는 제안된 폭이 유한하면 내용 실제 폭이 아니라 **그 폭을 그대로** 자기 크기로 보고한다 — 내용이 한 줄을 못 채워도 상위 스택의 기본(가운데) 정렬에 밀려 왼쪽 정렬이 안 보이는 문제를 막기 위한 의도적 선택. 폭 제약이 없을 때만(`.infinity`) 내용 폭에 맞춰 줄어든다.
- `FeedHeader`/`WSSFeedReact`는 콜백(`profileTapped`/`threeDotsButtonTapped`/`likeButtonTapped`)과 `isLiked`를 struct에 담지 않는다 — 각각 `WSSFeadHeaderView`/`WSSFeedReactView` **뷰 레벨** 파라미터로만 받는다(struct는 순수 표시 데이터). 좋아요 아이콘은 `icThumbUp`/`icThumbUpFill`만 쓴다(`icLike`/`icLikeSelected` 에셋 없음). 과거 "콜백 책임 분리" 리팩터(#135/#148)가 이 구조를 몇 번 바꾸려다 접근성 탭 타겟 수정(#154, `.contentShape`+`onTapGesture`+`accessibilityLabel`, 프로필 탭 영역을 닉네임까지 확장)과 반복 충돌했다 — rebase 시 두 설계를 섞지 말고 이 규칙대로 정리할 것.
- `WSSDropdownItem`의 글자색 파라미터명은 `textColor`(구 `titleColor` 아님), 순서는 `title, action, textColor = 기본값`. `textColor`가 기본값을 갖고 `action` 뒤에 오므로 `WSSDropdownItem(title: "x") { ... }` 트레일링 클로저 호출은 그대로 유효 — 단 색을 지정하려면 `action:`/`textColor:` 라벨을 명시해야 한다(트레일링 클로저는 라벨 있는 인자 뒤엔 못 붙음). `NovelDetailFeature`처럼 **다른 Feature 모듈**이 이 컴포넌트를 쓰면 rebase 시 그 호출부도 같이 깨질 수 있으니 시그니처 변경 시 전 레포 검색 필수.
- `WSSFeadView`는 `isLiked`/`likeButtonTapped`를 자체 파라미터로 받아 `WSSFeedReactView`에 그대로 넘긴다(둘 다 기본값 없는 필수 파라미터 — 호출부가 실제 좋아요 상태/토글을 직접 채워야 한다).
- `WSSFeedImageView`처럼 `AsyncImage`의 여러 `phase`(`.success`/`.failure`)에 이미지를 그릴 땐 **각 phase의 이미지마다 개별적으로 `.resizable()`을 걸어야** 바깥에 얹은 `.scaledToFill()`/`.frame`이 실제로 적용된다 — 하나라도 빠뜨리면 그 phase(예: 로드 실패 placeholder)만 조용히 원본 크기로 나온다.
- `WSSSortButton`처럼 `Button` 라벨 안의 값(예: `sortType`에 따른 텍스트/아이콘)이 바뀌는 경우, 호출부에 별도 `.animation`이 없어도 탭 트랜잭션에 얹혀 암시적으로 크로스페이드된다. 즉시 전환을 원하면 그 값에 `.animation(nil, value:)`를 명시해야 한다.
- `WSSFeadView`의 `isSpoiler`/`isPrivate`는 단순 배지가 아니라 **하위 콘텐츠를 통째로 대체**한다: `isSpoiler: true`면 `content` 텍스트가 "스포일러가 포함된 글 보기"로, `feedImage`가 있어도 이미지 자체가 렌더링되지 않는다. `isPrivate: true`면 `react`(좋아요/댓글) 섹션이 아예 안 뜨고 "나만 보는 기록이에요." 행으로 대체된다 — 호출부가 `react`를 넘겨도 private일 땐 좋아요/댓글 버튼에 접근할 수 없다.
- `HapticManager`(`Sources/Haptic/`)는 Core가 아니라 여기 있다 — 도메인 지식이 없는 순수 기술이라 Core 기준(재사용 가능한 기반 기술)에도 맞지만, 등록된 `CoreModule`에 범용 유틸 모듈이 없고(`Keychain`/`Networking`/`Logger`만 존재) 이걸 위해 새 Core 모듈을 만들 정도는 아니라고 판단해 WSSComponent에 뒀다. 호출은 자동 적용되지 않고 **각 콜사이트가 상황에 맞는 스타일을 직접 골라 명시적으로 호출**해야 한다(예: `WSSSortButton` action 클로저 안에서 `HapticManager.selection()`).
- Capsule 모양 칩/버튼의 배경·테두리는 `.background(Color).clipShape(Capsule()).overlay(Capsule().stroke(...))` 대신 `.background { Capsule().fill(...) }.overlay { Capsule().strokeBorder(...) }` 패턴을 쓰면 clipShape가 불필요해지고(도형이 이미 캡슐로만 그려짐) `strokeBorder`는 테두리가 프레임 안쪽으로만 그려져 `stroke`처럼 경계 밖으로 살짝 번지지 않는다. `WhiteRemovableKeywordChip`은 이 패턴으로 전환됨, `PrimaryRemovableKeywordChip`/`WSSFilterButton`은 아직 구 패턴 — 새로 만들 때는 신 패턴을 우선한다.
- **칩·셀 안에 "우선순위 서브 액션"(삭제 X 등)과 "나머지 영역 액션"을 함께 넣을 땐 서브 액션만 `Button`으로, 나머지 컨테이너는 `onTapGesture`로.** `Button`을 중첩하면(전체를 Button으로 감싸고 그 안에 또 Button) 안쪽 제스처가 불안정해진다(NovelDetailFeature에서도 같은 이유로 중첩 Button을 피함). `Button`은 자기 hit-test 영역에서 조상의 `onTapGesture`보다 우선한다 → `WhiteRemovableKeywordChip(keyword:onSelect:onDelete:)`가 이 패턴(X만 `Button`=`onDelete`, 컨테이너 `onTapGesture`=`onSelect`). `onSelect`는 `(() -> Void)? = nil` — 몸통 탭 액션이 필요 없는 호출부(예: `KeywordFeature`의 선택 트레이, X만으로 충분)는 생략하면 된다.
- **`WSSPrivateToggleRow`(`Sources/Toggle/`)는 `FeedFeature`의 "나만 보는 기록"과 `CollectionFeature`의 "나만
  보는 컬렉션"이 같이 쓰는 공개범위 토글 줄이다**(2026-08, #199 — 두 화면이 자물쇠 아이콘+라벨+`WSSToggleButton`을
  완전히 같은 규격(어두운 `wssGray300` 배경, 높이 58, 좌우 패딩 20)으로 손으로 각자 짜고 있어 승격) —
  `label: String`만 화면마다 다르게 받고 나머지(아이콘·색·크기)는 고정이다. **바인딩은 `isOn`을 직접 쓰지
  않고 `Binding(get:set:)`으로 감싸 `set`에서 VM의 `togglePrivate()` 액션을 부르는 패턴**(호출부 둘 다
  동일) — 토글 컴포넌트 자체는 값을 몰라도 되고 정책은 VM의 도메인 엔티티가 갖는다.
- **`WSSNovelSelectRow`(`Sources/NovelCell/`)는 `FeedFeature`의 연결 작품 검색(단일선택)과
  `CollectionFeature`의 작품 추가(다중선택)가 같이 쓰는 작품 검색 결과 행이다**(2026-08, #199,
  `FeedFeature`의 `CreateFeedConnectNovelRow`가 원본) — 단일/다중선택 정책은 이 컴포넌트가 모른다.
  `isSelected`/`action`만 값으로 받고, 그 의미(단일선택은 덮어쓰기·다중선택은 토글)는 호출부(VM)가
  정한다. 승격하며 원본이 쓰던 raw `AsyncImage`를 `WSSNovelCoverImage`로 교체했다(목록 반복 렌더의
  placeholder 번쩍임 방지, 이 문서 상단 `WSSAsyncImage`/`WSSNovelCoverImage` 항목과 동일 이유) — 크기가
  고정(78×105)인 자리라 `aspectRatio` 파라미터 없이 `.frame(width:height:)`로 직접 크기를 준다.
- **`WSSLibraryGridCell`(`Sources/NovelCell/`)는 `LibraryFeature`의 내 서재/타유저 서재 그리드와
  `CollectionFeature`의 "서재에서 추가" 화면이 같이 쓰는 서재류 작품 그리드 셀이다**(2026-08, 원본은
  `LibraryFeature`의 `LibraryGridCell`) — 두 화면의 유일한 차이가 선택 서클 오버레이뿐이라
  `isSelected: Bool?`로 흡수했다. **`nil`이면 선택 UI 자체를 안 그린다**(서재의 순수 열람 그리드),
  값이 있으면 그 상태로 서클(`WSSNovelSelectRow`와 동일 에셋)을 그린다 — "선택 가능 여부"와 "선택
  안 됨" 두 상태를 `Bool` 하나로는 구분 못 해 옵셔널을 썼다. `readingStatus`/`myRating`/`dateText`
  전부 옵셔널 — 있는 것만 자연스럽게 흐르고(1줄 제목이면 별점이 바로 따라옴), 정보 스택 **자체**는
  고정 높이(65)라 `LazyVGrid` 행이 안 어긋난다(`WSSNovelGridCell`과 같은 계약). **`LibraryNovel`
  같은 상위 Entity를 직접 받지 않는다** — `dateText: String?`처럼 이미 포맷된 표시값만 받는다(날짜
  포맷 로직 자체는 아래 `ReadingPeriod.displayText` 참고, 표기는 호출부 몫이라는 이 문서의 기본
  원칙과 동일). 탭 동작도 갖지 않는다(순수 표시 뷰) — 서재는 셀 전체를 `Button`으로, 컬렉션은
  `.onTapGesture`로 감싸는 등 호출부마다 방식이 달라서 강제하지 않는다.
  - `ReadingPeriod.displayText`(`Sources/DomainPresentation/ReadingPeriod+Presentation.swift`)도
    같은 이유로 공용화됐다(원본은 `LibraryFeature`의 `LibraryDateFormatter`) — "yy.MM.dd" 또는
    "yy.MM.dd ~ yy.MM.dd" 표기를 `ReadingPeriod`의 `public` computed property로 노출한다.
    `LibraryFeature`의 `LibraryListCell`(그리드 셀 승격과 무관하게 리스트 모드 전용, `WSSLibraryGridCell`로
    승격 안 됨)도 이 확장을 쓴다 — 날짜 포맷을 새로 필요로 하는 화면은 자체 포매터를 새로 만들지
    말고 이걸 재사용할 것.
- **`WSSNicknameField`(`Sources/TextField/`)는 `OnboardingFeature`의 닉네임 화면과 `UserPageFeature`의 `MyPageEditView`가 같이 쓰는 닉네임 필드다**(2026-08, 두 화면이 손으로 맞추다 드리프트해서 승격) — 글자수 clamp 트랩(로컬 `fieldText` 버퍼 → `text` 반영 2단계, [상위 CLAUDE.md](../../Feature/CLAUDE.md) 주의사항 참고)을 여기 한 곳에서만 처리한다. `WSSSearchBar`와 같은 이유로 `isFocused: FocusState<Bool>.Binding`을 **필수** 파라미터로 받는다(내부 자체 포커스 없음) — 호출부가 "필드 바깥 탭하면 키보드 내리기"를 계속 제어해야 해서다. **도메인(`ProfileDomain.NicknameDraft.ValidationState`)을 모른다** — `isError`/`isSuccess`·캡션(문구+색)을 값으로만 받고 판단은 호출자(VM)가 한다. **캡션 문구는 컴포넌트가 하드코딩하지 않는다** — 두 화면의 워딩이 의도적으로 다르게 유지돼 왔기 때문(1:1 동기화 요구 아님).
  - ⚠️ **`isFocused`는 이 필드 전용 `@FocusState`여야 한다 — 같은 화면의 다른 텍스트필드와 공유하지 말 것**(#178). 배경(gray50→white)·테두리(`wssGray70`)가 포커스 여부(`isFocused.wrappedValue`)로 바뀌는데, 다른 필드와 공유하면 그 다른 필드가 포커스돼도 이 컴포넌트가 함께 화이트/테두리로 반응한다(`MyPageEditView`가 원래 소개글과 하나의 `isKeyboardFocused`를 공유하다 이 문제로 필드별로 분리한 사례 — `UserPageFeature/CLAUDE.md` 참고). "빈 곳 탭하면 키보드 내리기"처럼 여러 필드를 동시에 내리고 싶으면, 필드마다 별도 `@FocusState`를 두고 탭 핸들러에서 전부 `false`로 내릴 것.
- **`WSSLibrarySection`(`Sources/Stat/`)는 관심/보는중/봤어요/하차 4칸 서재 통계 섹션이다**(2026-08-25,
  원본은 `UserPageFeature`의 MyPage·UserPage 로컬 `LibrarySection`) — 처음엔 화면별로 배경·숫자 컬러를
  다르게 넘길 수 있게 파라미터를 열어뒀으나, 두 화면을 완전히 같은 톤(`wssPrimary20`+`wssPrimary100`)
  으로 통일하며 그 파라미터째 없애고 승격했다(사용자 명시 요청) — **색이 고정값이라 화면마다 달라질
  일이 없다는 전제가 승격의 근거**이니, 나중에 다시 화면별로 다른 톤이 필요해지면(승격 이전처럼) 이
  컴포넌트를 그대로 못 쓴다. **도메인 엔티티(`NovelDomain.RegisteredNovelStats`)를 모른다** — `interest`/
  `watching`/`watched`/`quit` 4개 `Int`만 값으로 받고, 엔티티 → 값 매핑(옵셔널 처리 `stats?.interest ?? 0`
  포함)은 호출부(Feature)가 한다(이 문서 상단 "입력은 값/콜백" 원칙, `WSSLibraryGridCell`이 `LibraryNovel`
  을 직접 안 받는 것과 동일 이유).
- **`WSSPillBadge`(`Sources/Button/`)는 "+ 추가"/"× 삭제" 같은 짧은 필 배지다**(2026-08-23, 원본은
  `CollectionFeature`의 `CollectionSearchNovelView` 검색 결과 행) — **이례적으로 두 번째 사용처가 이
  레포에 아직 없는 채로 승격됐다**(사용자 명시 요청, "두 번째 필요 시점에 승격" 관례의 의도적 예외).
  설정 화면의 작품 알림 해제가 곧 두 번째로 쓸 예정이나 그 작업은 다른 미병합 브랜치에 있다.
  ⚠️ **라벨·아이콘은 값으로 안 받는다** — `init(style: .add | .remove, action:)`만 받고, 화면에 보이는
  텍스트("추가"/"삭제")와 아이콘(`icPillBadgePlus`/`icPillBadgeXMark`)은 `Style`이 내부적으로 고정해
  결정한다(호출부가 문구를 바꿀 수 없음). 두 번째 사용처(작품 알림 해제)가 실제로 다른 문구가 필요하면
  **이 컴포넌트를 그대로 못 쓴다** — 그 작업이 실제로 이 컴포넌트를 쓰게 되면 라벨을 값으로 받도록
  API를 넓힐지부터 다시 판단할 것(승격 당시엔 두 번째 사용처의 요구가 확인 전이라 미리 넓혀두지 않았다).
  `action: (() -> Void)? = nil` — `nil`(기본값)이면 순수 표시용(부모 행의 `onTapGesture`가 탭을 받음),
  값을 넘기면 배지 자신이 탭을 받는 단독 액션이 된다(`WhiteRemovableKeywordChip`의 `onSelect`/`onDelete`
  분리와 같은 이유 — `nil`일 때 무조건 `onTapGesture`를 걸면 빈 클로저라도 이 뷰가 탭을 소비해버려
  부모의 `onTapGesture`로 전파되지 않는다). `.remove` 스타일 배경은 `wssSecondary10`(#FFF5F7, 신설) —
  이전엔 이 배지가 `wssSecondary20`(#FFF5FC)을 빌려 쓰고 있었으나, 승격하며 전용 토큰으로 이름을
  확정했다. 다른 콜사이트가 없어 `wssSecondary20` 자체를 제거했다(사용자 확인, 2026-08-23).
