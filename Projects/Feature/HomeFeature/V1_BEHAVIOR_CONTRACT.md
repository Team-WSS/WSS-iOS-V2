# HomeFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 홈 화면이
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
- V1 경로 접두사 생략형: `…/Home/` = `WSSiOS/Source/Presentation/Home/Home/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/Home/HomeView.swift` (탭 콘텐츠) | `…/Home/HomeView/HomeView.swift` + `HomeViewController.swift` + `HomeViewModel/HomeViewModel.swift` | **헤더만 고정, 그 아래 스크롤**은 동일. RxSwift 다중 스트림 → 단일 `async let` 로드 |
| `HomeSearchSection` (검색바+상세검색 배너) | `SearchBarView` + `HomeInduceDetailSearchView` | 동일 |
| `todayDiscoverySection` (오늘의 발견) | `HomeTodayPopularView` + `HomeTodayPopularCollectionViewCell` | **엔드포인트·카드 2변형 동일** (`/novels/popular`) |
| `TrendingFeedSection` (추천글) | `HomeRealtimePopularView` + `HomeRealtimePopularCollectionViewCell` | **2건씩 3페이지 캐러셀 동일** (`/feeds/popular`) |
| `PreferenceGenreSection` (이 웹소설은 어때요) | `HomeTasteRecommendView` (취향추천) | **엔드포인트 동일**(`/novels/taste`). "미설정 vs 0건" 처리가 갈림(2.5) |
| *(없음)* | `HomeHeaderView.announcementButton` → 알림 목록 | V2는 헤더 벨 하나로 통합 |
| *(없음)* | 비로그인 홈 경로 전반(로그인 모달·비로그인 타이틀) | **V2엔 비로그인 경로가 통째로 없다**(3) |

> **알림 목록/상세**(`HomeNotification*`)는 V1에서 이 Home 폴더 하위에 있으나, V2에선 **`NotificationFeature`가 별도 모듈**이라 이 문서 범위 밖이다(홈은 벨 탭으로 이동만 위임).

---

## 0. 점검 대기 요약

**회귀 후보 판정** — 각 항목 배지가 결과다(✅유지·🔧고치기·🗑삭제·⏳⏸보류). 배지 없는 항목은 `docs/TODO.md` 9·10절로 이관됐거나 아직 판정 대기다.

