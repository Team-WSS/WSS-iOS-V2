<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedFeature

피드 작성/수정, 상세, 목록(내 피드/소소피드) 화면.

- 식별자: `ModuleType.feature(.feed)` / 의존: `FeedDomain`, `NovelDomain`, `ProfileDomain`, `SocialDomain`(피드 신고), `BaseDomain`, `Logger`(`SosoFeedViewModel`이 `logger: Logger? = nil` 주입받음)

## 주의사항 (작업 중 발견 시 누적)

- `fetchMyFeeds`/`fetchUserFeeds` 응답(`UserFeedResponse`, FeedData)은 작성자 닉네임/프로필 이미지를 내려주지 않는다(서버 스펙). `SosoFeedViewModel`이 `ProfileDomain.LoadProfileUseCase`로 프로필을 따로 조회해 `TotalFeed.author`를 다시 조립해 채운다(`applying(_:to:)`). `TotalFeed.author`가 `private(set)`이라 직접 mutate 불가 — 공개 `init`으로 새 값을 만들어 교체하는 방식.
- 이 조합 로직 때문에 FeedFeature가 `ProfileDomain`(다른 최상위 도메인)을 직접 의존한다 — Domain 레이어 규칙상 Domain끼리는 `BaseDomain` 외 서로 의존 못 하므로, 이런 두 도메인 조합은 Feature(ViewModel) 레벨에서 한다.
- `MyFeedOption.sortType`은 genres/visibilityType과 달리 필터 시트의 draft→`applyMyFeedFilter` 커밋 흐름을 타지 않는다. `WSSSortButton` 탭이 `.toggleMyFeedSort`로 `state.myFeedOption`을 즉시 갱신하고 바로 재조회한다(시트를 열 필요 없음) — 필터 시트가 열릴 때 draft가 `resetMyFeedFilterDraft`로 이 값도 그대로 복사해가므로 두 경로가 어긋나지 않는다.
- `state.myFeedOption.genres` 기본값은 "전체 선택" UX를 `NovelGenre.allCases`(9개 전부)로 표현한다 — 이 값을 그대로 서버로 보내면 무필터가 아니라 명시적 필터가 되어, 연결 작품이 없는 내 피드가 결과에서 빠진다("API 성공인데 0개"). 정규화는 FeedData(`DefaultFeedRepository.fetchMyFeeds`)가 담당하므로, 여기서 새 필터/기본값을 바꿀 땐 FeedData 쪽 "전체 선택=빈 배열" 정규화가 깨지지 않는지 같이 확인할 것.
- **피드 셀 threedots 드롭다운**(`SosoFeedView.feedMenuContext`)은 `NovelDetailFeature`의 같은 패턴을 참고했지만 좌표공간 태깅 위치가 다르다 — `NovelDetailView`는 몰입형 헤더라 `ScrollView` 자체에 `coordinateSpace(name:)`를 걸고 `ignoresSafeArea`로 화면 최상단과 맞춘다. `SosoFeedView`는 일반 화면(시스템 safe area 존중)이라 그 방식 대신 **루트 `ZStack`에 직접 `coordinateSpace(name: feedMenuSpaceName)`를 건다** — 셀 앵커(`cellTopYs`)와 오버레이(`feedMenuOverlay`)가 같은 루트의 형제이므로 이러면 별도 오프셋 계산 없이 좌표가 바로 맞는다. 이 화면에 몰입형 헤더 같은 걸 얹게 되면 이 가정이 깨지니 재검토할 것.
- 피드 삭제/신고 확인·완료 알럿은 `WSSComponent`의 공용 `WSSAlertType`(`deleteMyFeed`/`reportSpoilerContent`/`reportImproperContent`/`receivedReportSpoilerContent`/`receivedReportImproperContent`) 5종을 그대로 재사용한다 — `NovelDetailFeature`와 동일한 타입을 공유하므로 카피를 바꾸려면 두 Feature 모두에 영향이 간다.
