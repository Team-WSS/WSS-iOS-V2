<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelReviewFeature

작품 평가(리뷰 초안) 화면. **프로젝트의 첫 Feature 모듈** — 이후 Feature는 여기 패턴을 따른다.

- 식별자: `ModuleType.feature(.novelReview)` / 의존: `BaseDomain`, `NovelReviewDomain`, `DesignSystem`, `WSSComponent`
- **진입점: `NovelReviewFactory.makeView(novelID:title:loadUseCase:saveUseCase:)`** — 유일한 public API.
  opaque `some View`로 반환해 View/ViewModel을 `internal`로 감춘다. **UseCase(프로토콜)는 외부가 주입**한다
  (Feature는 Repository/Data 구현을 모름 → App이 조립, `Demo/`는 인메모리 Mock 주입).
  - **`title`(네비게이션 타이틀)은 진입 이전 화면이 주입**한다. 이 화면은 네비게이션으로만 진입하므로
    제목(예: 작품명)은 호출자가 아는 값을 넘긴다 — Feature가 자체 보유하지 않는다.

## 핵심 시나리오 (State / Action / handle 패턴)

- `NovelReviewViewModel`은 **단일 `@MainActor final class`**(프로토콜·typealias 없음). 입력은 `enum Action`(명령형: `load`,
  `selectStatus`, `updatePeriod`, `updateRating`, `toggleAttractivePoint`, `save`, `dismissError`) → `func handle(_:)`가 `switch`로 분기.
  상태는 단일 `@Published private(set) var state: State`로만 노출하고, `NovelReviewView`는 구체 타입을 `@StateObject`로 든다.
- `State`는 **`NovelReviewDraft`(도메인 엔티티)를 그대로 들고**(`state.draft`) UI 플래그(`isLoading`/`isSaving`/`shouldDismiss`/`errorMessage`)만 더한다.
  상태/정책은 엔티티에 위임한다 — 비즈니스 규칙(읽기 상태 단일 선택, 매력 포인트 최대 3개)은 ViewModel이 아니라 `NovelReviewDraft`에 있다.
  `handle(_:)`은 엔티티의 `throws`(예: `tooManyAttractivePoints`)를 잡아 **`state.errorMessage`로 변환만** 한다.
- **책임 분담(결정: "얇은 ViewModel" / A안)**: ViewModel은 **의미값**만 들고(`state.draft.rating`, `state.draft.period`, `state.draft.status` …),
  View가 `state.draft.…`로 직접 읽는다(selected* 별칭 프로퍼티 두지 말 것). **카피·포맷·빈상태 문구는 View 몫**
  (날짜 `yyyy.MM.dd`, `~` 구분자, "평점 없음"/"선택", 색). → ViewModel은 화면 표기 방식을 모른다(별이든 슬라이더든 View가 정함).
  표시 문자열을 유닛테스트로 고정할 필요가 생기면 그때만 별도 Formatter로 분리(현재는 불필요).

## 현재 범위

**읽기 상태 + 독서 기간(sheet) + 평점(슬라이더) + 매력 포인트 토글 + 키워드(진입 버튼) + 진입 시 로드(`load`) + 완료 시 저장(`save`)**.
저장 성공 시 `state.shouldDismiss = true`로 닫힘을 신호한다.
- 키워드는 `WSSSearchBarButton`(검색바 룩 탭 버튼)만 배치 — **탭 액션은 TODO(키워드 탐색뷰 이동 추후)**, draft.keywords 연결도 아직.
- 아직 미연결: 키워드 선택/탐색뷰, 삭제(`DeleteNovelReviewUseCase`).

## 주의사항 (작업 중 발견 시 누적)

#### 표현·라벨
- 화면 라벨은 **WSSComponent의 Presentation 확장**(`ReadingStatus.statusName`, `AttractivePoint.displayName`)을 쓴다.
  ViewModel은 표현 의존이 없어 `WSSComponent`를 import하지 않는다(View에서만 사용).

