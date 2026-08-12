<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseDomain

모든 Domain 모듈의 **공통 토대**. 다른 Domain은 거의 항상 이걸 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.domain(.base)` / 의존: 없음 (순수 Swift)

## 여기 들어있는 핵심 공통 타입

- `RepositoryError` — 전 레이어 공통 에러 (Data가 여기로 변환해 throw). `notFound`(404)와 `forbidden`(403, 숨김·차단 등 "존재하나 접근 불가")은 의도적으로 분리돼 있다 — 특정 화면이 둘을 같은 취급으로 묶고 싶으면 그 화면에서 `error == .notFound || error == .forbidden`처럼 판단하고, 전역 매핑에서 섞지 말 것(FeedDetail의 "피드를 찾을 수 없어요" 알럿이 그 예).
- `Paginated<T>` (`PaginatedWrapper`) — 페이지네이션 공통 래퍼.
- `WSSIdentifiers` / `IDWrapper` — `NovelID`, `UserID`, `FeedID`, `CommentID` 등 타입 안전 ID 래퍼.
- 공통 값 타입: `Rating`, `NovelGenre`, `Author`, `ReadingStatus`, `ReadingPeriod`, `SortType`, `AttractivePoint`, `ConnectedNovel`.
- **Novel 서브도메인** (`Novel/`): `Novel` Entity(관심 등록 정책 포함) + `NovelRatingThreshold` + `NovelPublicationStatus`. 원래 `NovelDomain` 소유였으나 `NovelDomain`(서재·상세)과 `SearchDomain`(작품 검색) 양쪽이 참조해야 해서 이곳으로 승격했다(작품 검색을 `SearchDomain`으로 옮긴 리팩토링, 관련 배경은 `SearchDomain/CLAUDE.md` 참고).
- **Keyword 서브도메인** (`Keyword/`): `Keyword`, `KeywordCategory`(카테고리 enum), `KeywordGroup`(`category` + `keywords`), `PopularKeywords` Entity + `KeywordRepository` + `SearchKeywordsUseCase`/`LoadTotalKeywordsUseCase`(전부 `Keyword/` 하위로 통합됨).
- **`AppURL`** — 앱 전역 외부 웹 링크 카탈로그(예: 작품 등록 문의, 오류 제보 노션 폼). Data가 아니라 여기 있는 이유: Feature는 Data를 import할 수 없어서(`App → Feature → Domain ← Data`), Feature가 직접 참조 가능한 곳이 BaseDomain뿐이다. 순수 `URL?` 상수 나열 — 네트워크 호출·설정 로딩 없음(그런 게 필요해지면 BaseData의 `NetworkingConfig`처럼 Data 레이어로 옮길 것).

## 주의사항 (작업 중 발견 시 누적)

- `KeywordRepository`의 `fetchKeywords`/`searchKeywords`는 **로컬 DB(파일 캐시) 기반**, `syncKeywords()`는 서버→로컬 동기화이며 **`throws` 없는 `async`**(실패를 던지지 않음). **`fetchPopularKeywords`(실시간 인기 키워드)만 예외적으로 매번 서버 직접 호출** — 같은 프로토콜 안에 로컬/서버 계약이 섞여 있으니 새 메서드 추가 시 어느 쪽인지 doc comment에 명시할 것. 구현은 `BaseData`의 `DefaultKeywordRepository` 하나.
- 키워드는 여러 도메인(Novel, Profile 등)이 캐시로 주입받아 쓴다 → Keyword 변경 시 교차 영향 확인.
- ID는 반드시 래퍼 타입 사용. raw `Int`/`String`을 도메인 경계로 넘기지 말 것.
- 화면 전용 부분집합/순서가 있는 필터 목록(예: 구 `NovelGenre.filterGenre`, `47b59a6a`에서 `WSSComponent`의 `myFeedFilter`로 이동·개명됨)은 여기 두지 않는다 — `BaseDomain`은 순수 enum만 갖고, 그런 목록은 `WSSComponent`의 `DomainPresentation` 확장(`NovelGenre+Presentation`)에 둔다.
  - ⚠️ **오래된 브랜치를 develop 위로 rebase하면 이 파일에서 `extension NovelGenre { filterGenre ... }` 형태의 충돌이 뜰 수 있다** — develop(빈 확장) 쪽이 맞다. 옛 `filterGenre`를 되살리지 말고, 그 커밋이 함께 추가한 새 목록(있다면)만 `WSSComponent`의 `DomainPresentation` 확장으로 옮겨 반영할 것.
- `PopularKeywords`(`Keyword/Entity/`)는 실시간 인기 키워드 랭킹을 담는 별도 타입 — 랭킹은 `keywords: [Keyword]` **배열 순서로만** 표현한다(명시적 rank/count 필드 없음).
- `NovelGenre.myFeedFilter`(피드 필터용, 구 `filterGenre`)·`.searchGenre`(검색 화면 장르 그리드용)·`.onboardingGenre`(온보딩 3x3 배지 그리드용, #178)는 **의도적으로 다른 순서**의 별개 목록 — 한쪽을 고친다고 다른 쪽까지 맞추지 말 것.
- **`KeywordCategory`는 `AttractivePoint`와 동일 패턴**(raw value 없는 순수 enum, `CaseIterable`) — 카테고리명·아이콘 같은 표시값은 도메인에 두지 않고 `WSSComponent`의 `DomainPresentation` 확장이 담당한다. 서버 응답의 `categoryImage`(카테고리 아이콘 URL)는 **의도적으로 매핑하지 않는다** — 아이콘은 로컬 고정 에셋(카테고리가 5종으로 고정)이라 서버 값을 매번 받을 필요가 없다는 판단.
- `RepositoryError.privateProfile`: 상대가 프로필을 비공개로 설정해 접근 자체가 거부된 경우 전용(서버 비즈니스 코드 `USER-015`) — `authenticationRequired`(내 세션 문제)와는 원인이 달라 재로그인으로 해결되지 않는다. 매핑은 공용 `NetworkingError.toRepositoryError()`가 아니라 영향받는 개별 Data 리포지토리 메서드가 한다(UserPageFeature #172, 자세한 이유는 `ProfileData`/`FeedData` 주의사항 참고).
