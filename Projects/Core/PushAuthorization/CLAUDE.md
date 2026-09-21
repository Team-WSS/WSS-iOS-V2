<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Core/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# PushAuthorization

시스템 푸시 알림 권한(`UNAuthorizationStatus`) 확인·요청을 감싸는 얇은 래퍼. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.core(.pushAuthorization)` / 의존: 없음(`UserNotifications`만 import)
- 진입점: `PushAuthorizationChecker` 프로토콜, 구현체는 `DefaultPushAuthorizationChecker()`(#193)

## 핵심 시나리오

- **상태는 3가지로 재분류**(`PushAuthorizationStatus`): `.authorized`(`.authorized`/`.provisional`/`.ephemeral` 통합), `.denied`, `.notDetermined`. 상위 레이어가 `UNAuthorizationStatus` 5종을 직접 다루지 않게 하기 위함.
- **기기 설정 앱으로 이동은 이 모듈 책임이 아니다** — `UIApplication.openSettingsURLString`은 UIKit이라 Core에 넣지 않고, 호출부(Feature)가 SwiftUI `@Environment(\.openURL)`로 직접 연다.
- `requestAuthorization()`은 **`notDetermined`에서만** 시스템 프롬프트를 띄운다 — 이미 `denied`인 상태에서 불러도 프롬프트 없이 즉시 `false`가 돌아온다(iOS 정책, 앱에서 재요청 불가). 호출부가 `denied`/`notDetermined`를 구분해 이 함수를 언제 부를지 정해야 한다.

## 주의사항 (작업 중 발견 시 누적)

- 특이사항 없음(신설, #193).
