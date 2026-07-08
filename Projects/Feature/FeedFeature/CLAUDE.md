<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedFeature

피드 작성/수정, 상세, 목록(내 피드/소소피드) 화면.

- 식별자: `ModuleType.feature(.feed)` / 의존: `FeedDomain`, `NovelDomain`, `ProfileDomain`, `BaseDomain`

## 주의사항 (작업 중 발견 시 누적)

- `fetchMyFeeds`/`fetchUserFeeds` 응답(`UserFeedResponse`, FeedData)은 작성자 닉네임/프로필 이미지를 내려주지 않는다(서버 스펙). `SosoFeedViewModel`이 `ProfileDomain.LoadProfileUseCase`로 프로필을 따로 조회해 `TotalFeed.author`를 다시 조립해 채운다(`applying(_:to:)`). `TotalFeed.author`가 `private(set)`이라 직접 mutate 불가 — 공개 `init`으로 새 값을 만들어 교체하는 방식.
- 이 조합 로직 때문에 FeedFeature가 `ProfileDomain`(다른 최상위 도메인)을 직접 의존한다 — Domain 레이어 규칙상 Domain끼리는 `BaseDomain` 외 서로 의존 못 하므로, 이런 두 도메인 조합은 Feature(ViewModel) 레벨에서 한다.
