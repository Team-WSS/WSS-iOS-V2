<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/UI/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# WSSComponent

웹소소 공용 SwiftUI 컴포넌트 — Alert, Toast, Button, FeedCell, SearchBar 등.

- 식별자: `ModuleType.ui(.wssComponent)` / 의존: SwiftUI, `DesignSystem`, `BaseDomain`

## 패턴

- **오버레이 UI(Alert/Toast)는 `ViewModifier` + `@Binding isPresented` + `View+` 확장**으로 제공. 예: `WSSAlertViewModifier`는 `isPresented`일 때 딤(`Color.black.opacity(0.6)`) + 알럿을 overlay, 전환 애니메이션 포함. 버튼 동작은 `buttonActions: [() -> Void]` 배열로 주입.
- 스타일/타입은 enum으로 분리 (`WSSAlertType`/`WSSAlertStyle`, `WSSToastType`/`WSSToastStyle`).
- 색·폰트는 전부 `DesignSystem` 토큰 사용.

## 주의사항 (작업 중 발견 시 누적)

- **`WSSNovelGridCell`(작품 그리드 셀)의 계약 — "폭은 부모가, 높이는 컴포넌트가"**:
  - ⚠️ **표지 아래 정보 스택은 고정 높이(72)** 다. 제목이 1~2줄로 갈려 자연 높이로 두면 **`LazyVGrid` 행이
    어긋나** 목록이 삐뚤빼뚤해진다(홈·서재 양쪽에서 실제로 겪음). 스택 **안은 자연스럽게 흐르게** 두고
    (1줄 제목이면 작가가 바로 따라옴 — 디자인 의도) 스택 **자체만** 고정한다. 빈 자리를 채우거나 제목을
    2줄로 강제하지 말 것. **높이를 파라미터로 열지 않은 것도 의도** — 폰트·줄 수가 고정이라 값이 흔들리면
    행 정렬이라는 존재 이유가 깨진다.
  - **표지·제목·작가가 같은 폭을 공유한다**(모두 셀 폭). 홈 시안엔 제목만 140(셀 163)이었으나 표지와
    오른쪽 끝이 어긋나 걷어냈다 — **시안 값을 근거로 제목 폭을 다시 좁히지 말 것**.
  - ⚠️ 표지 비율은 **투명 뷰가 잡고 이미지는 overlay로 채운다** — `scaledToFill`인 `WSSNovelCoverImage`에
    직접 `aspectRatio`를 걸면 둘이 충돌해 표지가 좁아진다(실측. `LibraryGridCell`도 같은 형태).
  - 기본 비율 상수가 `public`인 건 스타일이 아니라 **문법 제약**이다 — public `init`의 기본값 표현식은
    private 상수(`Metric`)를 참조할 수 없다.
