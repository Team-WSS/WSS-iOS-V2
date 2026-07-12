<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedData

`FeedDomain.FeedRepository` 구현 — 피드 작성/수정/삭제, 상세, 소스별 목록, 좋아요.

- 식별자: `ModuleType.data(.feed)` / 의존: `FeedDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `FeedDataFactory.makeFeedRepository(client:logger:)`

## 핵심 시나리오

- 목록 응답 DTO가 소스별로 나뉨 (`TotalFeedResponse`, `UserFeedListResponse`, `NovelFeedListResponse` 등) → `FeedMapper`가 도메인 `Paginated<TotalFeed>`로 통일.
- 작성/수정 입력은 `SubmitFeedRequest` (content/categories/novelId?/isSpoiler/isPublic).

## 주의사항 (작업 중 발견 시 누적)

- **이미지 필드(아바타·썸네일·피드 이미지)는 버킷 상대 경로로 올 수 있다** — `URL(string:)` 직조립 금지, `BucketImageURL.imageURL(from:)`(BaseData) 경유(full URL/경로 혼재 흡수). 직조립하면 경로형 응답에서 이미지가 조용히 placeholder로 깨진다.
- 목록 커서가 `lastFeedID` — 쿼리 DTO(`GetSosoFeedsQuery`/`GetUserFeedsQuery`)에서 매핑 규약 확인. 첫 페이지는 커서 0.
- `FeedEndpoint.query`가 `switch ... default: .none` 구조라, **목록 케이스를 새로 추가할 때 query 분기를 빼먹으면 파라미터가 조용히 유실**된다(에러 없이 빈 쿼리로 요청됨). 실제로 `getNovelFeeds`가 커서/size를 안 보내던 버그가 있었다(#154에서 수정) — raw 값 대신 query DTO를 case에 싣는 패턴을 유지할 것.
