<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDomain

작품(Novel) 도메인 — 상세 조회·서재·관심 등록의 비즈니스 로직과 계약.
구성요소 목록은 `Sources/{Entity,UseCase,Repository}/`를 직접 보면 된다. 여기엔 **코드만 봐선 모르는 것**만 적는다.

- 식별자: `ModuleType.domain(.novel)` / 의존: `BaseDomain` only

## 핵심 시나리오

- **작품 상세(`LoadNovelUseCase`)**: 키워드 매핑을 위해 `KeywordRepository`에서 캐시 키워드를 모아
  `NovelRepository.fetchNovel(id:cachedKeywords:)`에 주입한다. → 이 UseCase는 NovelRepository + KeywordRepository **둘 다** 의존.
- **관심 토글**: 도메인 정책은 Entity `Novel`의 `mutating` 메서드(`markAsInterested`/`toggleInterest`)가 담당. 서버 반영(`addNovelInterest`/`removeNovelInterest`)은 Repository 별도 호출.
- **서재**: 결과는 `(Paginated<T>, Int)` = (페이지 목록, 총 개수) 튜플.
- **내 서재(V2, #166)**: `LoadMyLibraryUseCase.execute(filter:cursor:size:)` → `(CursorPaginated<LibraryNovel>, Int)`.
  커서는 **서버 발급 opaque 문자열**(`nextCursor`) — 마지막 아이템 ID로 유도하지 말고 그대로 왕복한다.
  필터 시트 키워드 탭 데이터는 `LoadMyLibraryKeywordsUseCase`(등록 키워드 목록) 별도.
  - ⚠️ **`size`를 화면이 정하는 건 의도다** — 내 서재는 재진입할 때마다 "보고 있던 개수만큼" 한 번에 다시
    받아야 목록이 짧아지지 않는다(짧아지면 스크롤 위치가 위로 튄다). 그래서 페이지 크기가 고정이 아니고,
    Data에 상수로 숨기면 그 경로를 표현할 수 없다. **타유저 서재(`LoadUserLibraryUseCase`)엔 일부러 안 뚫었다** —
    push라 재진입마다 화면이 새로 서서 그 갱신 자체가 없다. Repository "내"/"유저" 쌍을 맞추려고 따라 넣지 말 것.
- **서재 요청 개수 정책(`LibraryPageSizePolicy`)**: 페이지 크기(20)·서버 상한(100)과 **재진입 갱신의 1차/2차 요청 크기**를 계산하는 순수 함수. 화면이 `size`를 넘기는 구조라 계산이 Feature에 흩어지기 쉬운데, 보던 개수·delta·상한이 얽혀 가장 틀리기 쉬운 부분이라 여기로 내려 테스트로 고정했다. Data의 타유저 서재 고정 크기도 이 상수를 쓴다(값이 두 벌로 갈리지 않게).
- **타유저 서재(V2, #166)**: `LoadUserLibraryUseCase.execute(id:filter:cursor:)` → 내 서재와 **같은 반환 타입·같은 엔드포인트**.
  ⚠️ **서버 경로가 `/users/{userId}/novels/v2`라 내 서재와 타유저 서재의 차이는 "어떤 userID를 넣느냐"뿐**이다 —
  내 서재는 Data가 저장된 userID를 채우고, 타유저는 호출자가 `UserID`를 넘긴다. 그래서 커서 페이지네이션·정렬 6종·
  키워드 복원이 양쪽에서 동일하게 동작한다(타유저용 별도 페이지네이션 규약을 만들 필요 없음).
  필터는 `LibraryFilter`(**정렬만** 보유) — 타유저 서재 화면엔 필터 UI가 없다.

## 주의사항 (작업 중 발견 시 누적)

- `fetchMyLibraryNovels`/`fetchRegisteredNovelStats`는 **로그인 사용자 기준** (구현체가 저장된 userID 사용). 타 사용자 조회는 `fetchUserLibraryNovels(id:_:)` / `fetchUserRegisteredNovelStats(id:)` 별도 — Repository에 "내" 버전과 "유저" 버전이 쌍으로 존재하는 게 이 모듈의 고정 패턴이니, 서재 관련 조회를 새로 추가할 땐 이 쌍을 먼저 따라간다.
- 키워드 캐시가 호출 측 주입 구조라, UseCase 시그니처에 키워드 의존이 숨어있음.
- ⚠️ **`KeywordRepository.fetchKeywords()`는 네트워크를 타지 않고 로컬 캐시만 읽는다** — 캐시를 채우는 건 `syncKeywords()` 뿐이다. 즉 **App 조립에서 `syncKeywords()`를 선행하지 않으면 서재·작품 상세의 키워드가 화면상 아무 오류 없이 통째로 빈다**(UseCase의 `try?` + `?? []` 폴백이 실패를 삼킨다 — 목록 자체를 막지 않으려는 의도된 설계. 단, Data 레이어에는 `logger?.logCacheError`가 남으므로 **원인 추적은 로그로** 한다). `LoadNovelUseCase`·`LoadMyLibraryUseCase` 둘 다 해당하며, 서재는 목록 전체가 영향받아 체감이 크다. Demo 앱들이 화면을 띄우기 전에 `await ...syncKeywords()`를 부르는 게 이 때문이다.
- **작품 상세의 키워드는 `NovelKeyword`(공통 `Keyword` + 선택 횟수 count)** — `UserNovelReview.keywords`는 유저 개인 선택이라 count 없는 `[Keyword]` 그대로. 둘을 혼동하지 말 것(#154).
- 엔티티 시그니처를 바꾸면 **`Testing/` Mock과 `Tests/`도 같이 갱신**할 것 — #135에서 authors/genres/필터 변경이 미반영돼 테스트 타깃이 컴파일 불가로 방치됐었다(#154에서 수리).
- **`Novel`/`NovelRatingThreshold`/`NovelPublicationStatus`는 이 모듈 소유가 아니라 `BaseDomain`에 있다** — `SearchDomain`도 참조해야 해서 공통 토대로 승격됐다. `NovelInformation`/`MyLibraryFilter` 등은 그대로 `import BaseDomain`으로 쓴다.
- **작품 제목/필터 검색(`SearchNovelUseCase`, `SearchFilter`)은 `SearchDomain` 소유**다 — 예전엔 이 모듈이 갖고 있었으나 계약과 구현(엔드포인트·매퍼) 전부 `SearchDomain`/`SearchData`로 이동했다. 이 모듈의 `NovelRepository`/`NovelData`는 더 이상 검색을 모른다.
- **서재 별점 필터(`LibraryRatingFilter`)는 검색의 `NovelRatingThreshold`(이상 4단계)와 다른 타입**(범위+별점없음). 혼용 금지.
  전체 범위(0.0~5.0)는 `setRatingRange`가 **nil로 정규화**한다("필터 없음"의 표현을 하나로 유지) — UI는 `rating != nil`로 칩 유무를 판단하면 된다.
- **`MyLibraryFilter.clearAll()`(시트 "초기화")은 시트 필터 6종만 리셋** — 관심(isInterest)·정렬(sortType)은 시트 소속이 아니라 유지된다.
- **연재상태(`publicationStatus`)가 단일 선택인 건 의도된 설계** — 서버 쿼리가 `isCompleted: Bool?` **하나뿐**이라 애초에 "연재중+완결작"을 표현할 수단이 없다. 구 WSSiOS는 이걸 배열로 들고 UI에서 둘 다 켤 수 있게 해뒀지만, Repository가 `count == 1`일 때만 파라미터를 실어서 **둘 다 고르면 필터가 통째로 무시**됐다(칩은 2개인데 결과는 전체). V1이 다중이라는 이유로 배열로 되돌리지 말 것.
- 서재 정렬은 공용 `SortType`(2종)이 아니라 **서재 전용 `LibrarySortType`(6종)** — 내 서재·타유저 서재 **둘 다** 이걸 쓴다(같은 V2 엔드포인트라 서버가 받는 정렬 문자열이 같다). 공용 `SortType`을 쓰던 구 `LibraryFilter`는 #166에서 `LibrarySortType`으로 전환했다.
