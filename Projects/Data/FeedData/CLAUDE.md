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
- **`getMyFeeds` 쿼리 조립은 `DefaultFeedRepository.fetchMyFeeds`에 있다** — 예전엔 `DefaultFeedService`가 문자열→Bool 변환·`genres.isEmpty ? nil : genres`를 했으나 A2에서 Service 밖으로 걷어냈다(**Service는 순수 passthrough, 매핑/분기는 Repository·`FeedMapper`로** — arch-lint `service-no-branch`가 warning으로 감시). `genres.isEmpty ? nil : genres`라서 **빈 배열이면 서버가 무필터로 처리**한다. `SosoFeedViewModel`의 기본 필터 상태는 "전체 선택" UX를 `MyFeedOption.genres = NovelGenre.allCases`(9개 명시 나열) + `includesUncategorized: true`로 표현하고, Repository는 이를 그대로 매핑해 보낼 뿐 별도 정규화는 하지 않는다. 카테고리 칩(장르+"그 외")을 전부 해제해 `genres == []`, `includesUncategorized == false`가 되면 같은 이유로 무필터가 되어 전체 목록이 오는데, **이는 의도된 동작**이다(빈 선택 = 무필터). 공개범위(`VisibilityType`)는 `FeedMapper.visibilityFlags`가 `isVisible`/`isUnVisible` 두 Bool로 바꾼다(all=둘 다 nil).
- **내 피드 `sortCriteria`는 `option.sortType.rawValue.uppercased()`로 대문자화해 싣는다** — `BaseDomain.SortType`이 `case recent`/`old`에 명시 rawValue가 없어 raw는 소문자 `recent`/`old`인데, **서버는 대문자 `RECENT`/`OLD`를 쓰는 V1과 같은 엔드포인트**라 타 모듈 패턴(`NovelMapper`의 읽기상태, `CollectionDetailQuery`의 정렬 — 둘 다 `.rawValue.uppercased()`)에 맞춘 것. ⚠️ **실서버 검증(C2 2026-08-28): 서버는 실제로 `sortCriteria` 대소문자 무관**(`recent`==`RECENT` 순서 동일)이라 소문자여도 기능은 정상이었으나, **일관성을 위해 대문자로 통일**했다(사용자 확정). 소소피드 옵션(`feedsOption`)은 `SosoFeedOption`이 `= "ALL"`/`"RECOMMENDED"`로 rawValue를 명시해 애초에 문제없다 — **명시 rawValue 없는 열거형을 서버로 실을 때 case명 소문자가 새지 않게 `.uppercased()` 또는 명시 rawValue를 쓸 것.**
- **`fetchUserFeeds`(타 유저 피드 목록)는 상대가 프로필을 비공개로 설정했을 때(`USER-015`) `RepositoryError.privateProfile`을 별도로 throw한다** — 공용 `NetworkingError.toRepositoryError()`(BaseData)를 건드리지 않고 `catch let error as NetworkingError` 블록 안에서 개별 처리(UserPageFeature #172). 이 코드가 의미 있는 호출은 이 메서드와 `ProfileData`의 장르/작품 취향 조회뿐이라 공용 변환기에 넣지 않기로 했다.