1. **비로그인 홈 경로 전체 제거** — V1 홈은 `isLogined`로 곳곳이 갈렸다: 셀 탭 시 로그인 유도 모달, 추천글 타이틀이 "지금 뜨는 수다글"(비로그인)/"{닉네임}…"(로그인)로 바뀜, 취향추천이 비로그인이면 설정 유도 카드. **V2엔 이 분기가 하나도 없다**(항상 로그인 가정). V2가 로그인 필수 앱이라 의도된 것으로 보이나 **문서화된 결정은 못 찾음**. → [3](#3-로그인-게이팅-비로그인-홈)
   - **✅ 확정(2026-08-27, 사용자): 의도된 제거.** V2는 로그인 필수 앱이라 비로그인 홈 경로가 존재하지 않는다. 회귀 아님 — 되살리지 말 것.
2. **에러 철학 반전** — V1은 **섹션마다 `.catch`로 빈 배열 폴백**이라 한 섹션이 실패해도 나머지 홈은 그려지고 **전면 에러가 뜨지 않는다**. V2는 **하나라도 실패하면 홈 전체가 전면 실패 뷰**(#179 문서화). 전면 실패 뷰 자체는 의도지만, **"부분 실패 시 나머지는 보여주던" 그레이스풀 저하가 사라진 것**이 의도인지 확인 필요. → [4.1](#41-에러-표현)
   - **✅ 확정(2026-08-27, 사용자): 전면 실패 일원화가 맞음.** 부분 성공을 안 보여주는 효과를 수용한다(사용자가 실패를 알고 재시도하는 쪽 우선). 그레이스풀 저하 되살리지 말 것.
3. **Splash 프리페치 제거** — V1은 `HomePrefetchService`로 오늘의 인기작·지금 뜨는 글을 **Splash 단계에서 미리 받아** 홈 진입 시 소비했다. V2엔 이 프리페치가 없다(진입 시 로드). → [1.5](#15-프리페치)
   - **🔧 확정(2026-08-27, 사용자): 되살린다(revive).** 단 V1의 `HomePrefetchService.shared` 싱글톤 방식은 쓰지 않는다. 합의된 설계·전제·구현 대기는 [1.5](#15-프리페치)에 상세. C1 범위 밖 구현이라 `docs/TODO.md`에 부활 대기로 올림.
4. **약관 동의 체크 제거** — V1은 홈 첫 진입(`viewDidLoad`)에서 `getTermSetting`으로 필수 약관 미동의면 동의 알럿을 띄웠다. **V2 홈엔 없다**(온보딩으로 옮겼을 가능성). → [6.1](#61-약관-동의-강제-업데이트)
   - **✅ 확정(2026-08-28): 온보딩으로 이동(누락 아님).** `OnboardingFeature/TermsAgreement` 실재 확인.
5. **앱 최소 버전 강제 업데이트 제거** — V1은 `viewWillAppear`마다 최소 버전을 조회해 낮으면 **닫을 수 없는 업데이트 알럿**(→ App Store)을 띄웠다. **V2 홈엔 없다**(App 레이어로 옮겼을 가능성). → [6.1](#61-약관-동의-강제-업데이트)
   - **🔧 확정(2026-08-28): 드롭 아님, App 배선 대기.** 최소버전 조회 인프라는 `SettingData`에 있음(게이트만 App 몫).
6. **Amplitude 이벤트 트래킹 전부 제거** — V1은 홈 진입·오늘의랭킹 탭·추천작 탭·선호장르 버튼 등에 Amplitude 이벤트를 심었다. **V2엔 없다**(분석 미이식으로 보이나 확인 필요). → [6.3](#63-기타-부수-작업)

**🔧 / 🗑 눈에 띄는 변경 (의도 확인)**

7. 🔧 **선호장르 "설정했으나 0건" 분리** — V1은 로그인+취향추천 0건을 **미설정과 똑같이 설정 유도 카드**로 처리했다(둘 다 `unregisterView`). V2는 `.noGenreSettings`(→ 설정 유도)와 `.novels([])`(→ 섹션 숨김)를 나눈다. → [2.5](#25-선호장르-이-웹소설은-어때요)
8. 🗑 **취향추천 독립 스켈레톤 로딩 제거** — V1은 취향추천만 별도 shimmer 스켈레톤을 항상 띄웠다(개인화 연산이 느려서). V2는 홈 전체가 한 로드라 섹션 단위 스켈레톤이 없다. → [4.2](#42-로딩)
9. 🗑 **유저 정보(userMe) 조회·UserDefaults 저장 / editProfile 토스트 제거** — V1 홈이 `getUserMeData`로 userId·nickname·gender를 저장하고, 프로필 수정 복귀 시 토스트를 띄웠다. V2 홈은 닉네임을 **로컬 캐시에서 읽기만** 한다. → [6.2](#62-유저-정보-처리)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 로드·생명주기·동시성

원본: `…/Home/HomeViewModel/HomeViewModel.swift`, `.../HomeViewController/HomeViewController.swift`

### 1.1 진입·재조회

- ✅ **Keep** — `viewWillAppear`마다 홈 데이터를 다시 조회한다(재진입·탭 복귀 시 최신화). 최초 1회 가드 없음.
  - V2: `onAppear`마다 `.load`. "1회 가드를 두지 않는 게 의도"라고 명문화됨(밖에서 바뀐 값을 다시 비춰야 함).
  - 근거: V1 `HomeViewController.swift:46-54`,`HomeViewModel.swift:107` · V2 `HomeView.swift:68-71`, `HomeViewModel.swift:131-138`, `CLAUDE.md`("탭 복귀마다 갱신")

### 1.2 동시 호출 구조

- 🔧 **Improve** — **N개 요청을 한 흐름으로 묶는 방식**. V1은 RxSwift **독립 스트림 여러 개**로 쪼갰다: (a) 오늘의 인기작+지금 뜨는 글을 `zip`으로 묶어 상단 로딩 스피너를 제어, (b) 취향추천은 **별도 구독**(느린 개인화라 상단 표시를 막지 않음), (c) 알림 미확인·앱 버전도 각각 독립. V2는 추천 3종을 UseCase 안에서 `async let`으로, 알림 배지를 VM에서 `async let`으로 **한 흐름**에 합친다.
  - V2: 진입 시 **총 4건이 한꺼번에** 나가고 **하나라도 실패하면 홈 전체가 실패**다(아래 4.1과 연결). 관찰상 "동시에 받아 그린다"는 같지만, **실패·로딩 결합 방식이 달라졌다**(V1은 섹션별로 독립, V2는 전부 한 몸).
  - 근거: V1 `HomeViewModel.swift:107-198`(스트림 4개) · V2 `HomeViewModel.swift:182-214`, `LoadHomeDataUseCase.swift:28-51`, `RecommendationDomain/CLAUDE.md`(async let 동시)
- ✅ **Keep** — 오늘의 인기작·지금 뜨는 글·취향추천을 **동시에** 받아 온다(순차 대기 아님).
  - V2: 수단 변경(RxSwift `zip`/독립 구독 → 구조적 동시성 `async let`). 병렬성 자체는 `issuesThreeCallsConcurrently` 테스트로 고정.
  - 근거: V1 `HomeViewModel.swift:111-124`,`149-160` · V2 `LoadHomeDataUseCase.swift:29-31`, `RecommendationDomain/CLAUDE.md`(퇴행 방지 테스트)

### 1.3 관심글(Interest) 호출

- 🗑 **Delete** — V1 Repository/Service엔 `getInterestFeeds()`(`/feeds/interest`)가 있으나 **홈에서 호출하지 않는다**(주석 "Deprecated"). 홈에 관심글 섹션이 없다.
  - V2: `fetchInterestFeeds`를 `LoadHomeDataUseCase`가 **일부러 부르지 않는다**(#179 명문화). Entity·Repository·DTO는 남겨둠. (오탐 방지: `RecommendationDomain/CLAUDE.md:17-20` — 되살리지 말 것.)
  - 근거: V1 `HomeViewModel.swift:313-316`(Deprecated 주석) · V2 `RecommendationDomain/CLAUDE.md`(관심글 미호출)

### 1.4 인증 만료 처리

- 🔧 **Improve** — V1 홈 VM엔 **화면 단위 인증 만료 분기가 없다**. 각 스트림이 `.catch`로 빈 값 폴백만 하고, 토큰 재발급은 `tokenCheckURLSession` 네트워크 계층이 담당한다.
  - V2: `authenticationRequired`를 화면에서 걸러 `onAuthenticationRequired`로 라우팅한다(탭 콘텐츠라 신호를 `.consumeAuthenticationRequired`로 소진). 홈은 동시 요청 4건이라 401이 동시에 나므로 `SessionRefreshCoordinator`(재발급 직렬화)가 전제(#184).
  - 근거: V1 `HomeViewModel.swift:113-121`(catch → 빈 값) · V2 `HomeViewModel.swift:223-239`, `Feature/CLAUDE.md`(인증 만료 처리 계약), `CLAUDE.md`(동시 요청 4건·401 4건)

### 1.5 프리페치

- 🔧 **Improve → 되살림 확정(2026-08-27)** — V1은 오늘의 인기작·지금 뜨는 글을 **Splash 단계에서 `HomePrefetchService`로 미리 받아** 두고, 홈 진입 시 `consumeTodayPopular()`/`consumeRealtimeFeeds()`로 있으면 그걸 쓰고 없으면 네트워크를 탔다(첫 홈 표시 지연 감소).
  - **V2 현재: 이 프리페치가 없다.** 홈 진입 시 항상 새로 로드한다.
  - 근거: V1 `HomeViewModel.swift:304-311`(`HomePrefetchService.shared.consume…`) · V2 `LoadHomeDataUseCase.swift`(프리페치 경로 없음)

  #### 합의된 V2 재구현 설계 (구현 대기 — `docs/TODO.md`)

  **전제**: V2에 **런치 부트스트랩 단계를 둔다**(사용자 확정 2026-08-27). 현재 V2엔 Splash/부트스트랩이 없어(`grep Splash` = 디자인시스템 에셋뿐) 프리페치를 얹을 자리가 없었다 — 프리페치 이득은 "런치→홈 표시 사이 dwell"에 전적으로 달렸으므로 이 부트스트랩이 **선행 전제**다. 부트스트랩 없이 홈이 런치 즉시 뜨면 프리페치가 착지 전에 홈 로드가 네트워크를 먼저 때려 이득이 0이 된다.

  **금지**: V1의 `HomePrefetchService.shared` **싱글톤 방식은 쓰지 않는다**(레포 철학). `DefaultRecommendationRepository`가 `struct`(값 타입)라 레포 안에 캐시 필드를 둘 수도 없다(복사되어 공유 불가).

  **설계**:
  1. **`HomePrefetchStore`(actor)** — `today: [TodayDiscovery]?`·`trending: [TrendingFeed]?` 단발성 슬롯. `consume…()`은 값을 돌려주고 **슬롯을 비운다**. struct 레포는 이 actor **참조**만 보유 → 값 타입이어도 캐시 공유(핵심 트릭). Swift 6 strict-concurrency도 actor라 안전.
  2. **부트스트랩이 트리거** — `PrefetchHomeDataUseCase`(또는 레포 fetch)를 fire-and-forget으로 호출해 today·trending을 미리 받아 store에 넣는다.
  3. **레포가 소비** — `fetchTodayDiscoveries()`/`fetchTrendingFeeds()`가 store에 값이 있으면 소비, 없으면 네트워크.
  4. **DI가 단일 인스턴스 공유** — App이 `HomePrefetchStore` 하나를 만들어 부트스트랩 트리거와 레포에 같이 주입. 싱글톤 아님, 의존 방향 그대로.

  **단발성(single-shot)이 정답인 이유**: 홈은 "탭 복귀마다 갱신" 계약(→ [CLAUDE.md](CLAUDE.md))이라 TTL 캐시를 두면 복귀 때 stale이 나온다. single-shot이면 프리페치가 슬롯 1회 채움 → 첫 홈 로드가 비움 → 이후 복귀 갱신은 전부 네트워크. V1 동작과 정확히 일치하고 stale 함정도 피한다.

  **범위**: today·trending **2종만**(V1도 그랬음). taste(선호장르)는 느린 개인화라 제외, 알림 배지도 제외.

---

## 2. 섹션별 콘텐츠

### 2.1 오늘의 발견 (`/novels/popular`)

- ✅ **Keep** — 가로 캐러셀. 카드는 **두 변형**이다: 대응 피드가 있으면 **"{닉네임}의 한마디" + 피드 내용**(유저 아바타), 없으면 **"작품 소개" + 작품 설명**. 카드 탭은 (변형 무관) **작품 상세**로 간다(유저 프로필로 가지 않음).
  - V2: `TodayDiscovery.content`가 `.novel`/`.userComment(user:)`로 같은 2변형. 카드 전체 탭 → `onNovelSelected`.
  - 근거: V1 `HomeTodayPopularCollectionViewCell.swift:283-356`(피드 변형 331-343 / 작품 변형 345-355) · V2 `HomeView.swift:184-188`, `CLAUDE.md`(유저 한마디 카드도 작품 상세)
- ✅ **Keep** — 표지 뱃지는 **`icGenreBackground`(코너 삼각형) + 장르 아이콘** 조합(배경 56 / 아이콘 25). 카드 배경은 **표지를 블러로 깔고 `imgNovelBg`를 덮는 2층**.
  - V2: 동일 구성(#179 실측으로 `imgTodayPopularBackground` 잔재를 배제하고 `imgNovelBg`로 확정).
  - 근거: V1 `HomeTodayPopularCollectionViewCell.swift:84-95`,`133-141`,`229-238` · V2 `CLAUDE.md`(장르 뱃지·2층 배경)
- ✅ **Keep** — 키워드 칩은 **표시 전용**(탭 없음), 키워드가 없으면 칩 영역을 숨긴다.
  - V2: 키워드 칩 표시 전용(노드명 `tagLink`지만 탭 안 함 — 카드 전체 탭과 경합 방지).
  - 근거: V1 `HomeTodayPopularCollectionViewCell.swift:296-305`(`keywordStackView.isHidden = keywords.isEmpty`) · V2 `CLAUDE.md`(키워드 칩 표시 전용)
- ❓ **Unknown** — V1 카드는 **작가명 5자·제목 17자에서 하드 절단**(`truncateText`)한다.
  - V2: 폭 제한 대신 `fixedSize`+`layoutPriority`+말줄임으로 실데이터 폭에 맞춘다(#179 — 시안 고정폭이 샘플 문구 결과였음). 관찰 결과(길면 말줄임)는 비슷하나 **자릿수 하드컷은 안 함**.
  - 근거: V1 `HomeTodayPopularCollectionViewCell.swift:285`,`291` · V2 `CLAUDE.md`(시안 텍스트 프레임 폭 함정)

### 2.2 추천글 / 지금 뜨는 글 (`/feeds/popular`)

- ✅ **Keep** — 응답을 **`prefix(6)` → 2건씩 묶어 3페이지**로 만들고, **페이지 수만큼 도트 인디케이터**를 그린다. 한 페이지 = 위아래 피드 2개가 구분선을 공유하는 카드.
  - V2: `stride(by: 2)`로 동일하게 페이지를 만들고 인디케이터 3개. 구분선(`wssGray80`) 동일.
  - 근거: V1 `HomeViewModel.swift:132-137`(prefix 6 + stride 2), `HomeRealtimePopularView.swift:142-153`(도트) · V2 `TrendingFeedSection.swift:53-58`,`112-127`,`177-189`
- ✅ **Keep** — 스포일러 피드는 본문 대신 **"스포일러가 포함된 글 보기"를 빨강(`wssSecondary100`)으로** 대체한다.
  - V2: `feed.isSpoiler` → 같은 문구·색, 1줄.
  - 근거: V1 `HomeRealTimePopularFeedView.swift:104-115` · V2 `TrendingFeedSection.swift:145-149`
- ✅ **Keep** — 피드 행 탭 → **피드 상세**로 이동.
  - V2: `onFeedSelected(feedID)` 위임. (V1은 비로그인이면 로그인 모달 — 3.)
  - 근거: V1 `HomeViewController.swift:124-135` · V2 `TrendingFeedSection.swift:130-132`
- ✅ **Keep** — 페이지 단위 스냅(한 장씩 넘어감)·현재 페이지 도트 강조.
  - V2: 수단 변경 — V1은 `scrollViewWillEndDragging` 커스텀 스냅 + `scrollViewDidScroll` 도트, V2는 `.scrollTargetBehavior(.viewAligned)` + `scrollPosition`.
  - 근거: V1 `HomeViewController.swift:297-315` · V2 `TrendingFeedSection.swift:98-107`,`180-185`
- ✅ **Keep(값 없음)** — 피드 행에 **좋아요·댓글 수를 표시하지 않는다**(V1 셀에 없음).
  - V2: `TrendingFeed`에 `likeCount`/`commentCount`가 있으나 **행에 렌더하지 않는다**(V1과 동일하게 미표시). 데이터만 들고 있음.
  - 근거: V1 `HomeRealTimePopularFeedView.swift:65-71`(제목·본문·표지만) · V2 `TrendingFeedSection.swift:136-170`, `TrendingFeed.swift:22-23`

### 2.3 추천글 타이틀 (닉네임)

- ✅ **Keep** — 로그인 사용자면 제목 주어에 **닉네임**을 넣는다(`"{nickname}…"`), 없으면 폴백 문구.
  - V2: `nickname.map { "\($0)님을 위한 추천글" } ?? "추천글"`. **닉네임 출처가 다름**(V1은 `getUserMeData` 저장값, V2는 로컬 캐시 `fetchCachedNickname`).
  - 근거: V1 `HomeRealtimePopularView.swift:134-140`, `HomeViewModel.swift:211` · V2 `TrendingFeedSection.swift:77-79`, `LoadHomeDataUseCase.swift:46`
  - ⚠️ **비로그인 폴백 문구는 3 참조** — V1은 비로그인 시 "지금 뜨는 수다글"(닉네임 없는 별도 카피), V2는 비로그인 경로가 없어 항상 "추천글"로만 폴백.

### 2.4 검색바·상세검색 배너

- ✅ **Keep** — 검색바 탭 → 검색 화면, 상세검색 유도 배너 탭 → 상세검색 화면.
  - V2: `onSearchTapped` / `onDetailSearchTapped` 위임. (V1은 상세검색이 비로그인이면 로그인 모달 — 3.) 좌우 여백 13(아래 추천 섹션 20과 다름)도 유지.
  - 근거: V1 `HomeViewModel.swift:215-229`, `HomeView.swift:89-98` · V2 `HomeSearchSection`, `HomeView.swift:136-139`, `CLAUDE.md`(검색바 여백 13)

### 2.5 선호장르 (이 웹소설은 어때요, `/novels/taste`)

- ✅ **Keep** — 2열 그리드로 취향 추천 작품을 보여준다. 셀 탭 → 작품 상세.
  - V2: `WSSNovelGridCell` 2열. `onNovelSelected` 위임.
  - 근거: V1 `HomeTasteRecommendView.swift:63-69`,`142-154`, `HomeViewModel.swift:243-249` · V2 `PreferenceGenreSection.swift:78-94`
- ✅ **Keep** — 선호장르 **미설정**이면 목록 대신 **설정 유도 카드**를 띄우고, 그 버튼은 설정 화면으로 보낸다.
  - V2: `.noGenreSettings` → `settingInduceCard` → `onPreferenceGenreSettingTapped`. (V1은 목적지가 `MyPageEdit(entryType:.home)` — 5.)
  - 근거: V1 `HomeTasteRecommendView.swift:129-164`, `HomeViewModel.swift:265-274` · V2 `PreferenceGenreSection.swift:97-122`
- 🔧 **Improve** — **"설정했으나 결과 0건" 처리**. V1은 `updateView(isLogined, isEmpty)`에서 **로그인+0건을 미설정과 똑같이** 설정 유도 카드로 덮었다(둘 다 `unregisterView`) — 장르를 골랐는데도 "선호장르 설정하기"가 뜨는 셈.
  - V2: `PreferenceGenreNovelState`를 `.noGenreSettings`(→ CTA) / `.novels([])`(→ **섹션 통째 숨김**)로 분리해 이 혼동을 없앴다. `state`가 **옵셔널**이라 로딩 전(nil)과 미설정을 안 섞어 CTA 번쩍임도 막는다.
  - 근거: V1 `HomeTasteRecommendView.swift:133-163`(logined+isEmpty → unregister) · V2 `PreferenceGenreSection.swift:48-53`, `HomeView.swift:156-164`,`202-205`, `CLAUDE.md`(preferenceGenreNovelState 옵셔널)

### 2.6 빈 섹션 숨김

- ✅ **Keep** — 섹션 데이터가 0건이면 **제목까지 통째로 숨긴다**(빈 문구 없이). 아래 섹션이 그만큼 올라붙는다.
  - V2: `if !state.xxx.isEmpty` 가드로 섹션+제목+간격 함께 숨김. 단 선호장르 **미설정**은 빈 상태가 아니라 CTA(2.5).
  - 근거: V1 `HomeTasteRecommendView.swift:129-164`(isHidden 토글), `HomeRealtimePopularView`(섹션별 표시) · V2 `HomeView.swift:141-164`, `CLAUDE.md`(섹션 0건 제목까지 숨김)

---

## 3. 로그인 게이팅 (비로그인 홈)

- 🗑 **의도된 제거 확정 (2026-08-27, 사용자: 로그인 필수 앱)** — V1 홈은 `APIConstants.isLogined`로 **거의 모든 동작이 갈렸다**:
  - **셀·배너 탭**: 오늘의 인기작 셀·상세검색 배너·선호장르 버튼은 비로그인이면 **로그인 유도 모달**(`showInduceLoginModalView` → `presentInduceLoginViewController`). 지금 뜨는 글 피드 탭도 비로그인이면 로그인 모달.
  - **추천글 타이틀**: 비로그인 → "지금 뜨는 수다글"(별도 카피), 로그인 → "{닉네임}…"(2.3).
  - **취향추천**: 비로그인이면 API를 아예 안 부르고 설정 유도 카드를 띄운다.
  - **알림 미확인 조회**: 비로그인이면 스킵하고 `false`로 둔다.
  - **V2: 이 `isLogined` 분기가 하나도 없다.** 항상 로그인된 사용자로 가정하고, 인증이 만료되면 1.4의 로그인 라우팅으로 화면을 교체한다.
  - 근거: V1 `HomeViewModel.swift:151`,`176`,`223-228`,`234-240`,`258-262`,`268-272`, `HomeViewController.swift:125-134`, `HomeRealtimePopularView.swift:134-139`, `HomeTasteRecommendView.swift:155-163` · V2 `HomeViewModel.swift`(isLogined 개념 없음), `HomeView.swift`(로그인 모달 없음)
  - **판정(2026-08-27, 사용자): 의도된 제거.** V2는 로그인 필수 앱이라 비로그인 홈 경로가 통째로 불필요하다(0-1). 회귀 아님 — 되살리지 않는다. (2026-08-28 로그인 정책 재확인 — SearchFeature 5.1과 동일 결론.)

---

## 4. 에러·로딩·빈 화면

### 4.1 에러 표현

- 🔧 **전면 실패 일원화 확정 (2026-08-27, 사용자)** — **부분 실패 처리**. V1은 오늘의 인기작·지금 뜨는 글·취향추천·알림 조회를 **각각 `.catch`로 빈 값 폴백**한다 → 한 섹션이 실패해도 **그 섹션만 비고 나머지 홈은 정상 표시**되며, **전면 에러 화면이 없다**(바깥 `onError`는 스피너만 끈다).
  - **V2: 하나라도 실패하면 홈 전체가 전면 실패 뷰**(`NetworkErrorView` + 재시도, 헤더만 남김)다. 전면 실패 뷰로 통일한 것 자체는 #179에서 문서화된 의도(사용자가 실패를 알고 재시도할 수 있어야 함, 서재·갱신 규칙과 정렬).
  - 근거: V1 `HomeViewModel.swift:113-121`,`140-143`,`156-159`,`180-183`(섹션별 catch → 빈 값) · V2 `HomeView.swift:116-126`, `HomeViewModel.swift:223-232`, `CLAUDE.md`(로딩·전면 실패는 헤더만 남기고 전면 대체)
  - **판정(2026-08-27, 사용자): 전면 실패 일원화가 맞음.** 부분 성공을 안 보여주는 효과를 수용한다 — 사용자가 실패를 알고 재시도하는 쪽 우선(#195 로드 실패 표현 계약·#179와 정렬). 그레이스풀 저하 되살리지 않는다. (2026-08-28 재확인.)
- ✅ **Keep** — 실패 표현은 **헤더만 남기고 그 아래(검색바·배너 포함)를 통째로 대체**한다.
  - V2: `content(for:)`가 `loadFailed`면 `NetworkErrorView`로 헤더 아래 전면 대체. 갱신(탭 복귀) 실패도 같게 다룸.
  - 근거: V1(전면 에러 뷰 없음 — 해당 개념 자체가 V2 신규) · V2 `HomeView.swift:98-126`, `CLAUDE.md`(헤더만 남기고 전면 대체 / 갱신 실패도 동일)

### 4.2 로딩

- 🔧 **Improve / 🗑 Delete(부분)** — **로딩 표시 세분화**. V1은 (a) 상단 2종(오늘의 인기작+지금 뜨는 글) `zip`이 **전면 로딩 스피너**(`WSSLoadingView`)를 제어하고, (b) 취향추천은 **자체 shimmer 스켈레톤**(항상, 개인화가 느려서)을 따로 띄웠다 — 상단이 뜬 뒤에도 취향추천만 스켈레톤이 남을 수 있다.
  - V2: 홈 전체가 한 로드라 **단일 전면 로딩**만 있고, 그마저 **`isInitialLoading`(보여줄 게 없을 때만)**으로 좁혔다(탭 복귀 갱신 시 이미 그린 화면을 로딩으로 갈아치우지 않음). **섹션 단위 스켈레톤은 사라졌다.**
  - 근거: V1 `HomeViewModel.swift:108-110`,`154`,`162`,`showLoadingView`, `HomeTasteRecommendView.swift:111-127`(setLoading 스켈레톤) · V2 `HomeViewModel.swift:52-54`,`183-187`, `HomeView.swift:111-126`, `CLAUDE.md`(isInitialLoading)
- ✅ **Keep** — **초기 진입엔 전면 로딩, 갱신(탭 복귀)엔 로딩 표시를 세우지 않는다**(콘텐츠 우선). 로딩과 실패의 기준이 일부러 다르다.
  - V2: `isInitialLoading`은 `!hasLoadedContent`일 때만 true. 실패는 갱신도 전면 대체(4.1)라 두 분기 기준이 의도적으로 갈림(#179).
  - 근거: V1 `HomeViewModel.swift:108`(viewWillAppear마다 spinner true지만 상단 도착 즉시 false) · V2 `HomeViewModel.swift:49-54`, `CLAUDE.md`(로딩은 콘텐츠 우선, 실패는 첫 로드와 동일 — 기준이 일부러 다름)

---

## 5. 상호작용·네비게이션

- ✅ **Keep** — **헤더 알림 벨 → 알림 목록**. (V1 헤더의 "announcement" 버튼이 실제로는 알림 목록(`pushToNotificationViewController`)으로 간다 — 이름과 목적지가 다름.)
  - V2: 헤더 벨 → `onNotificationTapped`. 안 읽은 알림은 **점 박힌 벨 에셋 variant**(`icAnnouncementDotted`)로 표현.
  - 근거: V1 `HomeViewController.swift:189-193`, `HomeHeaderView.checkNotificationUnread` · V2 `HomeHeaderView.swift:41-55`, `HomeView.swift:100-104`
- ✅ **Keep** — 알림 미확인 배지 표시(안 읽은 알림 있으면 벨에 표시).
  - V2: `hasUnreadNotifications` → 점 박힌 벨. **조회 방식이 달라짐**: V1은 독립 스트림(실패해도 홈 무사), V2는 `LoadUnreadNotificationStatusUseCase`를 **결합 로드**(실패 시 홈 전체 실패, 4.1)로.
  - 근거: V1 `HomeViewModel.swift:174-188`,`252-257` · V2 `HomeViewModel.swift:193`,`206`, `HomeHeaderView.swift:43-45`
- ✅ **Keep** — 모든 화면 전환을 **상위(App)에 위임**한다(홈은 스스로 push하지 않음).
  - V2: 선택 결과 전부 콜백(`onNovelSelected`/`onFeedSelected`/`onSearchTapped`/`onDetailSearchTapped`/`onNotificationTapped`/`onPreferenceGenreSettingTapped`). V1도 VM이 `PublishRelay`로 올려 VC가 push — 같은 결.
  - 근거: V1 `HomeViewModel.swift:276-293`(Output relay), `HomeViewController.swift:153-218` · V2 `HomeView.swift:27-33`, `HomeFeatureFactory`
- ❓ **Unknown** — **선호장르 설정 버튼의 목적지**. V1은 `MyPageEditViewController(entryType: .home)`(마이페이지 프로필 수정 화면)으로 간다.
  - V2: `onPreferenceGenreSettingTapped` 콜백(목적지는 App 배선). 개념상 "선호장르 설정"이나 **V1이 프로필 수정 화면을 재활용**한 것과 같은 목적지인지 확인 필요.
  - 근거: V1 `HomeViewController.swift:195-200`(`pushToMyPageEditViewController(entryType:.home)`) · V2 `HomeView.swift:32`, `CLAUDE.md`
- 🔧 **Improve (신규)** — **알림 벨 탭 시 이동과 푸시 권한 확인을 동시에**(#193). 탭 즉시 이동 신호를 올리고, 그와 동시에 시스템 푸시 권한을 확인해 `denied`면 **비차단 안내 알럿**(설정 유도), `notDetermined`면 시스템 프롬프트를 띄운다. 이동은 어느 쪽이든 막지 않는다.
  - V1: 벨 탭은 그냥 알림 목록으로 이동만 했다(iOS 푸시 권한 개념 없음). V2 신규 계약이라 대응 V1 동작이 없다.
  - 근거: V1 `HomeViewController.swift:189-193`(이동만) · V2 `HomeViewModel.swift:143-156`, `HomeView.swift:78-95`, `CLAUDE.md`(#193 벨 탭)

---

## 6. 홈 진입 부수 작업 (V1이 홈에서 하던 것들)

### 6.1 약관 동의·강제 업데이트

- ✅ **온보딩으로 이동 확인 (2026-08-28)** — **필수 약관 동의 강제**. V1은 홈 첫 진입(`viewDidLoad` → `getUserMeData` 성공 후)에서 `getTermSetting`을 조회해 **필수 약관 미동의면 동의 알럿**을 띄우고 약관 동의 모달을 present했다.
  - **V2 홈엔 이 흐름이 없다.** (온보딩/로그인 단계로 옮겼을 가능성이 크나 이 문서 범위 밖.)
  - 근거: V1 `HomeViewModel.swift:333-345`, `HomeViewController.swift:259-279` · V2 `HomeViewModel`(약관 관련 코드 없음)
  - **판정(2026-08-28): 온보딩 흐름으로 이동(누락 아님).** V2 `OnboardingFeature/TermsAgreement`(View+VM) 실재 확인 — 약관 동의가 홈 첫 진입이 아니라 온보딩 단계로 옮겨졌다.
- 🔧 **인프라 존재·App 게이트 배선 대기 (2026-08-28)** — **앱 최소 버전 강제 업데이트**. V1은 `viewWillAppear`마다 `getAppMinimumVersion`을 조회해 현재 버전이 낮으면 **닫을 수 없는(`isDismissable: false`) 업데이트 알럿** → App Store로 보냈다.
  - **V2 홈엔 없다.** (App 레이어 공통 처리로 옮겼을 가능성.)
  - 근거: V1 `HomeViewModel.swift:190-198`,`324-326`, `HomeViewController.swift:227-242` · V2 `HomeViewModel`(버전 체크 없음)
  - **판정(2026-08-28): 드롭 아님 — App 부트스트랩 배선 대기.** 서버 최소버전 조회 인프라는 이미 있다(`SettingData`의 `AppMinimumVersionQuery`/`AppMinimumVersionResponse`·`getAppMinimumVersion` 엔드포인트·`minimumVersion` 매핑). App 모듈이 아직 골격이라 이 게이트를 켜는 배선만 없다 — App 첫 조립(TODO 8) 몫.

### 6.2 유저 정보 처리

- 🗑 **Delete** — V1 홈은 `viewDidLoad`에서 `getUserMeData`로 **userId·nickname·gender를 UserDefaults에 저장**했다(홈이 유저 정보 갱신 지점 겸용).
  - V2: 홈은 닉네임을 **로컬 캐시에서 읽기만** 한다(`fetchCachedNickname`). 저장은 로그인·프로필 조회 등 다른 경로가 담당(홈의 책임 아님).
  - 근거: V1 `HomeViewModel.swift:200-213`,`299-301` · V2 `LoadHomeDataUseCase.swift:46`, `RecommendationDomain/CLAUDE.md`(닉네임은 로컬 캐시)
- 🗑 **Delete** — V1은 `NotificationName.editProfile`을 관찰해 프로필 수정 복귀 시 **"프로필 수정" 토스트**를 띄웠다.
  - V2: 홈에 이 토스트가 없다.
  - 근거: V1 `HomeViewController.swift:245-250` · V2 `HomeView`(editProfile 토스트 없음)

### 6.3 기타 부수 작업

- ❓ **Unknown (헤드라인)** — **Amplitude 이벤트 트래킹**. V1은 홈 진입(`home`)·오늘의 랭킹 탭(`homeTodayRanking`)·추천작 탭(`homePreferNovellist`)·선호장르 버튼(`homeToPreferButton`)에 Amplitude 이벤트를 심었다.
  - **V2엔 트래킹 코드가 없다.** (분석 인프라 미이식으로 보이나 확인 필요.)
  - 근거: V1 `HomeViewController.swift:53`, `HomeViewModel.swift:233`,`245`,`267` · V2 `HomeViewModel`(트래킹 없음)
- 🔧 **Improve (신규)** — **홈 진입 시 시스템 푸시 권한 확인**(#193). V1은 `viewDidLoad`에서 로그인 상태면 `NotificationHelper.setRemoteNotification()`으로 **원격 알림(APNs)에 조용히 등록**만 했다.
  - V2: 진입마다 `.checkPushAuthorizationOnEntry`로 권한을 확인해 **`notDetermined`면 그 자리에서 시스템 프롬프트**를 띄운다(첫 홈 진입 = 첫 알림 권한 결정 시점 의도, 온보딩 별도 단계 불필요). `authorized`/`denied`면 아무 것도 안 함.
  - 근거: V1 `HomeViewController.swift:288-294`(`setRemoteNotification`) · V2 `HomeViewModel.swift:168-174`, `HomeView.swift:68-71`, `CLAUDE.md`(#193 진입 시 권한 확인)

---

## 부록 A. 서버 요청 (C2 비교 재료)

V1 홈은 **쿼리 파라미터 없는 단순 GET 4종**(accessTokenHeader만)이다. V2도 같은 엔드포인트를 쓴다(대부분 ✅ Keep).

| 용도 | V1 엔드포인트 | V1 파라미터 | V2 대응 | 상태 |
|---|---|---|---|---|
| 오늘의 발견 | `GET /novels/popular` | 없음 | `fetchTodayDiscoveries()` | ✅ Keep |
| 추천글(지금 뜨는 글) | `GET /feeds/popular` | 없음 | `fetchTrendingFeeds()` | ✅ Keep |
| 선호장르 작품(취향추천) | `GET /novels/taste` | 없음 | `fetchPreferenceGenreNovels()` | ✅ Keep |
| 관심글 | `GET /feeds/interest` | 없음 | *(홈 미호출)* | 🗑 Delete (1.3) |
| 알림 미확인 여부 | *(NotificationRepository)* | 없음 | `LoadUnreadNotificationStatusUseCase` | ✅ Keep (결합 로드로 이동 — 4.1) |

- 근거: V1 `WSSiOS/Resource/Constants/URLs/URLs.swift:170-173`, `RecommendService.swift:22-100` · V2 `RecommendationRepository.swift`, `LoadHomeDataUseCase.swift:29-31`
- **V1이 홈에서 추가로 부르던 것**(V2 홈엔 없음, 6): `getUserMeData`, `getAppMinimumVersion`, `getTermSetting`. 닉네임은 V2에서 로컬 캐시(`fetchCachedNickname`)로 대체.
- 세 추천 엔드포인트 모두 **개수 고정·페이지네이션 없음**(오늘의 발견 3 / 추천글 6→3페이지 / 선호장르 10). V1도 `prefix(6)` 외 별도 페이징 없음. ✅ Keep.
