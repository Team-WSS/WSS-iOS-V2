<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelReviewFeature

작품 평가(리뷰 초안) 화면. **프로젝트의 첫 Feature 모듈** — 이후 Feature는 여기 패턴을 따른다.

- 식별자: `ModuleType.feature(.novelReview)` / 의존: `BaseDomain`, `NovelReviewDomain`, `DesignSystem`, `WSSComponent`
- **진입점: `NovelReviewFactory.makeView(novelID:loadUseCase:saveUseCase:)`** — 유일한 public API.
  opaque `some View`로 반환해 View/ViewModel을 `internal`로 감춘다. **UseCase(프로토콜)는 외부가 주입**한다
  (Feature는 Repository/Data 구현을 모름 → App이 조립, `Demo/`는 인메모리 Mock 주입).

## 핵심 시나리오 (MVVM 패턴)

- `NovelReviewViewModelInput`(행동) + `NovelReviewViewModelOutput`(상태, `ObservableObject`)을
  `typealias NovelReviewViewModel`로 합치고, `DefaultNovelReviewViewModel`이 둘 다 채택한다.
  `NovelReviewView<ViewModel: NovelReviewViewModel>`는 프로토콜에만 의존(테스트·프리뷰 교체 가능).
- ViewModel은 **`NovelReviewDraft`(도메인 엔티티)를 `@Published`로 들고** 상태/정책을 그 엔티티에 위임한다.
  비즈니스 규칙(읽기 상태 단일 선택, 매력 포인트 최대 3개)은 ViewModel이 아니라 `NovelReviewDraft`에 있다.
  ViewModel은 엔티티의 `throws`(예: `tooManyAttractivePoints`)를 잡아 **사용자 메시지로 변환만** 한다.

## 주의사항 (작업 중 발견 시 누적)

- 화면 라벨은 **WSSComponent의 Presentation 확장**(`ReadingStatus.statusName`, `AttractivePoint.displayName`)을 쓴다.
  ViewModel은 표현 의존이 없어 `WSSComponent`를 import하지 않는다(View에서만 사용).
- 현재 범위: **읽기 상태 + 독서 기간(sheet) + 매력 포인트 토글 + 진입 시 로드(`load`) + 완료 시 저장(`save`)**.
  로드는 `onAppear`에서 호출하며 초안이 없으면(nil) 기본 draft 유지. 저장 성공 시 `shouldDismiss = true`로 닫힘을 신호한다.
  아직 미연결: 평점/키워드, 삭제(`DeleteNovelReviewUseCase`).
- **독서 기간은 상태에 따라 입력 날짜가 다르며, 이 매핑은 도메인 `ReadingPeriod.normalized(for:)`가 강제한다**
  (watching=시작만, watched=시작+종료, quit=종료만). `ReadingPeriodSheet`는 watched일 때만 segment(시작/종료)를 띄운다.
  ⚠️ ViewModel이 어떤 날짜를 넣든 `draft.setPeriod`가 상태에 맞게 normalize하므로, UI 라벨을 도메인과 다르게 두면
  (예: watching에 "종료") 저장·재조회에서 어긋난다 — 라벨/입력은 반드시 위 매핑을 따를 것.
- 비동기 모델: 허브 문서는 Feature를 Combine으로 안내하나, 여기선 상태가 단순해 `@Published`/`ObservableObject`만 사용.
  async UseCase는 `@MainActor` ViewModel 안에서 `Task { await ... }`로 호출하고, `isLoading`/`isSaving`은 `defer`로 해제한다.
- **Demo/Preview 빌드**: `.demo` 타깃이 있어 `NovelReviewFeature` 스킴이 Demo 앱까지 함께 빌드한다.
  → `generic/platform=iOS`(실기기) 빌드는 Demo 앱 **코드 서명**을 요구하니, 검증은
  **시뮬레이터 대상으로 워크스페이스 스킴**을 빌드할 것. 단일 `-target ...Demo` 빌드는 교차 모듈 의존을 못 풀어 실패한다.
- `NovelReviewFactory.makeView`는 `@MainActor`(내부에서 `@MainActor` ViewModel 생성). Preview/Demo는 main actor라 그대로 호출 가능.