#### 도메인 값 매핑
- **평점은 도메인 `Rating`이 0.5~5.0(0.5 단위)만 허용하고 0.0을 표현 못 한다** → 슬라이더는 `0...5`지만
  `updateRating`이 **0.0을 `nil`(평점 없음)로 매핑**한다. "평점 없음 ↔ 0.0"은 이 매핑 규칙이라 임의로 바꾸지 말 것.
- **독서 기간 상태↔날짜 매핑(watching=시작만, watched=시작+종료, quit=종료만)은 도메인 `ReadingPeriod.normalized(for:)`가 강제한다.**
  - **표시(출력)**: status로 분기하지 말 것. normalize가 상태에 맞는 날짜만 채워두므로 **`start`/`end` 존재 여부로만** 표기한다
    (둘 다=기간, 하나=단일). status 분기는 normalize와 중복이라 제거함.
  - **입력**: `ReadingPeriodSheet.apply()`는 자기가 띄운 폼대로 의미 있는 날짜만 넘긴다(watched만 시작/종료 segment).
    단일 상태에 양쪽 날짜를 다 넘기면 `ReadingPeriod(start:end:)`가 `startAfterEnd`로 **오검증**할 수 있으니 입력측은 폼대로 보낼 것.

#### ReadingPeriodSheet UI
- 흰 배경, 완료=`WSSCTAButton`, 그 아래 "날짜 삭제". 취소는 우상단 X 또는 배경 탭(시트 dismiss) — 별도 취소 버튼 없음.
  높이는 `presentationDetents`로 고정: 단일(watching/quit) **362**, 시작+종료(watched) **436**.
- **날짜 삭제**는 `onApply(nil, nil)` → ViewModel `updatePeriod(nil, nil)`로 기간 제거(전용 콜백 없이 재사용).
- watched는 field 전환 시 편집 날짜가 바뀌므로 `WSSDateWheel`에 **`.id(field)`**를 줘 휠을 새로 띄워 초기값을 갱신한다(외부 동기화 루프 회피).
- `WSSDateWheel`/`WheelColumn`은 연·월·일 3열 커스텀 휠 — **iOS 17 ScrollView 스냅 API**
  (`scrollTargetLayout`/`scrollTargetBehavior(.viewAligned)`/`scrollPosition(id:)` + `contentMargins`로 위아래 여백)로 가운데 정렬값을 선택값으로 삼는다. 네이티브 `DatePicker(.wheel)`은 체크/회색 처리 룩이 안 나와 직접 구현.

#### 로드 생명주기
- `onAppear`에서 `handle(.load)`로 호출. 초안이 없으면(nil) 기본 draft를 유지한다(덮어쓰지 않음).
- **로드는 최초 1회만**(`hasLoaded` 가드). `onAppear`는 재진입마다 불리므로, 가드 없으면 편집 중 draft를 서버 값으로 덮어쓴다.

#### 비동기·Demo 빌드
- 비동기 모델: 허브 문서는 Feature를 Combine으로 안내하나, 여기선 상태가 단순해 단일 `@Published var state`/`ObservableObject`만 사용.
  async UseCase는 `@MainActor` ViewModel 안에서 `Task { await ... }`로 호출하고, `state.isLoading`/`state.isSaving`은 `defer`로 해제한다.
- `NovelReviewFactory.makeView`는 `@MainActor`(내부에서 `@MainActor` ViewModel 생성). Preview/Demo는 main actor라 그대로 호출 가능.
- **Demo/Preview 빌드**: `.demo` 타깃이 있어 `NovelReviewFeature` 스킴이 Demo 앱까지 함께 빌드한다.
  → `generic/platform=iOS`(실기기) 빌드는 Demo 앱 **코드 서명**을 요구하니, 검증은
  **시뮬레이터 대상으로 워크스페이스 스킴**을 빌드할 것. 단일 `-target ...Demo` 빌드는 교차 모듈 의존을 못 풀어 실패한다.
