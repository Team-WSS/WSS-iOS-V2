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
- ⚠️ **`TotalFeed`의 `==`는 `feedId`만 비교하는 identity 등가다**(커스텀 구현, `TotalFeed.swift`) — **내용 변경 감지에 쓰지 말 것**. 같은 ID 목록이면 본문·좋아요·댓글수가 달라도 "같음"이 된다. #236에서 재조회의 "무변화면 대입 스킵" 최적화가 이 `==` 위에 올라가 수정·좋아요 반영을 통째로 삼킬 뻔했다(리뷰에서 발견·제거). 내용 비교가 필요하면 표시 필드를 명시 비교하는 별도 수단을 만들 것.
- **목록 4종 중 `fetchNovelFeeds`만 `size: Int?`를 받는다**(#236) — 작품 상세의 재진입 조용한 재조회가 "보던 개수만큼 한 번에 다시 받아 통째 교체"(V1 parity)를 쓰기 때문. nil이면 Data 기본 페이지 크기. 요청 크기 규칙(보던 개수 유지·서버 상한 100 클램프)은 `NovelFeedPageSizePolicy`(Entity/TotalFeed)가 갖는다 — 상한은 실측 확정값이 아니라 서재 `LibraryPageSizePolicy`처럼 클라가 먼저 잘라 동작을 결정론적으로 만든 것. 다른 목록에 같은 갱신을 얹게 되면 이 정책을 재사용할 것.
- `MyFeedOption.includesUncategorized`(연결 작품 없어 장르가 없는 내 피드 포함 여부)는 **`NovelGenre`에 케이스를 추가하는 방식으로 풀지 않는다** — `NovelGenre`는 Novel 도메인 전역(검색·상세 등)이 공유하는 순수 장르 enum이라, 여기 값을 하나 늘리면 `WSSComponent`의 `NovelGenre+Presentation` 같은 exhaustive switch가 전부 영향받는다. "미분류"는 Feed 전용 개념이라 별도 `Bool` 필드로 표현하고, 서버가 이걸 받는 실제 값("etc" sentinel)으로의 변환은 FeedData(`DefaultFeedRepository.fetchMyFeeds`)가 담당한다.
- **`fetchUserFeeds`/`LoadUserFeedsUseCase`는 항상 "타 유저" 조회로 취급**한다 — "내 피드"는 별도 `fetchMyFeeds`가 있으므로 로그인 사용자와 대상 id를 비교해 `isMyFeed`를 판단하지 않는다(UserPageFeature #172). 응답에 author(닉네임·프로필 이미지)가 없어 `nickname`/`profileImage` 파라미터로 호출 측이 직접 채운다 — 이 조회는 유저 페이지에서만 일어나므로 호출 측(Feature)이 이미 프로필 조회로 그 값을 갖고 있다는 전제.
- ⚠️ **`LoadFeedDetailUseCase` 프로토콜의 구현 클래스명은 `DefaultLoadFeedDetailUseCase`가 아니라 `DefaultLoadFeedUseCase`다**(파일 `UseCase/FeedDetail/LoadFeedDetailUseCase.swift`) — 다른 Default 구현체는 전부 프로토콜명 그대로라(`DefaultDeleteFeedUseCase` 등) 관례를 따라 이름을 추측하면 컴파일 에러로 걸린다(App #196에서 실측). 리네임하면 이 문서도 같이 고칠 것.
- ⚠️ **`EditFeedUseCase.execute(feedID:editedFeed:imageDatas:)`는 이미지를 부분 수정이 아니라 전체 교체로 받는다** — `attachedImages: [AttachedImageID]`는 순서·목록만 있고 실제 바이트는 별도 `imageDatas: [Data]`로 같이 넘겨야 하는데, 기존에 이미 업로드된 이미지는 URL만 있어 바이트가 없다. **수정 시 기존 이미지를 유지하려면 호출 측(Feature)이 그 URL들을 먼저 다운로드해 `imageDatas`에 다시 실어 보내야 한다** — 그냥 빈 이미지로 제출하면 서버 응답이 기존 이미지를 지워버린다(사용자 확정, #197). 이 도메인엔 "기존 이미지 유지"를 표현하는 별도 파라미터가 없다.
