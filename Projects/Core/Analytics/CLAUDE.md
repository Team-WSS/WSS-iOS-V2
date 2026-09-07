<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Core/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# Analytics

이벤트 트래킹 추상화(`AnalyticsTracker` 프로토콜). `Logger`와 동일한 형태 — 이 모듈은 Amplitude·Microsoft
Clarity 등 구체 SDK를 **모른다**(#249). 구현체는 App 레이어에만 격리되고(외부 의존성 예외, 루트
`CLAUDE.md` 5번), 이 모듈은 순수 프로토콜만 노출해 Feature가 App을 몰라도 자유롭게 이벤트를 보낼 수 있게 한다.

- 식별자: `ModuleType.core(.analytics)` / 의존: 없음(순수 프로토콜)
- 진입점: 없음(Factory 없음) — Feature는 `AnalyticsTracker?`를 `logger: Logger? = nil`과 동일한 형태(옵셔널·
  nil 기본값)로 Factory→ViewModel 주입받는다. 실제 인스턴스는 App(DI)이, Demo/테스트는 nil.

## 핵심 시나리오

- `track(_ name: String, properties: [String: AnalyticsPropertyValue]?)` 하나뿐 — Amplitude 이벤트 스키마는
  콘솔에 미리 등록할 필요 없이 SDK가 보내는 이벤트명을 그대로 수집하는 구조라, 이 프로토콜도 이벤트명 문자열
  하나만 받는 얇은 형태로 충분하다.
- **`properties`는 `Any`가 아니라 `AnalyticsPropertyValue`(string/int/double/bool) 고정 케이스** — 프로토콜이
  `Sendable`이어야 하는데(Swift 6 mode 6 대비, `Logger`와 동일 이유) `Any`는 Sendable을 보장 못 한다.
- Clarity는 커스텀 이벤트 API가 아니라 세션 자동 수집(리플레이·히트맵) 위주라 이 프로토콜 대상이 아니다 —
  App 초기화 시점에 SDK만 띄우면 되고 Feature가 호출할 게 없다.
- **이벤트 이름은 문자열 리터럴로 호출부에 흩뿌리지 않는다** — 각 Feature 모듈이 자기 화면 이벤트만 담은
  `enum XxxAnalyticsEvent: String, AnalyticsEvent`(마커 프로토콜, 이 모듈이 제공)를 선언하고,
  `AnalyticsTracker.track<Event: AnalyticsEvent>(_:properties:)` 제네릭 오버로드가 `rawValue`로 풀어
  문자열 버전에 위임한다. 이벤트 enum 자체는 **Core가 아니라 그 이벤트를 쓰는 Feature 모듈에** 둔다 —
  Core는 제품 개념(화면·액션)을 모른다는 원칙 유지, 이 모듈은 마커 프로토콜(`RawValue == String` 제약)만
  제공한다. Feature ViewModel의 `track(_:properties:)` pass-through도 그 모듈의 `Event` 타입 하나로
  제네릭하게 두면 된다(`Logger`의 `logger?.error(...)`와 달리, Analytics는 이벤트 종류가 많아 enum
  하나로 카탈로그화하는 이유).

## 주의사항 (작업 중 발견 시 누적)

- **"화면 진입"류(`XxxViewed`) 이벤트는 `View.onAppear`가 아니라 VM의 `load()` 안, `hasLoaded` 가드를 통과한
  분기에서 쏜다** — `onAppear`는 뒤로가기 후 재진입마다 재발화되므로 거기서 직접 트래킹하면 화면 하나를 다시
  볼 때마다 중복 집계된다. `load()`에 `hasLoaded`/`!hasLoaded` 가드가 있는 화면은 그 안에, 가드 없이
  재진입마다 무조건 재조회하는 화면(예: `FeedDetailViewModel.load`)은 View 쪽에 별도 `hasTrackedXxx`
  `@State` 플래그를 둬서 최초 1회만 쏜다(`NovelDetailViewModel`/`DetailSearchResultViewModel`/
  `NormalSearchViewModel`/`FeedDetailView`에서 이 패턴으로 정리됨).
