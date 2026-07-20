<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseDomain

모든 Domain 모듈의 **공통 토대**. 다른 Domain은 거의 항상 이걸 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.domain(.base)` / 의존: 없음 (순수 Swift)

## 여기 들어있는 핵심 공통 타입

- `RepositoryError` — 전 레이어 공통 에러 (Data가 여기로 변환해 throw). `notFound`(404)와 `forbidden`(403, 숨김·차단 등 "존재하나 접근 불가")은 의도적으로 분리돼 있다 — 특정 화면이 둘을 같은 취급으로 묶고 싶으면 그 화면에서 `error == .notFound || error == .forbidden`처럼 판단하고, 전역 매핑에서 섞지 말 것(FeedDetail의 "피드를 찾을 수 없어요" 알럿이 그 예).
- `Paginated<T>` (`PaginatedWrapper`) — 페이지네이션 공통 래퍼.
- `WSSIdentifiers` / `IDWrapper` — `NovelID`, `UserID`, `FeedID`, `CommentID` 등 타입 안전 ID 래퍼.
- 공통 값 타입: `Rating`, `NovelGenre`, `Author`, `ReadingStatus`, `ReadingPeriod`, `SortType`, `AttractivePoint`, `ConnectedNovel`.
- **Keyword 서브도메인** (`Keyword/`): `Keyword`, `KeywordGroup` Entity + `KeywordRepository` + `SearchKeywordsUseCase` + 루트의 `LoadTotalKeywordsUseCase`.

## 주의사항 (작업 중 발견 시 누적)

- `KeywordRepository`의 `fetchKeywords`/`searchKeywords`는 **로컬 DB(파일 캐시) 기반**, `syncKeywords()`는 서버→로컬 동기화이며 **`throws` 없는 `async`**(실패를 던지지 않음). **`fetchPopularKeywords`(실시간 인기 키워드)만 예외적으로 매번 서버 직접 호출** — 같은 프로토콜 안에 로컬/서버 계약이 섞여 있으니 새 메서드 추가 시 어느 쪽인지 doc comment에 명시할 것. 구현은 `BaseData`의 `DefaultKeywordRepository` 하나.
- 키워드는 여러 도메인(Novel, Profile 등)이 캐시로 주입받아 쓴다 → Keyword 변경 시 교차 영향 확인.
- ID는 반드시 래퍼 타입 사용. raw `Int`/`String`을 도메인 경계로 넘기지 말 것.
- 화면 전용 부분집합/순서가 있는 필터 목록(예: 구 `NovelGenre.filterGenre`)은 여기 두지 않는다 — `BaseDomain`은 순수 enum만 갖고, 그런 목록은 `WSSComponent`의 `DomainPresentation` 확장(`NovelGenre+Presentation`)에 둔다.
- `PopularKeywords`(`Keyword/Entity/`)는 실시간 인기 키워드 랭킹을 담는 별도 타입 — 랭킹은 `keywords: [Keyword]` **배열 순서로만** 표현한다(명시적 rank/count 필드 없음).
