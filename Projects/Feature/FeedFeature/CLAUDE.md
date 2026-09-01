<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedFeature

피드 작성/수정, 상세, 목록(내 피드/소소피드) 화면.

- 식별자: `ModuleType.feature(.feed)` / 의존: `FeedDomain`, `SearchDomain`(작품 태깅 검색 — `CreateFeed`가 `SearchNovelUseCase` 사용), `ProfileDomain`, `SocialDomain`(피드 신고), `BaseDomain`, `Logger`(`SosoFeedViewModel`이 `logger: Logger? = nil` 주입받음)

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **댓글 입력은 반드시 `CommentDraft.maxContentCount`(500)로 clamp한다** — `CommentDraft.init`이 DEBUG에서
  초과 시 `assertionFailure`로 죽는다. `FeedDetailView`가 로컬 `@State commentDraft` 버퍼 + `.onChange` 2단계
  (clamp → 초과면 로컬 재대입 / 아니면 VM 전달)로 처리한다([상위/UserPageFeature CLAUDE.md]의 글자수 제한
  TextField 함정과 동일 패턴, #222 복원). 전송 버튼 활성(`FeedDetailCommentInputBar.isSendEnabled`)은 "비어있지
  않고 수정 모드면 원본과 다름"을 View(`isCommentSendEnabled`)가 계산해 넘긴다 — 무변경 재전송 가드.
- **댓글 작성/수정/삭제·피드 삭제 실패는 조용히 삼키지 않는다**(#222 회귀 복원) — `FeedDetailViewModel`이
  `isActionFailedToastPresented`로 `WSSToastType.networkDelay` 토스트를 띄우고, 전송 실패 시 입력 내용·수정
  모드를 보존해 재시도하게 한다(성공했을 때만 입력 비우고 목록 재조회). `create/editComment`가 성공 여부를
  `Bool`로 돌려주는 이유. "사용자 액션 실패"라 전면 뷰가 아니라 토스트([상위 CLAUDE.md] 로드 실패 표현 계약).
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
  - **피드 상세 데모는 씬이 둘이다** — `FeedDetailDemoScene`은 실서버(`NetworkingClient` + 토큰)로만
    떠서 네트워크가 막힌 시뮬레이터/샌드박스에선 화면 자체가 안 뜬다. `FeedDetailMockDemoScene`은
    mock UseCase 12개를 주입해 **dev 서버 없이** 상세를 띄우고, create/edit/delete UseCase가 일부러
    `throw .networkUnavailable`해 **조용한 실패 토스트·입력 보존(#222 #1)** 을 재현한다. `currentUserID`를
    피드·댓글 작성자와 같은 값(2)으로 둬 "내 글/내 댓글"이 되므로 수정/삭제 드롭다운·**전송 게이트(#3)**
    도 확인할 수 있다(`FeedDetailView`의 `#Preview` mock을 데모 타깃으로 승격한 형태).
- `fetchMyFeeds`/`fetchUserFeeds` 응답(`UserFeedResponse`, FeedData)은 작성자 닉네임/프로필 이미지를 내려주지 않는다(서버 스펙). `SosoFeedViewModel`이 `ProfileDomain.LoadProfileUseCase`로 프로필을 따로 조회해 `TotalFeed.author`를 다시 조립해 채운다(`applying(_:to:)`). `TotalFeed.author`가 `private(set)`이라 직접 mutate 불가 — 공개 `init`으로 새 값을 만들어 교체하는 방식.
- 이 조합 로직 때문에 FeedFeature가 `ProfileDomain`(다른 최상위 도메인)을 직접 의존한다 — Domain 레이어 규칙상 Domain끼리는 `BaseDomain` 외 서로 의존 못 하므로, 이런 두 도메인 조합은 Feature(ViewModel) 레벨에서 한다.
- `MyFeedOption.sortType`은 genres/visibilityType과 달리 필터 시트의 draft→`applyMyFeedFilter` 커밋 흐름을 타지 않는다. `WSSSortButton` 탭이 `.toggleMyFeedSort`로 `state.myFeedOption`을 즉시 갱신하고 바로 재조회한다(시트를 열 필요 없음) — 필터 시트가 열릴 때 draft가 `resetMyFeedFilterDraft`로 이 값도 그대로 복사해가므로 두 경로가 어긋나지 않는다.
- `state.myFeedOption.genres` 기본값은 "전체 선택" UX를 `NovelGenre.allCases`(9개 전부) + `includesUncategorized: true`로 표현한다(연결 작품 없는 내 피드까지 포함). FeedData는 이를 그대로 명시적 장르 필터로 보낼 뿐 정규화하지 않는다 — 카테고리 칩(장르+"그 외")을 전부 해제하면 `MyFeedOption.genres == []`가 되고 FeedData의 `genres.isEmpty ? nil : genres`가 이를 무필터로 해석해 전체 목록이 온다. **이는 의도된 동작**(빈 선택 = 무필터)이라 공개/비공개 체크박스와 달리 최소 1개 선택 가드를 두지 않는다.
- **피드 셀 threedots 드롭다운**(`SosoFeedView.feedMenuContext`)은 `NovelDetailFeature`의 같은 패턴을 참고했지만 좌표공간 태깅 위치가 다르다 — `NovelDetailView`는 몰입형 헤더라 `ScrollView` 자체에 `coordinateSpace(name:)`를 걸고 `ignoresSafeArea`로 화면 최상단과 맞춘다. `SosoFeedView`는 일반 화면(시스템 safe area 존중)이라 그 방식 대신 **루트 `ZStack`에 직접 `coordinateSpace(name: feedMenuSpaceName)`를 건다** — 셀 앵커(`cellTopYs`)와 오버레이(`feedMenuOverlay`)가 같은 루트의 형제이므로 이러면 별도 오프셋 계산 없이 좌표가 바로 맞는다. 이 화면에 몰입형 헤더 같은 걸 얹게 되면 이 가정이 깨지니 재검토할 것.
- 피드 삭제/신고 확인·완료 알럿은 `WSSComponent`의 공용 `WSSAlertType`(`deleteMyFeed`/`reportSpoilerContent`/`reportImproperContent`/`receivedReportSpoilerContent`/`receivedReportImproperContent`) 5종을 그대로 재사용한다 — `NovelDetailFeature`와 동일한 타입을 공유하므로 카피를 바꾸려면 두 Feature 모두에 영향이 간다.
- **탭(내 피드/소소피드)·소소피드 옵션(전체글/추천글)·내 피드 필터(장르/공개여부/정렬) 전환 시 스크롤이 이전 위치에 남는 문제**는 `FeedListSection`의 `ScrollView`에 `.id(scrollIdentity)`를 걸어 해결한다 — `scrollIdentity`는 이 모든 축(탭, 소소피드 옵션, `myFeedOption`의 genres/includesUncategorized/visibilityType/sortType)을 문자열로 합친 값이라 그중 하나라도 바뀌면 SwiftUI가 ScrollView를 "새 뷰"로 취급해 스크롤 오프셋을 버리고 최상단부터 다시 그린다. `state.myFeeds`/`sosoFeeds` 배열은 이미 `.load`(refresh: true)로 새로 교체되므로, 이 `.id()`는 순수하게 "화면(스크롤 위치)"만 리셋하는 역할이다. **새 필터 축을 추가하면 `scrollIdentity`에도 반영해야** 그 축 변경 시에도 스크롤이 리셋된다.
- 피드 셀 좋아요 버튼은 `feedRow`에서 `WSSFeadView`의 `likeButtonTapped`로 `.toggleLike(feed.feedId)`를 발화한다 — 낙관 반영/실패 롤백은 `SosoFeedViewModel.toggleLike`(엔티티 `TotalFeed.toggleLike()` 사용) 참고.
- **셀 탭(좋아요·프로필·연결 작품·threedots 등 안쪽 인터랙션 제외) → 피드 상세 진입은 `onFeedTapped: (FeedID) -> Void`**(기본값 `{ _ in }`, `makeSosoFeedView`/`SosoFeedView` 양쪽에 있음, #196에서 추가) — `FeedListSection`의 `.onTapGesture`가 호출한다. 프로필 탭(`onUserProfileTapped: (UserID) -> Void`, `Author.userId`가 nil이면 호출 안 함)·연결 작품 배너 탭(`onNovelTapped: (NovelID) -> Void`)도 같은 방식(파라미터 + `{ _ in }` 기본값)으로 뚫려 있다(#196).
  - **내 글이면 프로필 탭 자체가 비활성화된다** — `feedRow`가 `WSSFeadView`에 `isProfileTappable: !feed.isMyFeed`를 넘긴다(내 프로필로 "이동"할 곳이 없어서, #196). 탭이 죽은 영역이 되는 게 아니라 그대로 행의 나머지 영역과 동일하게 피드 상세 진입으로 흘러간다 — 구현 방식은 `WSSComponent/CLAUDE.md`의 `isProfileTappable` 항목 참고. 소소피드 탭에 내 글이 섞여 나오는 경우(전체글/추천글)도 `feed.isMyFeed` 기준이라 탭과 무관하게 항상 맞게 적용된다.
  - ⚠️ **`FeedDetailView`(피드 상세, 목록과는 별개 화면)의 프로필 탭은 #197까지 `print`만 찍는 죽은 버튼이었다** — `makeSosoFeedView`가 처음부터 `onUserProfileTapped`를 가졌던 것과 달리, `makeFeedDetailView`엔 그 파라미터 자체가 없었다(사용자 리포트로 발견, 2026-08-28). 이제 `FeedDetailView`/`makeFeedDetailView` 둘 다 `onUserProfileTapped: (UserID) -> Void = { _ in }`를 받고, `viewModel.isMyFeed`로 `isProfileTappable`을 계산해 `WSSFeadHeaderView`에 넘긴다 — 목록 화면과 동일한 계약이 됐다. 이 화면에 새 콜백형 진입점을 추가할 때 "Factory에 파라미터가 있다고 View까지 실제로 쓰는 건 아니다"를 전제로 짝을 맞춰 확인할 것.
  - ⚠️ **탈퇴 유저(`Author.userId == -1`) 판정은 `guard let userId = author.userId`(nil 체크)가 아니라
    `BaseDomain.Author.accessibleUserId`를 쓴다**(#197 후속, 2026-08-28) — 매퍼가 서버 `Int`를 항상
    `UserID`로 감싸 `userId`가 nil이 될 일이 없어, `SosoFeedView`/`FeedDetailView` 둘 다 nil 체크만
    하던 시절엔 죽은 가드였다(실제 탈퇴 유저는 `userId == -1`로 통과해버림). 이제 두 화면(+댓글) 모두
    `accessibleUserId`가 nil이면 이동 대신 `WSSToastType.unknownUser`("웹소소를 떠난 유저예요") 토스트를
    띄운다 — `SosoFeedViewModel`/`FeedDetailViewModel`에 각각 `isUnavailableUserToastPresented` +
    `userProfileUnavailableTapped`/`dismissUnavailableUserToast` 액션 쌍이 있다. `-1` 리터럴을 View에서
    다시 비교하지 말 것 — 센티널은 `Author` 안에 캡슐화돼 있다(`BaseDomain/CLAUDE.md` 참고).
- **`CommentRow`(`Sources/Comment/`)는 `userID: Int` 저장 프로퍼티 대신 `profileImageTapped: () -> Void`
  콜백만 받는다**(#197 후속, 2026-08-28 — 원래 `userID`는 표시에 안 쓰이고 죽은 `print` 안에서만 쓰였다).
  탈퇴 유저 판정(`Author.accessibleUserId`)은 호출자(`FeedDetailView`)가 하고 이 컴포넌트는 Domain 타입을
  모른다. **차단(blocked)/숨김(hidden) 댓글은 프로필 탭 자체를 비활성화한다**(내 댓글과 동일 취급, 사용자
  확정) — 두 상태에선 닉네임 자체가 "차단한 유저"로 가려져 나오는데 탭만 살아있으면 어색해서다.
  - ⚠️ **행 컨테이너는 `simultaneousGesture`가 아니라 평범한 `onTapGesture`다.** 프로필(`WSSFeadHeaderView`)·좋아요(`WSSFeedReactView`)가 안쪽 `Button`으로 승격되기 전엔 그 둘이 `onTapGesture`라 행의 "피드 상세 진입"을 `simultaneousGesture`로 걸 수밖에 없었는데, `simultaneousGesture`는 조상·자손을 **동시에** 발화시켜(하나가 이기는 구조가 아님) 프로필/좋아요를 눌러도 피드 상세로 같이 넘어가는 버그가 있었다(그 자리가 원래 no-op placeholder라 안 드러났다가 실제 콜백을 연결하며 드러남). 지금은 셀 안 서브 액션이 전부 진짜 `Button`이라 `Button`이 조상의 평범한 `onTapGesture`보다 우선한다 — 새 서브 액션을 이 화면에 추가할 땐 `onTapGesture`가 아니라 `Button`으로 만들 것(자세한 이유는 `WSSComponent/CLAUDE.md` 참고).
- **우상단 연필 아이콘 → 피드 작성 진입은 `onCreateFeedTapped: () -> Void`**(기본값 `{}`, `makeSosoFeedView`/`SosoFeedView` 양쪽, #196에서 추가) — `FeedTabSection`의 `Button(action: onCreateFeedTapped)`가 호출한다. 호출자(App)가 `makeCreateFeedView`를 조립해 push/present한다.
- **`FeedFeatureFactory.makeCreateFeedView(connectedNovel: ConnectedNovel? = nil)`**(#197) — 작품 상세의
  "나도 한마디"/피드 탭 플로팅 버튼처럼 **이미 어떤 작품을 보고 있는 채로 작성 화면에 들어가는 경로**를
  위한 파라미터다. 값이 있으면 초기 draft(`FeedFeatureFactory.emptyDraft(connectedNovel:)`)가 그 작품이
  이미 연결된 상태로 시작한다 — `CreateFeedConnectNovelSheet`로 나중에 연결하는 흐름과 달리 화면이 뜨는
  시점부터 연결돼 있다. 우상단 연필 아이콘처럼 특정 작품 맥락이 없는 진입점은 `nil`(기본값)을 그대로 둔다.
- **`onSubmitted()`**(#236, `makeCreateFeedView`/`makeEditFeedView` 공통, 기본 no-op) — 작성/수정 제출
  **성공**으로 닫힐 때 dismiss 직전 발화(취소로 닫힐 땐 안 부른다 — `.submitted` 전이에서만). "작성 완료!"
  토스트는 이 화면이 dismiss되므로 App의 크로스스크린 피드백 채널이 복귀 화면 위에 띄운다(V1 `feedEdited`
  알림 parity — V1처럼 작성·수정 모두 발화한다).
- **"수정" 계열 드롭다운(피드 상세 "수정"·목록 셀 "수정하기")은 전부 대상 `FeedID`만 콜백으로 넘긴다**(`onEditFeedTapped: (FeedID) -> Void`) — 이전 화면에서 데이터를 미리 준비하지 않고, App이 `FeedDetailAssembly.makeEditFeedView(feedID:dependencies:)`로 곧장 화면을 전환한다(#197, 빠른 전환 우선 — "누르자마자 로딩 화면이 잠깐 보였다 수정 화면으로 또 전환"되는 이전 방식은 화면이 두 번 깜빡여 UX상 되돌렸다). 실제 로드는 `CreateFeedViewModel` 자신이 한다(아래 항목).
- **`CreateFeedViewModel`은 `mode == .edit`이면 `.load`(View `onAppear`) 시 스스로 대상 피드를 불러온다** — `loadFeedDetailUseCase: LoadFeedDetailUseCase?`(작성 모드에선 `nil`)로 `FeedDetail`을 조회하고, 첨부 이미지는 URL만 있어(서버가 바이트를 안 돌려줌) `URLSession`으로 미리 받아 `draft`/`attachedImageDatas`를 채운다(`loadForEdit`, 서버 수정 API가 전체 교체 방식이라 기존 이미지를 유지하려면 필요 — `FeedDomain/CLAUDE.md`의 `EditFeedUseCase` 항목 참고). 로드 중엔 `state.isLoadingForEdit`로 `CreateFeedView`가 로딩 오버레이 + `allowsHitTesting(false)`를 걸어 **사용자가 로드 완료 전에 draft를 건드릴 수 없게 막는다** — 이 가드가 없으면 로드가 사용자의 진행 중 편집을 덮어쓸 수 있다. `hasLoadedForEdit` 가드로 재진입 시 재요청하지 않는다.
  ⚠️ **`.load`가 스폰하는 `Task`는 `[weak self]`로 감싼다**(#197 PR 리뷰에서 발견 — 처음엔 강한 캡처였다) — 없으면 화면이 로드 완료 전에 닫혀도 `Task`가 VM을 계속 붙잡고 있다가 완료 시점에 이미 죽은 화면의 `state`에 쓰게 된다. `CollectionFeature.CreateCollectionViewModel.loadForEdit`(동일 패턴이라 서로 참조하는 사이)가 처음부터 이 가드를 갖고 있었다 — 두 화면 중 하나만 고칠 게 아니라 앞으로도 짝을 맞출 것.
- ⚠️ **`CreateFeedViewModel`의 `draft.attachedImages`와 `attachedImageDatas`는 키가 어긋나도 에러 없이 조용히 이미지가 빠진다** — 제출 시 `draft.attachedImages.compactMap { state.attachedImageDatas[$0] }`(`CreateFeedViewModel.swift`)로 매핑하는데, `compactMap`이라 `attachedImages`의 `AttachedImageID`가 `attachedImageDatas`에 없으면 그 이미지만 매핑에서 빠지고 나머지는 정상 제출된다(크래시도, 로그도 없음). `loadForEdit`은 같은 루프에서 `draft.addImage(id)`와 `attachedImageDatas[id] = data`를 1:1로 채워 이 함정을 피한다 — 두 값을 채우는 새 코드를 추가할 땐 같은 방식으로 짝지어 채울 것.
- **`CreateFeedView`는 `submitState == .submitted`가 되면 `.onChange`로 자동 `dismiss()`한다**(작성·수정 공용, #197) — 제출 완료 후 사용자가 직접 뒤로가기를 누를 필요가 없다. 작성/수정 모드를 구분하지 않는 이유는 `submitState`가 두 모드가 공유하는 단일 상태라서다.
- **작성/수정 성공 시 앱스토어 평점 요청**(#221 재도입) — `CreateFeedViewModel.submit()` 성공(`state.submitState = .submitted`) 직후 `recordEngagementAndGateReview()`가 `AppReviewRequestUseCase`(BaseDomain, 감상평과 **공유** → 앱 전역 게이트)에 참여를 기록하고, 게이트(누적 참여 ≥ 임계치 AND 이번 버전 미요청)를 통과하면 `state.shouldRequestReview = true`. 실제 프롬프트는 `CreateFeedView`가 `import StoreKit` + `@Environment(\.requestReview)`로 띄운다 — ⚠️ **`submitState == .submitted` onChange에서 `dismiss()`보다 먼저 `requestReview()`를 부른다**(화면 pop 후에도 밑 화면 위로 정상 표시됨, 시뮬레이터 실측 확인). 작성·수정 모두 이 단일 `.submitted`를 지나므로 둘 다 카운트되지만 게이트가 버전당 1회로 수렴한다. V1은 성공마다 무조건 호출했으나 "무분별 호출 금지"로 게이트를 얹었다.
- **"완료" 버튼(`canSubmit`)은 내용이 비어있지 않은 것과 별개로, `originalDraft`(수정 모드는 `loadForEdit` 완료 시점, 작성 모드는 빈 draft) 대비 `state.draft`가 실제로 달라야(`hasChanges`) 활성화된다**(사용자 확정, #197) — 수정 모드에서 아무것도 안 바꾸고 "완료"를 누를 수 있으면 안 된다는 요구. `FeedDraft`/`ConnectedNovel`이 이 비교를 위해 `Equatable`을 준수한다(합성 비교로 충분 — `attachedImages`는 ID 목록이라 이미지 추가/삭제도 이 비교에 자연히 걸린다). 작성 모드는 별도 분기 없이도 항상 성립한다(빈 draft와 달라지는 순간 자연히 `hasChanges == true`). 로드 중(`isLoadingForEdit == true`)엔 `state.draft`가 아직 placeholder라 `originalDraft`와 같아 자연히 비활성 상태를 유지한다.
- **`FeedDetailLinkNovelBlock`(연결 작품 배너)의 표지는 `WSSNovelCoverImage`가 항상 `.fill`로 통일되며(#237,
  `WSSComponent/CLAUDE.md` 참고) 원본을 안 자르고 보여주던 이전 동작(`.fit`)에서 크롭 표시로 바뀌었다** —
  `aspectRatio: Metric.coverAspectRatio`(86/123, 로컬 파일 상수)로 넘겨 컴포넌트가 내부에서 크기·클립을
  전부 처리한다(밖에서 `.frame`+수동 `.clipped()`를 거는 방식은 쓰지 않는다 — `WSSComponent/CLAUDE.md`의
  "누가 프레임을 정하느냐" 원칙대로 `aspectRatio` 모드에선 컴포넌트가 프레임 소유자).