- 컴포넌트가 아는 도메인은 **`BaseDomain`의 공통 값 타입까지**(`ReadingStatus`, `AttractivePoint`, `NovelGenre`, `SortType`, `KeywordCategory` 등). 이들의 라벨·색·아이콘 매핑을 `Sources/DomainPresentation/`(`+Presentation` 확장, public)에 한곳으로 모아 Feature가 중복 매핑하지 않게 한다. → 그 외 도메인 Entity·Repository나 상위 Feature 모델은 모른다(표시 데이터/콜백만 값으로 받음).
- 특정 화면 전용 **필터용 값 목록**(예: `NovelGenre.myFeedFilter`, 검색 화면 장르 그리드용 `NovelGenre.searchGenre`)도 라벨·색 매핑과 동일하게 `DomainPresentation` 확장에 둔다 — `BaseDomain`은 순수 enum만 갖고 화면별 부분집합/순서는 여기서 정의. `myFeedFilter`와 `searchGenre`는 **의도적으로 다른 순서**의 별개 목록 — 한쪽을 고친다고 다른 쪽까지 맞추지 말 것.
- `KeywordCategory+Presentation`의 아이콘(`icCategoryWorld` 등)은 `AttractivePoint`의 `icAttractiveXxx`와 **다른 에셋**이다 — 이름이 비슷한 "세계관/소재/캐릭터/관계/분위기" 라벨을 공유하지만(매력포인트엔 "필력"이 하나 더 있음) 서로 다른 제품 개념이라 아이콘을 섞어 쓰지 말 것.
- ⚠️ **테두리는 `.stroke`가 아니라 `.strokeBorder`로 그린다.** `.stroke`는 선을 shape 경로의 **중앙**에 그려 `lineWidth 1`이면 0.5pt가 뷰 프레임 **밖**으로 나간다 → 컴포넌트를 `ScrollView`(또는 클립하는 컨테이너) 안에 넣는 순간 그 바깥 절반이 클립돼 **테두리가 한쪽만 얇아지거나 잘려 보인다**(서재 필터 칩·필터 시트 키워드 칩에서 실제 발생, #166). `.strokeBorder`는 `InsettableShape`를 lineWidth만큼 안으로 inset한 뒤 그려 선 전체가 프레임 안에 들어온다 — 컴포넌트는 어디에 놓일지 모르니 **공용 컴포넌트일수록 기본값이 `strokeBorder`**여야 한다. `Capsule`/`RoundedRectangle` 모두 `InsettableShape`라 그대로 바꿔 쓸 수 있다.
- Alert 버튼은 인덱스 기반 `buttonActions` 배열 ↔ 버튼 개수 매칭에 주의.
- **Alert 버튼 탭은 `isPresented`를 자동으로 닫지 않는다**(SwiftUI `.alert`와 다름) — 취소 버튼 포함 **모든 buttonActions가 스스로 표시 상태를 되돌려야** 한다. 안 그러면 알럿이 안 닫힌다.
- **`isPresented`는 그대로 두고 `alertType`만 바뀌는 다단계 알럿**(예: "신고할까요?" 확인 → "신고 접수했습니다" 완료)은 `WSSAlertView`에 `.id(alertType)`를 걸어 뷰 정체성을 갈라야 `.transition`이 실제로 발동한다 — 안 걸면 SwiftUI가 "같은 뷰"로 보고 내용만 즉시 스냅 교체해버려 애니메이션이 없다(`WSSAlertType`을 `Hashable`로 만든 이유). `.animation(value:)`도 `isPresented`뿐 아니라 `alertType` 변화에도 걸어야 이 전환이 애니메이션된다.
- **이미지 + `onTapGesture` 패턴은 접근성 트리에 안 잡힌다**(VoiceOver·UI 자동화 모두) — 탭 가능한 이미지에는 `.accessibilityLabel` + `.accessibilityAddTraits(.isButton)`을 같이 달거나 `Button`을 쓸 것(WSSFeadHeaderView의 프로필·threedots에서 발견).
- **`scaledToFill().frame(...).clipShape(...)`는 그리기만 자르고 hit-test 영역은 스케일된 원본 크기로 남는다** — 프레임보다 세로로 긴 이미지(정사각 이상)면 보이지 않는 터치 영역이 위아래로 넘쳐 **형제 뷰의 버튼 탭을 가로챈다**(WSSFeedImageView가 WSSFeadView 헤더의 프로필·threedots를 죽이던 버그, #154에서 수정). 장식 이미지는 `.allowsHitTesting(false)`, 탭이 필요한 이미지는 clip 뒤 `.contentShape`로 hit 영역을 명시할 것.
- `WSSSearchBar`는 `isFocused: FocusState<Bool>.Binding? = nil`로 외부 포커스 제어를 선택적으로 받는다(기본 nil이면 내부 `@FocusState` 사용). 호출부가 포커스를 직접 제어하려면(자동 포커스, 바깥 탭 시 dismiss 등) 일반 `@State`가 아니라 **자체 `@FocusState` 프로퍼티**를 선언해 그 `$binding`을 넘겨야 한다 — 타입이 `FocusState<Bool>.Binding`이라 `Binding<Bool>`과 호환되지 않는다.
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
