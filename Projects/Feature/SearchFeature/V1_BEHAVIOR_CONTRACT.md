# SearchFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 검색 화면들이
> **실제로 어떻게 동작했는지**를 코드에서 추출한 목록이다. V1은 "실제 운영으로 검증된 동작 기준"이고,
> V2가 이 각각을 **유지했는지 / 일부러 바꿨는지 / 삭제했는지**를 나중에 사람이 한 번에 점검하기 위한 재료다.
> (#205 축 C의 C1 산출물. 이슈 #222.)
>
> **이 문서가 아닌 것** — V2 화면의 정본 계약이 아니다. V2의 "코드만 봐선 모르는 것"은 여전히
> [`CLAUDE.md`](CLAUDE.md)가 정본이다. 이 문서는 **V1 기준으로 훑은 것**이고, 분류는 **초안**이다.

## 읽는 법 · 분류 범례

각 동작에 **초안 분류 배지**가 달려 있다. 나중에 사람이 와서 배지를 확정하고(바꾸면 바꾸고) 한 줄 근거를 남긴다.

| 배지 | 뜻 | 사용자가 할 일 |
|---|---|---|
| ✅ **Keep** | V2가 **같은 관찰 동작**을 유지(구현·구조는 달라도 됨) | 맞으면 그대로 |
| 🔧 **Improve** | V2가 V1의 버그·한계를 **의도적으로 고침**(근거 있음) | 근거 확인 |
| 🗑 **Delete** | V2가 **의도적으로 제거**한 동작 | 정말 버릴지 확인 |
| ❓ **Unknown** | 회귀일 수도, 의도일 수도 — **판정 대기** | **판정 필요** |

- ❓ 항목과 눈에 띄는 🔧/🗑는 [0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- V1 경로 접두사 생략형: `…/Search/` = `WSSiOS/Source/Presentation/Search/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/NormalSearch/NormalSearchView` (검색 진입점) | `…/Search/Search/` (`SearchViewController`+VM, **검색 탭 랜딩**) **＋** `…/Search/NormalSearch/` (`NormalSearchViewController`+VM, **push된 검색 화면**) | **V1은 2화면(랜딩→push), V2는 1화면.** V1 랜딩(비편집 검색바+소소픽+상세검색 유도 배너)이 V2에서 사라지고 그 소소픽이 NormalSearch 브라우즈로 흡수됨 (1) |
| `Sources/DetailSearch/DetailSearchFilterView` (#185) | `…/Search/DetailSearch/DetailSearchViewController`+`DetailSearchViewModel` | 정보/키워드 탭 필터 화면. **V2는 지금 Demo에서만 push**(실앱 진입점 미배선, 3) |
| `Sources/DetailSearch/DetailSearchResultView` | `…/Search/DetailSearch/DetailSearchResultViewController`+`DetailSearchResultViewModel` | 필터 검색 결과 그리드 (4) |
| (V2 신규) `NormalSearchAutoCompletionView` | **V1 대응 없음** | 검색어 자동완성은 V2 신규 (2.6) |

---

## 0. 점검 대기 요약

**❓ 판정 필요 (회귀일 수도 있음)**

1. **작품 상세 이동이 화면 전역에서 미배선/스텁이다.** V1은 소소픽 셀·일반 검색 결과 셀·상세검색 결과 셀 **셋 다** 탭하면 작품 상세로 push한다. V2는 소소픽 탭 = `print(...)` 스텁, 두 결과 그리드 = 탭 콜백 자체가 없는 순수 표시 뷰다. → [2.7](#27-작품-상세-이동)
2. **장르/키워드 섹션 "더보기" 헤더 → 상세탐색 진입이 TODO 스텁.** V1은 장르 헤더 → 상세검색 필터, 인기 키워드 헤더 → 상세검색 필터(키워드 탭)로 push. V2는 두 헤더 버튼 모두 `// TODO` 주석뿐. → [2.3](#23-장르별-검색)·[2.4](#24-키워드-검색인기-키워드)
3. **연재상태 미선택 시 `isCompleted=false`가 항상 전송된다(잠재 회귀).** V1은 연재상태 미선택이면 `isCompleted` 쿼리를 **아예 생략**(→ 전체)하는데, V2 `DetailSearchQuery.isCompleted`는 non-optional `Bool`이라 미선택도 `false`로 나간다 = "연재중만" 필터와 구별 불가. → [4.2 · 부록 A](#42-서버-요청-파라미터)
4. **로그인 유도(비로그인 브라우즈 + induce login) 전면 제거.** V1은 소소픽/검색결과/장르/키워드/상세검색 진입 등 거의 모든 상호작용을 `isLogined`로 가드해 비로그인 시 `InduceLoginViewController`를 present한다. V2엔 이 분기가 없다. → [5.1](#51-로그인-게이팅)
5. **검색창 자동 포커스(키보드 자동 노출) 미구현.** V1은 진입 시 `becomeFirstResponder()`로 키보드를 바로 띄운다. V2 `NormalSearchView`는 `onAppear`에서 포커스를 세우지 않는다. → [2.1](#21-진입생명주기)
6. **검색창 30자 입력 제한 미확인.** V1 검색 텍스트필드는 30자 초과 입력을 막는다. V2 `WSSSearchBar`의 제한 여부는 이 조사에서 확인하지 못했다. → [2.1](#21-진입생명주기)
7. **Amplitude 애널리틱스 이벤트 전면 부재.** V1은 검색 진입·일반검색·소소픽·결과 클릭·문의 등 다수 이벤트를 track한다. V2엔 대응 이벤트 전송이 없다(Logger는 에러 로깅용). → [5.2](#52-애널리틱스)

**🗑 눈에 띄는 삭제 (의도 확인)**

8. **검색 탭 랜딩 화면(`SearchView`) + "상세 검색으로 찾기" 유도 배너(`SearchDetailInduceView`) 제거** → NormalSearch 단일 화면으로 병합. → [1](#1-검색-진입랜딩-searchview)
9. **뒤로가기 3초 throttle**(연타로 pop 여러 번 막던 가드) 제거. → [2.1](#21-진입생명주기)

**🔧 눈에 띄는 개선 (근거 확인)**

10. 상세검색 결과 **에러 무처리 → `NetworkErrorView`**(V1은 실패 시 로딩만 내리고 빈 화면). → [4.3](#43-빈-화면로딩에러)
11. 최근 검색어 삭제 **롤백 추가**(V1은 서버 실패해도 롤백 없이 지운 채 유지). → [2.2](#22-최근-검색어)
12. 검색 직후 **최근 검색어 즉시 갱신**(V1은 다음 진입까지 안 보임). → [2.2](#22-최근-검색어)
13. 상세검색 정보탭 **활성 점 인디케이터가 플랫폼 선택도 반영**(V1은 플랫폼을 점 조건에서 누락 = 버그). → [3.2](#32-정보-탭-필터)
14. 플랫폼 "리디" **서버 전송값 "리디" → "리디북스"**로 정정(문서화됨). → [부록 A](#부록-a-서버-요청-파라미터-매핑-c2-비교-재료)

---

## 1. 검색 진입·랜딩 (SearchView)

원본: `…/Search/Search/SearchViewModel/SearchViewModel.swift`, `.../SearchViewController/SearchViewController.swift`

V1은 검색 **탭의 랜딩 화면**이 따로 있었다: 비편집 검색바(탭하면 검색화면 push) + 소소픽 + "상세 검색으로 찾기" 유도 배너(`SearchDetailInduceView`). 이 화면 자체는 검색을 안 하고 **진입 라우터** 역할만 한다.

- 🗑 **Delete** — 랜딩 화면(`SearchView`)과 유도 배너를 통째로 없애고 V2는 `NormalSearchView` 하나로 진입한다. V1 랜딩의 소소픽은 NormalSearch 브라우즈 섹션으로 흡수됐다(중복이던 걸 하나로).
  - V2: `SearchFeatureFactory.makeNormalSearchView(...)`가 "실제 앱 진입점"으로 명문화. 랜딩·배너 대응 코드 없음.
  - 근거: V1 `SearchViewController.swift:23`,`70-72`(랜딩+유도배너 바인딩) · V2 `SearchFeatureFactory.swift:24-46`, `CLAUDE.md`(진입점 = NormalSearch)
- 🗑 **Delete 확정** (2026-08-28: V2는 로그인 전용 앱) — 검색바 탭/유도배너 탭 시 **로그인 여부 가드**: 로그인 상태면 push, 아니면 로그인 유도 present. (5.1과 동일 사안 — 랜딩이 사라지며 함께 소멸.)
  - 근거: V1 `SearchViewModel.swift:48-68`
- ✅ **Keep** (확정 2026-08-28: SwiftUI 탭/네비 구조 차이, 대응 불필요) — `SearchView`는 진입마다 시스템 탭바를 다시 보이고(`showTabBar`) 네비바를 숨긴다(`setNavigationBarHidden(true)`). V2는 탭/네비 체계가 SwiftUI로 달라 직접 대응이 없다(구조 차이).
  - 근거: V1 `SearchViewController.swift:40-64`
- 🗑 **Delete 확정** (2026-08-28: V1 죽은 코드, 이식 불필요) — `"PushToDetailSearchResult"` Notification을 구독하지만 핸들러 본문이 비어 있다(아무 동작 안 함). V2에 대응 없음이 자연스럽다.
  - 근거: V1 `SearchViewModel.swift:70-74` · `SearchViewController.swift:88-93`(빈 subscribe)

---

## 2. 일반 검색 (NormalSearch)

원본: `…/Search/NormalSearch/NormalSearchViewModel/NormalSearchViewModel.swift`, `.../NormalSearchViewController/NormalSearchViewController.swift`

### 2.1 진입·생명주기

- ✅ **Keep** — 진입점에서 소소픽·최근검색어·인기키워드를 로드한다. V1은 소소픽을 `transform` 최초 1회, 최근검색어·인기키워드를 `viewWillAppear`마다.
  - V2: `onAppear`에서 `.loadSosoPick`/`.loadRecentSearchWords`/`.loadPopularKeywords` 셋 다 발동하되 **각각 `hasLoaded*` 가드로 1회만**. (재진입 재조회를 V1이 하던 것과 미세하게 다르나, 검색화면이 push 단발이라 관찰 차이는 거의 없음.)
  - 근거: V1 `NormalSearchViewModel.swift:160-166`,`259-268`,`331-339` · V2 `NormalSearchViewModel.swift:145-185`, `NormalSearchView.swift:108-112`
- 🔧 **복원 확정→TODO** (2026-08-28: V2 자동 포커스 없음 실측) — **검색창 자동 포커스**: V1은 `viewDidAppear`에서 `initialSearchText`가 없으면 `searchTextField.becomeFirstResponder()`로 키보드를 바로 띄운다(있으면 그 텍스트로 즉시 검색 실행).
  - V2: `NormalSearchView`는 `onAppear`에서 `isFocused`를 세우지 않아 키보드가 자동으로 뜨지 않는다. `initialSearchText` 경로도 없다.
  - 근거: V1 `NormalSearchViewController.swift:63-72` · V2 `NormalSearchView.swift:108-112`(포커스 미설정)
- 🔧 **복원 확정→TODO** (2026-08-28: V2 제한 없음 실측) — **검색어 30자 제한**: V1 텍스트필드는 `shouldChangeCharactersIn`에서 30자 초과 입력을 막는다.
  - V2: `WSSSearchBar`의 글자수 제한 여부 미확인.
  - 근거: V1 `NormalSearchViewController.swift:422-430`
- 🗑 **Delete** — **뒤로가기 3초 throttle**: V1은 back 버튼을 `throttle(.seconds(3), latest: false)`로 감싸 연타로 여러 번 pop되는 걸 막았다.
  - V2: 뒤로가기 = `@Environment(\.dismiss)` 직호출, throttle 없음.
  - 근거: V1 `NormalSearchViewController.swift:208-213`,`132`(backButton) · V2 `NormalSearchView.swift:126-135`(dismiss)
- ✅ **Keep** — 화면 아무 곳이나 탭하면 키보드가 내려간다. V1 `touchesBegan`→`endEditing(true)`, 컬렉션뷰 상하 스와이프에도 `endEditing`.
  - V2: 배경 `contentShape(Rectangle()).onTapGesture { isFocused = false }` + 자동완성 스크롤 탭 처리(`CLAUDE.md` "배경 탭 제스처" 함정).
  - 근거: V1 `NormalSearchViewController.swift:74-76`,`255-256` · V2 `NormalSearchView.swift:101-102`, `CLAUDE.md`

### 2.2 최근 검색어

- ✅ **Keep** — 최근 검색어를 서버에서 조회하고, 목록이 비면 섹션 전체를 숨긴다. 조회 실패는 빈 배열 폴백(에러 미표시).
  - V2: `LoadRecentSearchWordsUseCase`, `recentSearchWords.isEmpty`면 섹션 미표시. 실패는 로깅만.
  - 근거: V1 `NormalSearchViewModel.swift:259-268`,`292-298`(showRecentSearchView) · V2 `NormalSearchViewModel.swift:259-271`, `NormalSearchView.swift:81-85`
- ✅ **Keep** — 칩 탭(`recentSearchTagSelected`) → 그 단어로 **검색 실행**.
  - V2: `WhiteRemovableKeywordChip.onSelect` → `isFocused=false` + `.executeSearch(word.title)`.
  - 근거: V1 `NormalSearchViewModel.swift:289-290`, `NormalSearchViewController.swift:289-296`(fillSearchTextField→검색) · V2 `NormalSearchView.swift:176-183`
- ✅ **Keep** — 개별 삭제·전체 삭제 모두 **낙관적 반영 후 서버 호출**(UI를 먼저 지운다).
  - 근거: V1 `NormalSearchViewModel.swift:270-287` · V2 `NormalSearchViewModel.swift:165-180`
- 🔧 **Improve** — **삭제 실패 롤백**: V1은 서버 삭제가 실패해도 `catchAndReturn(())`으로 삼켜 **지운 채 유지**(롤백 없음, 서버-화면 불일치 가능). V2는 개별 삭제는 그 단어만 재삽입, 전체 삭제는 스냅샷 복원으로 되돌린다.
  - V2: 두 삭제가 **상호 배타**(동시 진행 시 스냅샷 롤백이 서로 덮는 버그를 막음, `CLAUDE.md`·PR 리뷰 근거).
  - 근거: V1 `NormalSearchViewModel.swift:270-281`(no rollback) · V2 `NormalSearchViewModel.swift:273-297`, `CLAUDE.md`(개별/전체 배타)
- 🔧 **Improve** — **검색 직후 즉시 갱신**: 검색 실행이 성공하면 서버가 최근 검색어를 자동 기록하는데, V1은 그 결과를 **다음 `viewWillAppear`까지** 목록에 안 비친다(그 화면에선 안 보임). V2는 검색 성공 시 가드를 우회해 최근 검색어를 곧바로 다시 불러온다.
  - 근거: V1 `NormalSearchViewModel.swift:180-196`(검색엔 recent 재조회 없음) · V2 `NormalSearchViewModel.swift:158-161`,`347`(refreshRecentSearchWordsAfterSearch)

### 2.3 장르별 검색

- ✅ **Keep** — 장르 그리드(9종)를 나열하고, 셀 탭 → `SearchFilter(genres: [genre])` 하나로 상세검색 **결과 화면**을 push한다(필터 화면 안 거치고 바로 결과).
  - V2: `genreItem` 탭 → `DetailSearchNavigation(filter: SearchFilter(genres: [genre]))` → `navigationDestination`으로 `DetailSearchResultView` push. (V1 `entryType: .genreOnly` 상당.)
  - 근거: V1 `NormalSearchViewModel.swift:300-308`, `NormalSearchViewController.swift:307-327` · V2 `NormalSearchView.swift:230-246`,`113-119`
- ✅ **Keep (순서 출처 상이)** — 장르 목록 자체는 9종으로 동일. V1은 하드코딩 `NovelGenre.normalSearchGenres`, V2는 `WSSComponent.NovelGenre.searchGenre`(Figma 실측으로 순서 재확정). 순서가 미세하게 다를 수 있으나 의도된 재정렬.
  - 근거: V1 `NovelGenre.swift:219` · V2 `NormalSearchView.swift:221`, `CLAUDE.md`(searchGenre)
- 🔧 **배선 대기→App** (2026-08-28: 상세검색 진입, App 라우터 담당) — **장르 섹션 "더보기" 헤더 → 상세검색 필터 진입**: V1 장르 헤더 버튼 탭 → 상세검색 **필터 화면**을 push(`pushToDetailSearch`).
  - V2: 헤더 버튼 본문이 `// TODO: - 탐색 정보탭으로 이동`뿐(미배선). 상세검색 필터 화면 자체가 실앱에서 안 열린다(3).
  - 근거: V1 `NormalSearchViewModel.swift:310-318`, `NormalSearchViewController.swift:329-334` · V2 `NormalSearchView.swift:204-212`(TODO)

### 2.4 키워드 검색(인기 키워드)

- ✅ **Keep** — 실시간 인기 키워드를 조회해 **랭킹 순 그대로** 칩으로 노출하고, 칩 탭 → `SearchFilter(keywords: [keyword])`로 상세검색 결과를 push(텍스트 검색이 아니라 필터 검색).
  - V2: `LoadPopularKeywordsUseCase`, `CapsuleSelectableKeywordChip` 탭 → `DetailSearchNavigation(filter: SearchFilter(keywords: [keyword]))` push. (V1 `entryType: .keywordOnly` 상당.)
  - 근거: V1 `NormalSearchViewModel.swift:331-350`, `NormalSearchViewController.swift:364-384` · V2 `NormalSearchView.swift:272-282`
- 🔧 **배선 대기→App** (2026-08-28: 상세검색 키워드탭 진입, App 라우터 담당) — **키워드 섹션 "더보기" 헤더 → 상세검색 필터(키워드 탭) 진입**: V1 인기 키워드 헤더 탭 → 상세검색 필터를 **키워드 탭으로 열어** push(`pushToDetailSearchViewController(initialTab: .keyword)`).
  - V2: 헤더 버튼 본문이 `// TODO: - 탐색 키워드탭으로 이동`뿐(미배선).
  - 근거: V1 `NormalSearchViewModel.swift:352-360`, `NormalSearchViewController.swift:386-391` · V2 `NormalSearchView.swift:259-267`(TODO)

### 2.5 소소픽 (브라우즈)

- ✅ **Keep** — 브라우즈 상태에서 소소픽("다른 독자들이 최근에 찾아본 웹소설") 가로 리스트를 노출.
  - 근거: V1 `NormalSearchViewModel.swift:160-166`, `NormalSearchViewController.swift:254-261` · V2 `NormalSearchView.swift:289-327`
- ✅ **Keep** — 브라우즈 콘텐츠 스왑 규칙: 검색어가 비어 결과가 없으면 브라우즈(최근/장르/키워드/소소픽) 노출.
  - V2: `isSearchExecuted` → 결과 / `isFocused && !searchText.isEmpty` → 자동완성 / 그 외 → 브라우즈, 로 우선순위화(`State`가 소유).
  - 근거: V1 `NormalSearchViewController.swift:165-187`(searchTextField 비었으면 소소픽/결과/빈뷰 분기) · V2 `NormalSearchView.swift:57-96`, `CLAUDE.md`(스왑 우선순위)

### 2.6 검색 실행·결과·자동완성

- ✅ **Keep** — 검색 실행 진입점 통합: 검색 아이콘 탭/키보드 return, 최근 검색어 칩 탭, (자동완성 제안어 탭 — V2 신규)이 전부 하나의 실행 경로로 모인다. 빈 문자열은 무시.
  - V2: 세 지점 모두 `.executeSearch(text)` 공통 호출(`executeSearch`가 trim+빈검사). V1은 return/searchButton merge + `filter { !isEmpty }` + `distinctUntilChanged`.
  - 근거: V1 `NormalSearchViewModel.swift:180-196` · V2 `NormalSearchViewModel.swift:208-225`, `NormalSearchView.swift:142-145`,`176-183`
- ✅ **Keep** — 첫 페이지 검색 중 로딩 뷰 노출, 결과 카운트 표시, 결과 0건이면 빈 화면.
  - V2: `NormalSearchResultView`가 `isLoading`→`LoadingView`, 빈 결과→`WSSEmptyView(type: .novel)`, 실패→`NetworkErrorView`(V1엔 실패 뷰 없음).
  - 근거: V1 `NormalSearchViewModel.swift:128-155`(page==0에 로딩 on), `NormalSearchViewController.swift:174-179`(empty) · V2 `CLAUDE.md`(결과 뷰 로딩/빈/실패)
- ✅ **Keep** — 검색 결과 무한스크롤: 다음 페이지를 append. 진행 중 중복 요청 가드 + "더 받을 게 있을 때만".
  - V2: 페이지 기반(`nextSearchResultPage`), `hasNextSearchResultPage`(서버 `Paginated.hasNext`) false면 중단, `searchResultTask`/`loadMoreSearchResultTask` 가드. V1은 `reachedBottom && !isFetching && isLoadable`.
  - 근거: V1 `NormalSearchViewModel.swift:210-228`, `NormalSearchViewController.swift:411-419`(near-bottom+1.0) · V2 `NormalSearchViewModel.swift:228-235`,`355-372`, `CLAUDE.md`(LazyVStack 마지막 행)
- ✅ **Keep** — 검색 후 다시 타이핑하면 결과 화면을 벗어나 브라우즈/자동완성으로 복귀.
  - V2: `updateSearchText`가 `isSearchExecuted=false`. ⚠️ `text != state.searchText` 가드가 없으면 키보드 내림 시 재커밋이 방금 실행한 검색을 취소하는 버그(`CLAUDE.md` 정본).
  - 근거: V1 `NormalSearchViewController.swift:165-187` · V2 `NormalSearchViewModel.swift:191-204`, `CLAUDE.md`(재커밋 가드)
- 🔧 **Improve 확정** (2026-08-28: V2 신규 기능, 회귀 아님) — **검색어 자동완성**: V1엔 자동완성이 없다(입력 텍스트는 검색 실행에만 쓰임). V2는 `isFocused && !searchText.isEmpty`일 때 300ms debounce 후 `SearchAutoCompletionWordsUseCase`로 제안어를 띄우고, 일치 구간 하이라이트·제안어 탭 검색을 붙였다.
  - 근거: (V1 없음) · V2 `NormalSearchViewModel.swift:191-204`,`313-332`, `NormalSearchAutoCompletionView`, `CLAUDE.md`(자동완성)

### 2.7 작품 상세 이동

- 🔧 **배선 대기→App** (2026-08-28: 작품상세 push, App 라우터 담당) — V1은 **소소픽 셀·일반 검색 결과 셀** 탭 시 (로그인돼 있으면) 작품 상세로 push한다.
  - **V2: 둘 다 상세 이동이 없다.** 소소픽 탭은 `print("\(pick.novelID)번 작품 상세로 이동")` 스텁, `NormalSearchResultView`는 `onSelect` 콜백 자체를 받지 않는 순수 표시 뷰다. `makeNormalSearchView` Factory에도 `onNovelSelected` 류 콜백이 없다.
  - 근거: V1 `NormalSearchViewModel.swift:168-178`(소소픽),`230-240`(결과셀) → `NormalSearchViewController.swift:229-233`(pushToNovelDetail) · V2 `NormalSearchView.swift:319-321`(print), `58-66`(결과뷰 onSelect 없음), `SearchFeatureFactory.swift:24-46`(콜백 없음)
  - **판정 포인트**: App 라우터 배선 대기(누락된 유지)인지 / 검색 결과에서 상세 이동을 안 하기로 한 건지. (4.1의 상세검색 결과도 동일 사안 — 검색 3계열 전부 미배선.)

---

## 3. 상세탐색 필터 (DetailSearch)

원본: `…/Search/DetailSearch/DetailSearchViewModel/DetailSearchViewModel.swift`

> V2 대응 `DetailSearchFilterView`(#185)는 존재하나 **실제 앱 흐름에서 아무 데서도 push되지 않는다**(Demo 전용 진입점만). 따라서 아래 항목들은 대부분 "V2에 구현은 있으나 실앱 경로가 없음" 상태다 — 2.3·2.4의 헤더 TODO가 열리면 살아난다.

### 3.1 진입·구조

- ✅ **Keep** — 정보/키워드 두 탭바 화면. 진입 탭을 인자로 받는다(V1 `initialTab`, 인기키워드 헤더는 `.keyword`로 진입).
  - V2: `DetailSearchFilterView` `@State selectedTab`(`.info`/`.keyword`), 밑줄로 활성 탭 표시. Demo가 진입.
  - 근거: V1 `DetailSearchViewModel.swift:117-121`,`152-162` · V2 `CLAUDE.md`(정보/키워드 탭바)
- 🔧 **배선 대기→App** (2026-08-28: 상세검색 진입경로, App 라우터 담당) — V1은 실제로 3경로로 이 화면을 push했다: 랜딩 유도배너, 장르 헤더, 인기키워드 헤더(1·2.3·2.4). V2는 세 경로가 전부 없거나 TODO라 필터 화면이 **Demo 밖에서 안 열린다**.
  - 근거: V2 `CLAUDE.md`("지금은 Demo 전용 진입점에서만 push"), `SearchFeatureFactory.swift:52-59`

### 3.2 정보 탭 필터

- ✅ **Keep** — 장르(다중 선택)·플랫폼(다중 선택)·연재상태(단일, 다시 누르면 해제)·별점 범위(min~max 슬라이더).
  - V2: `SearchFilter`가 `genres[]`/`platforms[]`/`publicationStatus?`/`ratingRange?` 보유. 연재상태 토글 해제·별점 슬라이더 동일.
  - 근거: V1 `DetailSearchViewModel.swift:212-266` · V2 `SearchFilter.swift:42-101`, `CLAUDE.md`(정보 탭 4종)
- ✅ **Keep** — 플랫폼 라벨 옆 툴팁을 탭으로 열고 닫는다(베타 안내).
  - V2: `icToolTip` 탭 토글, `WSSImage.icPlatformTooltip` 배경(`CLAUDE.md`). V1은 `showPlatformTooltip` 토글.
  - 근거: V1 `DetailSearchViewModel.swift:244-248` · V2 `CLAUDE.md`(플랫폼 툴팁)
- ✅ **Keep** — "초기화"는 **현재 보고 있는 탭만** 지운다(정보 탭이면 정보 4종만, 키워드 탭이면 키워드만).
  - V2: `selectedTab` 기준으로 `.clearInfoFilters`/`.clearKeywords`. `SearchFilter.clearInfoFilters()`는 키워드를 안 건드림(탭별 독립, 사용자 확정).
  - 근거: V1 `DetailSearchViewModel.swift:164-186` · V2 `SearchFilter.swift:134-139`, `SearchDomain/CLAUDE.md`(clearInfoFilters)
- ✅ **Keep** — "작품 찾기" 더블탭 가드: V1은 300ms debounce로 감쌈.
  - V2: `DetailSearchFilterView`는 확정 시 `onSearch` 콜백만 호출(pop 안 함, 호출부 책임 — `CLAUDE.md`). 명시적 debounce는 확인 안 됨(순수 입력 VM이라 재진입 push는 호출부가 관리).
  - 근거: V1 `DetailSearchViewModel.swift:188-208` · V2 `CLAUDE.md`(onSearch 콜백)
- 🔧 **Improve** — **정보 탭 활성 점(`new` 인디케이터)이 플랫폼 선택을 반영**: V1 `showInfoNewImageView`는 장르·연재상태·별점만 OR로 계산하고 **플랫폼을 빠뜨렸다**(플랫폼만 골라도 점이 안 켜짐 = 버그).
  - V2: `hasActiveInfoFilter`가 장르·플랫폼·연재상태·별점 4종을 모두 본다(`DetailSearchFilterViewModel`의 `Derived`).
  - 근거: V1 `DetailSearchViewModel.swift:386-392`(platform 누락) · V2 `CLAUDE.md`(hasActiveInfoFilter 4종)
- ✅ **Keep (순서 출처 상이)** — 정보 탭 장르 그리드는 V1 `NovelGenre.detailSearchGenres`, V2 `WSSComponent.NovelGenre.myFeedFilter`(Figma 실측 재확정). 둘 다 9종, `searchGenre`(브라우즈용)와는 다른 목록.
  - 근거: V1 `NovelGenre.swift:217`(detailSearchGenres) · V2 `SearchDomain/CLAUDE.md`(myFeedFilter)

### 3.3 키워드 탭 필터

- ✅ **Keep** — 키워드 검색 텍스트필드 + 카테고리 카탈로그 + 검색 결과에서 골라 담기, 선택 키워드 **최대 20개**. 20개 초과 담기 시 안내(토스트/알럿).
  - V2: 키워드 탭 콘텐츠는 `KeywordFeature` 화면을 주입(`KeywordTabContentBuilder`)해 재사용, 선택은 실시간으로 `SearchFilter.setKeywords`(20개 초과분 조용히 클램프). V1은 append 시 `keywordLimit=20` 검사.
  - 근거: V1 `DetailSearchViewModel.swift:40-42`,`338-348`(limit 20/over) · V2 `SearchFilter.swift:105-120`, `CLAUDE.md`(키워드 탭 콘텐츠 주입)
- ✅ **Keep** — "찾는 작품이 없다면?" 문의 링크(`inquiryAddNovel` 외부 URL).
  - V2: `BaseDomain.AppURL.inquiryAddNovel`을 `openURL`로. V1은 `ExternalLinks.inquiryAddNovel`.
  - 근거: V1 `DetailSearchViewModel.swift:372-381` · V2 `CLAUDE.md`("찾는 작품이 없다면?" 링크)

---

## 4. 상세탐색 결과 (DetailSearchResult)

원본: `…/Search/DetailSearch/DetailSearchViewModel/DetailSearchResultViewModel.swift`

### 4.1 진입·상호작용

- ✅ **Keep** — 진입 즉시 필터 옵션으로 page 0을 조회, 상단에 필터 요약 pill + 결과 카운트 + 작품 그리드.
  - V2: `DetailSearchResultViewModel.load()`가 `searchByFilter(filter, page: 0)`. pill은 `filterSummaryText`(적용 카테고리 나열).
  - 근거: V1 `DetailSearchResultViewModel.swift:87-111` · V2 `DetailSearchResultViewModel.swift:98-117`, `CLAUDE.md`(filterSummaryText)
- ✅ **Keep** — 필터 요약 pill/검색바 탭 = **뒤로가기**(필터 재편집이 아니라 이전 화면으로). V1은 `searchBarViewDidTap`→pop.
  - V2: pill 탭 = `dismiss()`, 결과 화면 자체엔 필터 편집 없음(사용자 확정, `CLAUDE.md`).
  - 근거: V1 `DetailSearchResultViewModel.swift:148-152` · V2 `CLAUDE.md`(pill = 뒤로가기)
- 🔧 **배선 대기→App** (2026-08-28: 작품상세 push, App 라우터 담당) — **결과 셀 탭 → 작품 상세 push**: V1은 결과 셀 탭 시 작품 상세로 push(+ Amplitude `clickSeekResult`).
  - V2: 그리드 셀(`WSSNovelGridCell`)이 `onTap` 없는 순수 표시 전용. (2.7과 같은 사안 — 검색 결과 상세 이동 전면 미배선.)
  - 근거: V1 `DetailSearchResultViewModel.swift:77-85` · V2 `CLAUDE.md`(onTap 없이 순수 표시 전용)

### 4.2 서버 요청 파라미터

- ✅ **Keep** — 페이지 기반 무한스크롤(page+1), size 20. 커서 아님.
  - V2: `nextPage`, `size: 20`. V1 `currentPage+1`, `searchSize=20`.
  - 근거: V1 `DetailSearchResultViewModel.swift:118-146`, `SearchRepository.swift:29` · V2 `DetailSearchResultViewModel.swift:119-136`, `SearchMapper.swift:68`
- 🔨 **회귀 확정→수정** (2026-08-28 실서버 검증: false=연재중만 9,319·true=완결 85,708·생략=전체 95,027 → 미선택 시 완결작 90% 누락) — **연재상태 미선택 시 `isCompleted` 전송 여부**: V1은 `isCompleted`가 nil이면 쿼리에서 **생략**(→ 전체 연재상태). V2 `DetailSearchQuery.isCompleted`는 non-optional `Bool`이고 `QueryItemConvertible`이 Bool을 항상 직렬화하므로, 미선택도 `isCompleted=false`로 나간다 → "연재중만" 필터와 구별 불가.
  - 근거: V1 `SearchService.swift:140-142`(`if let`으로 조건부 append) · V2 `SearchMapper.swift:63`(`filter.publicationStatus == .completed`), `DetailSearchQuery.swift:16`, `QueryParameters.swift:45-48`(Bool 항상 전송)
  - **판정 포인트**: 서버가 `isCompleted=false`를 "연재중만"으로 해석하면 회귀(미선택인데 완결작이 사라짐), "false=무시/전체"로 해석하면 무해. 서버 동작 확인 필요.

### 4.3 빈 화면·로딩·에러

- 🔧 **Improve** — **에러 처리**: V1은 결과 조회 실패 시 로딩만 내리고 **아무 표시도 안 한다**(빈 화면 + 콘솔 print). V2는 `NetworkErrorView`(재시도 포함)로 대체.
  - 근거: V1 `DetailSearchResultViewModel.swift:107-110`(에러 시 로딩만 off) · V2 `DetailSearchResultViewModel.swift:112-116`, `CLAUDE.md`(NetworkErrorView)
- ✅ **Keep** — 로딩 뷰(page 0)·결과 0건 빈 화면.
  - V2: `LoadingView` + 화면 전용 빈 카피("검색의 범위를 더 넓혀보세요" — V1의 재사용 빈뷰 대신 이 화면만의 문구). V1은 `showLoadingView` + `DetailSearchResultEmptyView`.
  - 근거: V1 `DetailSearchResultViewModel.swift:87-116` · V2 `CLAUDE.md`(빈 결과 = 화면 전용 정적 문구)

---

## 5. 횡단 관심사

### 5.1 로그인 게이팅

- 🗑 **Delete 확정** (2026-08-28: V2는 로그인 전용 앱, 비로그인 경로 없음) — V1은 검색 곳곳을 `isLogined = APIConstants.isLogined`로 가드한다: 검색바 진입·유도배너·소소픽 셀·검색 결과 셀·장르 셀·장르 헤더·인기키워드 셀·인기키워드 헤더 — **비로그인이면 전부 `InduceLoginViewController`를 present**(작품 상세로 안 감). 즉 V1은 **비로그인 상태로도 검색 랜딩/소소픽을 브라우즈**할 수 있고 상호작용에서만 로그인을 유도했다.
  - **V2: 이 가드가 전부 없다.** `NormalSearchViewModel`에 `isLogined` 개념이 없고 모든 액션이 무조건 실행된다.
  - 근거: V1 `SearchViewModel.swift:51-66`, `NormalSearchViewModel.swift:21`,`171-176`,`233-238`,`302-306`,`344-348` · V2 `NormalSearchViewModel.swift`(가드 없음)
  - **판정 포인트**: V2가 검색을 로그인 후에만 진입하게 하는 앱 전체 정책이라 induce-login이 불필요해진 건지(=의도된 제거) / 비로그인 브라우즈를 되살릴지.

### 5.2 애널리틱스

- 🔧 **횡단 이슈→TODO** (2026-08-28) — V1은 검색 흐름 전반에 Amplitude 이벤트를 심었다: `Search.search`(검색화면 진입), `generalSearch`(검색바 탭), `seek`(상세검색 유도), `sosoPick`, `clickSearchResult`, `clickSeekResult`, `contactNovelSearch`(문의).
  - V2: 대응 이벤트 전송이 없다(`Logger`는 에러 로깅 전용). 애널리틱스가 아직 이식 안 된 것으로 보임.
  - 근거: V1 `SearchViewController.swift:46`, `SearchViewModel.swift:50`,`61`, `NormalSearchViewModel.swift:170`,`232`,`249`, `DetailSearchResultViewModel.swift:79` · V2 (대응 없음)

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

### 일반 검색 `GET /novels` (V1 `searchNormalNovels` · V2 `NormalSearchQuery`)

| 파라미터 | V1 전송 | V2 전송 | 상태 |
|---|---|---|---|
| `query` | 검색어 문자열 | `query` 동일 | ✅ Keep |
| `page` | 0부터 정수 | 동일 | ✅ Keep |
| `size` | `20`(고정) | `20` 계열 | ✅ Keep (V2 실측값 확인 권장) |
| 인가 | `accessTokenHeader` | `.usesTokenIfAvailable`(#165 — 토큰 있으면 최근검색어 기록) | ✅ Keep (이유는 `SearchData/CLAUDE.md`) |

- 근거: V1 `SearchService.swift:95-119`, `SearchRepository.swift:39-43` · V2 `SearchMapper.swift:35-57`, `NormalSearchQuery.swift`, `SearchData/CLAUDE.md`

### 상세/필터 검색 `GET /novels/filtered` (V1 `searchDetailNovels` · V2 `DetailSearchQuery`)

| 파라미터 | V1 전송 규칙 | V2 전송 규칙 | 상태 |
|---|---|---|---|
| `genres` | `NovelGenre.rawValue` 콤마조인(빈 배열도 빈 문자열로 전송) | `mapNovelGenreString` 배열(값 동일). `[String]` non-optional이라 빈 배열도 `?genres=` 빈값 전송 — **V1과 동일**(서재 `UserLibraryV2Query`만 `Optional`로 생략) | ✅ Keep (V1 parity, [C2 3-4](../../../docs/V1_PARAM_MAPPING_C2.md)) |
| `platformNames` | `NovelPlatform.title` — **`.ridi`가 "리디"** | `mapNovelPlatformString` — **`.ridibooks`가 "리디북스"** | 🔧 Improve (3, `CLAUDE.md` 문서화) |
| `keywordIds` | `KeywordData.keywordId` 콤마조인 | `keyword.id.value` 배열 | ✅ Keep |
| `novelRatingStart`/`End` | `lower`/`upper`(**항상** 전송, 기본 0.0~5.0) | `ratingRange?.min ?? 0.0` / `?? 5.0`(항상 전송) | ✅ Keep |
| `isCompleted` | **nil이면 생략**, 아니면 `true`/`false` | **항상 `Bool`**(`publicationStatus == .completed`) | ❓ Unknown (4.2 잠재 회귀) |
| `page` | 0부터 정수 | 동일 | ✅ Keep |
| `size` | `20` | `20` | ✅ Keep |
| 인가 | `accessTokenHeader` | `.requireToken` | ✅ Keep (`SearchData/CLAUDE.md`) |

- 근거: V1 `SearchService.swift:121-161`, `DetailSearchResultViewModel.swift:91-100` · V2 `SearchMapper.swift:59-95`, `DetailSearchQuery.swift`, `SearchData/CLAUDE.md`(#185 쿼리 파라미터)

### 최근 검색어 (V1 `SearchService` · V2 `SearchData`)

- ✅ **Keep** — 조회 `GET /novels/recent-searches`, 개별 삭제 `DELETE …/{id}`, 전체 삭제 `DELETE …`. 별도 "add" API 없음(검색 실행 시 서버 자동 기록). V1/V2 응답 구조(`recentSearches[{id,keyword}]`) 동일.
  - 근거: V1 `SearchService.swift:31-74` · V2 `SearchData/CLAUDE.md`(recent-searches)
