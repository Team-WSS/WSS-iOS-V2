# FeedFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 피드 화면들(목록·상세·작성/수정)이
> **실제로 어떻게 동작했는지**를 코드에서 추출한 목록이다. V1은 "실제 운영으로 검증된 동작 기준"이고,
> V2가 이 각각을 **유지했는지 / 일부러 바꿨는지 / 삭제했는지**를 나중에 사람이 한 번에 점검하기 위한 재료다.
> (#205 축 C의 C1 산출물. 이슈 #222.)
>
> **이 문서가 아닌 것** — V2 화면의 정본 계약이 아니다. V2의 "코드만 봐선 모르는 것"은 여전히
> [`CLAUDE.md`](CLAUDE.md)가 정본이다. 이 문서는 **V1 기준으로 훑은 것**이고, 분류는 **초안**이다.
>
> ⚠️ **V2 FeedFeature는 아직 배선 진행 중(WIP)이다** — 특히 소소피드/내 피드 목록 화면(`SosoFeedView`)은
> 화면 전환(작성·상세·프로필·작품)이 대부분 `print`/주석 스텁이고, 목록 로드 실패·인증 만료 처리가 없다.
> 그래서 아래에는 "V2가 V1 동작을 **아직 안 붙였다**"는 ❓가 많다 — **의도적 삭제가 아니라 미구현**일 가능성이
> 크니 Break로 단정하지 말 것. 상세(`FeedDetailView`)·작성(`CreateFeedView`)은 거의 완성돼 있다.

## 읽는 법 · 분류 범례

각 동작에 **초안 분류 배지**가 달려 있다. 나중에 사람이 와서 배지를 확정하고(바꾸면 바꾸고) 한 줄 근거를 남긴다.

| 배지 | 뜻 | 사용자가 할 일 |
|---|---|---|
| ✅ **Keep** | V2가 **같은 관찰 동작**을 유지(구현·구조는 달라도 됨) | 맞으면 그대로 |
| 🔧 **Improve** | V2가 V1의 버그·한계를 **의도적으로 고침**(근거 있음) | 근거 확인 |
| 🗑 **Delete** | V2가 **의도적으로 제거**한 동작 | 정말 버릴지 확인 |
| ❓ **Unknown** | 회귀일 수도, 의도일 수도, 미구현일 수도 — **판정 대기** | **판정 필요** |

- ❓ 항목과 눈에 띄는 🔧/🗑는 [§0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- V1 경로 접두사 생략형: `…/Feed/` = `WSSiOS/Source/Presentation/Feed/Feed/`, `…/FeedDetail/` = `WSSiOS/Source/Presentation/FeedDetail/`, `…/FeedEdit/` = `WSSiOS/Source/Presentation/FeedEdit/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/SosoFeed/SosoFeedView.swift`+VM (내 피드/소소피드 목록) | `…/Feed/FeedViewController/FeedViewController.swift`(탭 컨테이너)·`FeedPageContentViewController.swift`·`FeedPageContentViewModel/FeedPageContentViewModel.swift` | **V1은 3-page `UIPageViewController`**(내 피드/소소전체/소소추천), V2는 탭+옵션 전환으로 한 뷰가 목록 교체 |
| `Sources/SosoFeed/MyFeedFilterSheet.swift` (내 피드 필터 시트) | `…/Feed/Filter/FeedFilterViewController/FeedFilterViewController.swift` | 장르 + 공개/비공개 필터 |
| `Sources/FeedDetail/FeedDetailView.swift`+VM (피드 상세) | `…/FeedDetail/FeedDetailViewController/FeedDetailViewController.swift`·`FeedDetailViewModel/FeedDetailViewModel.swift` | 상세+댓글. RxSwift 다중 스트림 → 구조적 동시성 |
| `Sources/CreateFeed/CreateFeedView.swift`+VM (피드 작성/수정) | `…/FeedEdit/FeedEditViewController/FeedEditViewController.swift`·`FeedEditViewModel/FeedEditViewModel.swift` | **V1은 작성/수정 겸용 VC**, V2도 `Mode(create/edit)` 겸용 |
| `Sources/CreateFeed/ConnectNovelSheet/CreateFeedConnectNovelSheet.swift` (작품 연결 검색) | `…/FeedEdit/FeedEditViewController/FeedNovelConnectModalViewController.swift`·`FeedNovelConnectModalViewModel.swift` | 작품 검색 후 연결 |

> **피드 셀 UI 자체**(`WSSFeadView`)와 좌표계 드롭다운은 V2에서 `WSSComponent`로 승격됐다. V1 `…/Base/FeedList/*`(공용 피드 리스트 셀)에 대응 — 셀 내부 렌더 함정은 이 문서 범위 밖(WSSComponent 정본).

---

## 0. 점검 대기 요약

**❓ 판정 필요 — V2 소소피드/내 피드 목록 화면이 아직 안 붙인 것 (미구현 vs 회귀)**

1. **목록 화면 전환 전부 미배선** — V1 목록은 셀 탭→피드 상세, 프로필 탭→유저 페이지, 연결 작품 탭→작품 상세, 작성 버튼(연필)→피드 작성으로 갔다. **V2 `SosoFeedView`는 이 넷이 전부 `print`/주석 스텁**이다(내 글 "수정하기" 콜백만 배선됨). → [§1.6](#16-상호작용네비게이션)
2. **목록 로드 실패 표현 없음** — V1도 목록 로드 에러엔 **전면 에러 뷰가 없었다**(그냥 `print`, 빈 목록 유지). V2도 `state.errorMessage`만 세팅하고 **View가 그걸 안 그린다**(사실상 V1과 같은 무처리). 단 V2 Feature 계약(#195, [Feature CLAUDE.md](../CLAUDE.md))은 "목록 로드 실패=전면 `NetworkErrorView`"를 요구하므로 **미이행 상태**다. → [§1.4](#14-빈-화면에러로딩)
3. **인증 만료 라우팅 없음** — V2 `SosoFeedViewModel`·`FeedDetailViewModel`엔 `requiresAuthentication`/`onAuthenticationRequired`가 아예 없다. V1도 화면 단위 분기는 없었으나(네트워크 계층이 토큰 재발급 담당), V2 Feature 계약은 인증 만료→로그인 라우팅을 요구한다. → [§1.4](#14-빈-화면에러로딩)
4. **내 피드 카운트 출처가 다르다** — V1은 서버가 준 **전체 개수**(`feedsCount`)를 "n개"로 표시. V2는 **현재 로드된 배열 길이**(`myFeeds.count`)를 "n개의 기록"으로 표시 → 무한 스크롤 전엔 20개까지만 세어 실제 총량과 다르다. → [§1.3](#13-정렬내-피드-카운트)
5. **셀 선택 더블탭 가드** — V1은 피드 선택에 `throttle(1s)`, push에 `throttle(500ms)`을 걸어 중복 진입을 막았다. V2 목록은 화면 전환 자체가 미배선이라 가드도 없다. → [§1.6](#16-상호작용네비게이션)

**❓ 판정 필요 — 상세/작성 화면(거의 완성)에서 빠진 동작**

6. **댓글 전송 실패 무처리** — V1은 댓글 작성/수정 실패 시 **"네트워크 지연" 토스트** + 전송 버튼 재활성. V2 `FeedDetailViewModel`의 `createComment`/`editComment`/`deleteComment`/`deleteFeed`는 **`catch {}`가 비어 조용히 삼킨다**. → [§3.4](#34-댓글-작성수정삭제)
7. **댓글 500자 제한** — V1은 댓글 입력을 500자에서 하드 컷(`deleteBackward`). V2 입력바엔 이 제한이 없다(`.lineLimit(5)` 표시 제한만). → [§3.4](#34-댓글-작성수정삭제)
8. **탈퇴 유저(userId == -1) 처리** — V1은 목록·상세·댓글에서 프로필 탭 시 탈퇴 유저면 **"탈퇴한 유저" 토스트**로 막았다. V2엔 이 분기가 없다(프로필 탭 자체가 상세는 print, 목록은 print). → [§1.6](#16-상호작용네비게이션)·[§3.6](#36-상호작용네비게이션-상세)
9. **작성 완료 후 처리** — V1은 작성/수정 성공 시 `NotificationName.feedEdited` 브로드캐스트(→ 피드 탭이 "수정됨" 토스트) + `AppReviewManager.requestReview()` + pop. V2 `CreateFeedView`는 `submitState == .submitted`에 **아무 반응이 없다**(dismiss·목록 갱신·리뷰요청 미배선). → [§4.3](#43-작성수정-완료저장)
10. **수정 모드 "변경 감지" 게이트 / 기존 이미지 prefill** — V1 수정은 **바뀐 게 있어야만** 완료 버튼 활성(`isInitialFeedChanged`), 기존 첨부 이미지를 Kingfisher로 내려받아 채웠다. V2는 `canSubmit`이 "내용 비어있지 않음"만 보고(수정 무변경도 저장 가능), 기존 이미지는 `initialDraft`에 데이터가 없으면 회색 placeholder로 뜬다(App 배선 의존). → [§4.1](#41-진입prefill)·[§4.3](#43-작성수정-완료저장)

**🗑 / 🔧 눈에 띄는 변경 (의도 확인)**

11. 🔧 **미분류(연결 작품 없는 내 피드) 필터 표현** — V1은 필터 장르 목록에 **`etc`(그 외) case**를 넣어 처리. V2는 `NovelGenre`에 case를 안 늘리고 **`includesUncategorized: Bool`** 별도 필드로 표현하고, 서버 전송 시 Data가 `"etc"` sentinel을 덧붙인다. (오탐 방지: `FeedDomain/CLAUDE.md:18` 명문화 — Break로 오분류 금지.) → [§2.2](#22-장르-필터)·[부록](#부록-a-서버-요청-파라미터-매핑-c2-비교-재료)
12. 🗑 **Amplitude 이벤트 트래킹 전부 제거** — V1은 피드 진입·작성 버튼·좋아요·신고 등 곳곳에 Amplitude 이벤트를 심었다. V2엔 없다(홈과 동일 — 분석 미이식). → [§5](#5-부수-작업-v1이-피드에서-하던-것들)
13. 🗑 **`BlockUser` / `feedEdited` 알림 기반 토스트** — V1 피드 탭은 차단·수정 완료를 `NotificationCenter`로 받아 토스트. V2엔 이 크로스-스크린 알림 배관이 없다. → [§5](#5-부수-작업-v1이-피드에서-하던-것들)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 피드 목록 (내 피드 / 소소피드)

원본: `…/Feed/FeedViewModel/FeedPageContentViewModel.swift`, `…/Feed/FeedViewController/FeedViewController.swift`·`FeedPageContentViewController.swift`

### 1.1 탭 구조·진입·재조회

- ✅ **Keep** — 상단 탭 2종(**내 피드 / 소소피드**), 소소피드 선택 시 하위 옵션 2종(**전체글 / 추천글**)이 추가로 뜬다.
  - V2: `FeedTab(myFeed/sosoFeed)` + `SosoFeedOption(all/recommended)`. 소소피드일 때만 옵션 칩 노출.
  - 근거: V1 `FeedViewController.swift:20-21`,`102-120`, `FeedTab.swift:10-53` · V2 `SosoFeedView.swift:198-245`, `SosoFeedViewModel.swift:18-31`
- 🔧 **Improve (수단)** — V1은 화면을 **`UIPageViewController` 3페이지**(내피드/소소전체/소소추천 각각 별도 VC+VM)로 만들고 좌우 스와이프는 막았다(탭 버튼으로만 전환). V2는 **단일 뷰**가 탭/옵션에 따라 목록 배열을 교체한다.
  - V2: `state.myFeeds`/`state.sosoFeeds` 두 배열을 한 VM이 들고, `currentFeeds`로 가른다. 관찰 동작(탭 누르면 그 목록)은 같다.
  - 근거: V1 `FeedViewController.swift:28-31`,`207-229`(3 VC 생성·스크롤 잠금) · V2 `SosoFeedView.swift:252-257`, `SosoFeedViewModel.swift:33-34`
- ✅ **Keep** — 탭/옵션을 바꾸면 목록을 **처음부터 다시 채운다**(페이징 상태 리셋 후 재조회).
  - V2: `onChange(of: selectedTab)`/`onChange(of: selectedSosoFeedOption)` → `.load`(refresh: true). 스크롤 위치도 `.id(scrollIdentity)`로 최상단 리셋.
  - 근거: V1 `FeedPageContentViewModel.swift:282-288`(`resetFeedPagingState`+refresh), `:370-375` · V2 `SosoFeedView.swift:98-104`,`259-266`, `SosoFeedViewModel.swift:160-163`
- ✅ **Keep** (확정 2026-08-28: 재진입 재조회 없음은 화면별 의도 설계) — V1 각 페이지 VC는 `viewDidLoad`에서 1회 `reloadFeed`만 한다(진입 시 로드). **`viewWillAppear` 재조회는 없다** — 피드 작성/수정 후 목록 갱신은 위 `feedEdited` 알림(§5)이나 탭 재선택으로만 일어났다.
  - V2: `SosoFeedView`가 `onAppear`마다 `.load`. **탭 콘텐츠라면 복귀마다 갱신**이 V2 규약([Feature CLAUDE.md](../CLAUDE.md))이지만, V1은 오히려 진입 1회였다. 재조회 시점이 어긋날 수 있어 확인 필요.
  - 근거: V1 `FeedPageContentViewController.swift:47-54` · V2 `SosoFeedView.swift:95-97`

### 1.2 목록 로드·페이지네이션

- ✅ **Keep** — **커서 페이지네이션**(`lastFeedId`): 마지막 피드의 `feedId`를 다음 페이지 커서로 넘기고, 첫 페이지는 커서 `0`. `isLoadable`이 true이고 진행 중(`isFetching`)이 아닐 때만 다음 페이지.
  - V2: `lastFeedID` 커서 동일(첫 페이지 `FeedID(0)`, `page.hasNext`로 더 있는지 판정, `!hasMore`면 무시). `Paginated<TotalFeed>`.
  - 근거: V1 `FeedPageContentViewModel.swift:21-23`,`92-107`,`231-255` · V2 `SosoFeedViewModel.swift:222-240`,`279-295`, `FeedDomain/CLAUDE.md`(lastFeedID 커서)
- ✅ **Keep** — 무한 스크롤(바닥 도달 시 다음 페이지 append).
  - V2: 수단 변경 — V1은 스크롤 오프셋 임계값(`offsetY + viewHeight >= contentHeight`, **여백 0 = 정확히 바닥**), V2는 `LazyVStack` 마지막 행 `onAppear` → `.loadMore`.
  - 근거: V1 `FeedPageContentViewController.swift:308-318`, `FeedPageContentViewModel.swift:231-255` · V2 `SosoFeedView.swift:290-294`
- ✅ **Keep** — 진행 중 중복 요청 가드(`isFetching`).
  - V2: `isLoading` + `hasMore` 가드. (경합 방어는 서재만큼 정교하진 않음 — 단일 슬롯/취소 구조 아님.)
  - 근거: V1 `FeedPageContentViewModel.swift:22`,`232-237` · V2 `SosoFeedViewModel.swift:223`,`280`
- ✅ **Keep** — 당겨서 새로고침(pull-to-refresh)으로 목록을 처음부터 다시 받는다.
  - V2: `.refreshable { .load }`.
  - 근거: V1 `FeedPageContentViewController.swift:86`(refreshControl), `FeedPageContentViewModel.swift:257-280` · V2 `SosoFeedView.swift:310-312`
- 🔧 **Improve** — **내 피드 작성자 정보 조립**. V1 내 피드는 `getMyFeedData`가 `getMyProfileData`(프로필)와 `getUserFeed`(목록)를 **`zip`으로 매번 함께** 받아 닉네임/프로필을 합쳤다. V2는 프로필을 **한 번 받아 캐시**(`cachedMyProfile`)하고 탭을 오갈 때 재사용한다.
  - V2: `fetchMyFeeds` 응답에 작성자 정보가 없어 `LoadProfileUseCase`로 따로 조회 후 `applying(_:to:)`으로 `TotalFeed.author`를 채운다(FeedFeature가 `ProfileDomain`을 직접 의존하는 이유). 관찰 동작(내 피드에 내 프로필/닉네임 표시)은 같다.
  - 근거: V1 `FeedPageContentViewModel.swift:320-341` · V2 `SosoFeedViewModel.swift:127-129`,`246-277`, `CLAUDE.md`(fetchMyFeeds 프로필 조립)
- ✅ **Keep** — 소소피드 옵션(전체글/추천글)은 서버 파라미터 `feedsOption`(`ALL`/`RECOMMENDED`)로 전송.
  - V2: `SosoFeedOption.rawValue` 그대로. 값 동일.
  - 근거: V1 `FeedPageContentViewModel.swift:312-317`, `FeedTab.swift:22-32` · V2 `SosoFeedOption.swift:12-14`, `FeedData` `GetSosoFeedsQuery`

### 1.3 정렬·내 피드 카운트

- ✅ **Keep** — **내 피드 정렬 2종**(최신순/오래된순), 정렬 버튼 탭 시 즉시 토글되어 재조회 + **햅틱 선택 피드백**.
  - V2: `MyFeedOption.sortType`(`.recent`/`.old`) 토글, `WSSSortButton` 탭 → `HapticManager.selection()` + `.toggleMyFeedSort`(시트 안 거치고 즉시 재조회).
  - 근거: V1 `FeedPageContentViewModel.swift:113-117`, `FeedPageContentViewController.swift:283-287`(sort 햅틱) · V2 `SosoFeedView.swift:222-226`, `SosoFeedViewModel.swift:303-315`, `CLAUDE.md`(sortType는 필터 커밋 흐름과 별개)
- ✅ **Keep** — 정렬은 **내 피드에만** 있다(소소피드엔 정렬 컨트롤 없음).
  - 근거: V1 `FeedPageContentView`(`myFeedFilterHeaderView`가 my 페이지에만) · V2 `SosoFeedView.swift:200-245`(myFeed 케이스에만 sort 버튼)
- ❓ **Unknown** — **내 피드 개수 표시 출처**. V1은 서버 응답의 **전체 개수**(`userFeedListEntity.feedsCount`)를 필터 버튼에 "n개"로 표시.
  - V2: **현재 로드된 배열 길이**(`state.myFeeds.count`)를 "n개의 기록"으로 표시 → 페이지네이션 전엔 최대 20까지만 세어 서버 전체 수와 다를 수 있다.
  - 근거: V1 `FeedPageContentViewModel.swift:332-334`, `FeedPageContentViewController.swift:97-101` · V2 `SosoFeedView.swift:206-208`

### 1.4 빈 화면·에러·로딩

- ✅ **Keep** — 내 피드가 0건이면 **빈 화면**(피드 없음 + "피드 작성" 유도)을 띄운다.
  - V2: `WSSEmptyView(type: .myFeed)`(내 피드 탭 한정). 단 CTA 액션은 아직 빈 클로저(§1.6과 함께 미배선).
  - 근거: V1 `FeedPageContentViewController.swift:118-124`,`299-303`(emptyView.writeFeedButton) · V2 `SosoFeedView.swift:272-275`
- ❓ **Unknown (판정 보류 2026-08-28)** — **목록 로드 실패 표현**. V1은 목록 로드 에러를 **`onError`에서 `print`만** 하고 UI로 알리지 않았다(전면 에러 뷰 없음, 빈/직전 목록 유지). 즉 V1엔 애초에 목록 실패 UI가 없었다.
  - V2: `catch`에서 `state.errorMessage`를 세팅하지만 **`SosoFeedView`가 그 값을 그리지 않는다**(토스트도 전면 뷰도 없음) → 관찰상 V1과 같은 무처리. 하지만 V2 Feature 계약(#195)은 "목록 실패=전면 `NetworkErrorView`+재시도"를 요구하므로 **아직 미이행**이다.
  - 근거: V1 `FeedPageContentViewModel.swift:108-110`,`252-254`,`277-279`(print) · V2 `SosoFeedViewModel.swift:241-243`,`296-298`, `SosoFeedView.swift:268-316`(errorMessage 미표시), [Feature CLAUDE.md](../CLAUDE.md)(로드 실패 표현 계약)
  - **판정 포인트**: V2에서 목록 실패를 전면 뷰로 표현할지(=계약 준수) / V1처럼 조용히 둘지.
- 🔧 **통일 확정→코드 대상** (2026-08-28: Library식 authenticationRequired 라우팅 추가) — **인증 만료 처리**. V1엔 목록 화면 단위 인증 만료 분기가 없고 네트워크 계층(`tokenCheckURLSession`)이 재발급을 담당했다. V2 `SosoFeedViewModel`엔 `requiresAuthentication`/`onAuthenticationRequired`가 아예 없다(에러를 전부 errorMessage로).
  - 근거: V1 `FeedService.swift:40`(tokenCheckURLSession) · V2 `SosoFeedViewModel.swift`(인증 신호 없음), [Feature CLAUDE.md](../CLAUDE.md)(인증 만료 처리 계약)
- ✅ **Keep** — 첫 로드 시 로딩 표시, 갱신/추가 로드 중엔 목록 유지.
  - V2: `isLoading && currentFeeds.isEmpty`일 때만 `LoadingView`(보여줄 게 없을 때만 — 홈·서재와 같은 결).
  - 근거: V1 `FeedPageContentViewModel.swift`(로딩 뷰 개념 없음 — V1 목록은 별도 로딩 뷰 없음) · V2 `SosoFeedView.swift:270-271`

### 1.5 좋아요(리액션)

- ✅ **Keep** — 좋아요 토글은 **낙관 반영 후 실패 시 롤백**(카운트·상태 되돌림).
  - V2: `TotalFeed.toggleLike()` 낙관 반영 → 실패 시 동일 토글로 롤백(내 피드/소소피드 두 배열 중 있는 쪽). 관찰 동작 동일.
  - 근거: V1 `FeedPageContentViewModel.swift:186-223` · V2 `SosoFeedViewModel.swift:319-348`, `CLAUDE.md`(toggleLike)
- 🔧 **복원 확정→TODO** (2026-08-28) — V1 좋아요는 **햅틱(light impact)**을 준다. V2 목록 좋아요엔 햅틱이 없다(정렬 토글엔 있음).
  - 근거: V1 `FeedPageContentViewModel.swift:196` · V2 `SosoFeedViewModel.swift:319-339`

### 1.6 상호작용·네비게이션

- ❓ **Unknown (헤드라인 · 미배선)** — V1 목록의 화면 전환 4종:
  - **셀 탭 → 피드 상세**(`throttle(1s)` + push `throttle(500ms)` 이중 가드).
  - **프로필 탭 → 유저 페이지**(단, 내 글이면 무시, `userId == -1`이면 "탈퇴 유저" 토스트).
  - **연결 작품 탭 → 작품 상세**.
  - **작성 버튼(연필) → 피드 작성**(`throttle(1s)`).
  - **V2 `SosoFeedView`는 이 넷이 전부 스텁**이다(`// 이동`, `print`). 유일하게 배선된 건 내 글 드롭다운의 "수정하기"(`onEditFeedTapped`).
  - 근거: V1 `FeedPageContentViewModel.swift:126-153`,`134-146`(탈퇴 유저), `FeedPageContentViewController.swift:126-138`, `FeedViewController.swift:122-128`(작성 버튼) · V2 `SosoFeedView.swift:118-124`,`298-300`,`327`,`347`, `FeedFeatureFactory.swift:111-136`(onEditFeedTapped만 콜백)
  - **판정 포인트**: 미구현일 뿐(설계상 콜백 위임 예정)인지 확인 — 의도적 삭제 아님.
- ✅ **Keep** — 피드 셀 threedots 드롭다운: **내 글 = 수정/삭제, 남의 글 = 스포일러·부적절 신고(빨강)**.
  - V2: `feedMenuItems`가 `feed.isMyFeed`로 갈라 같은 2×2 구성. 삭제·신고는 확인/완료 알럿(`WSSAlertType` 5종 공용).
  - 근거: V1 `FeedPageContentViewModel.swift:155-184`(dropdown 분기) · V2 `SosoFeedView.swift:384-417`, `SosoFeedViewModel.swift:415-465`, `CLAUDE.md`(알럿 5종 공용)
- ✅ **Keep** — 신고는 **확인 알럿 → API → 접수 완료 알럿**의 2단, 삭제는 확인 알럿 → 목록에서 제거.
  - V2: `FeedAlert`에 `reportSpoilerCompleted`/`reportImproperCompleted` 별도 케이스로 2단 유지. 삭제 성공 시 두 배열에서 제거.
  - 근거: V1 `FeedPageContentViewController.swift:166-265` · V2 `SosoFeedViewModel.swift:423-465`
- ✅ **Keep** — 드롭다운이 떠 있을 때 스크롤을 시작하거나 다른 곳을 탭하면 드롭다운을 닫는다.
  - V2: 투명 오버레이 탭 → `feedMenuContext = nil`.
  - 근거: V1 `FeedPageContentViewModel.swift:225-229`(willBeginDragging→hide) · V2 `SosoFeedView.swift:372-375`

---

## 2. 내 피드 필터 시트 (FeedFilter)

원본: `…/Feed/Filter/FeedFilterViewController/FeedFilterViewController.swift`, `…/Data/Entity/Feed/FeedFilter.swift`

- ✅ **Keep** — 필터 대상은 **장르 다중선택 + 공개/비공개(공개여부)** 두 축뿐이다(정렬은 필터 시트 밖 — §1.3).
  - V2: `MyFeedFilterSheet`가 draft(`myFeedOptionDraft`)를 편집, "작품 찾기"류 CTA에서 `applyMyFeedFilter`로 커밋 후 재조회(ReadingPeriod 패턴). 시트는 순수 입력.
  - 근거: V1 `FeedFilterViewController.swift:22-24`,`160-173` · V2 `SosoFeedViewModel.swift:44-50`,`174-185`,`350-357`, `CLAUDE.md`(draft→apply 커밋)
- ✅ **Keep** — 닫기(X)는 편집을 버리고 원래 필터를 반환(취소), CTA만 편집본 적용.
  - V2: 시트가 draft 복사본을 편집, `resetMyFeedFilterDraft`로 열 때 커밋값을 복사해온다.
  - 근거: V1 `FeedFilterViewController.swift:151-158`(dismiss→initialFilterOption) · V2 `SosoFeedViewModel.swift:174-175`

### 2.1 공개/비공개 (Visibility)

- ✅ **Keep** — 공개/비공개는 독립 토글이지만 **둘 다 해제되는 상태는 허용하지 않는다** — 마지막 하나를 끄면 반대쪽이 자동으로 켜진다.
  - V2: `toggleMyFeedFilterVisibility`가 `guard includesPublic || includesPrivate else { return }`로 둘 다 꺼짐을 **무시**한다(같은 불변식, 표현만 `VisibilityType` enum).
  - 근거: V1 `FeedFilterViewController.swift:80-104`(비면 opposite 추가) · V2 `SosoFeedViewModel.swift:385-413`, `CLAUDE.md`(둘 다 해제 불가)

### 2.2 장르 필터

- 🔧 **Improve** — **미분류("그 외") 표현**. V1 필터 장르 목록(`NovelGenre.feedFilterGenres`)엔 **`etc` case**가 실제 장르처럼 끼어 있어, 연결 작품 없는 피드는 이 칩으로 걸렀다.
  - V2: `NovelGenre`에 case를 안 늘리고 **`MyFeedOption.includesUncategorized: Bool`** 별도 필드로 표현한다(장르 enum은 검색·상세가 공유하는 순수 타입이라 오염 금지). 서버 전송 시 Data가 `"etc"` sentinel을 덧붙인다. (오탐 방지: `FeedDomain/CLAUDE.md:18` 명문화 — Break로 오분류 금지.)
  - 근거: V1 `NovelGenre.swift:216`(feedFilterGenres에 `.etc` 포함), `FeedFilterViewController.swift:23`,`160-163` · V2 `MyFeedOption.swift:12-16`, `SosoFeedViewModel.swift:373-382`(toggleEtc), `FeedDomain/CLAUDE.md`(includesUncategorized), `DefaultFeedRepository.swift:174-178`("etc" sentinel)
- ✅ **Keep** — 필터 장르 다중선택, 선택한 장르만 서버로 전송.
  - V2: 장르 칩 토글 → `genres` 배열. **빈 배열 = 무필터(전체)**로 서버가 해석(V2가 이를 의도된 동작으로 명문화).
  - 근거: V1 `FeedFilterViewController.swift:106-118` · V2 `SosoFeedViewModel.swift:359-371`, `FeedData/CLAUDE.md`(genres.isEmpty=무필터)
- ✅ **Keep** — 장르 필터의 시트 표시 순서·목록은 **디자인 전용 로컬 배열**(`feedFilterGenres`: 판타지·현판·로맨스·로판…etc 순).
  - 근거: V1 `NovelGenre.swift:216`(`feedFilterGenres`) · V2 `MyFeedFilterSheet`(장르 나열)

---

## 3. 피드 상세 (FeedDetail)

원본: `…/FeedDetail/FeedDetailViewModel/FeedDetailViewModel.swift`, `…/FeedDetail/FeedDetailViewController/FeedDetailViewController.swift`

### 3.1 진입·로드 구조

- 🔧 **Improve (수단)** — V1은 `viewWillAppear`마다 **두 스트림을 병렬로** 발화했다: (a) `getSingleFeed`(피드 본문 → 좋아요·연결작품·이미지 등 채움), (b) `zip(getSingleFeedComments, getMyProfile)`(댓글+내 프로필, 로딩 스피너 제어). V2는 `.load`에서 **세 `Task`를 동시에**(피드 상세 / 댓글 / 내 프로필 이미지) 띄운다.
  - V2: `Task { loadFeed() }` · `Task { loadComments() }` · `Task { loadCurrentUserProfileImage() }`. 관찰상 "본문·댓글·프로필을 함께 받아 그린다"는 같다.
  - 근거: V1 `FeedDetailViewModel.swift:184-231` · V2 `FeedDetailViewModel.swift:155-160`,`201-240`
- ✅ **Keep** (확정 2026-08-28: 의도적 설계) — V1은 `viewWillAppear`마다 다시 로드(수정 화면에서 돌아오면 최신 반영). V2는 `onAppear`의 `.load` 1회 — push 상세라 더 깊은 push에서 돌아올 때 재발화 여부(수정 반영)가 SwiftUI 생명주기에 달림.
  - 근거: V1 `FeedDetailViewController.swift:49-57` · V2 `FeedDetailView.swift:82-84`
- ✅ **Keep** — 로딩 중엔 로딩 뷰, 본문 도착 후 콘텐츠.
  - V2: `state.detail == nil && !detailLoadFailed`면 `LoadingView`.
  - 근거: V1 `FeedDetailViewModel.swift:209-211`(showLoadingView), `FeedDetailViewController.swift:545-550` · V2 `FeedDetailView.swift:47-62`

### 3.2 피드 본문·이미지·연결 작품

- ✅ **Keep** — 첨부 이미지 탭 → **전체화면 이미지 뷰어**(탭한 인덱스부터, 좌우 스와이프).
  - V2: `fullScreenCover(item: selectedImage)` → `FeedDetailImageViewer(imageURLs:initialIndex:)`.
  - 근거: V1 `FeedDetailViewModel.swift:283-288`, `FeedDetailViewController.swift:177-184` · V2 `FeedDetailView.swift:85-90`,`133-142`
- ✅ **Keep** — 연결 작품 블록 탭 → 작품 상세로 이동.
  - V2: `onNovelTapped(novel.basicInfo.id)` 콜백 위임(연결 작품이 있고 장르가 있을 때만 블록 표시).
  - 근거: V1 `FeedDetailViewModel.swift:291-297` · V2 `FeedDetailView.swift:144-162`
- ✅ **Keep** — 좋아요 토글은 **낙관 반영 + 실패 롤백**.
  - V2: `FeedDetail.toggleLike()` 낙관 → 실패 시 재토글. (V1은 좋아요에 `debounce(200ms)` + 햅틱; V2는 디바운스·햅틱 없음.)
  - 근거: V1 `FeedDetailViewModel.swift:242-270` · V2 `FeedDetailViewModel.swift:341-358`

### 3.3 피드 드롭다운·신고·삭제 (상세)

- ✅ **Keep** — 상세 우상단 threedots → 내 글이면 수정/삭제, 남의 글이면 스포일러/부적절 신고.
  - V2: `feedDropdownItems()`가 `isMyFeed`로 분기. 신고는 확인→완료 2단 알럿, 삭제는 확인 알럿→`dismiss`.
  - 근거: V1 `FeedDetailViewModel.swift:423-440`, `FeedDetailViewController.swift:302-403` · V2 `FeedDetailView.swift:295-337`, `FeedDetailViewModel.swift:250-299`
- 🔧 **Improve** — **"존재하지 않는/접근 불가 피드" 처리**. V1은 서버 에러 코드 `FEED-001/005/006`이면 "알 수 없는 피드" 별도 화면(`FeedDetailUnknownFeedErrorViewController`)을, 그 외엔 네트워크 에러 뷰를 띄웠다.
  - V2: `RepositoryError.notFound`(404)·`.forbidden`(403 숨김·차단)을 하나의 **`feedUnavailable` 알럿**("이미 삭제된 피드")로 뭉뚱그리고 확인 시 `dismiss`. 그 외 로드 실패는 **전면 `NetworkErrorView`+재시도**(`detailLoadFailed`).
  - 근거: V1 `FeedDetailViewModel.swift:678-700`(alertCodes) , `FeedDetailViewController.swift:559-564` · V2 `FeedDetailViewModel.swift:201-217`,`242-246`, `FeedDetailView.swift:57-58`
- ✅ **Keep** — 삭제 성공 시 상세를 벗어난다(pop/dismiss).
  - V2: `didDeleteFeed` → `dismiss()`.
  - 근거: V1 `FeedDetailViewController.swift:395-402` · V2 `FeedDetailView.swift:459-468`

### 3.4 댓글 작성/수정/삭제

- ✅ **Keep** — 댓글 작성/수정 후 **댓글 목록을 다시 받아 갱신**하고 입력창을 비운다.
  - V2: `submitComment` 성공 후 `state.commentText=""`, `editingCommentID=nil`, `Task { loadComments() }`.
  - 근거: V1 `FeedDetailViewModel.swift:342-419` · V2 `FeedDetailViewModel.swift:165-176`,`301-339`
- ✅ **Keep** — 댓글 수정은 대상 댓글 본문을 입력창에 채우고 수정 모드로 진입(같은 입력창 재사용).
  - V2: `beginEditingComment`가 `editingCommentID`+`commentText` 세팅, 전송 시 editing이면 `editComment`.
  - 근거: V1 `FeedDetailViewModel.swift:483-516`(commentDropdownDidTap top,true) · V2 `FeedDetailViewModel.swift:312-318`, `FeedDetailView.swift:342-355`
- ✅ **Keep** — 댓글 삭제/신고: 남의 댓글은 스포일러·부적절 신고(확인→완료 2단), 내 댓글은 수정/삭제. 삭제 성공 시 목록에서 제거 + 댓글 수 감소.
  - V2: `commentDropdownItems()` `selectedCommentIsMine` 분기, `AlertType`에 댓글 삭제/신고 케이스. 삭제 시 `removeCommentCount`.
  - 근거: V1 `FeedDetailViewModel.swift:483-516`, `FeedDetailViewController.swift:426-523` · V2 `FeedDetailView.swift:341-387`, `FeedDetailViewModel.swift:264-271`,`320-329`
- 🔧 **복원 확정→TODO** (2026-08-28: V2 제한 없음 실측) — **댓글 500자 제한**. V1은 댓글 입력을 500자에서 하드 컷(`textView.deleteBackward()`).
  - V2: 입력바에 글자수 제한이 없다(`.lineLimit(5)`는 표시 줄 제한).
  - 근거: V1 `FeedDetailViewController.swift:24`,`599-604` · V2 `FeedDetailCommentInputBar.swift:53-59`
- 🔨 **회귀 확정→TODO** (2026-08-28: 빈 catch 4곳 실측) — **댓글 전송 실패 표현**. V1은 작성/수정 실패 시 "네트워크 지연" 토스트 + 전송 버튼 재활성. V2 `createComment`/`editComment`/`deleteComment`/`deleteFeed`의 `catch {}`가 **비어 조용히 삼킨다**.
  - 근거: V1 `FeedDetailViewModel.swift:407-419`, `FeedDetailViewController.swift:247-252` · V2 `FeedDetailViewModel.swift:301-339`
- ❓ **Unknown (사소)** — V1 전송 버튼 활성 조건: 내용이 비어있지 않고 **초기값과 다를 때만**(수정 시 무변경이면 비활성). V2 `submitComment`는 trim 후 비어있지 않으면 전송(무변경 재전송 가능).
  - 근거: V1 `FeedDetailViewModel.swift:307-319`(isNotChanged) · V2 `FeedDetailViewModel.swift:165-166`
- ✅ **Keep** — 스포일러 댓글은 본문 대신 "스포일러" 표시로 가리고 탭하면 펼친다(가시성 처리).
  - V2: `CommentRow(visibility:)`로 스포일러/숨김/차단 표현(`FeedComment.isSpoiler/isHidden/isBlocked`).
  - 근거: V1 `FeedDetailViewModel.swift:114`,`632-640`(commentSpoiler) · V2 `FeedDetailView.swift:199`, `CommentRow`

### 3.5 댓글 입력창·키보드

- ✅ **Keep** — 댓글 입력창에 **로그인 사용자 프로필 이미지** 표시, 입력 시 키보드에 맞춰 스크롤을 바닥으로 내림.
  - V2: `currentUserProfileImageURL`(부차 콘텐츠라 실패해도 기본 표시), 포커스 시 `scrollToBottom`. 전송 중엔 버튼이 `ProgressView`.
  - 근거: V1 `FeedDetailViewModel.swift:642-645`, `FeedDetailViewController.swift:207-234` · V2 `FeedDetailViewModel.swift:232-240`, `FeedDetailView.swift:233-263`, `FeedDetailCommentInputBar.swift`

### 3.6 상호작용·네비게이션 (상세)

- ✅ **Keep** — 뒤로가기 → pop/dismiss, 신고·삭제 알럿·드롭다운은 배경 탭으로 닫힘.
  - V2: 툴바 back → `dismiss()`, `.onTapGesture`로 드롭다운/포커스 해제.
  - 근거: V1 `FeedDetailViewController.swift:71-73`,`442-447` · V2 `FeedDetailView.swift:77-81`,`271-280`
- ❓ **Unknown** — **프로필 탭 → 유저 페이지 / 탈퇴 유저 처리**. V1은 상세·댓글에서 프로필 탭 시 유저 페이지로 push(내 글이면 무시, `userId == -1`이면 "탈퇴 유저" 토스트).
  - V2: 상세 프로필 탭이 `print` 스텁, 탈퇴 유저 분기 없음.
  - 근거: V1 `FeedDetailViewModel.swift:272-281`,`451-465` · V2 `FeedDetailView.swift:110-114`(print)

---

## 4. 피드 작성/수정 (CreateFeed / FeedEdit)

원본: `…/FeedEdit/FeedEditViewModel/FeedEditViewModel.swift`, `…/FeedEdit/FeedEditViewController/FeedEditViewController.swift`

### 4.1 진입·prefill

- ✅ **Keep** — **작성/수정 겸용 화면**. 수정이면 대상 피드의 내용·스포일러·공개여부·연결작품·이미지를 채워 넣고 상단 타이틀이 "피드 수정"이 된다.
  - V2: `CreateFeedViewModel.Mode(create/edit(FeedID))`, `isEditing` → 타이틀 "피드 작성"/"피드 수정".
  - 근거: V1 `FeedEditViewModel.swift:60-72`,`112-152`, `FeedEditViewController` · V2 `CreateFeedViewModel.swift:19-24`,`62-66`, `CreateFeedView.swift:179-183`, `FeedFeatureFactory.swift:40-55`
- ❓ **Unknown** — **수정 prefill 방식**. V1은 `viewDidLoad`에서 `getSingleFeed`로 피드를 직접 받아 채우고, **기존 첨부 이미지를 Kingfisher로 내려받아** `selectedImages`에 넣었다.
  - V2는 `makeEditFeedView(initialDraft:)`로 **App(호출자)이 미리 채운 `FeedDraft`를 주입**받는다. 이미지의 경우 `initialDraft.attachedImages`(ID)만 있고 `attachedImageDatas`가 비면 회색 placeholder로 뜬다 — 기존 이미지 데이터 주입은 App 배선에 달림.
  - 근거: V1 `FeedEditViewModel.swift:112-152`(getSingleFeed + Kingfisher) · V2 `FeedFeatureFactory.swift:40-55`, `CreateFeedView.swift:324-334`

### 4.2 입력·검증·컨트롤

- ✅ **Keep** — 본문 **최대 2000자**, 첨부 이미지 **최대 5장**, 초과 시 토스트로 알린다.
  - V2: `FeedDraft.maxContentCount = 2000`, `maxImageCount = 5`. 이미지 초과·작품 중복 연결은 `showToast`(`limitAddImage`/`novelAlreadyConnected`). 본문 초과는 도메인 `updateContent`가 throw하나 토스트는 안 띄움(카운터로만 표현).
  - 근거: V1 `FeedEditViewModel.swift:23`,`217-233`, `StringLiterals+Feed.swift:11`(imageMaxCount 5) · V2 `FeedDraft.swift:53-54`,`46-95`, `CreateFeedView.swift:151-162`,`284-286`
- ✅ **Keep** — **스포일러 토글 / 공개여부(나만 보는 기록) 토글**.
  - V2: `toggleSpoiler`/`togglePrivate`(도메인 `FeedDraft` mutating). "나만 보는 기록" = isPrivate.
  - 근거: V1 `FeedEditViewModel.swift:199-215` · V2 `CreateFeedView.swift:203-238`, `CreateFeedViewModel.swift:146-150`
- ✅ **Keep** — **작품 연결**: 이미 연결돼 있으면 검색을 다시 열지 않고 "이미 연결됨" 토스트, 연결/해제 가능.
  - V2: 연결 있으면 `alreadyLinkedNovel`(→ `connectedNovelOverLimit` 토스트), 없으면 검색 시트. `removeConnectedNovel`로 해제.
  - 근거: V1 `FeedEditViewModel.swift:247-274` · V2 `CreateFeedView.swift:388-395`, `CreateFeedViewModel.swift:152-159`
- ✅ **Keep** — 사진 선택 시 남은 장수만큼만 고를 수 있게 제한(5장 - 현재 장수).
  - V2: `photosPicker(maxSelectionCount: max(1, maxImageCount - 현재장수))`.
  - 근거: V1 `FeedEditViewController.swift:230-236`(초과 시 토스트) · V2 `CreateFeedView.swift:85-90`

### 4.3 작성/수정 완료·저장

- 🔧 **Improve (수단)** — **저장 중 중복/이탈 방지**. V1은 완료·뒤로 버튼에 `throttle(3s)`를 걸고, 완료 시 로딩 뷰 + 완료/뒤로 버튼 비활성으로 재진입을 막았다.
  - V2: `canSubmit`(내용 있고 제출 중 아님) + `isSubmitting` 동안 **`allowsHitTesting(false)` + opacity 0.5**로 draft 편집·재제출을 차단, 완료 버튼은 `ProgressView`.
  - 근거: V1 `FeedEditViewModel.swift:161-197` · V2 `CreateFeedView.swift:73-74`,`185-199`, `CreateFeedViewModel.swift:53-60`,`245-281`
- ✅ **Keep** — 뒤로가기 시 **"작성 중단" 확인 알럿**을 띄운다.
  - V2: back 탭 → `showDismissAlert`(`.stopWritingFeed`), 확인 시 `dismiss`.
  - 근거: V1 `FeedEditViewModel.swift:160-165`,`276-280`(stopEditButton) · V2 `CreateFeedView.swift:174-176`,`139-146`
- 🔧 **부분 확정→TODO** (2026-08-28: 앱 리뷰 요청 재도입) — **작성/수정 성공 후 처리**. V1은 성공 시 `NotificationName.feedEdited` 브로드캐스트(→ 피드 탭 "수정됨" 토스트) + `AppReviewManager.requestReview()`(앱 리뷰 요청) + pop.
  - V2 `CreateFeedView`는 `state.submitState == .submitted`에 **아무 반응이 없다** — dismiss·목록 갱신·리뷰 요청이 View에 배선돼 있지 않다(App 조정 계층 몫일 수 있으나 확인 필요).
  - 근거: V1 `FeedEditViewModel.swift:188-197` · V2 `CreateFeedView.swift`(submitState 반응 없음), `CreateFeedViewModel.swift:277`(state만 `.submitted`)
- ❓ **Unknown** — **수정 "변경 감지" 게이트**. V1 수정 모드는 내용·스포일러·공개·연결작품·이미지 중 **하나라도 바뀌어야** 완료 버튼 활성(`isInitialFeedChanged`). V2 `canSubmit`은 "내용 비어있지 않음"만 봐 무변경 재저장이 가능하다.
  - 근거: V1 `FeedEditViewModel.swift:322-330` · V2 `CreateFeedViewModel.swift:53-56`

### 4.4 작품 연결 검색 (Connect Novel)

- ✅ **Keep** — 작품 제목/작가 검색 → 결과 리스트에서 선택 → 확인 시 연결. 무한 스크롤로 다음 페이지.
  - V2: `CreateFeedConnectNovelSheet`. 검색은 `WSSSearchBar.onSearch`(제출 시), 타이핑은 `updateConnectedNovelSearchText`로 즉시 반영, 결과 영역은 `hasSearchedNovel` 플래그로 가른다(응답 받은 뒤에만 켜짐). 무한 스크롤은 정수 `page`(0부터).
  - 근거: V1 `FeedNovelConnectModalViewModel.swift:42-46`, `FeedNovelConnectModalViewController.swift` · V2 `CreateFeedViewModel.swift:177-238`,`283-322`, `CLAUDE.md`(hasSearchedNovel·searchNovelTask 함정)
- 🔧 **Improve (수단)** — 검색 페이지네이션 방식이 V1은 커서/`reachedBottom`, V2는 정수 page(`SearchFeature`/`AddNovelViewModel`과 동일 관례).
  - 근거: V1 `FeedNovelConnectModalViewModel.swift:44`(reachedBottom) · V2 `CreateFeedViewModel.swift:104-106`,`307-322`

---

## 5. 부수 작업 (V1이 피드에서 하던 것들)

- 🗑 **Delete** — **Amplitude 이벤트 트래킹**. V1은 피드 탭 진입(`feedAll`), 작성 플로팅 버튼(`feedWriteFloatingButton`), 좋아요(`feedLike`/`feedDetailLike`), 신고 확인(`alertFeedSpoiler`/`alertFeedAbuse`/`alertComment*`), 작성 완료(`writeFeed`), 상세 진입(`feedDetail`) 등에 이벤트를 심었다.
  - V2엔 트래킹 코드가 전혀 없다(홈과 동일 — 분석 인프라 미이식으로 보이나 확인 필요).
  - 근거: V1 `FeedViewController.swift:48`,`125`, `FeedPageContentViewModel.swift:205`, `FeedDetailViewController.swift:66`,`328`,`359`,`465`,`501`, `FeedEditViewModel.swift:175` · V2 (트래킹 없음)
- 🗑 **Delete** — **크로스-스크린 알림 토스트**. V1 피드 탭은 `NotificationName.feedEdited`(작성/수정 완료 → "수정됨" 토스트)와 `"BlockUser"`(유저 차단 → "{닉네임} 차단" 토스트)를 `NotificationCenter`로 받아 처리했다.
  - V2엔 이 알림 배관이 없다.
  - 근거: V1 `FeedViewController.swift:130-143` · V2 (알림 관찰 없음)
- ❓ **Unknown** — **피드 상세 pop 알림**. V1은 `NotificationName.popFeedDetailViewController`를 받아 상세를 스스로 pop했다(예: 차단·삭제 후 외부에서 닫기).
  - V2엔 이 신호가 없다(상세는 자체 back/삭제로만 닫힘).
  - 근거: V1 `FeedDetailViewModel.swift:534-538`, `FeedDetailViewController.swift:135` · V2 (해당 신호 없음)

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

### 내 피드 목록 (`getUserFeed` → `GET /users/{id}/feeds`)

V1 `UserInfoRepository.getUserFeed` → `UserFeedListQuery`. V2 `DefaultFeedRepository.fetchMyFeeds` → `GetUserFeedsQuery`.

| 파라미터 | V1 전송 규칙 | V2 전송 규칙 | 상태 |
|---|---|---|---|
| `lastFeedId` | 커서(첫 페이지 0) | 커서(첫 페이지 `FeedID(0)`) | ✅ Keep |
| `size` | `size ?? 20` | `20` | ✅ Keep |
| `sortCriteria` | `SortType.queryText`(newest/oldest) | `option.sortType.rawValue` | ✅ Keep (값 동일성 확인 권장) |
| `isVisible` | **항상** `visibilityOptions.contains(.public)` (Bool) | `visibilityFlags`(all이면 **nil**) | 🔧 Improve — V1은 all일 때도 두 Bool을 실어 보냄, V2는 all이면 둘 다 생략 |
| `isUnVisible` | **항상** `visibilityOptions.contains(.private)` (Bool) | `visibilityFlags`(all이면 **nil**) | 🔧 Improve (동상) |
| `genreNames` | `genres.map(rawValue)` **항상**(콤마 join, 기본 10개 전부) | `genres.isEmpty ? nil : genres`(빈 배열 = 무필터로 생략) + 미분류면 `"etc"` 추가 | 🔧 Improve — §2.2 |

- 근거: V1 `UserInfoRepository.swift:117-130`, `UserFeedListQuery.swift:19-37` · V2 `DefaultFeedRepository.swift:170-187`, `FeedData/CLAUDE.md`(visibilityFlags·genres.isEmpty=무필터)
- `userId`: V1은 `UserDefaults userId`(내 피드), V2는 `storage.get(.userID)`. ✅ Keep.

### 소소피드 목록 (`getFeedList` → `GET /feeds`)

| 파라미터 | V1 전송 규칙 | V2 전송 규칙 | 상태 |
|---|---|---|---|
| `lastFeedId` | 커서(첫 0) | 커서(첫 0) | ✅ Keep |
| `size` | `size ?? 20` | `pageSize` | ✅ Keep (값 확인 권장) |
| `feedsOption` | `SosoFeedTab.rawValue`(`ALL`/`RECOMMENDED`) | `SosoFeedOption.rawValue`(동일 문자열) | ✅ Keep |

- 근거: V1 `FeedService.swift:19-48`, `FeedTab.swift:22-32` · V2 `DefaultFeedRepository.swift:113-119`, `SosoFeedOption.swift`

### 작성/수정 (`postFeed`/`putFeed` → `POST/PUT /feeds`)

- V1은 `FeedContentRequest`(feedContent/novelId?/isSpoiler/isPublic) + 멀티파트 이미지(`compressImages`). V2는 `SubmitFeedRequest`(content/categories/novelId?/isSpoiler/isPublic) + 이미지 Data.
- 본문 2000자·이미지 5장 상한은 양쪽 동일(§4.2). ✅ Keep. 이미지 압축·멀티파트 조립은 Data 레이어(범위 밖).
- 근거: V1 `FeedService.swift:50-129` · V2 `FeedData/CLAUDE.md`(SubmitFeedRequest·멀티파트)
