<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SearchData

`SearchDomain`의 Repository 구현 — `DefaultSearchRepository` 하나가 `RecentSearchRepository`·`SearchAutoCompletionRepository` 둘 다 구현.

- 식별자: `ModuleType.data(.search)` / 의존: `SearchDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `SearchDataFactory.makeRepository(network:logger:)` → `any RecentSearchRepository & SearchAutoCompletionRepository`

## 핵심 시나리오

- **실시간 인기 키워드(`BaseDomain.PopularKeywords`, `KeywordRepository.fetchPopularKeywords`)는 이 모듈이 아니라 `BaseData`가 구현한다** — Entity/Repository가 `BaseDomain`(Search가 아니라)에 있기 때문. `SearchData`에 넣지 않도록 주의.
- 최근 검색어는 검색 실행 시 서버가 자동 기록하므로 이 모듈에 별도 "add" API는 없다(조회/삭제/전체삭제만, `SearchEndpoint`의 `getRecentSearchWords`/`deleteRecentSearchWord`/`deleteAllRecentSearchWords`).

## 주의사항 (작업 중 발견 시 누적)

- **모든 엔드포인트 실서버로 확인 완료(#163)** — 더는 추정치 아님.
- 자동완성(`getAutoCompletionWords`, `/novels/autocomplete?query=&size=`) 응답은 `{ "keywords": [String] }` **문자열 배열**이다(객체 배열 아님) — `keywords: [String]`으로 디코딩해 각 문자열을 바로 `SearchAutoCompletionWord(word:)`로 감싼다. 중간에 `SearchAutoCompletionWordResponse` 같은 객체 DTO를 다시 넣지 말 것.
- 최근 검색어(`getRecentSearchWords`/`deleteRecentSearchWord`/`deleteAllRecentSearchWords`)는 `/novels/recent-searches`(`{id}` 서브패스로 개별 삭제) — 응답은 `{ "recentSearches": [{ "id": Int, "keyword": String }] }`(`RecentSearchWordsResponse`) 그대로 확인됨.
- `deleteRecentSearchWord`는 `RecentSearchWord.id.value`(서버 발급 Int)를 경로에 그대로 심는다(`CommentData`/`FeedData`의 delete 패턴과 동일) — 쿼리 DTO 없음.
