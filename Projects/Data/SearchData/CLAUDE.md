<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SearchData

`SearchDomain`의 Repository 구현 — `DefaultSearchRepository` 하나가 `RecentSearchRepository`·`SearchAutoCompletionRepository`·`SearchNovelRepository` **세 개 다** 구현.

- 식별자: `ModuleType.data(.search)` / 의존: `SearchDomain`, `BaseDomain`, `BaseData`, `Networking`, `Logger`
- 진입점: `SearchDataFactory.makeRepository(network:logger:)` → `any RecentSearchRepository & SearchAutoCompletionRepository & SearchNovelRepository`

## 핵심 시나리오

- **실시간 인기 키워드(`BaseDomain.PopularKeywords`, `KeywordRepository.fetchPopularKeywords`)는 이 모듈이 아니라 `BaseData`가 구현한다** — Entity/Repository가 `BaseDomain`(Search가 아니라)에 있기 때문. `SearchData`에 넣지 않도록 주의.
- 최근 검색어는 검색 실행 시 서버가 자동 기록하므로 이 모듈에 별도 "add" API는 없다(조회/삭제/전체삭제만, `SearchEndpoint`의 `getRecentSearchWords`/`deleteRecentSearchWord`/`deleteAllRecentSearchWords`).
- **작품 텍스트/필터 검색(`searchNovelByText`/`searchNovelByFilter`)은 원래 `NovelData` 소유였다가 이 모듈로 이관됐다** — 엔드포인트(`/novels`, `/novels/filtered`), DTO(`NormalSearchQuery`/`DetailSearchQuery`/`SearchNovelsResponse`), 매퍼(`SearchMapper.searchNovels`/`searchNovel`/`detailSearchQuery`)가 전부 여기로 옮겨왔다. `NovelData`는 더 이상 이 두 엔드포인트를 모른다.

## 주의사항 (작업 중 발견 시 누적)

- **모든 엔드포인트 실서버로 확인 완료(#163)** — 더는 추정치 아님.
- 자동완성(`getAutoCompletionWords`, `/novels/autocomplete?query=&size=`) 응답은 `{ "keywords": [String] }` **문자열 배열**이다(객체 배열 아님) — `keywords: [String]`으로 디코딩해 각 문자열을 바로 `SearchAutoCompletionWord(word:)`로 감싼다. 중간에 `SearchAutoCompletionWordResponse` 같은 객체 DTO를 다시 넣지 말 것.
- 최근 검색어(`getRecentSearchWords`/`deleteRecentSearchWord`/`deleteAllRecentSearchWords`)는 `/novels/recent-searches`(`{id}` 서브패스로 개별 삭제) — 응답은 `{ "recentSearches": [{ "id": Int, "keyword": String }] }`(`RecentSearchWordsResponse`) 그대로 확인됨.
- `deleteRecentSearchWord`는 `RecentSearchWord.id.value`(서버 발급 Int)를 경로에 그대로 심는다(`CommentData`/`FeedData`의 delete 패턴과 동일) — 쿼리 DTO 없음.
- **일반 검색(`getNormalSearchResult`, `/novels`)은 `.usesTokenIfAvailable`**(#165에서 `.withoutToken` → 수정 — 토큰이 없으면 서버가 검색을 익명 요청으로 봐서 최근 검색어로 기록하지 못한다), 상세/필터 검색(`getDetailSearchResult`, `/novels/filtered`)은 `.requireToken` — 인가 정책이 서로 다르다. 자동완성(`.usesTokenIfAvailable`)과는 값은 같지만 이유가 다르니 새 검색 엔드포인트 추가 시 이 셋 중 어디에 해당하는지 확인할 것.
- **`searchNovel` 매퍼가 만드는 `Novel.genres`는 항상 `[]`다** — 검색 응답(`SearchNovelResponse`)에 장르 필드가 없어서다(상세 조회의 `novelGenres`와 달리). 검색 결과 카드에서 장르를 보여줘야 하면 이 응답만으로는 안 되고 상세 조회가 별도로 필요하다.
- **`NovelData`에서 옮겨온 메서드는 성공 로깅(`logger?.logSuccess(action:)`)이 누락되기 쉽다** — `searchNovelByText`/`searchNovelByFilter` 이관 시 catch 분기의 에러 로깅만 그대로 옮기고 성공 분기의 `logSuccess` 호출을 빠뜨렸다가 PR 리뷰에서 발견됐다(#163). 다른 모듈에서 메서드를 이관할 때도 성공 로깅이 딸려왔는지 확인할 것.
- **상세탐색 필터(#185) 쿼리 파라미터**: `platformNames: [String]`(한글 표기, UI 라벨 "리디"↔서버값 "리디북스" 불일치 의도됨, `SearchMapper.mapNovelPlatformString`)과 별점 범위 `novelRatingStart`/`novelRatingEnd: Float`(사용자 확정 필드명). 필터 없음(`ratingRange == nil`)이면 전체 범위(0.0~5.0)를 그대로 보낸다. (초기엔 단일값 `novelRating`도 함께 있었으나 #185 후반에 `SearchFilter.ratingThreshold` 자체가 제거되며 같이 빠졌다.)
- **⚠️ `DetailSearchQuery.isCompleted`는 `Bool`(non-optional)이라 연재상태 미선택도 `false`로 나가는데, 서버는 `false`를 "연재중만"으로 해석한다**(실서버 검증 2026-08-28: `/novels/filtered`에서 `false`=9,319·`true`=85,708·생략=95,027=9,319+85,708). 즉 **미선택 시 완결작이 통째로 누락**된다(전체의 90%). V1은 미선택이면 파라미터를 생략해 전체를 받았다. `Bool?`로 바꿔 미선택이면 nil(→`QueryItemConvertible`이 NSNull 제외로 쿼리에서 자동 생략)해야 V1과 맞는다. 회귀 수정 대기 → `docs/TODO.md`.
