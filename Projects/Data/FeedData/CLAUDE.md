<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedData

`FeedDomain.FeedRepository` 구현 — 피드 작성/수정/삭제, 상세, 소스별 목록, 좋아요.

- 식별자: `ModuleType.data(.feed)` / 의존: `FeedDomain`, `BaseData`, `Networking`
- 진입점: `FeedDataFactory.makeFeedRepository(client:logger:)`

## 핵심 시나리오

- 목록 응답 DTO가 소스별로 나뉨 (`TotalFeedResponse`, `UserFeedListResponse`, `NovelFeedListResponse` 등) → `FeedMapper`가 도메인 `Paginated<TotalFeed>`로 통일.
- 작성/수정 입력은 `SubmitFeedRequest` (content/categories/novelId?/isSpoiler/isPublic).

## 주의사항 (작업 중 발견 시 누적)

- 목록 커서가 `lastFeedID` — 쿼리 DTO(`GetSosoFeedsQuery`/`GetUserFeedsQuery`)에서 매핑 규약 확인.
