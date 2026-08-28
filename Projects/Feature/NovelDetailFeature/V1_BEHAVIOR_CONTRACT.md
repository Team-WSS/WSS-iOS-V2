# NovelDetailFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 작품 상세 화면이
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
- V1 경로 접두사 생략형: `…/NovelDetail/` = `WSSiOS/Source/Presentation/NovelDetail/`(하위 폴더가 깊어 파일명:줄로 인용 — 파일명은 유일).
  Data/Network는 `WSSiOS/Source/Data/…`·`WSSiOS/Network/…` 그대로.
- V2 경로 생략형: `Sources/…` = `Projects/Feature/NovelDetailFeature/Sources/NovelDetail/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/NovelDetailView.swift` (몰입형 헤더 + 탭 컨테이너) | `…/NovelDetail/NovelDetailView/NovelDetailView.swift` + `NovelDetailViewController.swift` + `NovelDetailViewModel/NovelDetailViewModel.swift` | **몰입형 헤더·스티키 탭바·스크롤 반응 타이틀 동일**. RxSwift Input/Output 4구획 → SwiftUI 단일 `@Observable` VM |
| `Sources/NovelDetailHeaderView.swift` (헤더) | `…/NovelDetailHeaderView/**`(NovelInfo·ReviewResult·CoverImage·Dropdown 등) | 표지·장르 코너뱃지·작가 개별 밑줄·카운트 3종 **동일** |
| `Sources/NovelDetailReviewSection.swift` (유저 평가 + CTA) | `NovelDetailHeaderReviewResultView.swift` + `NovelDetailHeaderInterestFeedWriteButton.swift` | 평가 없음=셀렉터 / 있음=칩+상태바 **동일**. 2 참조 |
| `Sources/NovelDetailInfoTab.swift` (정보 탭) | `…/NovelDetailInfoView/**`(Description·Platform·Review·Graph) | 소개 아코디언·플랫폼·감상평 3요소·그래프 **동일**. visibility 2단 판정 **동일**(3) |
| `Sources/NovelDetailFeedTab.swift` (피드 탭) | `…/NovelDetailFeedView/**` + `FeedListView`(공용) | 커서 페이지네이션·좋아요·드롭다운·신고 **동일**. **지연 로드·실패 표현이 갈림**(4) |
| *(없음)* | `firstReviewDescription` 온보딩 오버레이(NovelDetailView.swift·VM) | **V2엔 통째로 없다**(6.4) |

> **작가 검색 결과 화면**(V1 `pushToNormalSearchViewController`)은 V2에서 `onAuthorTapped` 콜백으로 위임하나
> **App 라우팅이 아직 미구현(후속)**이라 이 문서 범위 밖이다(6.2). 평가 화면(NovelReview)·피드 작성/수정·피드 상세·
> 유저 프로필도 전부 콜백 위임이라 목적지 화면 자체는 각 모듈 문서 소관이다.

---

## 0. 점검 대기 요약

**판정 상태(2026-08-28 갱신)** — 모든 항목에 배지가 달려 있고 본문 각 절의 확정 배지와 일치한다. **판정 대기 0건.** 배지: ✅유지 · 🔧개선/고치기/미배선(되살리기·수정은 `docs/TODO.md` 12절에 구현 대기, 미배선은 App 배선 시 해소) · 🔨회귀 수정 · 🗑삭제 · ⏳⏸보류(`docs/PENDING_DECISIONS.md`) · 🆕V2 신규.

