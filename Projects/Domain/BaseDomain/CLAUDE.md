<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# BaseDomain

모든 Domain 모듈의 **공통 토대**. 다른 Domain은 거의 항상 이걸 의존한다. (= 여기 바꾸면 광범위 영향)

- 식별자: `ModuleType.domain(.base)` / 의존: 없음 (순수 Swift)

## 여기 들어있는 핵심 공통 타입

- `RepositoryError` — 전 레이어 공통 에러 (Data가 여기로 변환해 throw). `notFound`(404)와 `forbidden`(403, 숨김·차단 등 "존재하나 접근 불가")은 의도적으로 분리돼 있다 — 특정 화면이 둘을 같은 취급으로 묶고 싶으면 그 화면에서 `error == .notFound || error == .forbidden`처럼 판단하고, 전역 매핑에서 섞지 말 것(FeedDetail의 "피드를 찾을 수 없어요" 알럿이 그 예).
- `Paginated<T>`(`PaginatedWrapper`) / `CursorPaginated<T>` — 페이지네이션 래퍼 **두 종류**. 아래 주의사항의 "셋이 공존한다" 항목을 먼저 읽을 것.
- `WSSIdentifiers` / `IDWrapper` — `NovelID`, `UserID`, `FeedID`, `CommentID` 등 타입 안전 ID 래퍼.
- 공통 값 타입: `Rating`, `NovelGenre`, `Author`, `ReadingStatus`, `ReadingPeriod`, `SortType`, `AttractivePoint`, `ConnectedNovel`.
- **Novel 서브도메인** (`Novel/`): `Novel` Entity(관심 등록 정책 포함) + `NovelPublicationStatus`. 원래 `NovelDomain` 소유였으나 `NovelDomain`(서재·상세)과 `SearchDomain`(작품 검색) 양쪽이 참조해야 해서 이곳으로 승격했다(작품 검색을 `SearchDomain`으로 옮긴 리팩토링, 관련 배경은 `SearchDomain/CLAUDE.md` 참고).
- **Keyword 서브도메인** (`Keyword/`): `Keyword`, `KeywordCategory`(카테고리 enum), `KeywordGroup`(`category` + `keywords`), `PopularKeywords` Entity + `KeywordRepository` + `SearchKeywordsUseCase`/`LoadTotalKeywordsUseCase`(전부 `Keyword/` 하위로 통합됨).
- **`AppURL`** — 앱 전역 외부 웹 링크 카탈로그(예: 작품 등록 문의, 오류 제보 노션 폼). Data가 아니라 여기 있는 이유: Feature는 Data를 import할 수 없어서(`App → Feature → Domain ← Data`), Feature가 직접 참조 가능한 곳이 BaseDomain뿐이다. 순수 `URL?` 상수 나열 — 네트워크 호출·설정 로딩 없음(그런 게 필요해지면 BaseData의 `NetworkingConfig`처럼 Data 레이어로 옮길 것).
- **`DeepLink`**(#228) — 딥링크의 **생성(`url`·`kakaoExecutionParameters`)과 파싱(`init?(url:)`)을 한 타입에** 둔다. 만드는 쪽(Feature의 공유 버튼)과 받는 쪽(App `onOpenURL`)이 같은 규칙을 봐야 어긋나지 않아서다 — 새 딥링크 화면을 추가할 땐 case를 늘리고 **양쪽을 같은 커밋에서** 고칠 것(App의 4탭 Root `switch`가 exhaustive라 컴파일러가 잡아준다). `AppURL`과 같은 이유로 여기 있다(Feature가 참조 가능한 유일한 공통 자리). 받는 형식은 둘: `websoso://<host>/<정수 id>`(커스텀 스킴, App `Info.plist` 등록)와 `kakao{APP_KEY}://kakaolink?collectionId=<id>`(카카오톡 공유 카드의 "앱에서 보기" — 카드에 실은 `kakaoExecutionParameters`가 쿼리로 되돌아온 것). ⚠️ **`kakaolink` host는 스킴을 검사하지 않는다** — 앱 키는 App 설정에만 있어 이 모듈이 모르고, 어차피 등록된 스킴만 앱에 도착한다. 스킴·host는 대소문자 무시. **ID는 양의 정수만 인정**(`0`·음수는 nil, 리뷰 반영) — 통과시키면 존재할 수 없는 ID로 상세를 열어 404 실패 화면부터 보게 된다. **`websoso://` 생성(`url`)은 지금 프로덕션 호출자가 없다**(공유는 카카오 카드 하나로 통일, 2026-08-29) — 시뮬레이터 실측(`simctl openurl`)과 Universal Link 전 단계용으로 스킴 등록과 함께 남겨둔 것이니 "미사용"이라 지우지 말 것.

## 주의사항 (작업 중 발견 시 누적)

- `KeywordRepository`의 `fetchKeywords`/`searchKeywords`는 **로컬 DB(파일 캐시) 기반**, `syncKeywords()`는 서버→로컬 동기화이며 **`throws` 없는 `async`**(실패를 던지지 않음). **`fetchPopularKeywords`(실시간 인기 키워드)만 예외적으로 매번 서버 직접 호출** — 같은 프로토콜 안에 로컬/서버 계약이 섞여 있으니 새 메서드 추가 시 어느 쪽인지 doc comment에 명시할 것. 구현은 `BaseData`의 `DefaultKeywordRepository` 하나.
- 키워드는 여러 도메인(Novel, Profile 등)이 캐시로 주입받아 쓴다 → Keyword 변경 시 교차 영향 확인.
- ID는 반드시 래퍼 타입 사용. raw `Int`/`String`을 도메인 경계로 넘기지 말 것.
- **페이지네이션 모델이 셋 공존한다 — 하나로 합치려 하지 말 것.** 서재·컬렉션은 서버가 발급한 불투명 커서(`CursorPaginated`,
  `nextCursor`를 그대로 왕복), 피드는 `lastFeedId`(클라이언트가 마지막 항목에서 **유도**), 검색은 `page`/`size` 오프셋이다.
  뒤 둘은 넘길 커서 자체가 없어서 `CursorPaginated`로 바꾸면 `nextCursor`가 영원히 nil인 껍데기 필드가 되고,
  특히 피드의 `lastFeedId` 방식은 `CursorPaginated` 주석이 명시적으로 금지한 그 패턴이다.
  → `Paginated<T>`(68곳에서 사용)를 "구식이니 지우자"고 접근하지 말 것. 서버가 커서로 통일하면 그때 다시 본다.
  (`CursorPaginated`는 서재 전용이었으나 컬렉션도 같은 방식이라 #191에서 `NovelDomain`에서 승격했다.)
- 화면 전용 부분집합/순서가 있는 필터 목록(예: 구 `NovelGenre.filterGenre`, `47b59a6a`에서 `WSSComponent`의 `myFeedFilter`로 이동·개명됨)은 여기 두지 않는다 — `BaseDomain`은 순수 enum만 갖고, 그런 목록은 `WSSComponent`의 `DomainPresentation` 확장(`NovelGenre+Presentation`)에 둔다.
  - ⚠️ **오래된 브랜치를 develop 위로 rebase하면 이 파일에서 `extension NovelGenre { filterGenre ... }` 형태의 충돌이 뜰 수 있다** — develop(빈 확장) 쪽이 맞다. 옛 `filterGenre`를 되살리지 말고, 그 커밋이 함께 추가한 새 목록(있다면)만 `WSSComponent`의 `DomainPresentation` 확장으로 옮겨 반영할 것.
- `PopularKeywords`(`Keyword/Entity/`)는 실시간 인기 키워드 랭킹을 담는 별도 타입 — 랭킹은 `keywords: [Keyword]` **배열 순서로만** 표현한다(명시적 rank/count 필드 없음).
- **`Author.accessibleUserId`(#197 후속, 2026-08-28)** — 서버는 탈퇴한 유저를 `userId: -1`로 내려준다(피드
  관련 응답 `TotalFeedResponse`/`FeedDetailResponse`/`NovelFeedResponse`가 전부 `userId: Int` non-optional이라
  항상 채워진다 — `Author.userId`가 옵셔널인 건 다른 매퍼가 애초에 안 채우는 경우 대비일 뿐, 이 -1과는
  무관). 이 센티널 판정을 `Author` 밖으로 새지 않게 캡슐화한 게 `accessibleUserId: UserID?`(nil이면
  "이동할 프로필이 없다" — userId 미제공과 탈퇴 유저 둘 다 같은 의미로 묶는다). ⚠️ **`UserID` 자체
  (`IDWrapper<Int>` typealias)를 확장해 `.withdrawn`을 두지 않았다** — `FeedID`/`NovelID` 등 다른 ID도
  전부 같은 `IDWrapper<Int>`라 그렇게 하면 의미 없는 `FeedID.withdrawn`까지 새어버린다. 센티널은
  `Author.swift` 안 `private` 상수로만 존재한다 — 다른 곳에서 `-1` 리터럴로 재판정하지 말고 이 프로퍼티를
  재사용할 것(Feature 3곳 — `SosoFeedView`/`FeedDetailView`/`NovelDetailFeedTab` — 이 이미 이걸 쓴다).
- `NovelGenre.myFeedFilter`(피드 필터용, 구 `filterGenre`)·`.searchGenre`(검색 화면 장르 그리드용)·`.onboardingGenre`(온보딩 3x3 배지 그리드용, #178)는 **의도적으로 다른 순서**의 별개 목록 — 한쪽을 고친다고 다른 쪽까지 맞추지 말 것.
- **`KeywordCategory`는 `AttractivePoint`와 동일 패턴**(raw value 없는 순수 enum, `CaseIterable`) — 카테고리명·아이콘 같은 표시값은 도메인에 두지 않고 `WSSComponent`의 `DomainPresentation` 확장이 담당한다. 서버 응답의 `categoryImage`(카테고리 아이콘 URL)는 **의도적으로 매핑하지 않는다** — 아이콘은 로컬 고정 에셋(카테고리가 5종으로 고정)이라 서버 값을 매번 받을 필요가 없다는 판단.
- `RepositoryError.privateProfile`: 상대가 프로필을 비공개로 설정해 접근 자체가 거부된 경우 전용(서버 비즈니스 코드 `USER-015`) — `authenticationRequired`(내 세션 문제)와는 원인이 달라 재로그인으로 해결되지 않는다. 매핑은 공용 `NetworkingError.toRepositoryError()`가 아니라 영향받는 개별 Data 리포지토리 메서드가 한다(UserPageFeature #172, 자세한 이유는 `ProfileData`/`FeedData` 주의사항 참고).
- **`ConnectedNovel`은 `Hashable`을 준수한다**(#197) — 두 가지 이유가 겹친다. ① `FeedFeature`의
  `CreateFeedViewModel`이 `FeedDraft`(이 값을 담음) 전체를 원본과 비교해 "변경 없음"을 판단(수정
  모드에서 아무것도 안 바꾸면 "완료" 버튼이 비활성 상태를 유지해야 해서)하는 데 `Equatable`이 필요하고,
  ② App의 각 탭 `Destination` enum이 작품 상세 "나도 한마디"(`createFeedFromNovel(ConnectedNovel)`)를
  `NavigationPath`에 직접 push하려면 `Hashable`(`Destination: Hashable` 준수 조건)이 필요하다. 필드가
  전부 이미 Hashable이라 자동 합성만으로 충분했다.
- ⚠️ **`LoadTotalKeywordsUseCase`/`SearchKeywordsUseCase`의 구현 클래스명은 프로토콜명을 따르지 않는다** — 각각 `DefaultFetchTotalKeywordsUseCase`("Load"가 아니라 "Fetch")와 `DefaultSearchKeywordUseCase`("Keywords"가 아니라 단수 "Keyword")다. 다른 Default 구현체 대부분은 프로토콜명 그대로라(`DefaultDeleteFeedUseCase` 등) 관례를 따라 이름을 추측하면 컴파일 에러로 걸린다(`LoadFeedDetailUseCase`/`DefaultLoadFeedUseCase`와 같은 종류의 함정, `FeedDomain/CLAUDE.md` 참고). 리네임하면 이 문서도 같이 고칠 것.
