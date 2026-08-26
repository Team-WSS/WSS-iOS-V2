<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedFeature

피드 작성/수정, 상세, 목록(내 피드/소소피드) 화면.

- 식별자: `ModuleType.feature(.feed)` / 의존: `FeedDomain`, `SearchDomain`(작품 태깅 검색 — `CreateFeed`가 `SearchNovelUseCase` 사용), `ProfileDomain`, `SocialDomain`(피드 신고), `BaseDomain`, `Logger`(`SosoFeedViewModel`이 `logger: Logger? = nil` 주입받음)

## 주의사항 (작업 중 발견 시 누적)

- **`CreateFeedConnectNovelSheet`(작품 연결 검색)의 결과 영역은 `searchedNovels`가 아니라
  `CreateFeedViewModel.state.hasSearchedNovel` 플래그로 가른다** — `WSSSearchBar.onSearch`는 제출
  (엔터/검색 버튼)에만 발화하고 타이핑 자체는 매 글자마다 `updateConnectedNovelSearchText`로 바로
  반영된다. `hasSearchedNovel`은 그 액션이 매번 꺼뜨리고 `fetchSearchedNovels(_:)`가 응답을 **실제로
  받은 뒤에만** 켠다 — 시트는 `!hasSearched`면 결과 배열 상태와 무관하게 무조건 빈 화면(흰 배경)이다.
  원래는 `hasSearched`가 시트의 로컬 `@State`였고 검색 **제출 시점**에만 켜졌는데(응답을 기다리지 않고),
  텍스트를 편집해도 끄지 않아 결과를 받은 뒤 재입력하면 직전 결과/결과없음 뷰가 남는 문제가 있었다 —
  `CollectionFeature`의 `AddNovelViewModel`과 같은 패턴으로 VM 소유로 옮기며 고쳤다(`CollectionFeature/CLAUDE.md`
  참고, 정본은 그쪽).
  - ⚠️ **`searchNovelTask`(진행 중 검색 `Task` 프로퍼티)를 완료 시 반드시 `nil`로 되돌려야 한다** —
    안 그러면 `loadMoreSearchedNovels`의 `searchNovelTask == nil` 가드가 첫 검색 이후 영원히 막혀
    무한스크롤이 죽는다(`AddNovelViewModel`이 실제로 겪었던 버그와 동일).
  - 무한스크롤은 `SearchFeature.NormalSearchViewModel`과 동일한 정수 `page`(0부터) 방식 —
    `novelList`가 `LazyVStack`(non-lazy `VStack`이면 전체 행이 한꺼번에 나타나 즉시 연쇄 로드된다)의
    마지막 행 `onAppear`에서 `onLoadMore()`를 부른다.
  - 결과 `ScrollView` 내부(특히 빈 여백)는 상위 `VStack`의 배경 탭 제스처가 안 먹는다(스크롤뷰가 그
    터치를 자기 것으로 가져감) — `novelList`의 `ScrollView` 자신에도 같은
    `.contentShape(Rectangle()).onTapGesture { isSearchFocused = false }`를 직접 걸어야 한다
    (`SearchFeature/CLAUDE.md`의 자동완성 항목과 동일 함정). `.scrollDismissesKeyboard(.immediately)`도
    같이 건다.
  - **`CreateFeedDemoScene`은 Mock 토글이 없다** — `DefaultSearchNovelUseCase` + 실제 dev 서버로만
    동작해서(`CollectionFeature`의 Demo와 달리), 이 시트의 검색/무한스크롤을 시뮬레이터에서 직접
    확인하려면 dev 서버 접근이 필요하다.
