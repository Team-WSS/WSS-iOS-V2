<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDetailFeature

소설 상세(NovelDetail) 화면 — 몰입형 헤더 + 유저 평가 + 탭(정보/피드). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.novelDetail)` / 의존: **전용 `NovelDetailDomain`은 없고 `NovelDomain` + `FeedDomain`(피드 탭)을 쓴다**(#154 명세)
- 진입점: `NovelDetailFactory.makeView(novelID:loadNovelUseCase:novelInterestUseCase:loadNovelFeedsUseCase:logger:onReviewTapped:onCreateFeedTapped:)`
  - **`onReviewTapped(NovelInformation, ReadingStatus)`**: 평가 화면 진입 콜백. status는 평가 초안 seed — 평가 없음/있음 모두 상태바에서 탭한 상태(평가 있음의 칩·여백 탭만 현재 상태). 화면 전환은 호출자(App)가 NovelReviewFactory로 조립.
  - **`onCreateFeedTapped()`**: 피드 작성 진입 콜백 — "나도 한마디" 버튼과 피드 탭 플로팅 버튼이 공유.

## 핵심 시나리오

- **로드**: `LoadNovelUseCase` 1회(`hasLoaded` 가드)로 `NovelInformation` 확보. 피드 목록은 **피드 탭 첫 진입 시 지연 로드**, 이후 `lastFeedID` 커서 페이지네이션(첫 페이지 커서 0).
- **관심 토글**: 정책은 엔티티 `Novel.toggleInterest()`에 위임, UI 낙관 반영 후 서버 실패 시 롤백. `isInterested == nil`(비로그인 등)이면 엔티티가 no-op → 서버 호출도 스킵.
- **정보 탭 조건부 표시**: 매력포인트/키워드/읽기상태그래프는 각각 값 없으면 숨김, 전부 없으면 빈 상태(제목도 "독자들의 평가"로 변경). 그래프 우세 상태·동률 우선순위는 도메인 `dominantReadStatus`가 결정.

## 주의사항 (작업 중 발견 시 누적)

- 대응 `NovelDetailDomain`이 없다 — UseCase는 `NovelDomain`/`FeedDomain` 것을 주입받는다. `new-module` 기본 추론(`domain(.<같은이름>)`)과 다른 지점.
- **`state.novel`을 `state.information.novel`과 분리 보유** — `NovelInformation.novel`이 `let`이라 관심 토글(mutating)을 반영할 수 없어서다. 헤더/관심 버튼은 `state.novel`을 읽는다.
- **몰입형 헤더 = 시스템 네비바 숨김**(`.toolbar(.hidden)`) + 커스텀 고정 오버레이. `icNavigateLeft`/`icThreedots` 에셋은 **원색이 연회색(wssGray100)이라 밝은 배경에서 안 보임** → `renderingMode(.template)`로 색을 입혀야 한다.
- **스크롤 반응형 네비 타이틀**: 조금이라도 스크롤되면 커스텀 네비바에 작품 제목 + 흰 배경을 페이드인한다(`showNavTitle = scrollOffsetY < -1`). iOS 17이라 `onScrollGeometryChange`(18+)는 못 쓴다. **구현·함정(이 조합이 핵심 — 개별로 접근하면 다 실패):**
  - **오프셋 측정은 `GeometryReader` 안에서 `onChange`로 `@State`(`scrollOffsetY`)를 직접 쓴다.** `PreferenceKey`+`onPreferenceChange`를 쓰지 말 것 — ⚠️ **(1) ScrollView는 preference를 바깥 조상으로 안 올려보낸다**(reader를 ScrollView 밖 `content`에 붙이면 값이 안 옴), **(2) 이 SDK에선 `onPreferenceChange`→`@State` 갱신 자체가 안 먹는다**(reader를 ScrollView에 직접 붙여도 상수조차 전달 실패). 이 둘 때문에 preference 경로는 전멸한다. 좌표는 ScrollView의 named coordinate space(`scrollSpaceName`) 기준(`.global`은 스크롤 중 갱신이 안 옴).
  - **투명 네비바라 타이틀엔 함께 페이드인하는 흰 배경이 필수** — 없으면 스크롤되는 본문과 겹쳐 안 읽힌다(뒤로가기/더보기 버튼도 이 배경 덕에 가독). 이 배경은 상태바까지 덮어야 하는데, **안전영역 높이를 읽거나 네비바 높이(44)를 더하지 말 것** — 커스텀 상단 바는 **ZStack 자식이면 이미 안전영역 상단에 붙는다**(UIKit `top.equalTo(safeAreaLayoutGuide)`와 동일, 계산 0). 위로 뚫고 나가야 하는 건 **배경뿐**이고, 그건 네비바의 `.background(Color.wssWhite ... .ignoresSafeArea(edges: .top))`가 알아서 화면 끝까지 확장한다(노치·다이나믹 아일랜드 무관, iPhone SE 20pt / 16 Pro 59pt 실측 확인).
    - ⚠️ `.background`는 **`padding` 뒤에** 붙여야 좌우 끝까지 덮는다(앞에 두면 좌우 여백이 뚫린다).
    - ⚠️ 배경 `Color`엔 **`.allowsHitTesting(false)`** — 없으면 네비바 영역에서 시작하는 드래그가 Color에 먹혀 스크롤이 안 된다(투명 Spacer 영역과 달리 Color는 hit-test 대상).
    - ⚠️ (여전히 유효) **ZStack 안에 중첩된 `GeometryReader`의 `safeAreaInsets.top`은 0으로 보고**된다(상위가 이미 소비) — 안전영역을 *읽어야만* 하는 상황이 오면 루트 `GeometryReader`를 써야 한다. `ignoresSafeArea`는 별개 메커니즘이라 중첩돼도 정상 동작한다.
- **스티키 탭바(정보/피드)**: 스크롤로 탭바가 커스텀 네비바 하단에 닿으면 그 아래에 고정돼 보인다. **`LazyVStack(pinnedViews:)`를 쓰지 말 것** — pin 위치는 ScrollView의 content inset 상단인데 이 화면은 몰입형이라 `.ignoresSafeArea(edges: .top)`이 걸려 있어 **탭바가 상태바 밑(화면 최상단)에 붙어** 네비바와 겹친다. 대신 **오버레이 2벌 방식**: 스크롤 콘텐츠 안 "원본" 탭바는 자리만 유지(스티키 전환 시 콘텐츠 점프 방지)하고, 네비바와 **같은 VStack**에 탭바를 하나 더 그려 조건부로 띄운다(네비바 "바로 아래"가 레이아웃으로 보장 → 스티키 y 계산 불필요).
  - 임계선(네비바 하단 y)은 **안전영역을 읽거나 44를 더하지 않는다** — 이미 `ignoresSafeArea`로 상태바까지 확장된 **네비바 배경의 실측 높이**가 곧 `안전영역 top + 네비바 높이`다. 그래서 배경 `Color`를 `GeometryReader`로 감싸고(**`ignoresSafeArea`는 GeometryReader 쪽에** 붙여야 확장분이 `proxy.size.height`에 잡힌다) 그 높이를 쓴다.
  - 원본 탭바 위치(`tabBarMinY`)는 네비 타이틀과 **같은 방식**으로 잰다(named coordinate space + `GeometryReader` 안 `onChange`). 두 좌표 모두 화면 좌상단 기준이라 그대로 비교(`tabBarMinY <= navigationBarBottomY`).
  - ⚠️ 스티키 탭바는 ScrollView **바깥** 오버레이라 **그 위에서 드래그해도 스크롤되지 않는다**(탭 전환은 정상). 탭바가 얇아 실사용 영향은 작지만, 스크롤이 필요해지면 제스처를 스크롤뷰로 전달하는 별도 처리가 필요하다.
  - **탭 전환 시 화면 튐 → 탭 콘텐츠에 `.frame(minHeight: tabContentMinHeight, alignment: .top)`으로 해결.** 짧은 탭(피드 몇 개)으로 바뀌면 `contentSize`가 줄어 UIScrollView가 `contentOffset`을 스크롤 가능한 최대치로 되돌린다(클램프) → 화면이 위로 튄다. 최소 높이를 **"스티키 상태에서 탭바 아래 남는 화면 영역"**(`스크롤뷰 높이 - 네비바 하단 y - 탭바 높이`)만큼 주면 어떤 탭이든 스티키 지점까지의 스크롤 여유가 남아 클램프가 없다. 피드는 **지연 로드**라 로딩 중 잠깐 비는 순간에도 클램프가 걸리므로 이 최소 높이가 특히 필요하다.
    - ⚠️ 뷰포트 높이를 재는 `GeometryReader`에도 **`ignoresSafeArea(edges: .top)`을 걸어야 한다** — ScrollView는 이미 상태바까지 확장돼 있는데 background의 GeometryReader는 그냥 두면 안전영역 **안쪽** 높이를 보고한다. 그러면 최소 높이가 **딱 안전영역 top만큼**(SE 20pt) 모자라 탭 전환 시 그만큼 덜 붙는다(증상이 미묘해 원인 찾기 어렵다).
- **표지 우하단 장르 코너 뱃지 = `icGenreBackground`(흰 코너 삼각형 71pt) 우하단에 `genre.iconImage`(GenreIcon 방패형)를 `trailing 4 / bottom 5` 인셋으로 얹음.** V1(UIKit) 레이아웃 그대로. 주의: 아이콘은 배경을 꽉 채우지 않고 **32pt**로 코너에 작게 — 71pt로 키우면 틀림. 겹칠 아이콘은 `markImage`(GenreMark)가 **아니다**(헷갈리기 쉬움).
- 빈 상태는 `NovelDetailEmptyView`(화면 전용) — WSSComponent `WSSEmptyView`는 검색 빈 상태 전용(고정 문구+버튼 필수)이라 재사용 불가.
- 피드 셀의 좋아요/threedots/프로필 탭, 드롭다운(오류 제보/평가 삭제) 액션, **스포일러(isSpoiler) 가림 처리**(공용 `WSSFeadView`가 미지원 — 컴포넌트 확장 필요)는 **TODO(#154 범위 밖)** — UI만 배치됨.
- 유저 평가 없음 셀렉터와 있음 상태바는 같은 3분할 레이아웃 — **둘 다 상태별 개별 진입(탭한 상태를 seed)**. 있음은 추가로 박스의 칩·여백을 탭하면 현재 상태로 진입한다(상태 `Button`이 hit-test 우선이라 바깥 `onTapGesture`와 공존 — 중첩 Button은 불안정해 피함).
- **최상단 over-scroll만 제거(하단 bounce는 유지)는 `TopBounceDisabler`(UIViewRepresentable)로 한다.** iOS 17엔 상단만 끄는 SwiftUI modifier가 없고 `.scrollBounceBehavior(.basedOnSize)`는 콘텐츠가 화면보다 짧을 때만 먹혀 상세 화면엔 무의미. `UIScrollView.bounces = false`는 방향 구분이 없어 하단까지 죽는다 → 대신 조상 `UIScrollView`를 찾아 **`contentOffset` KVO로 `y < 0`을 0으로 클램프**(UIKit `scrollViewDidScroll` 클램프와 동일 동작). ⚠️ **delegate를 직접 교체하지 말 것** — SwiftUI가 delegate를 소유·재설정해 충돌한다. ⚠️ 반드시 **스크롤 콘텐츠 내부**(VStack의 `.background`)에 둬야 superview 체인이 UIScrollView에 닿는다 — ScrollView 바깥 background면 못 찾는다.
