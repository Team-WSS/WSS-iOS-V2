# LibraryFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 서재 화면들이
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
| ❓ **Unknown** | 회귀일 수도, 의도일 수도 — **판정 대기** | **판정 필요** — 2026-08-28 기준 **0건**(전부 판정 완료) |

- 회귀 후보였던 항목(판정 완료)과 눈에 띄는 🔧/🗑는 [0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- V1 경로 접두사 생략형: `…/Library/` = `WSSiOS/Source/Presentation/Library/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/Library/` (내 서재) | `…/Library/MyLibrary/` (`MyLibraryViewController`+VM, 2025 신버전) | 필터 시트 기반 단일 리스트 |
| `Sources/FilterSheet/` (필터 시트) | `…/Library/LibraryFilter/` (`LibraryFilterViewController`+VM) | 6탭 필터 |
| `Sources/UserLibrary/` (타유저 서재) | `…/Library/UserLibrary/` (`UserLibraryViewController`+`UserLibraryChildViewModel`, 2024 구버전) | **V1은 읽기상태 탭 페이저, V2는 탭 없는 단일 리스트** (3) |

---

## 0. 점검 대기 요약

**판정 상태(2026-08-28 갱신)** — 모든 항목에 배지가 달려 있고 본문 각 절의 확정 배지와 일치한다. **판정 대기 0건.** 배지: ✅유지 · 🔧개선/고치기/미배선(되살리기·수정은 `docs/TODO.md` 9절에 구현 대기, 미배선은 App 배선 시 해소) · 🔨회귀 수정 · 🗑삭제 · ⏳⏸보류(`docs/PENDING_DECISIONS.md`) · 🆕V2 신규.

1. **필터·정렬 영속화** — V1은 내 서재의 필터·정렬을 **UserDefaults에 저장하고 앱 재실행 후 복원**한다. **V2엔 이 저장/복원이 전혀 없다**(Feature·App 모두 grep 0) → 앱을 껐다 켜면 필터·정렬이 초기화된다. → [1.5](#15-영속화-userdefaults)
   - **🔧 확정(2026-08-28, 사용자): 되살린다(회귀 수정).** 매 실행 초기화는 UX 후퇴 — 경량 영속화(UserDefaults 등)로 저장/복원. C1 범위 밖 구현이라 [`docs/TODO.md`](../../../docs/TODO.md) 9에 부활 대기로 올림.
2. **타유저 서재 읽기상태 탭** — V1 타유저 서재는 **읽기상태별 탭 페이저**(`UIPageViewController` + `UserLibraryPageBar`). V2엔 **탭이 없다**(단일 리스트, 필터 UI 없음). → [3.1](#31-화면-구조-탭-페이저)
   - **🗑 확정(2026-08-28, 사용자): 단일 리스트가 의도.** V2는 필터 시트 패러다임으로 통일 — 탭 페이저(구버전 UI) 되살리지 않음.
3. ✅ **Keep 확정** (2026-08-28: NavigationStack+loadTask 가드로 해소) — **셀 선택 더블탭 가드** — V1은 작품 셀 선택에 throttle(내 서재 1s·타유저 2s)을 걸어 중복 push를 막는다. V2는 `onNovelSelected` 콜백으로 위임하며 **명시적 throttle이 안 보인다**. → [1.7](#17-상호작용네비게이션)
4. ✅ **Keep 확정** (2026-08-28: V2 튜닝) — **페이지 크기 12 → 15** — V1 내 서재 페이지 크기 `12`, V2 `15`(`LibraryPageSizePolicy.pageSize`). 의도적 조정으로 보이나 **문서화된 결정은 아님**. → [1.2](#12-목록-로드-3방식)
5. ⏳ **외부 확인(백엔드, [`PENDING_DECISIONS.md`](../../../docs/PENDING_DECISIONS.md) 3)** — **`.title`(제목순) 정렬 서버 토큰** — V1은 `"title"`에 *"TODO: 백엔드 토큰 확정 필요(v2 스펙 미정의)"* 주석이 달려 있다. V2 매퍼도 토큰을 싣지만 **백엔드 확정 여부는 별개 확인**이 필요. → [1.4](#14-정렬)

**🗑 눈에 띄는 삭제 (의도 확인)**

6. 🔧/🗑 **Improve(6종)·Delete(최적화) 확정** (2026-08-28, 사용자) — 타유저 서재 정렬 **2종(최신/오래된) → 6종**으로 확장, 그리고 **1페이지 내 정렬 시 클라이언트 배열 뒤집기** 최적화 제거. → [3.2](#32-정렬)
7. 🗑 **Delete 확정** (2026-08-28, 사용자: 남의 서재에서 검색 유도는 맥락 이탈) — 타유저 서재 빈 화면의 **"작품 찾기" CTA 제거**. → [3.3](#33-로드페이지네이션빈-화면에러)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 내 서재 (MyLibrary)

원본: `…/Library/MyLibrary/MyLibraryViewModel/MyLibraryViewModel.swift`, `.../MyLibraryViewController/MyLibraryViewController.swift`

### 1.1 진입·생명주기

- ✅ **Keep** — `viewWillAppear`마다 목록을 다시 반영한다(재진입 시 최신화). 최초 1회 가드 없음.
  - V2: `onAppear`마다 `.load`(있으면 갱신). "최초 1회 가드를 두지 않는 게 의도"라고 명문화됨.
  - 근거: V1 `MyLibraryViewController.swift:53-57`,`MyLibraryViewModel.swift:134-138` · V2 `LibraryViewModel.swift:161-175`, `CLAUDE.md`("탭 콘텐츠는 탭 복귀마다 갱신")

### 1.2 목록 로드 (3방식)

- ✅ **Keep** — 로드를 **3방식**으로 가른다: `reload`(필터·정렬 변경 → 처음부터), `nextPage`(커서로 다음 페이지 append), `refresh`(재진입 시 보던 만큼 다시 받아 덮어씀).
  - V2: `LoadKind`(`reload`/`more`/`refresh`) — **1:1 대응**. "시작 표시·결과 반영·실패 표현이 전부 여기서 갈린다"까지 계승.
  - 근거: V1 `MyLibraryViewModel.swift:25-60` · V2 `LibraryViewModel.swift:58-76`
- ✅ **Keep** — 커서 페이지네이션: 서버 발급 커서를 왕복하고, `isLoadable && cursor != nil`일 때만 다음 페이지.
  - V2: `nextCursor`/`hasNext` 그대로 왕복, `loadMore` 가드 동일.
  - 근거: V1 `MyLibraryViewModel.swift:38-47` · V2 `LibraryViewModel.swift:184-188`
- ✅ **Keep** — **늦게 도착한 이전 요청이 새 목록을 덮지 않는다**(경합 방어).
  - V2: 구현 수단은 **의도적으로 바꿈**(V1 RxSwift `flatMapLatest` → V2 구조적 동시성 "무효해진 로드 == 취소된 로드", 단일 `loadTask` 슬롯 + `Task.isCancelled`). 관찰 동작(최종 요청만 반영)은 같다.
  - 근거: V1 `MyLibraryViewModel.swift:197-225` · V2 `LibraryViewModel.swift:247-289`, `CLAUDE.md`(동시성 전제)
- 🔧 **Improve** — **재진입 갱신 요청 크기**: V1은 `refresh` 시 `loadedCount + pageSize`를 **한 번에 over-fetch**한다. V2는 `보던 개수(loadedCount)`를 1차로 받고, 서버 전체 수 delta가 있을 때만 2차를 이어 받는 **1차+delta 2단계**로 정교화했다.
  - 근거: V1 `MyLibraryViewModel.swift:49-53`(`size = loadedCount + pageSize`) · V2 `LibraryViewModel.swift:308-344`, `LibraryPageSizePolicy`, `CLAUDE.md`(재진입 갱신 2단계)
- ✅ **Keep** (확정 2026-08-28: V2 튜닝) — **페이지 크기 12 → 15**. V1 `pageSize = 12`, V2 `LibraryPageSizePolicy.pageSize = 15`.
  - 근거: V1 `MyLibraryViewModel.swift:36` · V2 `LibraryPageSizePolicy.swift:19`
- ✅ **Keep** — 무한 스크롤(다음 페이지 요청) 자체.
  - V2: 수단 변경 — V1은 스크롤 오프셋 임계값(`offsetY + frameHeight >= contentHeight - 100`), V2는 마지막 셀 `onAppear`.
  - 근거: V1 `MyLibraryViewController.swift:166-188` · V2 `CLAUDE.md`(마지막 셀 onAppear → `.loadMore`)
- 🗑 **Delete** — 필터+정렬을 잇달아 바꿀 때 `(새 필터, 옛 정렬)` 중간 조합으로 요청이 나가지 않게 **다음 런루프로 미루는** RxSwift 트릭(`observe(on: MainScheduler.asyncInstance)`).
  - V2: `applyFilter`/`selectSortType`가 각각 원자적으로 `handle`을 거쳐 중간 조합이 애초에 없다 → 트릭 불필요.
  - 근거: V1 `MyLibraryViewModel.swift:177-184` · V2 `LibraryViewModel.swift:197-208`

### 1.3 필터

- ✅ **Keep** — 필터 종류 6종(읽기상태·장르·연재상태·별점·매력포인트·키워드) + "관심만 보기" 토글.
  - 근거: V1 `LibraryFilterOption.swift:10-20` · V2 `MyLibraryFilter`(NovelDomain)
- ✅ **Keep** — 메인 화면 필터 칩 탭 → 해당 탭으로 필터 시트 진입.
  - 근거: V1 `MyLibraryViewController.swift:216-235` · V2 `CLAUDE.md`(칩 행 → `.sheet(item:)`)
- ✅ **Keep** — "관심만 보기"는 즉시 토글되어 목록을 다시 그린다.
  - 근거: V1 `MyLibraryViewModel.swift:140-148` · V2 `LibraryViewModel.swift:190-194`
- 🔧 **Improve** — **연재상태 단일 선택**. V1은 `[PublicationStatus]` **배열**로 UI에서 둘 다 켤 수 있으나, 서버 쿼리가 `isCompleted: Bool?` 하나뿐이라 Repository가 **정확히 1개일 때만** 전송한다(0·2개면 필터 통째 무시 = 칩은 2개인데 결과는 전체 = 버그).
  - V2: `NovelPublicationStatus?` **단일 선택**으로 바꿔 표현 불가능한 조합을 원천 차단. (오탐 방지: `NovelDomain/CLAUDE.md:41`에 명문화된 의도적 변경 — Break로 오분류 금지.)
  - 근거: V1 `MyLibraryRepository.swift:46-49` · V2 `NovelMapper.swift:215`, `NovelDomain/CLAUDE.md`(연재상태 단일)

### 1.4 정렬

- ✅ **Keep** — 서재 전용 정렬 **6종**(등록 최신/오래된·제목·날짜·별점 높은/낮은). 공용 `SortType`(2종) 아님.
  - 근거: V1 `LibrarySortType.swift:12-42` · V2 `LibrarySortType.swift`(NovelDomain, 6 case)
- ✅ **Keep** — 정렬 버튼 → 바텀시트에서 선택 즉시 적용.
  - 근거: V1 `MyLibraryViewController.swift:195-201` · V2 `LibrarySortSheet`, `CLAUDE.md`(정렬 시트 선택 즉시 적용)
- ✅ **Keep** — 서버 정렬 토큰 매핑 `created_desc/created_asc/title/read_date/rating_desc/rating_asc`.
  - 근거: V1 `LibrarySortType.swift:33-42` · V2 `NovelMapper.mapLibrarySortTypeString`, `NovelData/CLAUDE.md`
- 🔧 **외부 확인→TODO** (2026-08-28: 서버 실지원 확인) — **`.title`(제목순) 서버 토큰 확정**. V1에 *"TODO: 백엔드 토큰 확정 필요(v2 스펙 미정의)"* 주석. V2도 토큰을 싣지만 백엔드 실제 지원 여부는 별개 확인.
  - 근거: V1 `LibrarySortType.swift:37`

### 1.5 영속화 (UserDefaults)

- 🔧 **되살리기로 결정 (2026-08-28, 사용자)** — V1은 **필터·정렬을 UserDefaults에 저장**하고 **재진입 시 복원**한다. `libraryFilterOption`(JSON 인코딩된 `LibraryFilterOption`)·`librarySortOption`(정렬의 한글 텍스트)로 저장하며, 값이 바뀔 때마다 저장하고 `viewWillAppear`의 `applySavedOption()`에서 읽어 반영한다. 저장값이 현재와 다르면 reload, 같으면 refresh를 낸다.
  - **V2: 이 저장/복원이 전혀 없다.** VM이 매번 `MyLibraryFilter()` 기본값으로 시작하고, Feature·App 어디에도 `libraryFilterOption`/`librarySortOption` 저장이 없다(grep 0). → **앱을 껐다 켜면 필터·정렬이 초기화**된다. 탭 콘텐츠라 앱 세션 내에서는 메모리로 유지되지만, 세션을 넘겨 살아남지 않는다.
  - 근거: V1 `MyLibraryViewModel.swift:297-365`(applySavedOption·save/load) · V2 `LibraryViewModel.swift:22-23`(기본값 시작, 영속화 코드 없음)
  - **판정(2026-08-28, 사용자): 되살린다(회귀 수정).** 매 실행 초기화는 명백한 UX 후퇴 — V1처럼 마지막 필터·정렬을 경량 영속화(UserDefaults 등)로 저장/복원한다. 단 V1의 저장 키·구조를 그대로 복사하진 않는다(재설계). C1 범위 밖 구현이라 [`docs/TODO.md`](../../../docs/TODO.md) 9에 부활 대기로 올림.

### 1.6 빈 화면·에러

- ✅ **Keep** — 빈 상태 **2분화**: 필터가 걸린 상태로 0건(`filterOption != 기본값`)이면 "필터 결과 없음", 아니면 "서재 비어있음".
  - V2: `noMatchSection`(CTA 없음) vs `emptySection`("웹소설 찾기" CTA) — 같은 2분화(가르는 기준 `hasActiveSheetFilter || isInterest`).
  - 근거: V1 `MyLibraryViewModel.swift:235-249` · V2 `CLAUDE.md`(빈 상태 2분화)
- ✅ **Keep** — 목록 로드 실패는 **전면 에러 뷰 + 재시도**로 표현하고, 스트림을 끊지 않는다(첫 페이지·더보기·갱신 구분 없음).
  - V2: `loadFailed` → `NetworkErrorView` + 재시도(헤더만 남김). 첫 페이지·더보기·갱신 공통(#195에서 통일). **참고: V1은 애초에 "더보기만 토스트" 관행이 없었다** — V2 내부 히스토리(NovelDetail 관행)를 #195에서 V1과 같은 전면 뷰로 되돌린 것.
  - 근거: V1 `MyLibraryViewModel.swift:267-290`,`326-334` · V2 `LibraryViewModel.swift:395-412`, `CLAUDE.md`(에러 표현 규칙)
- 🔧 **Improve** — **인증 만료 → 로그인 라우팅**. V1 내 서재 VM엔 화면 단위 인증 만료 분기가 없다(에러를 전부 `showNetworkErrorView`로; 토큰 재발급은 `tokenCheckURLSession` 네트워크 계층이 담당). V2는 `authenticationRequired`를 화면에서 걸러 `onAuthenticationRequired`로 라우팅한다.
  - 근거: V1 `MyLibraryViewModel.swift:285-289`(catch → 에러 뷰) · V2 `LibraryViewModel.swift:422-435`, `Feature/CLAUDE.md`(인증 만료 처리 계약)
- ✅ **Keep** — 전체 로딩 뷰는 `reload`에서만 띄운다(갱신은 로딩 표시 없음).
  - 근거: V1 `MyLibraryViewModel.swift:56`,`326-334` · V2 `LibraryViewModel.swift:32`(재진입 갱신은 isLoading 미설정)

### 1.7 상호작용·네비게이션

- ✅ **Keep** (확정 2026-08-28: NavigationStack+loadTask 가드로 해소) — 작품 셀 선택에 **1초 throttle**을 걸어 중복 push를 막는다.
  - V2: `onNovelSelected` 콜백 위임 — VM에 명시적 throttle 없음. 중복 push 방지가 App 배선에 있는지 확인 필요.
  - 근거: V1 `MyLibraryViewModel.swift:227-233` · V2 `LibraryViewModel`(선택은 View→onNovelSelected)
- ✅ **Keep** — 그리드↔리스트 표시 토글(기본 그리드). 표시 모드는 **영속화하지 않는다**(세션 내 상태).
  - 근거: V1 `MyLibraryViewModel.swift:72`,`170-174` · V2 `LibraryDisplayMode`, `CLAUDE.md`
- ✅ **Keep** — 등록 버튼·빈 화면 CTA → 검색 화면으로 이동.
  - V2: `onRegisterTapped`/`onSearchTapped` 콜백.
  - 근거: V1 `MyLibraryViewController.swift:237-255` · V2 `LibraryFeatureFactory.makeMyLibraryView(...)`
- ✅ **Keep** — 정렬 버튼 탭 시 햅틱 선택 피드백.
  - 근거: V1 `MyLibraryViewController.swift:244-248` · V2 `CLAUDE.md`(정렬 시트/햅틱)

---

## 2. 필터 시트 (LibraryFilter)

원본: `…/Library/LibraryFilter/LibraryFilterViewModel/LibraryFilterViewModel.swift`

- ✅ **Keep** — 등록 키워드 목록을 **시트를 열 때 로드**하고 실패해도 빈 배열로 폴백(칩만 빔, 시트는 정상).
  - V2: 구조 변경 — **부모 VM이 로드**해 시트에 값으로 주입(시트는 순수 입력 VM, 서버 모름). 실패는 부모가 토스트. 관찰 동작(열 때 키워드 채워짐/실패해도 시트 살아있음)은 같다.
  - 근거: V1 `LibraryFilterViewModel.swift:93-101` · V2 `LibraryFilterSheetViewModel.swift:28-30`, `LibraryViewModel.swift:377-388`
- ✅ **Keep** — **선택 순서 추적**(`chipOrder`) + 칩은 **역순 노출**(최근 선택이 앞).
  - 근거: V1 `LibraryFilterViewModel.swift:30-31`,`312-317` · V2 `LibraryFilterSheetViewModel.swift:62-63`,`98-100`
- ✅ **Keep** — **별점 칩은 값이 아니라 활성 여부로만 순서에 들어간다**(슬라이더를 움직여도 칩 위치 고정).
  - 근거: V1 `LibraryFilterViewModel.swift:252-264` · V2 `LibraryFilterSheetViewModel.swift:265-272`
- ✅ **Keep** — 별점 배타성: "별점 없음"(`notStarRated`) 우선, 켜면 범위 0.0~5.0으로 리셋, 켜진 동안 범위 변경 무시.
  - V2: `LibraryRatingFilter` enum(`.range`/`.unratedOnly`/nil)로 **구조적 배타**. 전체 범위(0.0~5.0)는 `setRatingRange`가 nil로 정규화.
  - 근거: V1 `LibraryFilterViewModel.swift:234-264` · V2 `LibraryFilterSheetViewModel.swift:188-204`, `NovelDomain/CLAUDE.md`(별점 필터)
- ✅ **Keep** — 칩 탭 시 해당 필터 해제(칩 = 필터 제거 버튼).
  - 근거: V1 `LibraryFilterViewModel.swift:266-284` · V2 `LibraryFilterSheetViewModel.swift:226-244`
- ✅ **Keep** — "초기화" 버튼은 **시트 필터 6종만** 리셋(관심·정렬은 시트 소속 아님 → 유지).
  - 근거: V1 `LibraryFilterViewModel.swift:286-296`(+`makeResultOption`이 `initialFilterOption.interestedOption` 보존) · V2 `LibraryFilterSheetViewModel.swift:247-252`, `NovelDomain/CLAUDE.md`(clearAll)
- ✅ **Keep** — 닫기(X)는 편집을 버리고 원래 필터를 반환(취소). "작품 찾기"만 편집본을 적용.
  - V2: 시트가 필터 **복사본**을 편집, "작품 찾기"에서 View가 `onApply`로 올림(ReadingPeriodSheet 패턴).
  - 근거: V1 `LibraryFilterViewModel.swift:172-182` · V2 `CLAUDE.md`(필터 시트 순수 입력 VM)
- ✅ **Keep** — 탭 라벨 옆 활성 점 인디케이터(어떤 탭에 선택이 걸렸는지).
  - 근거: V1 `LibraryFilterViewModel.swift:319-321` · V2 `LibraryFilterSheetViewModel.swift:51-60`(`hasActiveFilter`)
- ✅ **Keep** — 매력포인트·장르의 시트 표시 순서는 **디자인 전용 로컬 배열**(공용 `allCases` 순서와 다름).
  - 근거: V1 `LibraryFilterViewModel.swift:127`(`detailSearchGenres`) · V2 `CLAUDE.md`(표시 순서 로컬 배열)

---

## 3. 타유저 서재 (UserLibrary)

원본: `…/Library/UserLibrary/UserLibraryViewController/UserLibraryViewController.swift`, `.../UserLibraryViewModel/UserLibraryChildViewModel.swift` (2024 구버전)

### 3.1 화면 구조 (탭 페이저)

- 🗑 **단일 리스트가 의도 (2026-08-28, 사용자 판정)** — V1 타유저 서재는 **읽기상태별 탭 페이저**다: `UIPageViewController` + `UserLibraryPageBar`, `readStatusList`(읽기상태 전체 케이스)를 순회해 탭 하나당 자식 VC(`UserLibraryChildViewController`)를 만든다. 탭을 좌우로 넘기며 읽기상태별 목록을 본다.
  - **V2: 탭이 없다.** V2 타유저 서재는 필터 UI 자체가 없는 **단일 리스트**이고(정렬만 있음), 읽기상태 탭 구조가 사라졌다.
  - 근거: V1 `UserLibraryViewController.swift:34`,`85-131`,`116-126` · V2 `CLAUDE.md`(타유저 서재 = 필터 없음), `UserLibraryView.swift`(탭 없음)
  - **판정(2026-08-28, 사용자): 단일 리스트 유지가 의도.** V2는 필터 시트 패러다임으로 통일(정렬 6종 확장·2단계 갱신 등 이미 재설계 — `CLAUDE.md` 참고)했고, 탭 페이저는 구버전 UI다. 되살리지 않는다.
- ✅ **Keep** — 커스텀 네비바(뒤로가기 + 중앙 "서재" 고정 타이틀), 시스템 탭바 숨김.
  - 근거: V1 `UserLibraryViewController.swift:160-170` · V2 `CLAUDE.md`(커스텀 헤더, 타이틀 "서재" 고정)
- 🗑 **Delete** — `isMyLibrary` 분기(같은 VC로 내 서재도 표시하던 구버전 경로). V2는 내 서재/타유저 서재를 **별도 화면**으로 명확히 분리.
  - 근거: V1 `UserLibraryViewController.swift:21-24`,`160-170` · V2 `LibraryFeatureFactory`(makeMyLibraryView/makeUserLibraryView 분리)

### 3.2 정렬

- 🔧 **Improve 확정** (2026-08-28, 사용자) — 정렬 **2종 → 6종**. V1 타유저 서재는 드롭다운으로 **최신순/오래된순 2종**만. V2는 내 서재와 같은 `LibrarySortSheet` 6종을 재사용.
  - (오탐 방지: `LibraryFeature/CLAUDE.md`에 "Figma 시안의 2종과 다른 건 의도된 결정"으로 명문화 — 2종으로 되돌리지 말 것.)
  - 근거: V1 `UserLibraryChildViewModel.swift:148-163` · V2 `CLAUDE.md`(정렬 6종)
- 🗑 **Delete 확정** (2026-08-28, 사용자: 6종에선 배열 뒤집기로 정렬을 흉내낼 수 없어 구조적으로 불성립) — **1페이지 내 정렬 최적화**: 총 개수가 페이지 크기 이하(`isNotLoadable`)면 정렬 변경 시 서버를 다시 부르지 않고 **로컬 배열을 뒤집기**만 한다.
  - V2: 정렬 변경 시 항상 서버 재조회(커서 리셋). 클라 뒤집기 트릭 제거.
  - 근거: V1 `UserLibraryChildViewModel.swift:180-195`,`274-278` · V2 `LoadUserLibraryUseCase`(정렬 변경 → 재조회)
- ✅ **Keep** — 정렬 변경 시 목록을 처음부터 다시 채운다(마지막 ID·로드가능 플래그 리셋).
  - 근거: V1 `UserLibraryChildViewModel.swift:164-168` · V2 `CLAUDE.md`(reloadFromScratch)

### 3.3 로드·페이지네이션·빈 화면·에러

- 🔧 **Improve** — **페이지네이션 방식**. V1은 `lastUserNovelId`(마지막 작품 ID 오프셋)로 다음 페이지를 받는다. V2는 서버 발급 **커서**(내 서재와 같은 v2 엔드포인트).
  - 근거: V1 `UserLibraryChildViewModel.swift:115-137`,`256-271` · V2 `NovelData/CLAUDE.md`(타유저 서재 V2 커서)
- ✅ **Keep** — 무한 스크롤(다음 페이지) + 진행 중 중복 요청 가드(`isFetching`).
  - 근거: V1 `UserLibraryChildViewModel.swift:115-137` · V2 `LoadUserLibraryUseCase`, `CLAUDE.md`
- ✅ **Keep** — 총 개수 ≤ 페이지 크기면 무한 스크롤을 끈다(더 받을 게 없음).
  - V2: 서버 `hasNext`로 판정.
  - 근거: V1 `UserLibraryChildViewModel.swift:268-270` · V2 `LibraryViewModel`(hasNext)
- 🗑 **Delete 확정** (2026-08-28, 사용자: 타유저 서재에서 검색 유도는 맥락 이탈) — 빈 화면의 **"작품 찾기" CTA**. V1 빈 화면엔 검색으로 가는 버튼이 있었다.
  - V2: 타유저 서재 빈 화면은 **CTA 없음**("보관함이 비어있어요"만). (`CLAUDE.md`에 "CTA 없음"으로 명문화 = 의도.)
  - 근거: V1 `UserLibraryChildViewModel.swift:98-103` · V2 `CLAUDE.md`(빈 상태 CTA 없음)
- 🔧 **Improve** — **내/타유저 구분**. V1은 `isMyPage`(저장된 userId와 비교)로 같은 화면에서 내 페이지/타유저를 분기하고 빈 화면 문구도 나눴다. V2는 화면 자체를 분리해 타유저 서재는 항상 타유저 기준.
  - 근거: V1 `UserLibraryChildViewModel.swift:88-89`,`266` · V2 `NovelDomain/CLAUDE.md`(내/유저 Repository 쌍)
- ✅ **Keep** (확정 2026-08-28: 동일 가드로 해소) — 셀 선택 **2초 throttle**(내 서재 1초보다 김) → 중복 push 방지. V2 대응 미확인(1.7과 동일 사안).
  - 근거: V1 `UserLibraryChildViewModel.swift:105-112`

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

내 서재 `getNovelList` → 쿼리(`MyLibraryNovelListQuery`). V2 `UserLibraryV2Query`와 **필드가 일치**한다(대부분 ✅ Keep). C2에서 이 매핑을 테스트로 고정할 후보.

| 필터 | V1 전송 규칙 | V2 전송 규칙 | 상태 |
|---|---|---|---|
| `isInterest` | `interestedOption ? true : nil` (true일 때만) | `filter.isInterest ? true : nil` | ✅ Keep |
| `readStatuses` | 비어있지 않을 때 `rawValue` 배열 | 비어있지 않을 때 `mapReadingStatusString` | ✅ Keep |
| `genres` | 비어있지 않을 때 `rawValue` 배열 | 비어있지 않을 때 `mapNovelGenreString`(영문) | ✅ Keep (값 동일성 확인 권장) |
| `isCompleted` | `publicationStatusOptions.count == 1`일 때만 | `publicationStatus.map { $0 == .completed }` (단일) | 🔧 Improve (1.3) |
| 별점 | `notStarRated` 우선 → `unratedOnly=true`, 아니면 기본범위 아닐 때 `ratingMin/Max` | `switch rating` 동일 | ✅ Keep |
| `attractivePoints` | 비어있지 않을 때 `rawValue` 배열 | 비어있지 않을 때 `mapAttractivePointString` | ✅ Keep |
| `keywords` | 비어있지 않을 때 `keywordName`(한글) | 비어있지 않을 때 `keyword.name`(한글) | ✅ Keep |
| 미적용 필터 | (해당 없음 — 조건부로만 세팅) | **nil로 둬 파라미터 생략**(빈 배열 금지) | ✅ Keep (V2가 규칙 명문화) |

- 근거: V1 `MyLibraryRepository.swift:28-65` · V2 `NovelMapper.myLibraryV2Query` `NovelMapper.swift:185-224`, `NovelData/CLAUDE.md`(V2 쿼리 함정)
- 커서·`userId` 출처: V1은 `UserDefaults userId`를 경로에 넣음 → V2도 `appStorage.get(.userID)`. 타유저는 인자 userID. ✅ Keep.
