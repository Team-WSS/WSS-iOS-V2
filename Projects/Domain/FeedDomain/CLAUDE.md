<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# FeedDomain

피드 도메인 — 작성/수정/삭제(Draft), 상세 조회, 목록 조회(소스별), 좋아요.

- 식별자: `ModuleType.domain(.feed)` / 의존: `BaseDomain`
- 디렉토리가 기능별로 나뉨: `Entity|UseCase/{FeedDraft, FeedDetail, TotalFeed}`

## 핵심 시나리오

- **목록은 소스별 4종**: `fetchSosoFeeds`(소소피드, `SosoFeedOption`), `fetchMyFeeds`(`MyFeedOption`), `fetchUserFeeds(id:)`, `fetchNovelFeeds(id:)`. 모두 `Paginated<TotalFeed>` 반환.
- **페이지네이션은 `lastFeedID` 커서 방식** (page 번호 아님).
- 작성/수정은 `FeedDraft` 입력. 좋아요는 `addLike`/`deleteLike`.

## 주의사항 (작업 중 발견 시 누적)

- 커서가 `lastFeedID`라, 첫 페이지 호출 시 어떤 ID를 넣는지 호출 측 규약 확인 (Data 구현/매핑 참고).
- `MyFeedOption.includesUncategorized`(연결 작품 없어 장르가 없는 내 피드 포함 여부)는 **`NovelGenre`에 케이스를 추가하는 방식으로 풀지 않는다** — `NovelGenre`는 Novel 도메인 전역(검색·상세 등)이 공유하는 순수 장르 enum이라, 여기 값을 하나 늘리면 `WSSComponent`의 `NovelGenre+Presentation` 같은 exhaustive switch가 전부 영향받는다. "미분류"는 Feed 전용 개념이라 별도 `Bool` 필드로 표현하고, 서버가 이걸 받는 실제 값("etc" sentinel)으로의 변환은 FeedData(`DefaultFeedRepository.fetchMyFeeds`)가 담당한다.
- **`fetchUserFeeds`/`LoadUserFeedsUseCase`는 항상 "타 유저" 조회로 취급**한다 — "내 피드"는 별도 `fetchMyFeeds`가 있으므로 로그인 사용자와 대상 id를 비교해 `isMyFeed`를 판단하지 않는다(UserPageFeature #172). 응답에 author(닉네임·프로필 이미지)가 없어 `nickname`/`profileImage` 파라미터로 호출 측이 직접 채운다 — 이 조회는 유저 페이지에서만 일어나므로 호출 측(Feature)이 이미 프로필 조회로 그 값을 갖고 있다는 전제.
