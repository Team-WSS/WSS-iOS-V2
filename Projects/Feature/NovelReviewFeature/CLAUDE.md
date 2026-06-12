<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙·State/Action 골격)와 함께 자동 로드됨. -->
# NovelReviewFeature

작품 평가(리뷰 초안) 화면. **프로젝트의 첫 Feature 모듈**로 레이어 가이드의 State/Action 골격을 처음 적용했다.
일반 패턴은 레이어 가이드를 따르고, 여기엔 이 모듈 고유의 함정·결정만 적는다.

- 식별자: `ModuleType.feature(.novelReview)` / 의존: `BaseDomain`, `NovelReviewDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- **진입점: `NovelReviewFactory.makeView(novelID:title:loadUseCase:saveUseCase:logger:)`** (`logger`는 옵셔널·nil 기본값)
  - **`title`(네비게이션 타이틀)은 진입 이전 화면이 주입**한다 — 이 화면은 네비게이션으로만 진입하므로 제목(작품명)은 호출자가 아는 값을 넘긴다(Feature가 자체 보유 ❌).

### 파일 구조 — 화면(영역)별 그룹
`Sources/`는 화면 단위로 폴더를 나눈다(타입별 View/ViewModel 분리 ❌). 각 화면 전용 컴포넌트는 그 폴더에 동거.
- `Factory/NovelReviewFactory.swift` — 유일한 public 진입점.
- `NovelReview/` — 메인 화면: `NovelReviewView` + `NovelReviewViewModel` + `StarRatingView`(별점 입력).
- `ReadingPeriodSheet/` — 기간 시트: `ReadingPeriodSheet`(View) + `ReadingPeriodSheetViewModel` + `WSSDateWheel`(휠).
- `Support/` — 모듈 공용 유틸: `ReviewDateFormatter`(기간/segment 날짜 포맷터).

## 도메인 위임 (얇은 ViewModel)

- `state.draft`(`NovelReviewDraft`)에 상태·정책을 위임한다. 비즈니스 규칙은 엔티티에 있다 — **읽기 상태 단일 선택, 매력 포인트 최대 3개**(초과 시 `throws` → `handle`이 `state.errorMessage`로 변환).
- ViewModel은 **의미값만** 노출(`state.draft.rating`/`period`/`status`). **카피·포맷·빈상태 문구는 View 몫**(날짜 `yyyy.MM.dd`, `~` 구분자, "평점 없음"/색). 표시 문자열을 테스트로 고정할 필요가 생기면 그때만 Formatter로 분리(현재 불필요).

## 현재 범위

**읽기 상태 + 독서 기간(sheet) + 평점(슬라이더) + 매력 포인트 토글 + 키워드(진입 버튼) + 진입 시 로드 + 완료 시 저장**. 저장 성공 시 `state.shouldDismiss = true`로 닫힘을 신호.
- 키워드는 `WSSSearchBarButton`(검색바 룩 탭 버튼)만 배치 — **탭 액션은 TODO(키워드 탐색뷰 이동)**, draft.keywords 연결도 아직.
- 미연결: 키워드 선택/탐색뷰, 삭제(`DeleteNovelReviewUseCase`).

## 주의사항 (작업 중 발견 시 누적)

#### 에러 처리 정책 (`presentError` → 토스트)
- **사용자에게 정상적으로 보여줄 검증 에러는 매력 포인트 초과(`tooManyAttractivePoints`) 하나뿐.** 나머지(네트워크/인증/서버/notFound/기간/평점)는 UI·도메인 가드(휠 미래 차단, 순서 보정, 슬라이더 범위, 단일 선택 등)가 **이미 입력단에서 막고 있어 도달하면 안 되는 경로**다. → `.unknown`으로 묶어 `logger?.error(...)`로 원인을 남기고 일반 토스트만 띄운다. 케이스별 친절 문구를 다시 늘리지 말 것(가드가 뚫린 거라 문구보다 로그가 중요).
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
- **채택한 방식**: 미래로 굴러가는 건 허용하되 ① 그동안 `date`(세그먼트 표시 소스)를 **갱신하지 않고**, ② `settleTask`(약 0.13s 디바운스)로 스크롤 **정착을 감지한 뒤에야** 직전 선택값으로 되돌린다(플링 중엔 계속 재예약돼 발동 안 함 = 관성과 안 싸움).
- **되돌림 목적지는 오늘이 아니라 "직전 유효 선택값"**이다. 오버슈트 중 `date`를 갱신하지 않으므로 `date`가 곧 직전값 → `bounceBackToLastValid`가 컬럼을 `date`로 재정렬. (신규 입력이라 직전값이 없으면 init 기본값 `Date()`=오늘로 복귀.)
- **물리 스크롤 되돌림은 `.scrollPosition(id:)`만으론 안 먹는다.** `bounceToken`을 증가시켜 `WheelColumn`의 `onChange(bounceToken)`에서 **`proxy.scrollTo(selection)`로 강제 정렬**해야 화면이 따라온다.
- 연도 컬럼은 `years = 1900...maxDate연도`로 막아 **미래 연도 자체를 못 굴린다**. 월/일만 오버슈트→바운스 대상.
- 도메인 `ReadingPeriod` 생성자가 미래 날짜를 **거부(불변식)** → Data 매퍼(`NovelMapper`)는 서버 미래 데이터에 **로드 실패(fail-loud)**. 휠 `maxDate` + sheet는 *사용자 입력단*의 예방선(서로 다른 경계).

#### 로드 생명주기
- `onAppear`에서 `handle(.load)`로 호출. 초안이 없으면(nil) 기본 draft를 유지한다(덮어쓰지 않음).
- **로드는 최초 1회만**(`hasLoaded` 가드). `onAppear`는 재진입마다 불리므로, 가드 없으면 편집 중 draft를 서버 값으로 덮어쓴다.

#### Demo 빌드
- `.demo` 타깃이 있어 `NovelReviewFeature` 스킴이 Demo 앱까지 함께 빌드한다. **검증은 시뮬레이터 대상 워크스페이스 스킴으로** 할 것 — 실기기(`generic/platform=iOS`)는 Demo 앱 코드 서명을 요구하고, 단일 `-target ...Demo`는 교차 모듈 의존을 못 풀어 실패한다.
