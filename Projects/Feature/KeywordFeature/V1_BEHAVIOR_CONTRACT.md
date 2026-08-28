# KeywordFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 **키워드 검색·선택**
> 화면이 **실제로 어떻게 동작했는지**를 코드에서 추출한 목록이다. V1은 "실제 운영으로 검증된 동작 기준"이고,
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
| ❓ **Unknown** | 회귀일 수도, 의도일 수도 — **판정 대기** | **판정 필요** — 2026-08-28 기준 **0건**(전부 판정 완료) |

- 회귀 후보였던 항목(판정 완료)과 눈에 띄는 🔧/🗑는 [0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- 경로 접두사: V1 `…/NovelReview/` = `WSSiOS/Source/Presentation/NovelReview/`, V1 공용 `…/Base/KeywordLabel/` = `WSSiOS/Source/Presentation/Base/KeywordLabel/`. V2는 이 모듈 기준 상대경로.

## 화면 매핑 (V1 → V2)

V2 `KeywordFeature`는 **재사용 콘텐츠**(카테고리 브라우징 + 검색 + 다중 선택)다. V1엔 이 콘텐츠를 담은 **독립 모듈이 없고**,
같은 서브뷰 묶음(`NovelKeywordSelect*`)이 **두 화면에 공유**돼 있었다:

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/SearchKeywordView.swift` + `SearchKeywordViewModel.swift` (재사용 콘텐츠, 크롬 없음) | **작품 리뷰 키워드 선택 모달**: `…/NovelReview/NovelReviewViewController/NovelKeywordSelectModalViewController.swift` + `…/NovelReviewViewModel/NovelKeywordSelectModalViewModel.swift` (동작 원천) | V1은 **바텀 모달 크롬**(타이틀·닫기·하단 액션바) 포함, V2는 **콘텐츠만** |
| (동일 콘텐츠) | **상세탐색 키워드 탭**: `…/Search/DetailSearch/…/DetailSearchKeywordView.swift` (같은 `NovelKeywordSelect*` 서브뷰 재사용, 검색 로직은 `DetailSearchViewModel`) | V1도 이미 "탭에 임베드"하는 재사용 사례가 있었음 — V2가 이 재사용을 **한 모듈로 정식화** |
| 칩·라벨 컴포넌트 | `…/Base/KeywordLabel/` (`KeywordTag`=선택 트레이 칩, `KeywordLink`=검색결과/카테고리 칩, `KeywordLabel`/`KeywordBox`) | V2는 `WSSComponent`의 `WhiteRemovableKeywordChip`·`CapsuleSelectableKeywordChip`로 대체 |

- V1 동작 원천은 **리뷰 키워드 선택 모달**이 가장 완전하므로 그것을 기준으로 추출했다(상세탐색 탭은 같은 서브뷰라 동작이 겹친다).

---

## 0. 점검 대기 요약

**판정 상태(2026-08-28 갱신)** — 모든 항목에 배지가 달려 있고 본문 각 절의 확정 배지와 일치한다. **판정 대기 0건.** 배지: ✅유지 · 🔧개선/고치기/미배선(되살리기·수정은 `docs/TODO.md` 9절에 구현 대기, 미배선은 App 배선 시 해소) · 🔨회귀 수정 · 🗑삭제 · ⏳⏸보류(`docs/PENDING_DECISIONS.md`) · 🆕V2 신규.

1. 🔨 **오배선 수정 확정→TODO 9절** (2026-08-28: 범용 문의로 되돌림) — **빈 화면 "문의" 버튼의 이동 URL이 다른 페이지다.** V1은 `ExternalLinks.inquiry`(노션 `…d0a0b0a`)를 여는데, 이 URL은 **V2에선 `AppURL.errorReport`(오류 제보)** 와 동일 페이지다. V2 키워드 빈 화면은 대신 `AppURL.inquiryAddNovel`(작품 등록 문의, `…51edaab` — **다른 노션 페이지**)을 연다. V2 `CLAUDE.md`는 "키워드 전용 폼이 없어 작품 등록 문의를 재사용"이라 적었으나, **V1도 키워드 전용 폼이 아니라 범용 문의(≈오류 제보) 페이지를 썼다** → 재사용 대상이 바뀐 셈. → [5](#5-빈-화면-검색-결과-없음)
2. ✅ **Keep 확정** (2026-08-28: 사소, V2 유지 — 본문 4) — **선택할 때마다 키보드를 내리던 동작**(`endEditing`)이 V2엔 없다. V1은 트레이/검색결과/카테고리 어디서 키워드를 고르든 곧바로 키보드를 접었다. → [4](#4-선택)
3. 🔧 **횡단 이슈→TODO 9절** (Amplitude 재도입) — **Amplitude 분석 이벤트 미포팅.** V1은 문의 버튼 탭에 `AmplitudeEvent.Search.contactKeyword`를 기록했다. V2 이 모듈엔 분석 계층이 없다(앱 전반 미포팅 여부는 별개 확인). → [9](#9-분석-analytics)

**🔧/🗑 눈에 띄는 의도적 변경 (의도 확인)**

4. 🗑/🔧 **Delete(호출부 이관)·Improve(전달 방식)** — **하단 액션바(초기화 + "n개 선택" 완료 버튼) 통째 제거 + 결과 전달 방식 전환.** V1은 `WSSBottomActionView`에 **초기화 버튼**과 **"n개 선택" 완료 버튼**을 두고, 완료 시 `NotificationCenter`(`"NovelReviewKeywordSelected"`)로 선택 목록을 던지고 모달을 닫았다. V2는 **확정 버튼 없이** 선택이 바뀔 때마다 `onSelectionChanged` 콜백으로 실시간 통지하며, 초기화·완료 CTA는 호출부 몫이다. → [8](#8-호출부로-이관삭제된-것-모달-크롬액션바)
5. 🗑 **Delete(호출부 이관)** — **모달 크롬(바텀 시트·타이틀·닫기 X) 제거.** V1은 화면 높이−81의 바텀 모달(상단 라운드 16, "키워드 선택" 타이틀, 닫기 X)이었다. V2는 크롬 없는 콘텐츠라 시트·타이틀·닫기를 호출부가 갖는다. → [8](#8-호출부로-이관삭제된-것-모달-크롬액션바)
6. 🔧 **Improve** — **카테고리 목록이 서버 응답 → 로컬 고정 5종.** V1은 서버가 준 `categoryName`·`categoryImage`(URL)로 카테고리를 그렸고, V2는 로컬 `KeywordCategory` enum 5종 + `DomainPresentation`(서버 `categoryImage` 미매핑)이다. → [2](#2-카테고리-브라우징-접힘펼침)
7. 🔧 **Improve** — **검색 데이터가 매 제출 서버 왕복 → 로컬 캐시 조회.** V1은 제출마다 `GET /keywords?query=`. V2는 로컬 DB 캐시(`searchKeywords`) + 실패 시 `syncKeywords()` 1회 폴백. → [3](#3-검색)

(나머지는 대부분 ✅ Keep — 수단만 RxSwift→구조적 동시성으로 바뀌고 관찰 동작은 같다.)

---

## 1. 진입·생명주기

원천: `…/NovelReview/NovelReviewViewModel/NovelKeywordSelectModalViewModel.swift`, `.../NovelReviewViewController/NovelKeywordSelectModalViewController.swift`

- ✅ **Keep** — 진입 즉시 **전체 카테고리를 로드해 브라우징 화면을 세운다**. 최초 1회 로드(재조회 개념 없음 — 모달/탭 콘텐츠라 뜰 때 1번).
  - V2: `.onAppear → .load → LoadTotalKeywordsUseCase.execute()`. 관찰 동작(뜨면 카테고리가 채워짐) 동일.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:76-88`(viewDidLoad → `searchKeyword()` → `keywordCategoryListData`) · V2 `Sources/SearchKeywordViewModel.swift:96-98,126-132`
- 🔧 **Improve (수단)** — V1은 **카테고리 로드에도 검색 API를 재사용**한다(`searchKeyword(query: nil)`가 `categories`를 반환). V2는 **전용 UseCase**(`LoadTotalKeywordsUseCase`, 로컬 캐시)로 브라우징 로드와 검색을 분리했다.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:240-243`(같은 `searchKeyword`가 카테고리도 검색결과도 반환) · V2 `Sources/SearchKeywordViewModel.swift:58-59,126-143`(로드/검색 UseCase 2개)
- ✅ **Keep** — 초기 로드 실패 시 화면을 세우기만 하고 **전면 에러 뷰를 세우지 않는다**(V1은 `onError`에서 `print`만, 빈 브라우징 유지).
  - V2: 로드 실패는 `presentError` → **토스트(`unknownError`)** 로만 알리고 브라우징은 빈 채 남긴다. 관찰상 "치명적으로 막지 않음"은 같다(V2는 토스트를 더함).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:83-87`(에러 시 print) · V2 `Sources/SearchKeywordViewModel.swift:129-131,148-152`

## 2. 카테고리 브라우징 (접힘/펼침)

- ✅ **Keep** — 카테고리 블록은 기본 **2줄만 보이고**(고정 높이), chevron 버튼으로 펼침/접힘한다.
  - V2: 접힘 높이 `80`(칩35+간격8+칩35+여유2) + `.clipped()`, chevron **180° 회전**. V1은 컬렉션뷰 높이 `78`↔`contentSize` 토글 + 화살표 에셋 교체(`icChevronDown`↔`icChevronUp`). 표현 수단만 다르고 "2줄 접힘 + 토글" 동작 동일.
  - 근거: V1 `…/NovelReviewAssistantView/NovelKeywordSelectCategoryView.swift:131-135,157-165` · V2 `Sources/SearchKeywordView.swift:176-238`
- 🔧 **Improve** — **카테고리 목록·이름·아이콘의 출처**. V1은 **서버 응답**(`categoryName` + `categoryImage` URL, `kfSetImage`로 원격 로드)으로 카테고리를 그렸다. V2는 **로컬 고정 enum 5종**(`worldview/material/character/relationship/vibe`) + `WSSComponent`의 `DomainPresentation`(아이콘은 로컬 에셋). 서버 `categoryImage`는 의도적으로 미매핑.
  - (오탐 방지: `BaseDomain/CLAUDE.md`에 "카테고리 5종 고정·서버 categoryImage 의도적 미매핑"으로 명문화 — Break로 오분류 금지. 단 **서버가 6번째 카테고리를 추가하면 V1은 노출·V2는 무시**라는 차이는 남는다.)
  - 근거: V1 `WSSiOS/Source/Data/DTO/SearchKeywordResult.swift:14-18`(서버 `categoryName`/`categoryImage`), `…/NovelKeywordSelectCategoryView.swift:71-81` · V2 `Projects/Domain/BaseDomain/Sources/Keyword/Entity/KeywordCategory.swift:11-17`, `BaseDomain/CLAUDE.md`(카테고리 표시값)

## 3. 검색

- ✅ **Keep** — **제출 시에만 검색**한다(실시간 타이핑 검색 아님). 서치바 검색 버튼 탭 또는 리턴키(`editingDidEndOnExit`).
  - V2: `WSSSearchBar`의 `onSearch`(엔터·버튼)에서만 `.search(text:)`. `state.query`는 제출 때만 갱신.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:126-152`(`searchButtonDidTap`·`editingDidEndOnExit` 병합 → 검색) · V2 `Sources/SearchKeywordView.swift:47-54`, `Sources/SearchKeywordViewModel.swift:101-108`
- ✅ **Keep** — **빈 검색어 제출 → 브라우징 복귀**(검색결과를 비우고 카테고리 목록을 다시 보임).
  - V2: 빈 텍스트면 `searchedKeywords`만 비우고 서버/캐시 호출 안 함(브라우징으로 복귀).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:134-148`(`enteredText.isEmpty`면 카테고리 재조회) · V2 `Sources/SearchKeywordViewModel.swift:102-107`
- ✅ **Keep** — 검색 결과는 **카테고리 구분 없는 평탄한 칩 리스트**(모든 카테고리의 keywords를 flatMap).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:146`(`data.categories.flatMap { $0.keywords }`) · V2 `Projects/Domain/BaseDomain/Sources/Keyword/Usecase/SearchKeywordsUseCase.swift:25-26`
- ✅ **Keep (수단)** — **늦게 온 이전 검색 응답이 새 결과를 덮지 않는다**(경합 방어, 마지막 제출만 반영).
  - V2: 구현 수단 변경 — V1 RxSwift `flatMapLatest`(이전 요청 취소), V2는 응답 도착 시 `state.query == query` **stale 가드**로 그사이 바뀐 결과를 버린다. 관찰 동작 동일.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:134`(`flatMapLatest`) · V2 `Sources/SearchKeywordViewModel.swift:134-143`, `CLAUDE.md`(stale 가드)
- 🔧 **Improve** — **검색 데이터 소스**. V1은 제출마다 **서버 왕복**(`GET /keywords?query=`, 액세스 토큰 헤더). V2는 **로컬 DB 캐시** 조회(`searchKeywords`) + 실패 시 `syncKeywords()` 1회 후 재조회 폴백.
  - (오탐 방지: `BaseDomain/CLAUDE.md`에 "fetch/search는 로컬 캐시, sync가 서버 동기화"로 명문화된 의도적 구조.)
  - 근거: V1 `WSSiOS/Network/Keyword/KeywordService.swift:18-42`(서버 GET) · V2 `SearchKeywordsUseCase.swift:23-33`, `BaseDomain/CLAUDE.md`(로컬/서버 계약)

## 4. 선택

- ✅ **Keep** — 브라우징·검색결과 어디서든 **칩 탭 = 선택 토글**(이미 선택이면 해제).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:163-181`(검색결과 select/deselect), `…/NovelKeywordSelectModalViewController.swift:205-220`(카테고리 칩 select/deselect) · V2 `Sources/SearchKeywordViewModel.swift:112-120`
- ✅ **Keep** — **선택 최대 20개**. 20개를 채운 상태에서 새 키워드를 고르면 **선택하지 않고 토스트**(`selectionOverLimit(count: 20)`)만 띄운다.
  - V2: `maxSelectionCount = 20`, 초과 시 `presentedError = .selectionOverLimit` → 토스트. V1은 초과 시 컬렉션 항목을 즉시 deselect하는 시각 정리가 있으나(선택 안 됨이라 결과 동일).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:21,163-168`, `…/NovelKeywordSelectModalViewController.swift:163-168,207-210`(토스트 20) · V2 `Sources/SearchKeywordViewModel.swift:38,113-119`, `CLAUDE.md`(20 고정)
- ✅ **Keep** — **선택 순서 유지**(선택한 순서대로 트레이에 표시, 새 선택은 **끝에 추가**).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:168`(`append`) · V2 `Sources/SearchKeywordViewModel.swift:118`
- ✅ **Keep** — **선택 트레이**: 서치바 바로 아래 **가로 스크롤** 목록, 선택이 하나라도 있을 때만 표시(없으면 숨기고 그 자리를 접음).
  - V2: `selectedKeywords`가 비지 않을 때만 `selectedKeywordTray`(가로 `ScrollView`). V1은 `updateNovelKeywordSelectModalViewLayout`로 선택 유무에 따라 트레이를 `isHidden` 토글하고 아래 콘텐츠를 53pt 밀었다.
  - 근거: V1 `…/NovelKeywordSelectModalView.swift:154-166` · V2 `Sources/SearchKeywordView.swift:58-61,109-135`
- ✅ **Keep (동작 동일, 탭 타깃 좁힘)** — **트레이 칩을 눌러 그 키워드를 해제**한다.
  - V1: 트레이 칩(`KeywordTag`, X 아이콘은 `isUserInteractionEnabled = false`인 **장식**) **몸통 전체 탭**이 해제 트리거였다. V2: X 버튼(`onDelete`)만 해제하고 **몸통 탭은 의도적으로 비활성**(`onSelect` 생략). 시각(칩+X)과 "탭해서 해제" 결과는 같고 탭 영역만 X로 좁혔다.
  - 근거: V1 `…/Base/KeywordLabel/KeywordTag.swift:23,50-53`(eraseButton 비활성), `NovelKeywordSelectModalViewModel.swift:154-161`(셀 선택 = remove) · V2 `Sources/SearchKeywordView.swift:113-118`, `CLAUDE.md`(트레이 칩 몸통 탭 비활성)
- ✅ **Keep** (확정 2026-08-28: 사소, V2 유지) — V1은 **키워드를 고를 때마다 키보드를 내린다**(`endEditing`). V2엔 선택 시 명시적 키보드 해제가 없다.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:156,171,179`(select/deselect마다 `endEditing.accept`) · V2 `Sources/SearchKeywordViewModel.swift:112-120`(키보드 처리 없음)

## 5. 빈 화면 (검색 결과 없음)

- ✅ **Keep** — 검색 결과가 0건이면 **중앙 빈 뷰**(이미지 + 안내문 + 문의 버튼)를 띄운다.
  - V2: `isSearching && searchedKeywords.isEmpty`면 `WSSEmptyView(type: .keyword)`를 화면 정중앙(`maxHeight: .infinity`)에. V1은 `novelKeywordSelectEmptyView`(이미지+2줄 안내문+`contactButton`)를 `centerY`에.
  - 근거: V1 `…/NovelReviewAssistantView/NovelKeywordSelectEmptyView.swift:38-93`, `…/NovelKeywordSelectModalViewController.swift:134-139` · V2 `Sources/SearchKeywordView.swift:70-78`
- 🔨 **오배선 수정 확정→TODO** (2026-08-28: 범용문의로 되돌림) — **문의 버튼 이동 URL이 다른 페이지다.** V1은 `ExternalLinks.inquiry`(`https://helpwebsoso.notion.site/…d0a0b0a`)를 열었는데, 이 URL은 **V2에서 `AppURL.errorReport`(오류 제보)** 와 동일 페이지다. V2 키워드 빈 화면은 대신 `AppURL.inquiryAddNovel`(작품 등록 문의, `…51edaab`)을 연다.
  - **판정 근거**: V2 `CLAUDE.md`는 "키워드 전용 폼이 없어 작품 등록 문의 재사용"이라 하지만, **V1도 키워드 전용 폼이 아니라 범용 문의(≈오류 제보) 페이지**를 썼다 — 재사용 대상 페이지가 실제로 바뀐 오배선으로 판정 → 범용 문의로 되돌린다.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:215-223`(`ExternalLinks.inquiry` open), `WSSiOS/Resource/Constants/URLs/ExternalLinks.swift:12` · V2 `Sources/SearchKeywordView.swift:74-76`(`AppURL.inquiryAddNovel`), `Projects/Domain/BaseDomain/Sources/AppURL.swift:15,18`

## 6. 서치바 포커스·흰 배경

- ✅ **Keep** — 서치바가 **포커스를 얻으면 카테고리 브라우징(회색)을 숨기고 흰 배경**만 보인다.
  - V2: `showsWhiteBackground = isSearchBarFocused || isSearching`이면 브라우징 숨김 + 흰 배경. V1은 `keywordTextFieldEditingDidBegin`에서 `showCategoryListView(false)` + `showEmptyView(false)`.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:96-102` · V2 `Sources/SearchKeywordView.swift:41-42,82-99`
- ✅ **Keep** — 서치바 자체 스타일이 포커스에 따라 바뀐다(V1: 편집 중 흰 배경+테두리, 아니면 회색).
  - V2: `WSSSearchBar` 컴포넌트가 포커스 스타일을 내장. 관찰 동작 동일.
  - 근거: V1 `…/NovelReviewAssistantView/NovelKeywordSelectSearchBarView.swift:94-99`(`updateKeywordTextField`) · V2 `Sources/SearchKeywordView.swift:47-49`

## 7. 검색 취소 (서치바 x 버튼)

- ✅ **Keep** — 서치바 취소(x) → **입력 초기화 + 브라우징 복귀 + 포커스 해제**.
  - V2: `onCancel → .search(text: "")`(검색어 비움 → 브라우징) + `isSearchBarFocused = false`. V1은 `searchCancelButtonDidTap`에서 `enteredText("")` + `showCategoryListView(true)` + `endEditing`.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:110-118` · V2 `Sources/SearchKeywordView.swift:51-54`

## 8. 호출부로 이관·삭제된 것 (모달 크롬·액션바)

V1의 "동작 원천"인 리뷰 키워드 모달은 콘텐츠 위에 **모달 크롬 + 하단 액션바**를 두고 자기완결로 확정·닫기까지 처리했다.
V2 `KeywordFeature`는 콘텐츠만 제공하고 이 껍데기를 전부 호출부로 넘겼다(V2 `CLAUDE.md`에 명문화).

- 🗑 **Delete (호출부 이관)** — **모달 크롬**: 화면 높이−81의 바텀 시트(상단 라운드 16), "키워드 선택" 타이틀, 닫기(X) 버튼.
  - V2: 크롬 없는 콘텐츠 — 시트 표시·타이틀·닫기는 호출부(`SearchFeature` 상세탐색 탭 등)가 갖는다.
  - 근거: V1 `…/NovelReview/NovelReviewView/NovelKeywordSelectModalView.swift:44-100,120-124`(모달 크기·타이틀·close) · V2 `Sources/SearchKeywordView.swift`(크롬 없음), `CLAUDE.md`(콘텐츠만 제공)
- 🗑 **Delete (호출부 이관)** — **하단 액션바 `WSSBottomActionView`**: **초기화 버튼**(전체 선택·텍스트·검색결과 리셋 → 브라우징 복귀) + **"n개 선택" 완료 버튼**.
  - V2: 자체 액션바 없음. 초기화·완료 CTA는 호출부 몫(`CLAUDE.md`: 이 화면엔 `showsBottomActionBar` 스위치조차 없음).
  - 근거: V1 `…/NovelKeywordSelectModalView.swift:26`, `NovelKeywordSelectModalViewModel.swift:197-206`(reset), `…/NovelKeywordSelectModalViewController.swift:87-88,120-126`("n개 선택" 타이틀) · V2 `CLAUDE.md`(자체 액션바 없음)
- 🔧 **Improve** — **선택 결과 전달 방식**. V1은 완료 버튼을 눌러야 확정되고, `NotificationCenter`(`"NovelReviewKeywordSelected"`)로 선택 목록을 브로드캐스트한 뒤 모달을 닫았다(**확정 버튼 필요 + 느슨한 전역 알림**). V2는 **확정 버튼 없이** 선택이 바뀔 때마다 `onSelectionChanged([Keyword])` **클로저 콜백**으로 실시간 통지한다.
  - (오탐 방지: `CLAUDE.md`에 "Feature 간 직접 의존 없이 콜백으로 실시간 통지, 확정 버튼 불필요"로 명문화된 의도.)
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:208-213`(NotificationCenter post + dismiss) · V2 `Sources/SearchKeywordView.swift:103-105`, `Sources/Factory/KeywordFeatureFactory.swift:18-27`, `CLAUDE.md`(#185 재사용)
- ✅ **Keep** — **진입 시 이미 선택된 키워드 시딩**. V1 모달은 생성자로 `selectedKeywindList`를 받아 열 때 트레이에 반영했다.
  - V2: `initialSelectedKeywords`로 동일 시딩(#185, 상세탐색 필터 재진입).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:38-41,78`(초기 선택 반영) · V2 `Sources/SearchKeywordViewModel.swift:65-75`

## 9. 분석 (Analytics)

- 🔧 **횡단 이슈→TODO** (2026-08-28) — V1은 문의 버튼 탭에 **Amplitude 이벤트**(`AmplitudeEvent.Search.contactKeyword`)를 기록했다. V2 이 모듈엔 분석 계층이 없다.
  - **판정 근거**: 앱 전반 애널리틱스 부재의 일부(이 지점만의 누락이 아님) → 이 문서 범위 밖, 횡단 재도입(`docs/TODO.md` 9절)으로 흡수.
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:217` · V2 `Sources/SearchKeywordView.swift:74-76`(분석 호출 없음)

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

| 항목 | V1 | V2 | 상태 |
|---|---|---|---|
| 검색/브라우징 소스 | 서버 `GET /keywords` (액세스 토큰 헤더) | 로컬 DB 캐시(`searchKeywords`/`fetchKeywords`), 서버 동기화는 `syncKeywords()` | 🔧 Improve (3) |
| 검색어 파라미터 | `query` (nil이 아닐 때만 쿼리에 추가) | `searchText`(String) → 캐시 조회 | ✅ Keep (개념 동일) |
| 카테고리 브라우징 | `query` 없이 같은 `GET /keywords` → `categories` | 전용 `LoadTotalKeywordsUseCase`(로컬) | 🔧 Improve (1·2) |
| 응답 스키마 | `SearchKeywordResult { categories: [{ categoryName, categoryImage, keywords: [{ keywordId, keywordName }] }] }` | `KeywordGroup(category: KeywordCategory, keywords: [Keyword(id, name)])`, 카테고리는 로컬 enum 5종 | 🔧 Improve (서버 categoryName/Image 미사용, 2) |
| 인기 키워드(`GET /keywords/popular`, size=7) | `getPopularKeywords` (이 화면 미사용 — 홈/일반검색용) | `LoadPopularKeywordsUseCase`(BaseDomain) | 참고(이 화면 무관) |

- 근거: V1 `WSSiOS/Network/Keyword/KeywordService.swift:18-42`, `WSSiOS/Resource/Constants/URLs/URLs.swift:202-203`(`/keywords`, `/keywords/popular`), `WSSiOS/Source/Data/DTO/SearchKeywordResult.swift:10-23` · V2 `SearchKeywordsUseCase.swift`, `LoadTotalKeywordsUseCase.swift`, `Projects/Domain/BaseDomain/Sources/Keyword/`