- `fetchMyFeeds`/`fetchUserFeeds` 응답(`UserFeedResponse`, FeedData)은 작성자 닉네임/프로필 이미지를 내려주지 않는다(서버 스펙). `SosoFeedViewModel`이 `ProfileDomain.LoadProfileUseCase`로 프로필을 따로 조회해 `TotalFeed.author`를 다시 조립해 채운다(`applying(_:to:)`). `TotalFeed.author`가 `private(set)`이라 직접 mutate 불가 — 공개 `init`으로 새 값을 만들어 교체하는 방식.
- 이 조합 로직 때문에 FeedFeature가 `ProfileDomain`(다른 최상위 도메인)을 직접 의존한다 — Domain 레이어 규칙상 Domain끼리는 `BaseDomain` 외 서로 의존 못 하므로, 이런 두 도메인 조합은 Feature(ViewModel) 레벨에서 한다.
- `MyFeedOption.sortType`은 genres/visibilityType과 달리 필터 시트의 draft→`applyMyFeedFilter` 커밋 흐름을 타지 않는다. `WSSSortButton` 탭이 `.toggleMyFeedSort`로 `state.myFeedOption`을 즉시 갱신하고 바로 재조회한다(시트를 열 필요 없음) — 필터 시트가 열릴 때 draft가 `resetMyFeedFilterDraft`로 이 값도 그대로 복사해가므로 두 경로가 어긋나지 않는다.
- `state.myFeedOption.genres` 기본값은 "전체 선택" UX를 `NovelGenre.allCases`(9개 전부) + `includesUncategorized: true`로 표현한다(연결 작품 없는 내 피드까지 포함). FeedData는 이를 그대로 명시적 장르 필터로 보낼 뿐 정규화하지 않는다 — 카테고리 칩(장르+"그 외")을 전부 해제하면 `MyFeedOption.genres == []`가 되고 FeedData의 `genres.isEmpty ? nil : genres`가 이를 무필터로 해석해 전체 목록이 온다. **이는 의도된 동작**(빈 선택 = 무필터)이라 공개/비공개 체크박스와 달리 최소 1개 선택 가드를 두지 않는다.
- **피드 셀 threedots 드롭다운**(`SosoFeedView.feedMenuContext`)은 `NovelDetailFeature`의 같은 패턴을 참고했지만 좌표공간 태깅 위치가 다르다 — `NovelDetailView`는 몰입형 헤더라 `ScrollView` 자체에 `coordinateSpace(name:)`를 걸고 `ignoresSafeArea`로 화면 최상단과 맞춘다. `SosoFeedView`는 일반 화면(시스템 safe area 존중)이라 그 방식 대신 **루트 `ZStack`에 직접 `coordinateSpace(name: feedMenuSpaceName)`를 건다** — 셀 앵커(`cellTopYs`)와 오버레이(`feedMenuOverlay`)가 같은 루트의 형제이므로 이러면 별도 오프셋 계산 없이 좌표가 바로 맞는다. 이 화면에 몰입형 헤더 같은 걸 얹게 되면 이 가정이 깨지니 재검토할 것.
- 피드 삭제/신고 확인·완료 알럿은 `WSSComponent`의 공용 `WSSAlertType`(`deleteMyFeed`/`reportSpoilerContent`/`reportImproperContent`/`receivedReportSpoilerContent`/`receivedReportImproperContent`) 5종을 그대로 재사용한다 — `NovelDetailFeature`와 동일한 타입을 공유하므로 카피를 바꾸려면 두 Feature 모두에 영향이 간다.
- **탭(내 피드/소소피드)·소소피드 옵션(전체글/추천글)·내 피드 필터(장르/공개여부/정렬) 전환 시 스크롤이 이전 위치에 남는 문제**는 `FeedListSection`의 `ScrollView`에 `.id(scrollIdentity)`를 걸어 해결한다 — `scrollIdentity`는 이 모든 축(탭, 소소피드 옵션, `myFeedOption`의 genres/includesUncategorized/visibilityType/sortType)을 문자열로 합친 값이라 그중 하나라도 바뀌면 SwiftUI가 ScrollView를 "새 뷰"로 취급해 스크롤 오프셋을 버리고 최상단부터 다시 그린다. `state.myFeeds`/`sosoFeeds` 배열은 이미 `.load`(refresh: true)로 새로 교체되므로, 이 `.id()`는 순수하게 "화면(스크롤 위치)"만 리셋하는 역할이다. **새 필터 축을 추가하면 `scrollIdentity`에도 반영해야** 그 축 변경 시에도 스크롤이 리셋된다.
- 피드 셀 좋아요 버튼은 `feedRow`에서 `WSSFeadView`의 `likeButtonTapped`로 `.toggleLike(feed.feedId)`를 발화한다 — 낙관 반영/실패 롤백은 `SosoFeedViewModel.toggleLike`(엔티티 `TotalFeed.toggleLike()` 사용) 참고.
