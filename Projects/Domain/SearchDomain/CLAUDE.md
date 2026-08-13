<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SearchDomain

일반 검색 화면(`SearchFeature`) 전용 도메인 — 최근 검색어, 제목 기반 자동완성. 검색 기능이 커지면서(장르별 검색·자동완성·인기 키워드 등) 기존 `NovelDomain`/`BaseDomain`만으로는 부족해져 신설했다(#163).

- 식별자: `ModuleType.domain(.search)` / 의존: `BaseDomain`

## 핵심 시나리오

- **최근 검색어**(`RecentSearchWord`): `RecentSearchRepository`는 **서버 호출**이다 — 검색 실행 시 서버가 자동 기록하므로 클라이언트에 명시적 "add" UseCase는 없고 `Load`/`Remove`/`Clear`만 있다.
- **제목 자동완성**(`SearchAutoCompletionWord`): `SearchAutoCompletionWordsUseCase.execute(searchText:)`가 앞뒤 공백을 trim하고, 빈 문자열이면 서버 호출 없이 빈 배열을 즉시 반환한다(타이핑 중 불필요한 네트워크 호출 방지).
- **작품 제목/필터 검색**(`SearchNovelUseCase`, `SearchFilter`, `SearchNovelRepository`): 원래 `NovelDomain` 소유였으나 이 모듈로 이동했다 — `Novel` 엔티티가 `NovelDomain`과 이 모듈 양쪽에서 필요해지면서 `BaseDomain`으로 공용화됐고(`BaseDomain/CLAUDE.md` 참고), 그 김에 작품 검색 계약 자체와 **구현(엔드포인트·매퍼)까지 전부 `SearchData`로 이관**했다 — `NovelData`는 더 이상 검색을 모른다.
- 같은 이유로 **실시간 인기 키워드(`PopularKeywords`)는 `BaseDomain`**에 있다(키워드 카탈로그 소유가 `BaseDomain`이라서) — 이 모듈로 옮기지 않는다.

## 주의사항 (작업 중 발견 시 누적)

- `RecentSearchWord.id`는 서버 발급 `SearchWordID`(`IDWrapper<Int>`, `BaseDomain.WSSIdentifiers`에 등록됨) — 클라이언트가 임의로 생성하지 않는다.
- 구현체는 `SearchData`의 `DefaultSearchRepository` 하나가 `RecentSearchRepository`/`SearchAutoCompletionRepository`/`SearchNovelRepository` **세 프로토콜 전부**를 구현한다(`SearchDataFactory.makeRepository`가 세 타입의 교집합을 반환). 실서버 확인 완료 — 세부 응답 형태는 `SearchData/CLAUDE.md` 참고.
- **`NovelPlatform`/`NovelRatingRange`(#185)는 이 모듈 전용 신규 타입**이다. `NovelPlatform`은 `NovelDomain.NovelPlatform`(name+image+url, 작품 상세용)과 동명이지만 별개 — 이쪽은 상세탐색 필터 선택지로 쓸 고정 5종 enum이다. `NovelRatingRange`도 `BaseDomain.NovelRatingThreshold`(단일 최소값 4단계)를 대체하지 않는 별도 개념(`SearchFilter`가 둘 다 갖는다) — 한쪽을 보고 다른 쪽을 지우지 말 것.
- **상세탐색 필터 화면(정보 탭)의 장르 그리드 순서는 `WSSComponent.NovelGenre.myFeedFilter`와 동일**(`searchGenre`가 아니다) — Figma 실측으로 확인됐다. 새 순서 목록을 만들지 말고 재사용할 것.
