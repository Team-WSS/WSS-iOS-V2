# NovelReviewFeature — V1 동작 계약 (V1 Behavior Contract)

> **이 문서는 무엇인가** — 운영 중인 **V1**(`Team-WSS/WSS-iOS`, UIKit·RxSwift)의 작품 평가(리뷰 작성) 화면이
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

- ❓ 항목과 눈에 띄는 🔧/🗑는 [§0 점검 대기 요약](#0-점검-대기-요약)에 모아뒀다.
- 근거는 **`repo@commit + 내부 경로`**로 남긴다(머신마다 다른 절대경로 금지). V1 스냅샷 기준 커밋: **`Team-WSS/WSS-iOS@eefcb9b2`**.
- V1 경로 접두사 생략형: `…/NovelReview/` = `WSSiOS/Source/Presentation/NovelReview/`.

## 화면 매핑 (V1 → V2)

| V2 (이 모듈) | V1 원본 | 성격 차이 |
|---|---|---|
| `Sources/NovelReview/` (메인: `NovelReviewView`+`NovelReviewViewModel`+`StarRatingView`) | `…/NovelReviewViewController`+`ViewModel`+`View` + `NovelReviewAssistantView/*` + `NovelReviewViewCell/*` | UIKit `UICollectionView`·`UIStackView` 섹션 → SwiftUI `VStack`. RxSwift `Input/Output` → `State/Action` |
| `Sources/ReadingPeriodSheet/` (기간 시트) | `…/NovelDateSelectModal*`(VC+VM+View + `NovelDateSelect*` 보조뷰) | UIKit 바텀 모달 + `UIDatePicker(.date)` → SwiftUI `.sheet` + 커스텀 휠(`WSSDateWheel`) |
| *(미구현 — 진입 버튼만)* | `…/NovelKeywordSelectModal*`(VC+VM+View, 키워드 검색·선택 모달) | **V2는 키워드 선택/탐색 화면이 통째로 미연결(TODO)** — §7 |

---

## 0. 점검 대기 요약

**❓ 판정 필요 (회귀일 수도 있음)**

1. **저장 성공 후 App Store 리뷰 요청 제거** — V1은 리뷰 저장에 성공하면 `AppReviewManager.shared.requestReview()`로 **App Store 평점 요청 프롬프트**를 띄웠다(리뷰를 남긴 직후 = 앱 평가를 부탁하기 좋은 시점). **V2엔 이 호출이 없다.** → [§2.4](#24-저장-부수-작업앱-리뷰-요청노티피케이션분석)
2. **키워드 선택/탐색 모달 전체 미구현** — V1은 키워드 검색바 탭 → **키워드 선택 모달**(검색·카테고리·최대 20개·문의하기)을 present하고, 고른 키워드 ID를 저장에 실었다. **V2는 키워드 섹션이 검색바 룩 버튼(탭 시 `print`만) 하나뿐이고 `draft.keywords`에 연결되지 않았다** → 저장 시 `keywordIds`가 **항상 빈 배열**이다. → [§7](#7-키워드)
3. **매력포인트 가로 배열 순서 차이** — V1 `AttractivePoint.allCases`는 `worldview·material·writingSkill(필력)·character·relationship·vibe` 순, V2는 `worldview·material·character·relationship·vibe·writingSkill(필력 마지막)`. 둘 다 `allCases`를 그대로 나열해 **6개 버튼의 표시 순서가 다르다**(필력 위치). → [§6](#6-매력-포인트)

**🔧 / 🗑 눈에 띄는 변경 (의도 확인)**

4. 🔧 **저장 실패의 조용한 실패 → 토스트로 표면화** — V1 저장 `onError`는 `print(error)`뿐이라 실패해도 사용자에게 **아무 표시가 없고 화면도 안 닫힌다**(무엇이 잘못됐는지 모름). V2는 `presentError` → 토스트. → [§2.2](#22-저장-실패--중복-저장-가드)
5. 🔧 **POST/PUT 결정 방식** — V1은 진입 시 **클라이언트가 추정**한다(`isNovelReviewExist = 서버 status != nil || isInterest`). V2는 **항상 POST 먼저 시도**하고 서버가 "이미 리뷰함"(`USER_NOVEL-002`)을 주면 **PUT으로 폴백**한다(서버 주도). → [§2.3](#23-생성put-vs-수정post-결정)
6. 🔧 **뒤로가기 중단 알럿 조건** — V1은 뒤로가기 시 **변경 여부와 무관하게 항상** "평가를 그만할까요?" 알럿을 띄운다. V2는 **초안이 실제로 바뀌었을 때만**(`hasUnsavedChanges`) 알럿을 띄우고, 변경이 없으면 곧장 닫는다. → [§8](#8-뒤로가기중단-알럿)
7. 🗑 **Amplitude 이벤트 전부 제거** — 저장 시 `rateNovel`, 키워드 모달의 `contactKeyword`. V2엔 트래킹이 없다. → [§2.4](#24-저장-부수-작업앱-리뷰-요청노티피케이션분석)

(나머지는 대부분 ✅ Keep 또는 문서화된 🔧 Improve.)

---

## 1. 진입·생명주기·로드

원본: `…/NovelReviewViewModel/NovelReviewViewModel.swift`, `…/NovelReviewViewController/NovelReviewViewController.swift`

### 1.1 진입 파라미터

- ✅ **Keep** — 진입 이전 화면이 **작품 ID·제목·읽기 상태**를 넘겨 준다(화면이 자체 보유하지 않음). 네비게이션 타이틀은 주입된 작품 제목 고정.
  - V1: `init(…, isInterest:, readStatus:, novelId:, novelTitle:)` — 네비 타이틀에 `novelTitle` 사용.
  - V2: `makeView(novelID:title:status:…)` — `title`(네비 타이틀)·`status`(초기 읽기 상태) 주입. **단 V1의 `isInterest`는 V2에 없다**(§2.3에서 그 용도가 서버 폴백으로 대체됨).
  - 근거: V1 `NovelReviewViewModel.swift:57-63`, `NovelReviewViewController.swift:56-58` · V2 `NovelReviewFeatureFactory.swift:28-49`, `CLAUDE.md`(진입점)

### 1.2 초안 로드 (최초 1회)

- ✅ **Keep** — 진입 시 `getNovelReview`로 **기존 리뷰 초안을 1회 로드**해 별점·기간·매력포인트·키워드를 채운다. 초안이 없으면 기본값 유지.
  - V2: `onAppear` → `.load`, **`hasLoaded` 가드로 최초 1회만**. 초안 nil(초안 없음)이면 초기 draft 유지(덮어쓰지 않음).
  - **탭 콘텐츠가 아니라 push되는 편집 폼**이라 "최초 1회 가드"가 **여기선 올바르다** — 재진입마다 재조회하면 편집 중 draft를 서버 값으로 덮는다. (홈·서재의 "탭 복귀마다 갱신"과 반대 결정이며, V2 `CLAUDE.md`에 그 이유가 명문화됨.)
  - 근거: V1 `NovelReviewViewController.swift:43-52`(viewDidLoad 1회), `NovelReviewViewModel.swift:99-120` · V2 `NovelReviewViewModel.swift:136-140`,`226-255`, `CLAUDE.md`(로드 최초 1회)
- ✅ **Keep** — **주입된 읽기 상태를 서버 저장 상태보다 우선**한다(로드된 `status`로 세그먼트를 덮지 않음).
  - V1: 로드 콜백이 `owner.readStatus`(주입값)를 그대로 `readStatusData`로 방출하고, 서버 `data.status`는 **오직 "리뷰 존재 여부"(§2.3) 판단에만** 쓴다.
  - V2: `loadDraft`가 `loaded.changeStatus(initialStatus)`로 주입 상태를 덮어 적용한다(원본과 다르면 '변경됨'으로 잡혀 중단 알럿 대상 — §8).
  - 근거: V1 `NovelReviewViewModel.swift:104`,`117-118` · V2 `NovelReviewViewModel.swift:237-239`
- ❓ **Unknown** — **로드 실패 처리**. V1 로드는 `flatMapLatest`로 갈아끼우기만 하고 **에러 분기가 없다**(에러 시 스트림이 조용히 끝나 화면이 초기값 그대로 남음). V2는 `state.loadFailed` → **전면 실패 뷰(`NetworkErrorView`, 재시도)**.
  - V2는 신규 계약(로드 실패 표현). V1엔 대응 동작 자체가 없어 "V1 유지"라 부를 게 없다 → 판정보단 참고. (전면 실패 뷰는 V2 전반의 로드 실패 계약과 정렬 — `Feature/CLAUDE.md`.)
  - 근거: V1 `NovelReviewViewModel.swift:99-120`(에러 분기 없음) · V2 `NovelReviewViewModel.swift:246-254`, `NovelReviewView.swift:44-54`

### 1.3 인증 만료

- 🔧 **Improve** — V1 리뷰 VM엔 **화면 단위 인증 만료 분기가 없다**(로드는 에러 무시, 저장은 `print`만; 토큰 재발급은 `tokenCheckURLSession` 네트워크 계층이 담당). V2는 `authenticationRequired`를 걸러 `requiresAuthentication` 신호 → `onAuthenticationRequired` 콜백으로 로그인 라우팅한다(로드·저장 공통).
  - 근거: V1 `NovelReviewService.swift:50`,`77`(tokenCheckURLSession) · V2 `NovelReviewViewModel.swift:249`,`296-300`, `NovelReviewView.swift:86-88`, `Feature/CLAUDE.md`(인증 만료 처리 계약)

---

## 2. 완료(저장)

### 2.1 저장 흐름

- ✅ **Keep** — 툴바 "완료" 탭 → 현재 입력을 저장하고 **성공 시 화면을 닫는다**(pop/dismiss).
  - V1: 성공 → `popViewController` → VC가 `popViewController(animated:)`.
  - V2: 성공 → `state.shouldDismiss = true` → View `onChange` → `dismiss()`.
  - 근거: V1 `NovelReviewViewModel.swift:160-163`, `NovelReviewViewController.swift:117-121` · V2 `NovelReviewViewModel.swift:262-263`, `NovelReviewView.swift:81-84`
- ✅ **Keep** — 저장 페이로드: 별점·읽기상태·시작/종료일·매력포인트·키워드ID. **시작일은 하차면 생략, 종료일은 보는중이면 생략**(읽기상태에 맞는 날짜만 전송).
  - V1: `startDate = readStatus != .quit ? … : nil`, `endDate = readStatus != .watching ? … : nil`.
  - V2: `draft.period?.start/end`를 그대로 싣되, `ReadingPeriod.normalized(for:status)`가 상태에 맞는 날짜만 이미 채워 둔 상태다(같은 결과). 자세한 매핑은 [부록 A](#부록-a-서버-요청-파라미터-매핑-c2-비교-재료).
  - 근거: V1 `NovelReviewViewModel.swift:134-136` · V2 `NovelReviewMapper.swift:65-89`, `NovelReviewDomain`(`NovelReviewDraft`·`ReadingPeriod.normalized`)

### 2.2 저장 실패 · 중복 저장 가드

- 🔧 **Improve** — **저장 실패를 사용자에게 알린다**. V1은 저장 `onError`가 **`print(error)`뿐**이라, 실패해도 토스트·알럿이 없고 화면도 안 닫혀 사용자는 "완료를 눌렀는데 아무 일도 안 일어난" 상태에 놓인다(조용한 실패 버그).
  - V2: `presentError(error)` → 토스트. 단 사용자에게 친절 문구를 주는 검증 에러는 매력포인트 초과뿐이고, 나머지(네트워크/서버 등)는 `.unknown` 토스트 + 로그.
  - 근거: V1 `NovelReviewViewModel.swift:164-166`(`print(error)`) · V2 `NovelReviewViewModel.swift:264-266`,`279-291`, `CLAUDE.md`(에러 처리 정책)
- ✅ **Keep** — **중복 저장/뒤로가기 방지**. V1은 완료·뒤로가기 버튼에 `throttle(.seconds(3), latest: false)`를 걸었다. V2는 저장 중 `guard !state.isSaving` + **완료 버튼을 스피너로 바꾸고 disabled**, 닫기는 `guard !isClosing`.
  - 관찰 동작(연타로 저장/닫기가 두 번 나가지 않음)은 같다. 수단만 다름(시간 throttle → 진행 플래그).
  - 근거: V1 `NovelReviewViewModel.swift:122-123`,`129-130` · V2 `NovelReviewViewModel.swift:188`,`194-199`, `NovelReviewView.swift:151-160`

### 2.3 생성(POST) vs 수정(PUT) 결정

- 🔧 **Improve** — **결정 주체가 클라이언트 → 서버로 바뀌었다**. V1은 진입 시 리뷰 존재 여부를 **클라이언트가 추정**한다: `isNovelReviewExist = 로드된 data.status != nil || isInterest`. 참이면 PUT(수정), 거짓이면 POST(생성). `isInterest`(관심작 여부)를 리뷰 존재의 대리 신호로 쓴 셈이라, **관심작인데 리뷰는 없는 경우 PUT을 쏘는 위험**이 있다.
  - V2: `isInterest` 개념 없이 **항상 POST를 먼저** 시도하고, 서버가 "이미 리뷰함" 코드(`USER_NOVEL-002`)를 주면 그때 **PUT으로 폴백**한다. 존재 여부를 서버가 권위 있게 판단.
  - 근거: V1 `NovelReviewViewModel.swift:104`,`138-158`(isNovelReviewExist로 put/post 분기) · V2 `DefaultNovelReviewRepository.swift:48-87`, `NovelReviewMapper.swift:91-93`(`isAlreadyReviewed` = `USER_NOVEL-002`)
- ✅ **Keep** — 엔드포인트: 생성 `POST /user-novels`, 수정 `PUT /user-novels/{novelId}`, 조회 `GET /user-novels/{novelId}`.
  - 근거: V1 `WSSiOS/Resource/Constants/URLs/URLs.swift:74-82` · V2 `NovelReviewData/Sources/Endpoint/NovelReviewEndpoint.swift`

### 2.4 저장 부수 작업(앱 리뷰 요청·노티피케이션·분석)

- ❓ **Unknown (헤드라인)** — **저장 성공 후 App Store 리뷰 요청**. V1은 저장 성공 콜백에서 `AppReviewManager.shared.requestReview()`로 **iOS 앱 평점 요청 프롬프트**(StoreKit)를 띄웠다. **V2엔 없다.**
  - **판정 포인트**: 앱 리뷰 요청을 되살릴지(리뷰 남긴 직후가 요청 적기) / 의도적으로 뺀 것인지. (분석·StoreKit 인프라 미이식으로 보이나 근거 미확인.)
  - 근거: V1 `NovelReviewViewModel.swift:163`(`AppReviewManager.shared.requestReview()`) · V2 `NovelReviewViewModel.swift:257-267`(없음)
- 🗑/✅ — **저장 성공 후 다른 화면 갱신**. V1은 `NotificationCenter.post(name: "NovelReviewed")`로 브로드캐스트해 작품 상세 등이 갱신하게 했다. V2는 노티 없이 **화면을 닫고, 복귀한 화면이 `onAppear` 재조회로 갱신**(탭 콘텐츠 갱신 계약)한다.
  - 관찰 동작(리뷰 저장 후 상세의 별점·읽기상태가 갱신됨)은 같은 결이나 **수단이 노티 → 재조회로 바뀌었다**. 상세가 실제로 갱신되는지는 상세 화면 계약과 함께 확인.
  - 근거: V1 `NovelReviewViewModel.swift:161`(`"NovelReviewed"` post) · V2 `NovelReviewViewModel.swift:262-263`, `Feature/CLAUDE.md`(탭 복귀마다 갱신)
- 🗑 **Delete** — **Amplitude 이벤트**. V1은 완료 시 `AmplitudeEvent.Novel.rateNovel`(그리고 키워드 모달의 `contactKeyword`)을 트래킹했다. V2엔 트래킹 코드가 없다.
  - 근거: V1 `NovelReviewViewModel.swift:132`, `NovelKeywordSelectModalViewModel.swift:217` · V2 (트래킹 없음)

---

## 3. 읽기 상태 (보는 중 / 봤어요 / 하차)

- ✅ **Keep** — 3상태를 **가로로 나열해 단일 선택**(탭 전환). 순서 `보는 중 → 봤어요 → 하차`, 선택은 primary 색·채움 아이콘, 미선택은 회색·외곽선 아이콘.
  - V1: `ReadStatus.allCases`(watching/watched/quit) 컬렉션뷰, 선택/해제로 표현.
  - V2: `ReadingStatus.allCases` `ForEach`, `fillImage`/`strokeImage` 틴팅(선택 색 전환에 0.1s 애니메이션).
  - 근거: V1 `ReadStatus.swift:10-45`, `NovelReviewViewController.swift:123-134` · V2 `NovelReviewView.swift:171-205`, `BaseDomain/Sources/ReadingStatus.swift:11-14`
- ✅ **Keep** — 라벨 문구 `보는 중`/`봤어요`/`하차`. (V2는 WSSComponent `DomainPresentation`의 `status.statusName` 재사용.)
  - 근거: V1 `ReadStatus.swift:15-21` · V2 `NovelReviewView.swift:191`(`status.statusName`)
- ✅ **Keep** — 상태를 바꾸면 **기존 날짜가 새 상태에 맞게 정리**된다(하차로 바꾸면 시작일 무의미, 보는중이면 종료일 무의미). V1은 저장 시점에 날짜를 상태로 걸러 보냈고(§2.1), V2는 `changeStatus`가 `period.normalized(for:)`로 즉시 정리한다.
  - 근거: V1 `NovelReviewViewModel.swift:134-135` · V2 `NovelReviewDomain`(`NovelReviewDraft.changeStatus`)

---

## 4. 독서 기간 (날짜 시트)

원본: `…/NovelReviewViewModel/NovelDateSelectModalViewModel.swift`, `…/NovelReviewView/NovelDateSelectModalView.swift`

### 4.1 진입·상태별 입력 형태

- ✅ **Keep** — 기간 라벨(밑줄 텍스트) 탭 → 날짜 선택 시트. **상태별로 입력 형태가 다르다**: 보는중=시작 날짜 1개 / 하차=종료 날짜 1개 / 봤어요=시작·종료를 세그먼트로 전환하며 둘 다.
  - V1: 모달이 `bindData(readStatus:)`로 봤어요만 시작/종료 버튼을 남기고 단일 상태는 제거·제목 표시.
  - V2: 시트가 `status == .watched`에만 세그먼트를 그리고, 단일 상태는 제목 + 휠 1개. (means: UIKit 바텀 모달 + `UIDatePicker` → SwiftUI `.sheet` + 커스텀 휠.)
  - 근거: V1 `NovelDateSelectModalView.swift:106-129`, `NovelDateSelectModalViewModel.swift:53-73` · V2 `ReadingPeriodSheet.swift:52-89`, `CLAUDE.md`(ReadingPeriodSheet UI)
- ✅ **Keep** — 시트 닫기(X)는 **적용 없이 취소**(편집을 버림). "완료"만 선택을 반영.
  - 근거: V1 `NovelDateSelectModalViewModel.swift:76-80`(close → dismiss만), `:138-143`(complete → 노티+dismiss) · V2 `ReadingPeriodSheet.swift:67-70`,`104-113`

### 4.2 미래 차단 · 순서 보정 · 삭제

- ✅ **Keep** — **미래(오늘 이후) 날짜는 못 고른다**. V1은 datePicker 변경값이 `Date()`보다 미래면 직전값으로 되돌린다. V2는 휠 `maxDate`(오늘 자정) + 오버슈트→정착→되돌림.
  - 근거: V1 `NovelDateSelectModalViewModel.swift:98-136`(`isFutureDate`) · V2 `ReadingPeriodSheet.swift:41`, `WSSDateWheel.swift`, `CLAUDE.md`(미래 날짜 차단)
- ✅ **Keep** — **봤어요 시작/종료 순서 보정**: 시작이 종료보다 미래면 종료를 시작에 맞추고, 종료가 시작보다 과거면(편집 중인 쪽 기준으로) 끌어다 맞춘다.
  - V1: datePicker 변경 로직이 `startDate > endDate` 시 상호 보정(하차는 종료<시작이면 시작=종료).
  - V2: `applyEditedDate`가 포커스(field) 기준으로 같은 보정. (V2는 하차 결과가 `(nil, end)`라 시작/종료 충돌 자체가 없다 — 더 단순.)
  - 근거: V1 `NovelDateSelectModalViewModel.swift:103-134` · V2 `ReadingPeriodSheetViewModel.swift:105-120`,`46-52`
- ✅ **Keep** — **"날짜 삭제"로 기간을 비운다**. V1 remove 버튼 → `NovelReviewDateRemoved` 노티 → 시작·종료 nil. V2 "날짜 삭제" → `onApply(nil, nil)` → `setPeriod(nil)`.
  - 근거: V1 `NovelDateSelectModalViewModel.swift:145-150`, `NovelReviewViewModel.swift:255-261` · V2 `ReadingPeriodSheet.swift:73-82`, `NovelReviewViewModel.swift:145-149`
- ✅ **Keep** — 기간 표시: 비어 있으면 `본 날짜 추가`, 채워지면 `yy년 M월 d일`(상태에 맞는 쪽만; 봤어요는 `시작 ~ 종료`).
  - V1: 라벨 기본 `본 날짜 추가`, `bindData`가 상태별로 한쪽을 blank 처리해 `시작 ~ 종료` 표기.
  - V2: `periodValueLabel`이 `start`/`end` 존재 여부로만 분기(둘 다=기간, 하나=단일), 빈 값이면 `본 날짜 추가`. 포맷 `yy년 M월 d일` **동일**.
  - 근거: V1 `NovelReviewStatusView.swift:58-61`(포맷),`86-108`(blank 처리), `StringLiterals+Novel.swift:103`(`본 날짜 추가`) · V2 `NovelReviewView.swift:226-238`, `ReviewDateFormatter.swift:14-20`

---

## 5. 별점

- ✅ **Keep** — 별 5개, **0.5 단위** 점수. 탭/드래그로 부여하고, **0점 = 평점 없음**(별점을 지운 상태로 저장 가능).
  - V1: 탭은 최소 0.5(`index + 0.5/1.0`), 팬(드래그)은 0.0까지 내려가 클램프(`min/max 0.0~5.0`). 채움/반쪽/빈 이미지 교체.
  - V2: `DragGesture(minimumDistance: 0)` 하나로 탭·드래그를 함께 처리(0.5 단위 올림), 0.0은 도메인 `Rating`(0.5~5.0)이 표현 못 하므로 **`nil`(평점 없음)으로 매핑**.
  - 근거: V1 `NovelReviewViewModel.swift:184-201`, `NovelReviewRatingView.swift:97-113` · V2 `StarRatingView.swift:51-70`, `NovelReviewViewModel.swift:160-170`, `CLAUDE.md`(평점 0.0↔nil)
- ✅ **Keep** — 로드된 리뷰의 별점이 0이면 별을 빈 상태로 시작(초기 미평가와 구분 없이 0). V1 서버 `userNovelRating` 0.0 = 빈 별, V2 매퍼가 `0.0 → nil`.
  - 근거: V1 `NovelReviewViewModel.swift:110`, `NovelReviewRatingView.swift:83-95` · V2 `NovelReviewMapper.swift:28`

---

## 6. 매력 포인트

- ✅ **Keep** — 매력포인트 6종을 토글하고, **최대 3개**까지만 선택된다. 4번째를 누르면 선택되지 않고 **"3개까지 선택 가능" 토스트**(`selectionOverLimit(count: 3)`)를 띄운다. 이미 선택된 걸 다시 누르면 해제.
  - V1: `selectedAttractivePointList.count >= 3`이면 `isAttractivePointCountOverLimit` 방출 → `showToast(.selectionOverLimit(count: 3))`.
  - V2: 도메인 `NovelReviewDraft.addAttractivePoint`가 `maxAttractivePoints(3)` 초과 시 `throw` → `presentError` → 토스트(같은 타입).
  - 근거: V1 `NovelReviewViewModel.swift:203-217`, `NovelReviewViewController.swift:165-169` · V2 `NovelReviewViewModel.swift:174-184`, `NovelReviewDraft.swift:23`,`65-73`, `NovelReviewView.swift:343-347`
- ✅ **Keep** — 라벨 문구 6종(세계관·소재·필력·캐릭터·관계·분위기)과 서버 토큰(`worldview`·`material`·`writingskill`·`character`·`relationship`·`vibe`)이 동일. (V2 표시명은 WSSComponent `DomainPresentation`.)
  - 근거: V1 `AttractivePoint.swift:10-40` · V2 `NovelReviewMapper.swift:193-204`(토큰), `NovelReviewView.swift:285`(`point.displayName`)
- ❓ **Unknown** — **가로 배열 순서가 다르다**. V1 `AttractivePoint.allCases` = `worldview·material·writingSkill(필력)·character·relationship·vibe`. V2 = `worldview·material·character·relationship·vibe·writingSkill(필력 마지막)`. 둘 다 `allCases`를 그대로 나열하므로 **6개 버튼의 나열 순서(특히 필력 위치)가 다르게 보인다**.
  - **판정 포인트**: V2가 `AttractivePoint` enum을 재정렬(필력 마지막)한 결과가 리뷰 화면에도 반영된 것 — 의도된 순서인지(서재 필터는 "필력 마지막" 로컬 배열을 쓴다는 기록이 있으나 이 화면 순서에 대한 명문 근거는 없음) / 간과된 것인지.
  - 근거: V1 `AttractivePoint.swift:10-16`(allCases 순서), `NovelReviewAttractivePointView.swift:19-20`(allCases 나열) · V2 `BaseDomain/Sources/AttractivePoint.swift:12-17`, `NovelReviewView.swift:267`(allCases 나열)

---

## 7. 키워드

원본: `…/NovelReviewViewModel/NovelKeywordSelectModalViewModel.swift`, `…/NovelReviewViewController/NovelKeywordSelectModalViewController.swift`

- ❓ **Unknown (헤드라인)** — **V2는 키워드 선택/탐색이 통째로 미구현이다**. V1은 키워드 검색바 탭 → **키워드 선택 모달**을 present했다:
  - `/keywords` 검색(카테고리 목록 + 텍스트 검색 결과), **최대 20개** 선택, 초과 시 토스트, "초기화", 결과 없을 때 빈 뷰, **문의하기**(외부 링크 + `contactKeyword` 트래킹).
  - "선택" 시 `NovelReviewKeywordSelected` 노티로 메인에 돌려주고, 메인은 선택 칩을 컬렉션뷰로 표시하며 **칩 탭 시 개별 제거**.
  - 저장 시 `keywordIds`(키워드 정수 ID 배열)를 실어 보냈다.
  - **V2 현황**: 메인 화면에 `WSSSearchBarButton`(검색바 룩) 하나만 배치, **탭 액션이 `print`뿐**이고 `draft.keywords`에 연결되지 않았다. 도메인엔 `NovelReviewDraft.keywords`·`setKeywords`(최대 20, 중복 금지)와 매퍼의 `keywordIds` 매핑이 **준비돼 있으나 화면이 안 씀** → 저장 시 `keywordIds`가 **항상 빈 배열**로 나간다(로드된 키워드도 화면에 안 뜨고, 저장 시 소실될 수 있음).
  - **판정 포인트**: 키워드 선택 화면(모달 또는 별도 탐색뷰)을 붙이고 `draft.keywords`에 연결하는 후속 작업. V2 `CLAUDE.md`가 "키워드 선택/탐색뷰 미연결(TODO)"로 명시 → **의도된 미완성**이지 회귀는 아님(다만 그때까지 키워드 저장이 비어 나가는 부작용 확인 필요).
  - 근거: V1 `NovelKeywordSelectModalViewModel.swift:21`(최대 20),`163-224`(선택/문의/초기화), `NovelReviewViewModel.swift:136`(`keywordIds`),`219-244`(모달 왕복·칩) · V2 `NovelReviewView.swift:303-319`(TODO), `NovelReviewMapper.swift:75`,`87`(빈 배열 매핑), `NovelReviewDraft.swift:79-92`, `CLAUDE.md`(현재 범위·미연결)

---

## 8. 뒤로가기·중단 알럿

- 🔧 **Improve** — **중단 알럿 조건**. V1은 뒤로가기 시 **변경 여부와 무관하게 항상** "평가를 그만할까요?" 알럿을 띄운다(아무것도 안 고쳤어도 뜬다). V2는 **초안이 실제로 바뀌었을 때만**(`hasUnsavedChanges = draft != baselineDraft`) 알럿을 띄우고, 변경이 없으면 곧장 닫는다.
  - 근거: V1 `NovelReviewViewModel.swift:122-127`(back → 무조건 `showStopReviewingAlert`) · V2 `NovelReviewViewModel.swift:193-206`,`72-74`
- ✅ **Keep** — 알럿 문구·버튼: 제목 "평가를 그만할까요?", 버튼 **"그만하기"(닫기) / "계속 작성"(머무름)**. "그만하기"만 화면을 닫는다.
  - V1: `StringLiterals.NovelReview.Alert`(titleText/stopTitle/writeTitle), 왼쪽(그만하기) → pop.
  - V2: `WSSAlertType.stopNovelReview`, `.confirmStop`(닫기)/`.keepWriting`(머무름).
  - 근거: V1 `NovelReviewViewController.swift:189-203`, `StringLiterals+Novel.swift:131-134` · V2 `NovelReviewView.swift:73-80`, `NovelReviewViewModel.swift:209-219`
- ✅ **Keep** — **로드 중 뒤로가기**는 로드 완료를 기다리지 않고 즉시 닫기 흐름을 탄다(진행 중 로드는 취소).
  - V1: back throttle만 있을 뿐 로드와 독립(로드가 늦게 와도 pop됨). V2: `requestClose`가 로드 중이면 `close()`로 직행하며 `loadTask.cancel()`.
  - 근거: V1 `NovelReviewViewModel.swift:122-127` · V2 `NovelReviewViewModel.swift:193-199`,`214-219`

---

## 9. 로딩·구조 메모

- ✅ **Keep(값 없음 → V2 신규)** — V1엔 리뷰 화면의 **전면 로딩 인디케이터가 없다**(진입 즉시 폼을 그리고 로드 결과를 채움). V2는 `state.isLoading` 동안 `ProgressView` 오버레이를 띄운다(로드 중 편집 방지).
  - 근거: V1 `NovelReviewViewController.swift:43-52`(로딩 뷰 없음) · V2 `NovelReviewView.swift:44-48`
- ✅ **Keep** — 화면 구조: 헤더(뒤로가기 + 완료) 아래 세로 스크롤에 **읽기상태 / 별점 / 매력포인트 / 키워드** 섹션을 구분선으로 나눠 쌓는다.
  - V1: `UIScrollView` + `UIStackView`(spacing 1, `wssGray50` 배경 = 구분선 효과).
  - V2: `ScrollView` + `VStack`, 섹션 사이 `sectionDivider`(1pt `wssGray50`).
  - 근거: V1 `NovelReviewView.swift:69-88` · V2 `NovelReviewView.swift:91-124`

---

## 부록 A. 서버 요청 파라미터 매핑 (C2 비교 재료)

리뷰 조회 `GET /user-novels/{id}`, 생성 `POST /user-novels`, 수정 `PUT /user-novels/{id}`. **요청 바디 필드가 V1↔V2 동일**하다(대부분 ✅ Keep). C2에서 이 매핑을 테스트로 고정할 후보.

| 필드 | V1 전송 규칙 | V2 전송 규칙 | 상태 |
|---|---|---|---|
| `novelId` (POST) | 인자 | `draft.novelID.value` | ✅ Keep |
| `userNovelRating` | `Float`(0.0=미평가) | `Float(rating?.value ?? 0.0)` — nil→0.0 | ✅ Keep |
| `status` | `ReadStatus.rawValue`(`WATCHING`/`WATCHED`/`QUIT`) | `readingStatusString`(동일 토큰) | ✅ Keep |
| `startDate` | 하차면 `nil`, 아니면 `yyyy-MM-dd` | `period?.start`를 `yyyy-MM-dd`(normalize가 하차 시작을 이미 제거) | ✅ Keep |
| `endDate` | 보는중이면 `nil`, 아니면 `yyyy-MM-dd` | `period?.end`를 `yyyy-MM-dd`(normalize가 보는중 종료를 이미 제거) | ✅ Keep |
| `attractivePoints` | 선택 `rawValue` 배열(최대 3) | `attractivePointString` 배열(동일 토큰) | ✅ Keep |
| `keywordIds` | 선택 키워드 `keywordId` 배열(최대 20) | `keywords.map{$0.id.value}` — **화면 미연결이라 현재 항상 `[]`** | ❓ (§7) |
| POST vs PUT | 클라 추정(`status!=nil \|\| isInterest`) | POST 먼저 → `USER_NOVEL-002`면 PUT 폴백 | 🔧 Improve (§2.3) |

- 조회 응답 필드(`NovelReviewResult`): `novelTitle`·`status?`·`startDate?`·`endDate?`·`userNovelRating`·`attractivePoints`·`keywords`. V2 `NovelReviewResponse`와 동형이며 `status`가 nil이면 "초안 없음"(POST 대상)으로 본다. ✅ Keep.
- 날짜 포맷 `yyyy-MM-dd` / `ko_KR` / 서울 타임존은 양쪽 동일(V1 `dateFormatter`, V2 `DateParser`). ✅ Keep.
- 근거: V1 `NovelReviewResult.swift:10-37`, `NovelReviewViewModel.swift:129-158`, `NovelReviewService.swift:31-102` · V2 `NovelReviewMapper.swift:15-93`, `NovelReviewData/Sources/DTO/*`, `DefaultNovelReviewRepository.swift:53-87`
