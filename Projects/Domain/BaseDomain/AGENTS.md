<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseDomain

모든 Domain 모듈의 **공통 토대**. 다른 Domain은 거의 항상 이걸 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.domain(.base)` / 의존: 없음 (순수 Swift)

## 여기 들어있는 핵심 공통 타입

- `RepositoryError` — 전 레이어 공통 에러 (Data가 여기로 변환해 throw).
- `Paginated<T>` (`PaginatedWrapper`) — 페이지네이션 공통 래퍼.
- `WSSIdentifiers` / `IDWrapper` — `NovelID`, `UserID`, `FeedID`, `CommentID` 등 타입 안전 ID 래퍼.
- 공통 값 타입: `Rating`, `NovelGenre`, `Author`, `ReadingStatus`, `ReadingPeriod`, `SortType`, `AttractivePoint`, `ConnectedNovel`, `ImageWrapper`.
- **Keyword 서브도메인** (`Keyword/`): `Keyword`, `KeywordGroup` Entity + `KeywordRepository` + `SearchKeywordsUseCase` + 루트의 `LoadTotalKeywordsUseCase`.

## 주의사항 (작업 중 발견 시 누적)

- `KeywordRepository`는 **로컬 DB 기반** — `fetchKeywords`/`searchKeywords`는 로컬 조회, `syncKeywords()`는 서버→로컬 동기화이며 **`throws` 없는 `async`** (실패를 던지지 않음). 구현은 `BaseData`.
- 키워드는 여러 도메인(Novel, Profile 등)이 캐시로 주입받아 쓴다 → Keyword 변경 시 교차 영향 확인.
- ID는 반드시 래퍼 타입 사용. raw `Int`/`String`을 도메인 경계로 넘기지 말 것.