1. **재진입 재조회 없음** — V1은 `viewWillAppear`마다 header·info·feed를 **전부 다시 조회**한다(재진입할 때마다 최신 집계 반영). V2는 `hasLoaded` 가드로 **1회만 로드**하고 재진입 시 재조회하지 않는다. 화면 **내부** 변경(평가 삭제·피드 삭제)은 V2가 직접 재로드하나, **다른 화면을 다녀온 뒤**(평가 작성·수정, 피드 수정, 피드 상세에서 좋아요)의 헤더 별점·읽기상태·키워드/그래프 집계 최신화가 사라졌을 수 있다. "1회 로드"는 V2 `CLAUDE.md`에 명문화됐으나 그 **부작용(외부 변경 후 stale)**은 별도 판정. → [1.1](#11-진입재조회생명주기)
   - **🔧 확정(2026-08-28, 사용자): 재진입 재조회 복원 — 종전 'Keep(1회 로드)' 판정을 뒤집음.** ⚠️ **실측 회귀(사용자 보고): 작품을 평가한 뒤 상세로 복귀해도 헤더 별점·집계가 갱신되지 않는다** — parity 복원이 아니라 **관측된 확정 회귀**다. 횡단 push 재조회 결정(알림·타유저 프로필과 함께)에 작품상세 포함. 단 화면이 무거우니(header·info·feed) 전체 재로드 강제가 아니라 **외부 변경 최신화(헤더 집계 등) 목적의 가벼운 갱신**으로 조정. `docs/TODO.md` 9.
2. ✅ **Keep 확정** (2026-08-28: VM Task 슬롯 가드+NavigationStack로 해소, 순수 네비 중복만 App 몫 — 본문 6.1) — **더블탭 가드(throttle) 제거**: V1은 관심·피드작성·평가·셀선택·드롭다운·뒤로가기에 **1초 throttle**을 걸어 중복 발화를 막았다. V2는 Task 슬롯 가드(`isSyncingInterest`/`feedsTask == nil` 등)로 대체하나, **화면 전환 콜백**(`onFeedTapped`/`onReviewTapped`/`onCreateFeedTapped`/`onAuthorTapped`)엔 명시 throttle이 없다 → 중복 push 방지가 App 배선에 있는지 확인 필요. → [6.1](#61-더블탭-가드throttle)
3. 🔧 **미배선(App 배선 대기·삭제 아님)** — **작가 검색 화면 라우팅 미구현**: V1은 헤더 작가 이름 탭 → **작가명으로 검색 결과 화면 push**. V2는 `onAuthorTapped` 콜백만 있고 **App 라우팅이 아직 미구현(후속)**이라 현재 소비처가 Demo 로그뿐(V2 `CLAUDE.md` 명문). 후속 배선 전까지는 탭해도 아무 일도 안 일어난다. → [6.2](#62-작가-검색-진입)
4. 🔧 **재도입 확정→TODO 12절** (2026-08-28, 사용자: 되살린다 — PENDING 5 닫힘) — **첫 감상평 안내 오버레이** — V1은 정보 탭의 감상평을 처음 볼 때 **1회성 온보딩 오버레이**(딤 + 상태바 미리보기 + 말풍선 "당신의 감상이 궁금해요" 류 힌트)를 띄우고, 탭하면 닫으며 `UserDefaults.showReviewFirstDescription`로 다시 안 뜨게 저장했다. **V2엔 이 오버레이가 통째로 없다**(grep 0). → [6.4](#64-첫-감상평-안내-오버레이)
5. 🔧 **횡단 이슈→TODO 12절** (Amplitude 재도입) — **Amplitude 이벤트 트래킹 전부 제거** — V1은 상세 진입·평가·관심·피드작성·플랫폼 이동·좋아요·신고 등 십여 곳에 Amplitude 이벤트를 심었다. **V2엔 없다**(분석 미이식으로 보이나 확인 필요 — Home과 동일 사안). → [6.3](#63-amplitude-트래킹)

**🔧 / 🗑 눈에 띄는 변경 (의도 확인)**

6. 🔧 **Improve 확정** (2026-08-28, 사용자) — **이미지 로드 실패 → 전면 에러 뷰 제거** — V1은 **표지/장르 이미지 로드가 실패하면 화면 전체를 `NetworkErrorView`로 덮었다**(`imageNetworkError`). V2는 표지 실패 시 placeholder(`imgLoadingThumbnail`)로 폴백하고 화면을 실패로 만들지 않는다. → [1.4](#14-로드-실패-표현)
7. 🔧 **Improve 확정** (2026-08-28, 사용자) — **관심 토글 방식** — V1은 관심 토글 후 **header·info·feed를 전부 재조회**(무거운 재로드). V2는 낙관 반영 + 서버 실패 시 롤백(재조회 없음). → [2.2](#22-관심-토글)
8. 🔧 **Improve 확정** (2026-08-28, 사용자) — **피드 지연 로드** — V1은 피드를 `viewWillAppear`마다 **eager**로 받는다. V2는 **피드 탭 첫 진입 시 지연 로드**(V2 `CLAUDE.md` 명문). → [4.1](#41-지연-로드페이지네이션)
9. 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 계약) — **피드 로드 실패 표현 통일** — V1은 실패 경로가 갈렸다(eager 로드 실패=전면 에러 뷰 / 탭탭·페이지네이션 실패=`print`만, 무음). V2는 첫 페이지·더보기를 가리지 않고 **탭 자리를 `NetworkErrorView`+재시도로 대체**(#195). → [4.4](#44-빈-화면실패)
10. 🔧 **복원 확정→TODO 12절** (2026-08-28, 사용자: Feed 8·UserPage 4(USER-018)와 통일 — 화면마다 다르지 않게) — **탈퇴 유저 프로필 탭 토스트** — V1은 피드 프로필 탭 시 `userId == -1`이면 "unknownUser" 토스트를 띄웠다. V2는 `userId`가 없으면 조용히 무시(토스트 없음). → [4.3](#43-피드-셀-상호작용-탭프로필드롭다운신고)
11. 🔧 **복원 확정→App 크로스스크린 피드백 재설계(Feed 15와 묶음, TODO 12절)** (2026-08-28, 사용자) — **피드 수정·평가 완료 토스트** — V1은 `feedEditedNotification`·`novelReviewedNotification`을 관찰해 복귀 시 "수정 완료"·"평가 완료" 토스트를 띄웠다. V2엔 이 알림 관찰자·토스트가 없다. → [6.5](#65-알림-관찰자-토스트)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 로드·생명주기·동시성

원본: `…/NovelDetail/NovelDetailViewModel/NovelDetailViewModel.swift`, `.../NovelDetailViewController/NovelDetailViewController.swift`

### 1.1 진입·재조회·생명주기

- 🔧 **재조회 복원으로 변경** (2026-08-28, 사용자 — 종전 'Keep(1회 로드)' 판정을 뒤집음) — V1은 `viewWillAppear`마다 `reloadData`를 쏴 **header·info·feed 3종을 전부 다시 조회**한다(재진입 시 최신 집계 반영). 최초 1회 가드 없음.
  - **V2: `hasLoaded` 가드로 1회만 로드**하고 재진입(onAppear 재발화) 시 재조회하지 않는다. 화면 **내부** 변경(평가 삭제·피드 삭제)은 `hasLoaded = false` 후 `loadNovel()`로 직접 재동기화하지만, **평가 작성/수정·피드 수정·피드 상세 좋아요처럼 다른 화면을 다녀온 결과**는 재진입해도 반영되지 않을 수 있다(V1은 반영됐다).
  - 근거: V1 `NovelDetailViewController.swift:71-77`(viewWillAppear→event), `NovelDetailViewModel.swift:191-204`(reloadData→get 3종) · V2 `NovelDetailViewModel.swift:219-223`(load, `guard !hasLoaded`), `396-411`·`432-446`(내부 삭제만 재로드), `CLAUDE.md`("LoadNovelUseCase 1회(hasLoaded 가드)")
  - **판정(2026-08-28, 사용자): 재진입 재조회 복원.** ⚠️ **실측 회귀(사용자 보고): 작품 평가 후 상세로 복귀하면 헤더 별점·집계가 갱신되지 않는다** — "1회 로드"의 부작용이 실제로 드러난 확정 회귀다. 횡단 push 재조회 결정(알림·타유저 프로필과 함께)에 작품상세 포함 — 외부 변경(평가·피드 수정 후 복귀) 최신화를 되살린다. 무거운 화면이라 전체 재로드보다 **헤더 집계 등 외부 변경분 위주의 가벼운 갱신**으로 조정 권장. `docs/TODO.md` 9. (종전 'Keep(1회 로드)' 판정을 뒤집은 것 — `CLAUDE.md`의 "1회 로드" 명문은 구현 시 함께 갱신.)
- ✅ **Keep** — 뒤로가기 = 이전 화면으로 pop(back 버튼). 몰입형 헤더라 시스템 네비바를 숨기고 커스텀 back 버튼 + 스와이프 뒤로가기를 함께 쓴다.
  - V2: `.requestClose` → `shouldDismiss` → `dismiss()`. 커스텀 네비바 + `.enableSwipeBack()`(네비바 숨기면 스와이프백이 꺼져 되살린다 — 두 레포 공통 함정). V1도 `swipeBackGesture()`를 viewWillAppear에서 걸었다.
  - 근거: V1 `NovelDetailViewController.swift:76`(swipeBackGesture),`493-499`(back 1s throttle→pop) · V2 `NovelDetailView.swift:100-102`,`285-296`, `CLAUDE.md`(몰입형 헤더=시스템 네비바 숨김/enableSwipeBack)

### 1.2 로드 구조 (header / info / feed)

- 🔧 **Improve** — **로드 단위**. V1은 상세를 **3개의 독립 API**(header `/novels/{id}`, info `/novels/{id}/info`, feed `/novels/{id}/feeds`)로 나눠 각각 구독하고, header 도착 시 로딩 뷰를 내렸다. V2는 header+info를 **`LoadNovelUseCase` 1건**(`NovelInformation`)으로 합치고 피드만 별도 지연 로드로 남겼다.
  - V2: 화면 상단 로딩은 `information == nil && isLoading`, 실패는 `information == nil && !isLoading`으로 갈린다(단일 상태).
  - 근거: V1 `NovelDetailViewModel.swift:563-593`(header·info 각각), `Data/Repository/NovelDetailRepository.swift:33-39` · V2 `NovelDetailViewModel.swift:346-364`, `CLAUDE.md`(LoadNovelUseCase 1회)
- ✅ **Keep** — header 도착 전엔 상단 로딩(스피너), 도착하면 콘텐츠로 교체. V1은 `showLoadingView(false)`를 header 콜백에서, V2는 `isLoading`이 `information` 도착 시 내려간다.
  - 근거: V1 `NovelDetailViewController.swift:121-132`(header→showLoadingView false) · V2 `NovelDetailView.swift:137-145`(information/isLoading 분기), `NovelDetailViewModel.swift:34-36`(isLoading 초기 true 이유)

### 1.3 인증 만료 처리

- 🔧 **Improve** — V1 상세 VM엔 **화면 단위 인증 만료 분기가 없다**. 각 API 실패를 `showNetworkErrorView`로만 처리하고, 토큰 재발급은 `tokenCheckURLSession` 네트워크 계층이 담당한다.
  - V2: 어느 서버 호출에서든 `authenticationRequired`를 감지하면 개별 실패 뷰/토스트 대신 `requiresAuthentication` 신호를 세우고 `onAuthenticationRequired` 콜백으로 로그인 라우팅에 일원화한다(`routeToLoginIfAuthenticationRequired`가 모든 catch 공통 경로). **push 후 dismiss돼 VM이 사라지므로 신호 소진은 불필요**(서재·홈과 다른 점).
  - 근거: V1 `NovelDetailViewModel.swift:574-576`,`588-590`(실패→에러뷰) · V2 `NovelDetailViewModel.swift:496-503`, `NovelDetailView.swift:126-128`, `Feature/CLAUDE.md`(인증 만료 처리 계약)

### 1.4 로드 실패 표현

- 🔧 **Improve 확정** (2026-08-28, 사용자) — **이미지 로드 실패가 화면을 죽이지 않는다.** V1은 표지·장르 이미지를 Kingfisher `zip`으로 받다 **둘 중 하나라도 실패하면 `imageNetworkError=true` → 화면 전체를 `NetworkErrorView`로 덮었다**(데이터는 정상인데 이미지만 실패해도 상세가 통째로 에러).
  - V2: 표지 실패 시 `imgLoadingThumbnail` placeholder로 폴백하고 화면을 실패로 만들지 않는다(장르 마크는 도메인 값이라 이미지 실패와 무관).
  - 근거: V1 `NovelDetailViewController.swift:573-586`(makeUIImage→imageNetworkError),`206-208`(→showNetworkErrorView) · V2 `NovelDetailHeaderView.swift:91-101`(AsyncImage else placeholder)
- ✅ **Keep** — header/info **데이터** 로드 실패 시 화면 전체를 실패 뷰 + 재시도로 대체(재시도 = 다시 로드).
  - V2: `information == nil && !isLoading` → `NetworkErrorView { .load }`. 재시도는 `hasLoaded`를 소진 안 해 다시 시도가 열려 있다.
  - 근거: V1 `NovelDetailViewModel.swift:574-576`,`588-590` + `NovelDetailViewController.swift:143-147`,`210-214`(refresh→reloadData) · V2 `NovelDetailView.swift:142-145`, `NovelDetailViewModel.swift:218`(실패는 가드 미소진)

---

## 2. 헤더 (작품 정보 · 관심 · 평가 상태바 · 표지)

원본: `…/NovelDetailHeaderView/**`

### 2.1 작품 정보 (제목·메타·카운트·작가)

- ✅ **Keep** — 제목(최대 3줄 말줄임) + 메타 줄(`장르  ·  연재상태  ·  작가`) + 카운트 3종(관심수·별점(횟수)·피드수). **작가만 개별 밑줄 버튼**(다작가면 이름별 버튼, 구분자 `, `는 비탭)이고 탭 시 작가 검색으로.
  - V2: `metaRow`가 앞부분(장르·연재상태)은 한 `Text`, 작가는 이름마다 `Button`, 구분자는 비탭 `Text`로 분해 — V1의 `authorStackView`(라벨별 tap gesture)와 같은 결. 작가 목적지는 6.2.
  - 근거: V1 `NovelDetailHeaderNovelInfoView.swift:125-186`(메타·카운트·작가별 라벨) · V2 `NovelDetailHeaderView.swift:133-223`, `CLAUDE.md`(작가만 개별 밑줄 버튼)
- ✅ **Keep** — 연재상태 표기 `완결작`/`연재작`(V1 `isNovelCompleted`), 별점 `%.1f (횟수)`, 장르 나열은 `/` 구분.
  - 근거: V1 `NovelDetailHeaderNovelInfoView.swift:126-134` · V2 `NovelDetailHeaderView.swift:185-207`

### 2.2 관심 토글

- 🔧 **Improve 확정** (2026-08-28, 사용자) — V1은 관심 버튼 탭(1s throttle) → 서버 POST/DELETE 성공 후 로컬 플래그를 뒤집고 **곧바로 `reloadData`로 header·info·feed 전체를 재조회**했다(하트 하나 바꾸자고 피드까지 1페이지로 리셋되는 무거운 경로).
  - V2: 엔티티 `Novel.toggleInterest()` 정책 위임 + **낙관 반영 → 서버 실패 시 롤백**(재조회 없음). `isInterested == nil`(비로그인 등)이면 엔티티가 no-op이라 서버 호출도 스킵.
  - 근거: V1 `NovelDetailViewModel.swift:289-307`(throttle→서버→reloadData) · V2 `NovelDetailViewModel.swift:240-250`,`466-479`, `CLAUDE.md`(관심 토글 낙관/롤백)
- ✅ **Keep** — 관심 on/off 시 하트 에셋·배경색 전환. V2는 짧은 명시 애니메이션(0.1s)로 기본 크로스페이드가 느리게 번지는 걸 막는다(수단 보강, 관찰 동작 동일).
  - 근거: V1 `NovelDetailViewController.swift:199-203`(updateInterestButtonState) · V2 `NovelDetailReviewSection.swift:203-230`

### 2.3 유저 평가 상태바 / 셀렉터

- ✅ **Keep** — 평가 **없음** = 읽기상태 3분할 셀렉터(각 상태가 개별 진입점, 탭한 상태를 평가 초안 seed로). 평가 **있음** = 별점·기간 칩 + 상태바(현재 상태 강조). 상태바의 상태 탭은 그 상태로, 그 외(칩·여백) 탭은 현재 상태로 진입.
  - V2: `NovelDetailReviewSection`이 `userReview` 유무로 갈리고, 상태 `Button`이 hit-test 우선이라 바깥 `onTapGesture`(현재 상태 진입)와 공존. V1은 `reviewResultButtonDidTap`에서 `$0 ?? readStatus.value`로 같은 seed 규칙(탭 값 없으면 현재 상태).
  - 근거: V1 `NovelDetailViewModel.swift:270-281`(seed=탭값 ?? 현재), `NovelDetailHeaderReviewResultView.swift:118-149` · V2 `NovelDetailReviewSection.swift:41-93`, `NovelDetailView.swift:184-190`, `CLAUDE.md`(onReviewTapped seed 규칙)
- ✅ **Keep** — 별점/기간 칩은 **값이 있을 때만** 표시(둘 다 없으면 상태바만). 기간 표기는 시작·종료 존재로 갈림(하차=`~ 종료`, 보는중=`시작 ~`).
  - V2: `reviewChips`가 `rating`/`period`를 옵셔널로 각각 렌더, `periodText`가 start/end 존재로만 결정(도메인 `ReadingPeriod.normalized`가 상태별 날짜를 이미 강제). V1의 `bindVisibility(isUserNovelRatingExist, isReadDateExist)` 4분기와 같은 결과.
  - 근거: V1 `NovelDetailHeaderReviewResultView.swift:118-149`(visibility·readDateText) · V2 `NovelDetailReviewSection.swift:97-152`, `CLAUDE.md`(기간은 상태별 날짜)
- ✅ **Keep** — "나도 한마디"(피드 작성) CTA + 관심 버튼이 한 줄. 피드 작성 진입은 헤더 CTA와 피드 탭 플로팅 버튼이 공유하고, 진입 시 피드 탭으로 전환.
  - V2: `onCreateFeedTapped` 공용. 단 **V1은 피드 작성 버튼 탭 시 `selectedTab=.feed`로 전환**했는데, V2는 콜백만 발화(전환은 App). 관찰상 목적지가 피드 작성 화면이라 탭 전환 여부는 복귀 후에나 보인다 — 미세 차이.
  - 근거: V1 `NovelDetailViewModel.swift:309-335`(feedWrite/createFeed→피드탭 전환) · V2 `NovelDetailReviewSection.swift:236-256`, `NovelDetailView.swift:492-514`

### 2.4 표지 대형 오버레이

- ✅ **Keep** — 표지 탭 → 대형 표지 오버레이(dim + 원본 비율 확대). X 버튼 또는 표지 **바깥** 탭으로 닫고, 표지 자체 탭은 no-op.
  - V2: dim의 `onTapGesture`와 확대 표지를 ZStack 형제로 둬 표지 위 탭이 자연히 무시됨(V1의 표지 탭 no-op과 동일). V1은 오버레이 표시 시 시스템 네비바를 숨겼다(V2는 몰입형이라 애초에 숨김).
  - 근거: V1 `NovelDetailViewModel.swift:252-268`, `NovelDetailViewController.swift:568-571`(네비바 숨김) · V2 `NovelDetailView.swift:400-449`, `CLAUDE.md`(대형 표지 오버레이)

---

## 3. 정보 탭 (소개 · 플랫폼 · 독자 감상평 · 그래프)

원본: `…/NovelDetailInfoView/**`

### 3.1 작품 소개 (아코디언)

- ✅ **Keep** — 소개는 기본 **3줄 접힘 + 펼침 버튼(chevron)**. 텍스트가 3줄 이하면 펼침 버튼을 숨긴다.
  - V2: `lineLimit(isDescriptionExpanded ? nil : 3)` + `expandButton`(chevron 회전). V1은 3줄 높이 실측으로 버튼 숨김(`isAccordionButtonHidden`) — V2는 자연 판정(3줄 이하면 chevron이 있어도 no-op이나 시각 차이는 미미). **V2는 짧은 소개에도 chevron이 남을 수 있음**(경미).
  - 근거: V1 `NovelDetailInfoDescriptionView.swift:102-120`(3줄 실측→버튼 숨김), `NovelDetailViewModel.swift:368-372`(아코디언 토글) · V2 `NovelDetailInfoTab.swift:44-74`

### 3.2 플랫폼 (작품 보러가기)

- ✅ **Keep** — 플랫폼 아이콘 나열, 탭 → 외부 브라우저로 해당 플랫폼 URL 오픈. 플랫폼이 없으면 섹션 통째 숨김.
  - V2: `platformSection`을 `!platforms.isEmpty`로 가드, 아이콘 탭 → `openURL(platform.url)`. V1은 플랫폼 탭 시 Amplitude `directNovel` 트래킹(6.3).
  - 근거: V1 `NovelDetailViewController.swift:259-275`(itemSelected→open URL + 트래킹), `NovelDetailInfoPlatformView` · V2 `NovelDetailInfoTab.swift:29-113`

### 3.3 독자 감상평 3요소 + 그래프 (visibility 2단 판정)

- ✅ **Keep** — 감상평 영역은 **매력포인트 · 키워드 · 읽기상태 그래프** 3요소. 각 요소는 값이 없으면 그 부분만 숨기고, **셋 다 없으면 빈 상태**("아직 평가가 없어요")로 제목까지 "독자들의 평가"로 바꾼다.
  - V2: `hasAnyReviewSummary`(= 매력포인트/키워드 있음 or 그래프 있음)로 빈 상태를 가른다. V1은 `visibilities`(graph/attractivepoint/keyword) 배열이 비면 `reviewEmptyView`를 띄우는데, graph는 총 읽기수>0일 때만 추가돼 **셋 다 없음 == 배열 빔**으로 동일.
  - 근거: V1 `Data/Entity/NovelDetail/NovelDetailInfoEntity.swift:44-64`(visibilities 계산), `NovelDetailInfoView.swift:76-85`(빈 상태 분기) · V2 `NovelDetailInfoTab.swift:117-163`, `CLAUDE.md`("독자들의 평가" 빈 상태)
- ✅ **Keep (미묘한 2단 판정)** — **"독자들의 감상평" 제목의 소속은 매력포인트·키워드뿐**이라, **그래프만 있고 매력포인트·키워드가 다 비면 제목까지 감춘다**. 그래프 위 구분선도 위에 감상평이 실제로 있을 때만 그린다.
  - V2: `hasReviewContent`(매력포인트 or 키워드)로 제목·구분선을 가르고, 그래프는 별도로 `dominantReadStatus`로 표시. **V1과 완전히 같은 2단 판정**: V1 `titleLabel.isHidden = !attractive && !keyword`, `dividerView.isHidden = !((attractive || keyword) && graph)`.
  - 근거: V1 `NovelDetailInfoReviewView.swift:112-128`(title/divider 판정) · V2 `NovelDetailInfoTab.swift:117-153`, `CLAUDE.md`(감상평 제목 소속·2단 판정)
- ✅ **Keep** — 매력포인트 문구 `"{나열}(이)가 매력적인 작품이에요"`(나열만 포인트 컬러), 키워드는 `키워드 횟수` 칩 가로 스크롤(표시 전용).
  - 근거: V1 `NovelDetailInfoReviewAttractivePointView`, `NovelDetailInfoReviewKeywordView` + `NovelDetailViewModel.swift:657-662`(키워드 라벨 `이름 횟수`) · V2 `NovelDetailInfoTab.swift:166-194`
- ✅ **Keep** — 읽기상태 그래프: 우세 상태 강조 + `"{n}명이 작품을 {우세상태 문구}"` 타이틀(인원수만 포인트 컬러). **동률 시 우선순위 watching → watched → quit.**
  - V2: `dominantReadStatus`(도메인)가 우세·동률을 결정하며 **tie 순서가 V1 switch(watching→watched→quit)와 일치**. 막대는 우세 상태만 포인트 컬러.
  - 근거: V1 `NovelDetailInfoReviewGraphStackView.swift:69-93`, `NovelDetailInfoEntity.swift:30-42`(topReadStatus switch 순서) · V2 `NovelDetailInfoTab.swift:200-257`, `NovelDomain/…/NovelInformation.swift:54-67`(dominantReadingStatusOrder), `CLAUDE.md`(dominantReadStatus가 우세·동률 결정)

---

## 4. 피드 탭

원본: `…/NovelDetailFeedView/**`, `…/NovelDetailViewModel.swift`(feed 구획)

### 4.1 지연 로드·페이지네이션

- 🔧 **Improve 확정** (2026-08-28, 사용자) — **피드 지연 로드**. V1은 피드를 `viewWillAppear`마다 **eager**로 받고(첫 진입에 정보 탭을 봐도 피드가 이미 로드됨), 추가로 피드 탭 탭 시에도 다시 받는다. V2는 **피드 탭 첫 진입 시에만** 로드(`selectTab(.feed)` + `!hasLoadedFirstFeeds`).
  - 근거: V1 `NovelDetailViewModel.swift:200-202`(reloadData→feed),`343-364`(탭탭→feed) · V2 `NovelDetailViewModel.swift:226-236`, `CLAUDE.md`(피드 탭 첫 진입 시 지연 로드)
- ✅ **Keep** — **커서 페이지네이션**: 첫 페이지 `lastFeedId=0`, 이후 마지막 피드 ID를 커서로 다음 페이지 append. 서버 `isLoadable`(= 더 있음)일 때만 다음 요청, 진행 중 중복 요청 가드.
  - V2: `loadFeeds(after: lastFeedID ?? FeedID(0))`, `hasNextFeeds`(= 서버 hasNext)와 `feedsTask == nil` 가드. V1의 `isLoadable && !isFetching`과 같은 결. 첫 페이지 커서 0 규약 동일.
  - 근거: V1 `NovelDetailViewModel.swift:55`(lastFeedId 0),`479-504`(scrollReachedBottom→isFetching/isLoadable) · V2 `NovelDetailViewModel.swift:252-260`,`366-393`
- ✅ **Keep** — 무한 스크롤(하단 도달 시 다음 페이지). V1은 스크롤 오프셋 임계값(`offsetY + viewHeight >= contentHeight`), V2는 마지막 셀 `onAppear`(수단 변경).
  - 근거: V1 `NovelDetailViewController.swift:588-598`(observeReachedBottom) · V2 `NovelDetailFeedTab.swift:81-86`
- 🗑 **Delete** — V1 재진입 eager 로드는 **이미 본 개수만큼 over-fetch**(`size = feedList.count`)해 목록을 다시 채웠다(서재의 재진입 갱신과 유사).
  - V2: 재진입 재조회 자체가 없어(1.1) 이 경로가 사라졌다. 피드 목록은 화면 수명 동안 유지된다.
  - 근거: V1 `NovelDetailViewModel.swift:595-612`(size=count over-fetch) · V2 `NovelDetailViewModel.swift`(재진입 재로드 없음)

### 4.2 좋아요

- ✅ **Keep** — 좋아요 탭 → **낙관 반영(카운트 ±1·햅틱) + 서버 실패 시 롤백**. 셀별 독립(다른 셀 병행 허용).
  - V2: 엔티티 `TotalFeed.toggleLike()` 정책 위임 + 낙관/롤백, `syncingLikeFeedIDs`로 같은 셀 연타만 가드. V1도 즉시 반영 후 실패 시 rollback. V1은 좋아요 성공 시 Amplitude `feedLike`(6.3).
  - 근거: V1 `NovelDetailViewModel.swift:419-456`(UI 반영→서버→롤백) · V2 `NovelDetailViewModel.swift:277-289`,`415-430`, `CLAUDE.md`(좋아요 낙관/롤백)

### 4.3 피드 셀 상호작용 (탭·프로필·드롭다운·신고)

- ✅ **Keep** — 셀 탭 → 피드 상세. 프로필(이미지+닉네임) 탭 → 유저 프로필(**내 글이면 차단**). threedots → 셀 드롭다운(**내 글: 수정/삭제, 남의 글: 신고 2종 빨강**). 연결 작품 배너 탭 → 그 작품 상세.
  - V2: `onFeedTapped`/`onUserProfileTapped`(`!isMyFeed` 가드)/`onNovelTapped`, threedots 드롭다운은 화면 오버레이(앵커 셀 y 실측). V1의 드롭다운은 셀 인라인이지만 항목 구성(수정/삭제 vs 신고 2종)은 동일.
  - 근거: V1 `NovelDetailViewModel.swift:381-417`(itemSelected/dropdown/신고분기), `NovelDetailViewController.swift:620-636`(delegate) · V2 `NovelDetailFeedTab.swift:100-140`, `NovelDetailView.swift:581-613`, `CLAUDE.md`(피드 셀 인터랙션)
- ✅ **Keep** — 신고(스포일러/부적절)는 **확인 알럿 → API → 접수 완료 알럿**의 2단. 삭제는 확인 알럿 → API → 목록 제거.
  - V2: `FeedAlert` 의미값으로 관리(신고는 완료 케이스 분리 — 문구가 종류별로 다름). 삭제 성공 시 목록 제거 + **상세 재로드**(헤더 피드 수 집계 동기화). V1은 삭제 후 `reloadNovelDetailFeed`(피드만 리셋)로 목록만 갱신 — **V2는 집계까지 재동기화**하는 차이(경미한 Improve).
  - 근거: V1 `NovelDetailViewController.swift:353-453`(신고/삭제 2단 알럿), `NovelDetailViewModel.swift:458-477` · V2 `NovelDetailViewModel.swift:291-312`,`433-463`, `NovelDetailView.swift:615-644`, `CLAUDE.md`(피드 삭제/신고 2단 알럿)
- 🔧 **복원 확정→TODO 12절** (2026-08-28, 사용자: Feed·UserPage 결정과 통일) — V1은 프로필 탭 시 **`userId == -1`(탈퇴 유저)이면 "unknownUser" 토스트**를 띄웠다.
  - V2: `feed.author.userId`가 없으면(응답 미제공) 조용히 무시(토스트 없음). 탈퇴 유저 안내가 사라졌다.
  - 근거: V1 `NovelDetailViewModel.swift:514-522`(userId==-1→토스트) · V2 `NovelDetailFeedTab.swift:108-112`(userId nil→return)
  - ⚠️ **복원 시 함정**: V2 `FeedMapper.author`는 `userId`를 non-optional `UserID`로 넘기므로 서버가 탈퇴 유저를 `-1`로 주면 **nil 가드에 안 걸리고 `UserID(-1)`로 유저 페이지 push → USER-018**. `-1` 판별을 매퍼(→ nil)에서 할지, 유저 페이지의 USER-018 폴백(UserPage 4.7 복원)에 맡길지 구현 시 결정.
- ✅ **Keep** — 스포일러 피드는 본문 대신 "스포일러가 포함된 글" 대체 표기(공용 피드 셀이 처리).
  - V2: `WSSFeadView(isSpoiler:)`. V1도 공용 `FeedListTableViewCell`이 처리.
  - 근거: V1 `NovelDetailViewController.swift:293-300`(FeedListTableViewCell) · V2 `NovelDetailFeedTab.swift:137`

### 4.4 빈 화면·실패

- ✅ **Keep** — 피드 0건이면 빈 상태("아직 글이 없어요\n최초로 남겨보세요!").
  - V2: `feeds.isEmpty && !isLoading` → `NovelDetailEmptyView`. V1은 `bindData(isEmpty:)`로 emptyView 교체.
  - 근거: V1 `NovelDetailFeedView.swift:58-66`, `NovelDetailFeedEmptyView.swift` · V2 `NovelDetailFeedTab.swift:52-63`
- 🔧 **Improve 확정** (2026-08-28, 사용자 — #195 로드 실패 표현 계약) — **피드 로드 실패 표현 통일**. V1은 경로가 갈렸다: eager(viewWillAppear) 피드 로드 실패는 **화면 전체 `NetworkErrorView`**, 탭탭·페이지네이션·삭제후 리로드 실패는 **`print`만(무음, 재시도 수단 없음)**. V2는 **첫 페이지·더보기를 가리지 않고 탭 자리를 `NetworkErrorView`+재시도로 대체**(#195).
  - V2: `feedsLoadFailed`를 실패보다 **먼저** 판단(목록이 남아도 걷어내고 실패 뷰). 재시도는 첫 페이지부터 다시 세운다.
  - 근거: V1 `NovelDetailViewModel.swift:607-609`(eager 실패→에러뷰),`361-363`,`474-476`,`501-503`(탭탭/리로드/스크롤 실패→print) · V2 `NovelDetailViewModel.swift:382-392`, `NovelDetailFeedTab.swift:46-51`, `Feature/CLAUDE.md`(로드 실패 표현 계약), `CLAUDE.md`(피드 실패 규칙)

---

## 5. 화면 드롭다운 (오류 제보 · 평가 삭제)

원본: `NovelDetailHeaderDropdownView.swift`, `NovelDetailViewModel.swift`(Total 구획)

- ✅ **Keep** — 헤더 threedots(더보기) → 드롭다운(오류 제보 / 평가 삭제). 바깥 탭으로 닫힘.
  - V2: `menuOverlay`(오류 제보 / 평가 삭제), 투명 레이어 탭으로 닫힘. V1은 `showHeaderDropdownView` 토글 + `backgroundDidTap`으로 닫힘.
  - 근거: V1 `NovelDetailViewModel.swift:216-242`(dots 토글/드롭다운 분기), `NovelDetailViewController.swift:214-227` · V2 `NovelDetailView.swift:349-371`
- ✅ **Keep** — "오류 제보" → 외부 브라우저로 문의 페이지 오픈.
  - V2: `AppURL.errorReport`(#165에서 화면 전용 상수 → 앱 전역 카탈로그로 이관). V1은 `ExternalLinks.inquiry`. 목적지 동일.
  - 근거: V1 `NovelDetailViewController.swift:220-227`(ExternalLinks.inquiry) · V2 `NovelDetailView.swift:356-360`, `CLAUDE.md`(오류 제보 외부 브라우저)
- ✅ **Keep** — "평가 삭제" → 확인 알럿 → `DELETE /user-novels/{id}` → **성공 토스트 + 상세 재로드**(키워드·읽기상태 집계 동기화). 삭제할 평가가 없으면 무시.
  - V2: `DeleteNovelReviewUseCase` → `.reviewDeleted` 토스트 + `hasLoaded=false` 후 `loadNovel()`. `information?.userReview == nil`이면 알럿 없이 무시(관심 no-op과 같은 정책). V1도 삭제 후 `reloadData` + `showReviewDeletedToast`.
  - 근거: V1 `NovelDetailViewModel.swift:231-248`(드롭다운→삭제 알럿),`644-653`(deleteReview→reload+toast) · V2 `NovelDetailViewModel.swift:316-327`,`398-411`, `CLAUDE.md`(평가 삭제→상세 재로드)

---

## 6. 상호작용·네비게이션·부수 작업

### 6.1 더블탭 가드(throttle)

- ✅ **Keep** (확정 2026-08-28: VM loadTask 가드+NavigationStack로 해소) — V1은 중복 발화를 막으려 곳곳에 **1초 throttle**을 걸었다: 관심 버튼, 피드작성/플로팅 버튼, 평가 결과 버튼, 피드 셀 선택, 피드 드롭다운, 뒤로가기.
  - V2: Task 슬롯 가드(`isSyncingInterest`·`feedsTask == nil`·`feedActionTask == nil`·`isClosing`)로 **서버 호출류의 중복은 막지만**, **순수 화면 전환 콜백**(`onFeedTapped`/`onReviewTapped`/`onCreateFeedTapped`/`onAuthorTapped`)엔 명시 throttle이 없다 → 빠른 더블탭 시 중복 push 방지는 App 배선에 달림.
  - 근거: V1 `NovelDetailViewModel.swift:280`,`290`,`310`,`320`,`382`,`407`, `NovelDetailViewController.swift:494` · V2 `NovelDetailViewModel.swift:241`,`254`,`293`,`301`(Task 가드), `NovelDetailView.swift`(전환 콜백 직접 발화)
  - **판정 근거**: 서버 호출류는 VM Task 슬롯 가드, 화면 전환 중복은 `NavigationStack`이 막는다(서재·홈도 같은 결론으로 확정). 순수 네비 콜백의 중복 push 방지는 App 배선 몫.

### 6.2 작가 검색 진입

- 🔧 **미배선 확정→App 배선 대기** (2026-08-28: 삭제 아님) — V1은 헤더 작가 이름 탭 → **그 작가명으로 검색 결과 화면을 push**(`pushToNormalSearchViewController(searchText: authorName)`).
  - V2: `onAuthorTapped(작가명)` 콜백만 있고 **작가 검색 화면의 Feature·App 라우팅이 아직 미구현(후속)**이라, 현재 소비처는 Demo 로그뿐이다(V2 `CLAUDE.md` 명문). 즉 지금은 탭해도 화면이 안 열린다.
  - 근거: V1 `NovelDetailViewController.swift:229-234`(push search), `NovelDetailViewModel.swift:283-287` · V2 `NovelDetailFeatureFactory.swift:30-31`, `CLAUDE.md`("작가 검색 화면 Feature·App 라우팅은 아직 미구현(후속)")
  - **결정(배선 대기)**: 삭제 아님 — 후속으로 작가 검색 라우팅을 App에 배선(목적지는 V1과 같은 검색 결과 화면).

### 6.3 Amplitude 트래킹

- 🔧 **횡단 이슈→TODO** (2026-08-28: 애널리틱스 별도 이슈) — V1은 상세 화면 곳곳에 Amplitude 이벤트를 심었다: 오류 제보(`contactError`)·평가 삭제(`rateDelete`)·평가 진입(`rate`)·관심(`rateLove`)·피드작성 버튼/플로팅(`novelWriteButton`/`novelWriteFloatingButton`)·정보/피드 탭(`novelInfo`/`novelFeed`)·좋아요(`feedLike`)·신고(`alertFeedSpoiler`/`alertFeedAbuse`)·플랫폼 이동(`directNovel`).
  - **V2엔 트래킹 코드가 없다**(분석 미이식으로 보이나 확인 필요 — Home 문서와 동일 사안).
  - 근거: V1 `NovelDetailViewModel.swift:235`,`238`,`272`,`292`,`312`,`322`, `NovelDetailViewController.swift:244-247`,`270`,`365`,`400` · V2 `NovelDetailViewModel`(트래킹 없음)

### 6.4 첫 감상평 안내 오버레이

- 🔧 **재도입 확정→TODO 12절** (2026-08-28, 사용자: 되살린다 — PENDING_DECISIONS 5 닫힘) — V1은 감상평을 처음 볼 때 **1회성 온보딩 오버레이**를 띄웠다: 딤(`wssBlack60`) + 상태바 미리보기(`NovelDetailHeaderReviewResultView` 비활성 복제) + 말풍선 힌트 라벨. 오버레이(또는 배경)를 탭하면 닫히고 `UserDefaults.showReviewFirstDescription = true`로 저장해 **다시 뜨지 않는다**. viewWillAppear마다 저장값을 읽어 표시 여부를 정했다.
  - **V2엔 이 오버레이가 통째로 없다**(grep 0 — `firstReview`/`speechBalloon`/`showReviewFirst` 흔적 없음).
  - 근거: V1 `NovelDetailViewModel.swift:183-189`,`197-199`(hideFirstReviewDescription·UserDefaults), `NovelDetailView.swift:26-29`,`269-274`(오버레이 뷰) · V2 `Sources/**`(해당 코드 없음)
  - **판정 근거**: 사용자 확정(2026-08-28) — 되살린다. 디자인 시안은 구현 시 V1 오버레이 구성(딤·상태바 미리보기·말풍선)을 재료로 요청.

### 6.5 알림 관찰자 토스트

- 🔧 **복원 확정→App 크로스스크린 피드백 재설계(TODO 12절)** (2026-08-28, 사용자: 재진입 재조회 복원과 별개로 완료 피드백은 유지 — Feed 15·UserPage 차단 토스트와 한 묶음) — V1은 `NotificationCenter`로 **피드 수정 완료**(`feedEdited`)·**평가 완료**(`NovelReviewed`)를 관찰해 복귀 시 각각 토스트("수정 완료"·"평가 완료")를 띄웠다.
  - V2엔 이 알림 관찰자·토스트가 없다(피드 수정/평가는 콜백으로 위임, 복귀 후 토스트 없음).
  - 근거: V1 `NovelDetailViewModel.swift:506-512`, `NovelDetailViewController.swift:455-459`,`470-474`,`561-562` · V2 `NovelDetailView`(해당 관찰자 없음)

### 6.6 스티키 탭바·스크롤 트릭 (구현 수단 — 관찰 동작 동일)

- ✅ **Keep** — 스크롤 시 탭바(정보/피드)가 커스텀 네비바 하단에 닿으면 그 아래에 고정, 조금이라도 스크롤되면 네비바에 작품 제목 페이드인, 최상단 over-scroll만 제거(하단 bounce 유지).
  - V2: 오버레이 2벌 스티키 탭바 + `GeometryReader` 오프셋 측정 + `TopBounceDisabler`(KVO 클램프). V1은 `scrollViewDidScroll` 클램프 + `contentOffset` 관찰 스티키. **관찰 동작 동일, 수단만 UIKit→SwiftUI**.
  - 근거: V1 `NovelDetailViewController.swift:484-491`(sticky),`612-618`(top clamp) · V2 `NovelDetailView.swift:459-489`,`652-693`, `CLAUDE.md`(스티키 탭바·TopBounceDisabler)

---

## 부록 A. 서버 요청 (C2 비교 재료)

V1 상세는 **작품 ID 경로 기반 GET/POST/DELETE** 묶음이다(accessTokenHeader). V2도 같은 엔드포인트를 쓴다(대부분 ✅ Keep).

| 용도 | V1 엔드포인트 | V1 파라미터 | V2 대응 | 상태 |
|---|---|---|---|---|
| 헤더(제목·카운트·관심·읽기상태) | `GET /novels/{id}` | 없음 | `LoadNovelUseCase`(header+info 합침) | ✅ Keep (1.2) |
| 정보(소개·플랫폼·감상평·그래프) | `GET /novels/{id}/info` | 없음 | 〃 | ✅ Keep |
| 피드 목록 | `GET /novels/{id}/feeds` | `lastFeedId`, `size` | `LoadNovelFeedsUseCase(novelID:lastFeedID:)` | ✅ Keep (커서 동일) |
| 관심 등록 | `POST /novels/{id}/is-interest` | 없음 | `NovelInterestUseCase.add(id:)` | ✅ Keep |
| 관심 해제 | `DELETE /novels/{id}/is-interest` | 없음 | `NovelInterestUseCase.remove(id:)` | ✅ Keep |
| 평가 삭제 | `DELETE /user-novels/{id}` | 없음 | `DeleteNovelReviewUseCase.execute(novelID:)` | ✅ Keep |
| 좋아요/신고/피드삭제 | (FeedDetail·Social 계열) | — | `FeedLikeUseCase`·`Report*FeedUseCase`·`DeleteFeedUseCase` | ✅ Keep |

- 근거: V1 `WSSiOS/Resource/Constants/URLs/URLs.swift:56-72`, `WSSiOS/Network/NovelDetail/NovelDetailService.swift:75-132` · V2 `NovelDetailViewModel.swift:346-463`, `NovelDetailFeatureFactory.swift:35-53`
- **피드 페이지 크기**: V1 첫 페이지 size **20**(`DefaultNovelDetailRepository.novelDetailFeedSize`), 재진입 over-fetch 시 `count`. V2는 커서 기반이며 페이지 크기가 **Data 레이어 소유**(NovelDetailFeature `CLAUDE.md`의 Demo Mock은 10 기준) — **실서버 페이지 크기 20→? 확정은 별도 확인**. → 부록 후보(경미).
  - 근거: V1 `Data/Repository/NovelDetailRepository.swift:25`,`42`(size 20) · V2 `NovelDetailFeature/CLAUDE.md`(Demo "페이지 크기 10")
- **첫 페이지 커서 규약**: V1 `lastFeedId = 0`, V2 `lastFeedID ?? FeedID(0)` — 동일. ✅ Keep.
