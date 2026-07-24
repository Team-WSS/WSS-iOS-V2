<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedFeature

피드 작성/수정, 상세, 목록(내 피드/소소피드) 화면.

- 식별자: `ModuleType.feature(.feed)` / 의존: `FeedDomain`, `NovelDomain`, `ProfileDomain`, `SocialDomain`(피드 신고), `BaseDomain`, `Logger`(`SosoFeedViewModel`이 `logger: Logger? = nil` 주입받음)

## 주의사항 (작업 중 발견 시 누적)

- `fetchMyFeeds`/`fetchUserFeeds` 응답(`UserFeedResponse`, FeedData)은 작성자 닉네임/프로필 이미지를 내려주지 않는다(서버 스펙). `SosoFeedViewModel`이 `ProfileDomain.LoadProfileUseCase`로 프로필을 따로 조회해 `TotalFeed.author`를 다시 조립해 채운다(`applying(_:to:)`). `TotalFeed.author`가 `private(set)`이라 직접 mutate 불가 — 공개 `init`으로 새 값을 만들어 교체하는 방식.
- 이 조합 로직 때문에 FeedFeature가 `ProfileDomain`(다른 최상위 도메인)을 직접 의존한다 — Domain 레이어 규칙상 Domain끼리는 `BaseDomain` 외 서로 의존 못 하므로, 이런 두 도메인 조합은 Feature(ViewModel) 레벨에서 한다.
- `MyFeedOption.sortType`은 genres/visibilityType과 달리 필터 시트의 draft→`applyMyFeedFilter` 커밋 흐름을 타지 않는다. `WSSSortButton` 탭이 `.toggleMyFeedSort`로 `state.myFeedOption`을 즉시 갱신하고 바로 재조회한다(시트를 열 필요 없음) — 필터 시트가 열릴 때 draft가 `resetMyFeedFilterDraft`로 이 값도 그대로 복사해가므로 두 경로가 어긋나지 않는다.
- `state.myFeedOption.genres` 기본값은 "전체 선택" UX를 `NovelGenre.allCases`(9개 전부) + `includesUncategorized: true`로 표현한다(연결 작품 없는 내 피드까지 포함). FeedData는 이를 그대로 명시적 장르 필터로 보낼 뿐 정규화하지 않는다 — 카테고리 칩(장르+"그 외")을 전부 해제하면 `MyFeedOption.genres == []`가 되고 FeedData의 `genres.isEmpty ? nil : genres`가 이를 무필터로 해석해 전체 목록이 온다. **이는 의도된 동작**(빈 선택 = 무필터)이라 공개/비공개 체크박스와 달리 최소 1개 선택 가드를 두지 않는다.
- **피드 셀 threedots 드롭다운**(`SosoFeedView.feedMenuContext`)은 `NovelDetailFeature`의 같은 패턴을 참고했지만 좌표공간 태깅 위치가 다르다 — `NovelDetailView`는 몰입형 헤더라 `ScrollView` 자체에 `coordinateSpace(name:)`를 걸고 `ignoresSafeArea`로 화면 최상단과 맞춘다. `SosoFeedView`는 일반 화면(시스템 safe area 존중)이라 그 방식 대신 **루트 `ZStack`에 직접 `coordinateSpace(name: feedMenuSpaceName)`를 건다** — 셀 앵커(`cellTopYs`)와 오버레이(`feedMenuOverlay`)가 같은 루트의 형제이므로 이러면 별도 오프셋 계산 없이 좌표가 바로 맞는다. 이 화면에 몰입형 헤더 같은 걸 얹게 되면 이 가정이 깨지니 재검토할 것.
- 피드 삭제/신고 확인·완료 알럿은 `WSSComponent`의 공용 `WSSAlertType`(`deleteMyFeed`/`reportSpoilerContent`/`reportImproperContent`/`receivedReportSpoilerContent`/`receivedReportImproperContent`) 5종을 그대로 재사용한다 — `NovelDetailFeature`와 동일한 타입을 공유하므로 카피를 바꾸려면 두 Feature 모두에 영향이 간다.
- **탭(내 피드/소소피드)·소소피드 옵션(전체글/추천글)·내 피드 필터(장르/공개여부/정렬) 전환 시 스크롤이 이전 위치에 남는 문제**는 `FeedListSection`의 `ScrollView`에 `.id(scrollIdentity)`를 걸어 해결한다 — `scrollIdentity`는 이 모든 축(탭, 소소피드 옵션, `myFeedOption`의 genres/includesUncategorized/visibilityType/sortType)을 문자열로 합친 값이라 그중 하나라도 바뀌면 SwiftUI가 ScrollView를 "새 뷰"로 취급해 스크롤 오프셋을 버리고 최상단부터 다시 그린다. `state.myFeeds`/`sosoFeeds` 배열은 이미 `.load`(refresh: true)로 새로 교체되므로, 이 `.id()`는 순수하게 "화면(스크롤 위치)"만 리셋하는 역할이다. **새 필터 축을 추가하면 `scrollIdentity`에도 반영해야** 그 축 변경 시에도 스크롤이 리셋된다.
