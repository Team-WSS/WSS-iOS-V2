<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SearchDomain

일반 검색 화면(`SearchFeature`) 전용 도메인 — 최근 검색어, 제목 기반 자동완성. 검색 기능이 커지면서(장르별 검색·자동완성·인기 키워드 등) 기존 `NovelDomain`/`BaseDomain`만으로는 부족해져 신설했다(#163).

- 식별자: `ModuleType.domain(.search)` / 의존: `BaseDomain`

## 핵심 시나리오

- **최근 검색어**(`RecentSearchWord`): `RecentSearchRepository`는 **서버 호출**이다 — 검색 실행 시 서버가 자동 기록하므로 클라이언트에 명시적 "add" UseCase는 없고 `Load`/`Remove`/`Clear`만 있다.
- **제목 자동완성**(`SearchAutoCompletionWord`): `SearchAutoCompletionWordsUseCase.execute(searchText:)`가 앞뒤 공백을 trim하고, 빈 문자열이면 서버 호출 없이 빈 배열을 즉시 반환한다(타이핑 중 불필요한 네트워크 호출 방지).
- **작품 제목/작가 검색은 이 모듈이 아니라 `NovelDomain.SearchNovelUseCase`**를 그대로 쓴다(`NovelRepository` 소유이므로) — Search 화면에 있다고 전부 이 모듈로 옮기지 않는다. 같은 이유로 **실시간 인기 키워드(`PopularKeywords`)는 `BaseDomain`**에 있다(키워드 카탈로그 소유가 `BaseDomain`이라서).

## 주의사항 (작업 중 발견 시 누적)

- `RecentSearchWord.id`는 서버 발급 `SearchWordID`(`IDWrapper<Int>`, `BaseDomain.WSSIdentifiers`에 등록됨) — 클라이언트가 임의로 생성하지 않는다.
- 구현체는 `SearchData`(`RecentSearchRepository`/`SearchAutoCompletionRepository` 둘 다 `DefaultSearchRepository` 하나가 구현). 실서버 확인 완료 — 세부 응답 형태는 `SearchData/CLAUDE.md` 참고.
