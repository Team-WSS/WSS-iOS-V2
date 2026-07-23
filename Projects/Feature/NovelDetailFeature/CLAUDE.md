<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDetailFeature

소설 상세(NovelDetail) 화면 — 몰입형 헤더 + 유저 평가 + 탭(정보/피드). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.novelDetail)` / 의존: **전용 `NovelDetailDomain`은 없고** `NovelDomain` + `FeedDomain`(피드 탭·좋아요·삭제) + `NovelReviewDomain`(평가 삭제) + `SocialDomain`(피드 신고)을 쓴다
- 진입점: `NovelDetailFactory.makeView(...)` — UseCase 8종 + 콜백 8종(화면 전환 7 + 인증 1, 파라미터는 코드가 진실)
  - **`onReviewTapped(NovelInformation, ReadingStatus)`**: 평가 화면 진입 콜백. status는 평가 초안 seed — 평가 없음/있음 모두 상태바에서 탭한 상태(평가 있음의 칩·여백 탭만 현재 상태). 화면 전환은 호출자(App)가 NovelReviewFactory로 조립.
  - **`onCreateFeedTapped()`**: 피드 작성 진입 콜백 — "나도 한마디" 버튼과 피드 탭 플로팅 버튼이 공유.
  - **`onAuthorTapped(String)`**: 작가 검색 화면 진입 콜백 — 헤더 작품 정보의 **작가 이름 탭**. 전달값은 탭한 **작가 한 명**의 이름(다작가면 이름별 개별 버튼). 화면 전환은 호출자(App)가 수행 — 단 **작가 검색 화면 Feature·App 라우팅은 아직 미구현(후속)**이라 현재 소비처는 Demo 로그뿐.
  - **`onAuthenticationRequired()`**: 인증 만료(`RepositoryError.authenticationRequired`) 시 로그인 유도 콜백. **화면 내 모든 서버 호출 공통** — VM이 `state.requiresAuthentication` 신호만 세우고(어느 catch에서 발생하든 `presentError`/`loadNovel` 경유 `routeToLoginIfAuthenticationRequired`로 수렴), View가 `onChange`로 소비해 콜백 발화(`shouldDismiss`→`dismiss`와 대칭). 인증 만료면 개별 실패 토스트/실패 뷰 대신 이 신호만 낸다.

## 핵심 시나리오

- **로드**: `LoadNovelUseCase` 1회(`hasLoaded` 가드)로 `NovelInformation` 확보. 피드 목록은 **피드 탭 첫 진입 시 지연 로드**, 이후 `lastFeedID` 커서 페이지네이션(첫 페이지 커서 0).
- **관심 토글**: 정책은 엔티티 `Novel.toggleInterest()`에 위임, UI 낙관 반영 후 서버 실패 시 롤백. `isInterested == nil`(비로그인 등)이면 엔티티가 no-op → 서버 호출도 스킵.
- **정보 탭 조건부 표시**: 매력포인트/키워드/읽기상태그래프는 각각 값 없으면 숨김, 전부 없으면 빈 상태(제목도 "독자들의 평가"로 변경). 그래프 우세 상태·동률 우선순위는 도메인 `dominantReadStatus`가 결정.
  - ⚠️ **"독자들의 감상평" 제목의 소속은 매력포인트·키워드뿐**이다 — 읽기 상태 그래프는 제목을 공유하지 않는 별도 섹션. 그래서 **그래프만 있고 매력포인트·키워드가 다 비면 제목까지 통째로 숨긴다**(`hasReviewContent`). 셋 다 없을 때만 빈 상태(`hasAnyReviewSummary`)라는 점과 헷갈리기 쉽다 — 판정이 **두 단계**인 이유가 이것. 그래프 위 구분선도 감상평이 실제로 있을 때만 그린다(나눌 대상이 없으면 선도 없다).

## Demo 시나리오 (Mock)

Demo 앱의 Mock 모드는 **버튼 하나 = 데이터 조건 하나**다(`DemoScenario`). 화면이 **데이터에 따라 분기하는 지점**만
시나리오로 만든다 — 조건부 섹션·빈 상태·실패 뷰. 필드 하나씩 다른 조합은 버튼만 늘고 볼 게 없어 만들지 않는다.

| 그룹 | 시나리오 | 확인 대상 |
|---|---|---|
| 기본 | 전체 데이터 | 모든 섹션 표시 |
| 내 평가 — 없음 | 내 평가 없음 | 평가 상태바 → 읽기 상태 셀렉터 |
| 내 평가 — 항목 조합 | 읽기 상태만 / 별점+읽기 상태 / 기간+읽기 상태 / 별점+기간+읽기 상태 | 상태바의 별점·기간 **칩이 각각** 나타나고 사라짐 |
| 독자 평가 — 하나만 없음 | 매력포인트 없음 / 키워드 없음 / 읽기 상태 없음 | **그 섹션 하나만** 사라짐 |
| 독자 평가 — 하나만 있음 | 매력포인트만 있음 / 키워드만 있음 / 읽기 상태만 있음 | **그 섹션 하나만** 남음 |
| 독자 평가 — 전부 없음 | 독자 평가 전부 없음 | 감상평 영역 전체가 빈 상태(제목도 "독자들의 평가") |
| 피드 | 피드 없음 / 1개 / 5개 / 15개 / 45개 | 빈 상태 / 셀 하나뿐인 최소 목록 / 페이지네이션 없음(1페이지) / 2페이지 / 5페이지(페이지 크기 10) |
| 극단 | 최소 데이터(신규 작품) | 표지·평점·플랫폼·평가·피드 전부 없음 |
| 실패 | 작품 로드 실패 / 피드 로드 실패 | NetworkErrorView / 빈 상태 대신 실패 문구 |

- 시나리오는 `userReviewParts`(`Set<UserReviewPart>?`) / `readerReviewParts`(`Set<ReaderReviewPart>`) / `feedCount`(`Int` — 0이면 빈 상태, 페이지 크기 10 기준으로 페이지 수가 갈린다) **축**으로 표현하고 Mock UseCase 둘이 그 축만 읽는다 — 새 조건을 넣을 땐 축(또는 집합의 원소)을 늘리지, `if scenario == ...` 분기를 Mock 곳곳에 흩뿌리지 말 것.
- ⚠️ **`userReviewParts`는 옵셔널 집합** — `nil`(평가 자체가 없음 → 셀렉터)과 `[]`(평가는 있고 **읽기 상태만** 있음 → 칩 없는 상태바)는 **다른 화면**이다. 읽기 상태는 평가가 존재하면 반드시 있으므로 축에 넣지 않는다(그래서 "읽기 상태만" = 빈 집합).
- ⚠️ **기간(`ReadingPeriod`)은 읽기 상태에 따라 채워지는 날짜가 다르다** — 보는 중=**시작일만**, 봤어요=시작+종료, 하차=**종료일만**(시작일 없음 → 표기가 `~ 26. 06. 11`). 이 규칙은 도메인 `ReadingPeriod.normalized(for:)`가 강제하므로 **Mock/테스트 데이터가 흉내내지 말고 그 함수를 태울 것** — 직접 `ReadingPeriod(start:end:)`로 만들면 상태와 모순된 데이터(하차인데 시작일 있음)가 나온다.
- **독자 평가 3요소(매력포인트·키워드·읽기 상태)는 각각 독립** — 하나만 비면 그 섹션만 숨고, 셋이 다 비어야 감상평 영역이 빈 상태로 대체된다. 그래서 "하나만 없음"·"하나만 있음"·"전부 없음"을 각각 별도 시나리오로 둔다. 요소별 Bool 프로퍼티 3개 대신 **채울 부분의 집합** 하나(`readerReviewParts`)로 표현해, 조합이 늘어도 그 switch 한 곳만 고치면 되게 했다.
- ⚠️ **평점 없음은 `rating: nil`이 아니라 `rating: 0` + `ratingCount: 0`** — `Novel.rating`은 non-optional `Float`다.
- ⚠️ **연재중 케이스는 `.onGoing`** (`.serial` 아님 — `NovelPublicationStatus`).

## 주의사항 (작업 중 발견 시 누적)

- 대응 `NovelDetailDomain`이 없다 — UseCase는 `NovelDomain`/`FeedDomain` 것을 주입받는다. `new-module` 기본 추론(`domain(.<같은이름>)`)과 다른 지점.
- **`state.novel`을 `state.information.novel`과 분리 보유** — `NovelInformation.novel`이 `let`이라 관심 토글(mutating)을 반영할 수 없어서다. 헤더/관심 버튼은 `state.novel`을 읽는다.
- **헤더 메타 줄(장르·연재상태·작가)은 작가만 개별 밑줄 버튼이라 단일 `Text`로 못 합치고 `HStack`으로 분해**(`NovelDetailHeaderView.metaRow`) — 앞부분(`nonAuthorMetaText`=장르·연재상태)은 한 `Text`, 작가는 이름마다 `Button`, 구분자(`  ·  `/`, `)는 **비탭 `Text`**. 작가 `Text`엔 `.underline()`을 **raw Text에 먼저** 걸고 `applyWSSFont`를 뒤에 붙여야 밑줄이 렌더된다(순서 반대면 무증상 실패 — [[DesignSystem]] 주의사항 참고). 탭 영역은 작가 글자에만 국한(구분자 제외)됨을 diagnostic 배경으로 실측 확인.
- **몰입형 헤더 = 시스템 네비바 숨김**(`.toolbar(.hidden)`) + 커스텀 고정 오버레이. `icNavigateLeft`/`icThreedots` 에셋은 **원색이 연회색(wssGray100)이라 밝은 배경에서 안 보임** → `renderingMode(.template)`로 색을 입혀야 한다.
  - ⚠️ **네비바를 숨기면 밀어서 뒤로가기(`interactivePopGestureRecognizer`)까지 iOS가 함께 꺼버린다** — 뒤로가기가 버튼으로만 되던 이유. `SwipeBackEnabler`(UIViewRepresentable)가 조상 `UINavigationController`를 responder chain으로 찾아 제스처를 다시 켠다. **superview 체인으론 뷰컨트롤러에 못 닿는다**(SwiftUI 뷰는 hosting VC의 child) → `next` responder를 타야 한다(같은 파일 `TopBounceDisabler`가 UIScrollView를 찾을 때 쓰는 superview 체인과 다른 점).
    - ⚠️ **제스처 delegate를 `nil`로 비우지 말 것** — 루트 화면에서도 제스처가 발화해 pop 대상이 없는데 전환이 시작되고 **내비게이션이 얼어붙는다**. Coordinator가 delegate를 맡아 `viewControllers.count > 1`일 때만 시작시킨다. (delegate는 약한 참조라 Coordinator가 살아 있어야 한다.)
    - `updateUIView`마다 다시 거는 건 의도 — 다른 화면을 다녀오며 네비바 숨김이 재적용되면 제스처가 도로 꺼질 수 있다.
    - ⚠️ **이 제스처는 시뮬레이터 자동화로 검증할 수 없다** — XcodeBuildMCP `gesture(swipe-from-left-edge)`는 화면 가장자리 pan을 트리거하지 못하고(delegate의 `shouldBegin`이 아예 안 불림), CGEvent로 HID 마우스를 주입하는 우회로도 손쉬운 사용 권한이 없어 막힌다(탭조차 전달 안 됨). **사람이 직접 밀어서 확인**해야 한다.
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
- **헤더 상단 인셋은 디자인 고정값(99)이 아니라 실측 `navigationBarBottomY`를 넘겨 쓴다** — 99 = 상태바 54 + 네비 44로, 안전영역이 다른 기기(SE 20 / 16 Pro 59)에선 표지가 네비바에서 뜨거나 겹친다. ⚠️ **헤더 배경(backdrop) 높이도 같은 인셋에 묶어야 한다**(`topInset + 표지 217 + 14`) — 디자인의 330은 "표지 아래 14pt에서 회색으로 전환"을 뜻하는 파생값이라, 표지만 인셋을 따라가고 배경을 330으로 고정하면 안전영역이 작은 기기에서 **제목이 회색이 아닌 블러 보라 배경 위로 올라온다**.
- **표지 우하단 장르 코너 뱃지 = `icGenreBackground`(흰 코너 삼각형 71pt) 우하단에 `genre.iconImage`(GenreIcon 방패형)를 `trailing 4 / bottom 5` 인셋으로 얹음.** V1(UIKit) 레이아웃 그대로. 주의: 아이콘은 배경을 꽉 채우지 않고 **32pt**로 코너에 작게 — 71pt로 키우면 틀림. 겹칠 아이콘은 `markImage`(GenreMark)가 **아니다**(헷갈리기 쉬움).
- **Demo 실서버 모드는 토글 시 `syncKeywords()`를 직접 호출**한다 — 작품 상세의 키워드 매핑이 파일 캐시(keywords.json)만 읽는데, 실제 앱에선 App(DI)이 시작 시 채울 캐시를 Demo는 스스로 채워야 해서다. 안 부르면 캐시 없는 시뮬레이터에서 키워드 섹션이 통째로 빈다(에러 없이 조용히).
- **플랫폼 아이콘 URL은 래스터(png)여야 한다** — `AsyncImage`(UIImage)는 **런타임 다운로드 SVG를 디코딩 못 해** SVG URL이면 조용히 placeholder만 남는다(에셋 카탈로그 번들 SVG만 지원되는 iOS 제약).
- 빈 상태는 `NovelDetailEmptyView`(화면 전용) — WSSComponent `WSSEmptyView`는 검색 빈 상태 전용(고정 문구+버튼 필수)이라 재사용 불가.
- 피드 셀의 **스포일러(isSpoiler) 가림 처리**와 **나만 보는 글(isPublic=false) 표기**(공용 `WSSFeadView`가 둘 다 미지원 — 컴포넌트 확장 필요)는 **TODO(#154 범위 밖)** — 데이터(`TotalFeed.isSpoiler`/`isPublic`)는 매핑돼 흐르지만 UI 미반영. 실서버 작품 1의 피드들이 `isSpoiler: true`인데 본문이 그대로 노출된다.
- **피드 셀 인터랙션**: 셀 탭=피드 상세 콜백, 프로필 영역(이미지+닉네임) 탭=유저 프로필 콜백(**내 글이면 차단** — `isMyFeed`), 좋아요=엔티티 `TotalFeed.toggleLike()` 낙관 반영+실패 롤백(셀별 병행 허용, 같은 셀 연타만 가드), threedots=셀 드롭다운(**내 글: 수정하기 콜백·삭제하기, 남의 글: 신고 2종 빨강** — Figma 6773-26280/26272). 드롭다운은 화면 레벨 오버레이로 띄우고 앵커는 **셀 y 실측**(네비 타이틀과 같은 스크롤 좌표공간 방식) + threedots 오프셋(52)으로 계산, 하단 셀에선 화면 안에 다 보이게 클램프. ⚠️ 앵커가 화면 최상단(상태바 포함) 기준이라 **오버레이 ZStack에 `ignoresSafeArea(edges: .top)` 필수** — 빼면 메뉴가 안전영역 높이만큼 내려앉는다.
  - ⚠️ **위 "좋아요" 설명은 현재 UI까지는 안 이어진다** — `WSSFeadView`가 좋아요 상태/콜백을 받는 파라미터가 없어 내부에서 `isLiked: true, likeButtonTapped: { print(...) }`로 하드코딩돼 있다(WSSComponent 쪽 리팩터의 부작용, [[WSSComponent]] CLAUDE.md 참고). `NovelDetailFeedTab`이 넘기는 `onToggleLike`는 현재 어디에도 연결되지 않는 죽은 프로퍼티다 — `WSSFeadView`가 해당 파라미터를 받도록 확장돼야 다시 이어진다.
- **피드 삭제/신고는 2단 알럿 하나의 의미값(`FeedAlert`)으로 관리** — 삭제는 확인 알럿 → `DeleteFeedUseCase` → 목록 제거 + **상세 재로드**(헤더 피드 수 등 집계 동기화, 성공 토스트 없음 — 디자인에 없음). 신고는 확인 알럿 → SocialDomain UseCase → **접수 완료 알럿으로 전환**(문구가 종류별로 달라 완료 케이스 분리). 알럿 타입·버튼 매핑(WSSAlertType 5종)은 View가 한다.
- **화면 드롭다운(오류 제보/평가 삭제)**: 오류 제보는 노션 문의 페이지를 외부 브라우저로 연다(`errorReportURL`). 평가 삭제는 알럿 확인 후 `DeleteNovelReviewUseCase`(NovelReviewDomain) → **성공 시 상세 재로드**(키워드·읽기 상태 집계가 함께 바뀌므로 화면 데이터를 서버와 재동기화). 삭제할 평가가 없으면 VM이 무시(관심 토글 no-op과 같은 정책).
- 유저 평가 없음 셀렉터와 있음 상태바는 같은 3분할 레이아웃 — **둘 다 상태별 개별 진입(탭한 상태를 seed)**. 있음은 추가로 박스의 칩·여백을 탭하면 현재 상태로 진입한다(상태 `Button`이 hit-test 우선이라 바깥 `onTapGesture`와 공존 — 중첩 Button은 불안정해 피함).
- **대형 표지 오버레이(표지 탭)**: dim(`wssBlack60`)의 `onTapGesture`와 확대 표지를 ZStack **형제**로 두면 표지 위 탭은 자연히 무시된다(제스처는 형제 뷰에 안 닿음 — V1의 표지 탭 no-op과 동일 동작, 별도 처리 불필요). 확대 크기는 `scaledToFit` + 패딩(가로 20 / 세로 60 = X 버튼 44 + 여유)이 V1의 "두 여백 중 먼저 걸리는 기준" 비율 분기 계산을 대체한다.
  - ⚠️ **오버레이 안에서 `AsyncImage`를 쓰지 말 것** — URLCache 캐시 히트여도 **새 인스턴스는 `.empty` phase부터 시작**해 placeholder가 한 프레임 이상 번쩍이고, 오버레이는 열 때마다 뷰가 재생성되므로 매번 반복된다. 대신 화면 로드 시 `URLSession.shared`(URLCache 공유 — 헤더가 이미 받은 응답이면 재다운로드 없음)로 `UIImage`를 **prefetch해 동기로 그린다**(영상 프레임 검증: 오버레이 첫 프레임부터 실제 표지).
  - clip·그림자는 컨테이너가 아니라 **핏된 이미지 자신에** 걸 것 — 컨테이너 크기가 핏 결과와 어긋나면 이미지 주변 탭이 dim에 안 닿는 dead zone 위험. X 아이콘 `icCancelModal`도 원색이 회색(#52515F)이라 dim 위에선 template + 흰색 틴트 필요(네비바 아이콘과 같은 함정).
- **최상단 over-scroll만 제거(하단 bounce는 유지)는 `TopBounceDisabler`(UIViewRepresentable)로 한다.** iOS 17엔 상단만 끄는 SwiftUI modifier가 없고 `.scrollBounceBehavior(.basedOnSize)`는 콘텐츠가 화면보다 짧을 때만 먹혀 상세 화면엔 무의미. `UIScrollView.bounces = false`는 방향 구분이 없어 하단까지 죽는다 → 대신 조상 `UIScrollView`를 찾아 **`contentOffset` KVO로 `y < 0`을 0으로 클램프**(UIKit `scrollViewDidScroll` 클램프와 동일 동작). ⚠️ **delegate를 직접 교체하지 말 것** — SwiftUI가 delegate를 소유·재설정해 충돌한다. ⚠️ 반드시 **스크롤 콘텐츠 내부**(VStack의 `.background`)에 둬야 superview 체인이 UIScrollView에 닿는다 — ScrollView 바깥 background면 못 찾는다.
