<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙·State/Action 골격)와 함께 자동 로드됨. -->
# NovelReviewFeature

작품 평가(리뷰 초안) 화면. **프로젝트의 첫 Feature 모듈**로 레이어 가이드의 State/Action 골격을 처음 적용했다.
일반 패턴은 레이어 가이드를 따르고, 여기엔 이 모듈 고유의 함정·결정만 적는다.

- 식별자: `ModuleType.feature(.novelReview)` / 의존: `BaseDomain`, `NovelReviewDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- **진입점: `NovelReviewFeatureFactory.makeView(novelID:title:status:loadUseCase:saveUseCase:logger:onAuthenticationRequired:keywordSearchSheet:)`** (`logger`는 옵셔널·nil 기본값)
  - **`title`(네비게이션 타이틀)·`status`(초기 읽기 상태)는 진입 이전 화면이 주입**한다 — 이 화면은 네비게이션으로만 진입하므로 호출자가 아는 값(작품명·진입 시점의 읽기 상태)을 넘긴다(Feature가 자체 보유 ❌). `status`는 `NovelReviewDraft`의 초기 상태를 seed한다.
  - **`onAuthenticationRequired()`**: 인증 만료 시 로그인 유도 콜백(이 화면의 유일한 상위 위임 콜백). 화면 전환은 호출자(App)가 수행 — 현재 소비처는 Demo 로그뿐(실제 로그인 화면·App 라우팅 미구현, 후속).
  - **`keywordSearchSheet: KeywordSearchSheetBuilder`**(`Sources/Navigation/`, public seam) — 키워드 탐색 시트 콘텐츠. 이 모듈은 `KeywordFeature`를 모르므로(Feature 간 직접 의존 금지) App이 `KeywordFeatureFactory.makeSearchKeywordView`로 조립한 `AnyView`를 값으로 넘긴다. `SearchFeature`의 `KeywordTabContentBuilder`와 같은 형태·같은 이유 — 자세한 건 아래 "주의사항" 참고.

### 파일 구조 — 화면(영역)별 그룹
`Sources/`는 화면 단위로 폴더를 나눈다(타입별 View/ViewModel 분리 ❌). 각 화면 전용 컴포넌트는 그 폴더에 동거.
- `Factory/NovelReviewFeatureFactory.swift` — 유일한 public 진입점.
- `NovelReview/` — 메인 화면: `NovelReviewView` + `NovelReviewViewModel` + `StarRatingView`(별점 입력).
- `ReadingPeriodSheet/` — 기간 시트: `ReadingPeriodSheet`(View) + `ReadingPeriodSheetViewModel` + `WSSDateWheel`(휠).
- `Support/` — 모듈 공용 유틸: `ReviewDateFormatter`(기간/segment 날짜 포맷터).

## 도메인 위임 (얇은 ViewModel)

- `state.draft`(`NovelReviewDraft`)에 상태·정책을 위임한다. 비즈니스 규칙은 엔티티에 있다 — **읽기 상태 단일 선택, 매력 포인트 최대 3개**(초과 시 `throws` → `handle`이 `state.errorMessage`로 변환).
- ViewModel은 **의미값만** 노출(`state.draft.rating`/`period`/`status`). **카피·포맷·빈상태 문구는 View 몫**(날짜 `yyyy.MM.dd`, `~` 구분자, "평점 없음"/색). 표시 문자열을 테스트로 고정할 필요가 생기면 그때만 Formatter로 분리(현재 불필요).

## 현재 범위

**읽기 상태 + 독서 기간(sheet) + 평점(슬라이더) + 매력 포인트 토글 + 키워드(sheet) + 진입 시 로드 + 완료 시 저장**. 저장 성공 시 `state.shouldDismiss = true`로 닫힘을 신호.
- 키워드는 `WSSSearchBarButton` 탭 → `keywordSearchSheet`(App 주입)가 만드는 시트. 선택은 실시간으로 `draft.keywords`에 반영되고(`.setKeywords`), 칩(`WhiteRemovableKeywordChip` + `WSSFlowLayout`)으로 표시·개별 삭제(`.removeKeyword`) 가능.
- 미연결: 삭제(`DeleteNovelReviewUseCase`).

## 주의사항 (작업 중 발견 시 누적)

#### 저장 성공 시 앱스토어 평점 요청 (#221 재도입)
- `saveDraft()` 성공 직후 `recordEngagementAndGateReview()`가 `AppReviewRequestUseCase`(BaseDomain, **피드와 공유** → 앱 전역 게이트)에 참여를 기록하고, 게이트(누적 참여 ≥ 임계치 AND 이번 버전 미요청) 통과 시 `state.shouldRequestReview = true`. 실제 프롬프트는 `NovelReviewView`가 `import StoreKit` + `@Environment(\.requestReview)`로 띄운다.
- ⚠️ **`shouldDismiss`를 리뷰 트리거로 쓰면 안 된다** — `close()`(취소/뒤로가기)에도 켜지므로, 저장 성공 경로에서만 세우는 **별도 `shouldRequestReview` 플래그**를 둔다. `NovelReviewView`의 `shouldDismiss` onChange에서 `dismiss()`보다 먼저 `if shouldRequestReview { requestReview() }`를 부른다(pop 후에도 정상 표시, 시뮬레이터로 저장→프롬프트 / 취소→프롬프트 없음 양쪽 실측 확인). V1은 성공마다 무조건 호출했으나 "무분별 호출 금지"로 게이트를 얹었다.

#### 에러 처리 정책 (표현이 셋으로 분화됨)
에러 종류마다 표현이 다르다 — 한 catch가 다 받지 않는다:
- **초안 로드 실패(`loadDraft`) → 전면 실패 뷰**(`NetworkErrorView`, 재시도). `state.loadFailed` 플래그를 세우고 View가 overlay로 띄운다. 로드 실패는 `presentError`(토스트)를 **거치지 않는다** — 토스트까지 띄우면 시그널 이중화. "초안 없음(nil)=정상"과 구별해야 해서 draft 유무가 아니라 별도 플래그로 판단(NovelDetail의 `information==nil` 대신). 실패 뷰가 뜬 동안 툴바 "완료"는 disabled(빈/초기 draft 저장 차단).
- **저장·검증 실패 → 토스트**(`presentError`). 사용자에게 정상적으로 보여줄 검증 에러는 매력 포인트 초과(`tooManyAttractivePoints`) 하나뿐. 나머지(네트워크/서버/notFound/기간/평점)는 UI·도메인 가드(휠 미래 차단, 순서 보정, 슬라이더 범위, 단일 선택 등)가 **이미 입력단에서 막아 도달하면 안 되는 경로** → `.unknown`으로 묶어 `logger?.error(...)`로 원인만 남긴다. 케이스별 친절 문구를 다시 늘리지 말 것(가드가 뚫린 거라 문구보다 로그가 중요).
- ⚠️ **인증 만료(`authenticationRequired`) → 로그인 라우팅**(어느 catch든 공통). `routeToLoginIfAuthenticationRequired`가 감지해 `state.requiresAuthentication` 신호만 세우고(토스트·실패 뷰 생략), View가 `onChange`로 소비해 `onAuthenticationRequired` 콜백을 발화(`shouldDismiss`→`dismiss`와 대칭). **로드 catch는 직접 호출**하고(전면 실패 뷰보다 먼저 체크), 저장·검증은 `presentError` 첫 줄이 대신 호출한다 — 두 경로 모두 인증을 먼저 걸러낸다. NovelDetail과 동일 배관.
- **표현은 토스트**(알럿 ❌). `WSSToastViewModifier`(`.showWSSToast`)로 띄운다. 단, **VM은 의미값(`State.ReviewError`)만** 노출하고 **토스트 타입 매핑은 View**가 한다(얇은 ViewModel) — `attractivePointLimit→.selectionOverLimit`, `unknown→.unknownError`. 새 에러 표기가 필요하면 `WSSToastType`에 케이스를 더한다(문구는 `WSSToastStyle`).

#### 도메인 값 매핑
- **평점**: 도메인 `Rating`은 0.5~5.0(0.5 단위)만 허용하고 0.0을 표현 못 한다 → 슬라이더의 0.0을 **`nil`(평점 없음)로 매핑**한다. "평점 없음 ↔ 0.0"은 이 규칙이라 임의 변경 ❌.
- **독서 기간** 상태↔날짜 매핑(watching=시작, watched=시작+종료, quit=종료)은 도메인 `ReadingPeriod.normalized(for:)`가 강제한다.
  - 표시: status로 분기하지 말 것 — normalize가 상태에 맞는 날짜만 채우므로 **`start`/`end` 존재 여부로만** 표기(둘 다=기간, 하나=단일).
  - 입력: `ReadingPeriodSheet.apply()`는 폼대로 의미 있는 날짜만 넘긴다. 단일 상태에 양쪽 날짜를 넘기면 `ReadingPeriod(start:end:)`가 `startAfterEnd`로 **오검증**한다.

#### ReadingPeriodSheet UI
- 시트는 부모와 별개인 자체 **`ReadingPeriodSheetViewModel`(순수 입력 VM)** 을 가진다 — 비동기·UseCase·콜백 없이 상태와 파생값(`editingDate`, `result`)만 노출한다. watched의 시작/종료 **순서 보정**(`applyEditedDate`)은 *도메인 규칙이 아니라 포커스에 달린 입력 UX 정책*이라 이 VM에 산다.
  - **결과 발화는 View가 한다**(VM은 콜백을 들지 않음 — `shouldDismiss` 식 관습과 일관). "완료"=`viewModel.result`를, "날짜 삭제"=`(nil, nil)`을 부모 `onApply`로 넘기면 부모가 `updatePeriod` + dismiss.
  - **시트는 `ReadingPeriod`를 만들거나 normalize하지 않는다** — raw `(Date?, Date?)`만 올린다. 도메인 생성·검증은 status를 가진 draft가 `setPeriod`에서 단독 수행(미래는 휠이, `start>end`는 순서 보정이 이미 예방).
- 높이는 `presentationDetents`로 고정: 단일(watching/quit) **320**, 시작+종료(watched) **394**.
- watched의 field 전환 시 `WSSDateWheel`이 `editingDateBinding`(=`date`) 변화를 `onChange`로 감지해 스스로 컬럼을 재정렬한다(`syncColumns`). 내부 스크롤발 `date` 변경은 컬럼값과 같아 early-return으로 되먹임 루프를 막는다.
  - ⚠️ **`.id(field)`로 휠을 재생성하지 말 것.** 새 `ScrollView`가 `scrollPosition` 미적용 상태(맨 위)로 한 프레임 그려진 뒤 `onAppear`의 async `scrollTo`로 점프해 **번쩍인다**. 직접 겪고 폐기 — 되살리지 말 것.

#### WSSDateWheel — 연·월·일 3열 커스텀 휠
네이티브 `DatePicker(.wheel)`은 체크/회색 룩이 안 나와, **iOS 17 ScrollView 스냅 API**(`scrollTargetBehavior(.viewAligned)` + `scrollPosition(id:)` + `contentMargins`)로 가운데 정렬값을 선택값으로 삼는 휠을 직접 구현했다.

##### 미래 날짜 차단 (오버슈트→정착→되돌림)
- **미래(오늘 이후)는 못 고른다.** `maxDate`(= sheet가 넘기는 오늘) 기준.
- ⚠️ **스크롤 "도중에" 클램프 금지.** 플링 중 상태를 오늘로 되돌리면 iOS 관성과 싸워 멈칫거리다 결국 미래값에 멈춘다(상태/물리 위치 어긋남). 직접 겪고 폐기한 방식 — 되살리지 말 것.
- **채택한 방식**: 미래로 굴러가는 건 허용하되 ① 그동안 `date`(세그먼트 표시 소스)를 **갱신하지 않고**, ② `settleTask`(약 0.2s 디바운스)로 스크롤 **정착을 감지한 뒤에야** 직전 선택값으로 되돌린다(플링 중엔 계속 재예약돼 발동 안 함 = 관성과 안 싸움).
- **되돌림 목적지는 오늘이 아니라 "직전 유효 선택값"**이다. 오버슈트 중 `date`를 갱신하지 않으므로 `date`가 곧 직전값 → `bounceBackToLastValid`가 컬럼을 `date`로 재정렬. (신규 입력이라 직전값이 없으면 init 기본값 `Date()`=오늘로 복귀.)
- **물리 스크롤 되돌림은 `.scrollPosition(id:)`만으론 안 먹는다.** `bounceToken`을 증가시켜 `WheelColumn`의 `onChange(bounceToken)`에서 **`proxy.scrollTo(selection)`로 강제 정렬**해야 화면이 따라온다.
- 연도 컬럼은 `years = 1900...maxDate연도`로 막아 **미래 연도 자체를 못 굴린다**. 월/일만 오버슈트→바운스 대상.
- 도메인 `ReadingPeriod` 생성자가 미래 날짜를 **거부(불변식)** → Data 매퍼(`NovelMapper`)는 서버 미래 데이터에 **로드 실패(fail-loud)**. 휠 `maxDate` + sheet는 *사용자 입력단*의 예방선(서로 다른 경계).

#### 로드 생명주기
- `onAppear`에서 `handle(.load)`로 호출. 초안이 없으면(nil) 기본 draft를 유지한다(덮어쓰지 않음).
- **로드는 최초 1회만**(`hasLoaded` 가드). `onAppear`는 재진입마다 불리므로, 가드 없으면 편집 중 draft를 서버 값으로 덮어쓴다.

#### Demo 빌드
- `.demo` 타깃이 있어 `NovelReviewFeature` 스킴이 Demo 앱까지 함께 빌드한다. **검증은 시뮬레이터 대상 워크스페이스 스킴으로** 할 것 — 실기기(`generic/platform=iOS`)는 Demo 앱 코드 서명을 요구하고, 단일 `-target ...Demo`는 교차 모듈 의존을 못 풀어 실패한다.

#### 키워드 탐색 시트 (2026-08, 과거 한 차례 되돌려졌다가 재설계)
- **`SearchKeywordView`(App이 주입) 자신은 하단 액션바가 없다** — `onSelectionChanged`로 선택을 실시간 보고만 하고 확인/닫기 UI를 안 갖는다. 그래서 `NovelReviewView`가 그 콘텐츠를 감싸 하단에 `WSSCTAButton("완료")`를 직접 얹는다 — 이 "완료"는 **확정이 아니라 닫기 그 자체**다(선택은 이미 실시간으로 `draft.keywords`에 반영돼 있으므로, 시트를 스와이프로 내려도 선택은 그대로 유지된다).
- **`.setKeywords`(전체 교체)와 `.removeKeyword`(단건 제거)를 용도로 나눠 쓴다** — 시트의 실시간 보고는 매번 선택 전체 배열을 주므로 `setKeywords`(도메인이 중복·최대개수를 검증), 화면에 그려진 칩의 X 삭제는 `removeKeyword`(단건, throw 없음)로 처리한다. 최대 개수(20)는 시트(`SearchKeywordViewModel.maxSelectionCount`)가 이미 막고 있어 `setKeywords`의 `tooManyKeywords` throw는 원래 도달하면 안 되는 경로 — 걸리면 `.unknown` 토스트 + 로그로만 남긴다(다른 에러들과 동일 정책).
- **`Sources/Navigation/KeywordSearchSheetBuilder.swift`가 이 모듈의 유일한 조립 seam**이다(`SearchFeature`의 `KeywordTabContentBuilder`와 형태·이유 동일 — Feature 간 직접 의존 금지라 App이 `AnyView`로 조립해 값으로 건넨다). arch-lint `feature-exclusivity`가 이 폴더의 public만 `*Factory` 외 예외로 허용한다.
- **Demo도 `KeywordFeature`를 알아야 시트를 실제로 띄워볼 수 있다** — `Project.swift`의 `demoDependencies`에 `.module(.feature(.keyword))`를 추가했다(Sources는 여전히 모른다). `NovelReviewFeatureDemoApp`은 Mock/실서버 두 모드 각각 별도 키워드 UseCase(Mock=인메모리 `DemoLoadTotalKeywordsUseCase`/`DemoSearchKeywordsUseCase`, 실서버=`KeywordDataFactory.makeRepository`)를 조립해 `keywordSearchSheet`로 넘긴다 — `SearchFeatureDemoApp`의 동일 패턴.
- **App 쪽 조립은 `NovelReviewAssembly`(App/Sources/Novel/) 한 곳에서만** 한다 — 홈/피드/서재/마이 4개 탭 Root가 전부 이 Assembly를 통해 진입하므로, `keywordSearchSheet` 빌더를 Assembly 내부에 두면 호출부 4곳을 손대지 않고 한 번에 배선된다(`AppDependencies.keywordRepository` 재사용, Home 상세탐색 키워드 탭과 동일 UseCase).
