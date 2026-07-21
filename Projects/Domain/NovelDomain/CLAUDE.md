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
- **내 서재(V2, #166)**: `LoadMyLibraryUseCase.execute(filter:cursor:)` → `(CursorPaginated<LibraryNovel>, Int)`.
  커서는 **서버 발급 opaque 문자열**(`nextCursor`) — 마지막 아이템 ID로 유도하지 말고 그대로 왕복한다.
  필터 시트 키워드 탭 데이터는 `LoadMyLibraryKeywordsUseCase`(등록 키워드 목록) 별도.

## 주의사항 (작업 중 발견 시 누적)

- `fetchMyLibraryNovels`/통계는 **로그인 사용자 기준** (구현체가 저장된 userID 사용). 타 사용자 조회는 `fetchUserLibraryNovels(id:_:)` 별도.
- 키워드 캐시가 호출 측 주입 구조라, UseCase 시그니처에 키워드 의존이 숨어있음.
- **작품 상세의 키워드는 `NovelKeyword`(공통 `Keyword` + 선택 횟수 count)** — `UserNovelReview.keywords`는 유저 개인 선택이라 count 없는 `[Keyword]` 그대로. 둘을 혼동하지 말 것(#154).
- 엔티티 시그니처를 바꾸면 **`Testing/` Mock과 `Tests/`도 같이 갱신**할 것 — #135에서 authors/genres/필터 변경이 미반영돼 테스트 타깃이 컴파일 불가로 방치됐었다(#154에서 수리).
- **`Novel`/`NovelRatingThreshold`/`NovelPublicationStatus`는 이 모듈 소유가 아니라 `BaseDomain`에 있다** — `SearchDomain`도 참조해야 해서 공통 토대로 승격됐다. `NovelInformation`/`MyLibraryFilter` 등은 그대로 `import BaseDomain`으로 쓴다.
- **작품 제목/필터 검색(`SearchNovelUseCase`, `SearchFilter`)은 `SearchDomain` 소유**다 — 예전엔 이 모듈이 갖고 있었으나 계약과 구현(엔드포인트·매퍼) 전부 `SearchDomain`/`SearchData`로 이동했다. 이 모듈의 `NovelRepository`/`NovelData`는 더 이상 검색을 모른다.
- **서재 별점 필터(`LibraryRatingFilter`)는 검색의 `NovelRatingThreshold`(이상 4단계)와 다른 타입**(범위+별점없음). 혼용 금지.
  전체 범위(0.0~5.0)는 `setRatingRange`가 **nil로 정규화**한다("필터 없음"의 표현을 하나로 유지) — UI는 `rating != nil`로 칩 유무를 판단하면 된다.
- **`MyLibraryFilter.clearAll()`(시트 "초기화")은 시트 필터 6종만 리셋** — 관심(isInterest)·정렬(sortType)은 시트 소속이 아니라 유지된다.
- 서재 정렬은 공용 `SortType`(2종)이 아니라 **서재 전용 `LibrarySortType`(6종)** — 타유저 서재(`LibraryFilter`)는 여전히 공용 `SortType`을 쓴다.
