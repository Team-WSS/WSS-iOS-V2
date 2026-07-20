# SearchFeature

일반 검색 화면(`NormalSearchView`). 5개 섹션 중 **소소픽·최근 검색어·키워드 검색(인기 키워드)이 실제 UseCase로 연동**됐고 나머지(장르별 검색/검색 실행)는 정적 UI + TODO 액션 상태. 검색어 입력 중에는 **검색어 자동완성**(`SearchAutoCompletionWordsUseCase`)도 실서버 연동됨.

- 식별자: `ModuleType.feature(.search)` / 의존: `BaseDomain`, `RecommendationDomain`, `SearchDomain`, `DesignSystem`, `WSSComponent`, `Logger` (`NovelDomain`은 검색 결과 화면 구현 시 추가 예정 — 아직 미사용이라 뺌)
- 진입점: `SearchFactory.makeView(loadSosoPickUseCase:loadRecentSearchWordsUseCase:removeRecentSearchWordUseCase:clearRecentSearchWordsUseCase:searchAutoCompletionWordsUseCase:loadPopularKeywordsUseCase:logger:)`

## 핵심 시나리오

- `NormalSearchView` = 상단바(뒤로가기+검색바) + 최근 검색어 + 장르별 검색 + 키워드 검색 + 소소픽, 세로 나열.
- `onAppear` → `.loadSosoPick`/`.loadRecentSearchWords`/`.loadPopularKeywords` 세 액션을 함께 발동. 각각 1회만 로드(`hasLoaded*` 가드).
- **최근 검색어**: `SearchDomain`의 `Load`/`Remove`/`Clear`RecentSearchWordsUseCase로 연동. 개별 삭제·전체 삭제 모두 낙관적 반영 후 서버 실패 시 롤백한다. 목록이 비면 섹션 전체를 숨긴다.
- **키워드 검색**: `BaseDomain.LoadPopularKeywordsUseCase`(실시간 인기 키워드)로 연동. `PopularKeywords.keywords`를 그대로 표시(순서=랭킹, 재정렬 금지 — BaseDomain 문서 참고).
- **검색어 자동완성**: 검색바 포커스 상태(`isFocused`) + 검색어 비어있지 않음, 두 조건이 모두 참일 때 `NormalSearchAutoCompletionView`가 나머지 섹션을 덮어쓴다. `updateSearchText`가 입력마다 이전 `Task`를 취소하고 300ms debounce 후 `SearchAutoCompletionWordsUseCase`를 호출(타이핑 중 매 글자마다 서버를 치지 않기 위함). 제안어 탭 시 `.updateSearchText(word.word)`로 검색창에 반영(검색 실행 자체는 TODO). 일치 구간은 `wssPrimary100`로 하이라이트(대소문자 무시, 첫 일치 구간만).
- 나머지 섹션(장르 탭 이동, 검색 실행, 뒤로가기)은 하드코딩 더미 데이터만 있고 버튼 액션은 전부 TODO.

## 주의사항 (작업 중 발견 시 누적)

- **전용 SearchDomain이 생겼다**(#163). 검색 관련 UseCase는 여전히 도메인별로 흩어져 있다: 작품 검색은 `NovelDomain.SearchNovelUseCase`, 키워드 검색은 `BaseDomain.SearchKeywordsUseCase`, 소소픽은 `RecommendationDomain.LoadSosoPickUseCase`, 최근 검색어/자동완성은 `SearchDomain`. 나머지 섹션 구현 시 어떤 UseCase를 쓸지 확정하고 필요하면 `Project.swift`의 `internalDependencies`를 갱신할 것.
- 장르별 검색 그리드는 `BaseDomain.NovelGenre.searchGenre`(필터용 `filterGenre`와 순서가 다른 별개 목록) 순서를 그대로 쓴다.
- `WhiteRemovableKeywordChip(keyword:onSelect:onDelete:)`로 콜백이 분리됨 — X 버튼(`onDelete`)은 `Button`, 나머지 칩 영역(`onSelect`)은 바깥 `onTapGesture`(WSSComponent CLAUDE.md의 "Button이 onTapGesture보다 hit-test 우선" 패턴). X는 이제 `Button`이라 접근성 트리에 잡혀 자동화 탭 가능. `onSelect`는 현재 검색창 텍스트만 채우고 실제 검색 실행은 TODO(`WSSSearchBar.onSearch`와 같이 아직 미구현).
- `.tests` 타깃은 아직 없다. 화면 로직(특히 나머지 섹션의 UseCase 연동)이 늘어나면 `Project.swift`의 `targets`에 `.tests`를 추가하고 `Tests/` 폴더를 만든다.
- **`.scrollBounceBehavior(.basedOnSize)`의 `axes` 기본값은 `.vertical`** — 가로 `ScrollView`(이 화면의 최근 검색어/장르별 검색/소소픽 전부 가로)에 걸려면 `axes: .horizontal`을 반드시 명시해야 한다. 안 그러면 아무 효과 없이 무시된다(에러도 없이 조용히 무시돼 원인 찾기 어렵다). 지금은 최근 검색어 섹션만 적용, 나머지 가로 스크롤도 필요해지면 같은 함정 주의.
- `NormalSearchAutoCompletionView`의 제안어 행은 액션이 하나뿐이라(`WhiteRemovableKeywordChip`처럼 X 버튼과 경합하는 두 번째 액션이 없음) `onTapGesture` 대신 **`Button`으로 감싼다** — 접근성 트리에 잡혀야 자동화 탭(`snapshot_ui`/`tap`)이 가능하고, 여러 액션이 공존하는 칩류가 아니라면 `Button`이 기본값.
- **최근 검색어 개별 삭제와 전체 삭제는 서로 배타적**(`removingRecentSearchWordIDs.isEmpty`/`isClearingRecentSearchWords` 상호 가드) — 처음엔 각자 낙관적 반영 시점의 배열 전체를 스냅샷해뒀다가 실패 시 그 스냅샷으로 복원하는 방식이었는데, 두 종류가 동시에 진행되면 나중에 실패한 쪽의 스냅샷 복원이 그 사이 반영된 다른 변경을 덮어써 서버-화면 상태가 어긋나는 버그가 있었다(PR 리뷰에서 발견). 그래서 **개별 삭제 롤백은 스냅샷 복원이 아니라 그 단어 하나만 재삽입**하도록 바꿨고, 두 액션은 서로 진행 중이면 무시하도록 가드했다. 이후 수정 시 "스냅샷 후 통째로 복원" 패턴으로 되돌리지 말 것 — 여러 항목이 동시에 지워질 수 있는 화면에서는 안전하지 않다(단일 엔티티만 다루는 `NovelDetailViewModel`의 관심 토글 롤백과는 성격이 다름).
