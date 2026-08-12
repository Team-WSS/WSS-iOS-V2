<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedData

`FeedDomain.FeedRepository` 구현 — 피드 작성/수정/삭제, 상세, 소스별 목록, 좋아요.

- 식별자: `ModuleType.data(.feed)` / 의존: `FeedDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `FeedDataFactory.makeFeedRepository(client:logger:)`

## 핵심 시나리오

- 목록 응답 DTO가 소스별로 나뉨 (`TotalFeedResponse`, `UserFeedListResponse`, `NovelFeedListResponse` 등) → `FeedMapper`가 도메인 `Paginated<TotalFeed>`로 통일.
- 작성/수정 입력은 `SubmitFeedRequest` (content/categories/novelId?/isSpoiler/isPublic).

## 주의사항 (작업 중 발견 시 누적)

- **이미지 필드(아바타·썸네일·피드 이미지)는 버킷 상대 경로로 올 수 있다** — `URL(string:)` 직조립 금지, `ImageURLResolver.resolve(from:)`(BaseData) 경유(full URL/경로 혼재 흡수). 직조립하면 경로형 응답에서 이미지가 조용히 placeholder로 깨진다.
- 목록 커서가 `lastFeedID` — 쿼리 DTO(`GetSosoFeedsQuery`/`GetUserFeedsQuery`)에서 매핑 규약 확인. 첫 페이지는 커서 0.
- `FeedEndpoint.query`가 `switch ... default: .none` 구조라, **목록 케이스를 새로 추가할 때 query 분기를 빼먹으면 파라미터가 조용히 유실**된다(에러 없이 빈 쿼리로 요청됨). 실제로 `getNovelFeeds`가 커서/size를 안 보내던 버그가 있었다(#154에서 수정) — raw 값 대신 query DTO를 case에 싣는 패턴을 유지할 것.
- `UserFeedResponse.likerUsers`는 `FeedMapper`가 전혀 읽지 않고 실제 서버 응답과도 안 맞아 `getMyFeeds`/`getUserFeeds`의 JSON 디코딩이 실패하는 원인이었다 → 제거함. `UserFeedListResponse.feedsCount`는 실제 응답 필드가 맞아 유지(마찬가지로 Mapper는 안 씀 — 필드 존재 자체는 정상이니 미사용이라고 바로 의심 대상은 아님). **Response DTO는 형제 DTO를 베껴 짐작하지 말고, 실제 응답 바디로 검증할 것.**
- `DefaultFeedService.getMyFeeds`는 `genres.isEmpty ? nil : genres`라서 **빈 배열이면 서버가 무필터로 처리**한다. `SosoFeedViewModel`의 기본 필터 상태는 "전체 선택" UX를 `MyFeedOption.genres = NovelGenre.allCases`(9개 명시 나열) + `includesUncategorized: true`로 표현하고, `DefaultFeedRepository.fetchMyFeeds`는 이를 그대로 문자열로 매핑해 보낼 뿐 별도 정규화는 하지 않는다. 카테고리 칩(장르+"그 외")을 전부 해제해 `genres == []`, `includesUncategorized == false`가 되면 같은 이유로 무필터가 되어 전체 목록이 오는데, **이는 의도된 동작**이다(빈 선택 = 무필터).
- **`fetchUserFeeds`(타 유저 피드 목록)는 상대가 프로필을 비공개로 설정했을 때(`USER-015`) `RepositoryError.privateProfile`을 별도로 throw한다** — 공용 `NetworkingError.toRepositoryError()`(BaseData)를 건드리지 않고 `catch let error as NetworkingError` 블록 안에서 개별 처리(UserPageFeature #172). 이 코드가 의미 있는 호출은 이 메서드와 `ProfileData`의 장르/작품 취향 조회뿐이라 공용 변환기에 넣지 않기로 했다.
