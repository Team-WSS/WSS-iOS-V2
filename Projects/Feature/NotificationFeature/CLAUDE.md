<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationFeature

알림 목록·알림 상세 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.notification)` / 의존: `BaseDomain`, `NotificationDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점(둘 다 `NotificationFactory` — 대등한 화면이라 양쪽 다 `makeXxxView`):
  - `makeNotificationListView(loadPagedNotificationsUseCase:markNotificationAsReadUseCase:logger:onNotificationSelected:onFeedSelected:onAuthenticationRequired:)` — 홈 알림 벨에서 **push**
  - `makeNotificationDetailView(notificationID:loadNotificationDetailUseCase:logger:onAuthenticationRequired:)` — 목록에서 **push**
- **모듈 안에 `navigationDestination`은 없다** — 목록 → 상세 전환도 콜백으로 올리고 배선은 호출자(App/Demo)가 한다.

## 핵심 시나리오

- **목록 로드**: 진입 1회(`hasLoaded` 가드, 성공 시만 소진) → 커서 무한 스크롤. 커서는 서버 발급 문자열이 아니라
  **마지막으로 받은 `NotificationID`**(`lastNotificationID`)이고, 종료 판단은 응답의 `isLoadable`이다.
- **셀 탭 = 두 가지 일**: ① VM이 읽음 처리(낙관 반영 + `MarkNotificationAsReadUseCase`), ② View가
  `NotificationDeeplink`를 분기해 상위 콜백 발화(`.notificationDetail`→상세, `.feedDetail`→피드, `.unknown`/nil→전환 없음).
- **에러 분화**: 첫 페이지 실패=전면 `NetworkErrorView`(재시도), 더보기 실패=토스트, 인증 만료=`requiresAuthentication`
  신호 → `onAuthenticationRequired` 콜백(Feature 공통 계약).

## 화면 동작 계약

- (3B에서 확정한 것만 기록)

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`NotificationID`와 `FeedID`는 둘 다 `IDWrapper<Int>`의 typealias라 컴파일러에겐 같은 타입이다** —
  딥링크 두 갈래를 라우팅할 때 `navigationDestination(for: NotificationID.self)`와 `FeedID.self`를 나란히 두면
  **먼저 등록된 쪽이 양쪽을 다 삼킨다**. 호출자는 반드시 자체 Route enum으로 감싸야 한다(Demo가 `DemoRoute`로 그렇게 한다).
- **읽음 처리는 실패해도 롤백하지 않는다** — 같은 셀 재탭은 `markedAsReadIDs`로 막고 로그만 남긴다.
  읽음 여부는 재진입 시 서버 값으로 다시 맞춰지므로, 실패를 토스트로 알리면 화면 전환과 겹쳐 시끄럽다.
- **`NotificationItem`은 전 프로퍼티가 `let`** — 낙관 반영은 `mutating` 정책이 아니라 새 인스턴스 교체로 한다
  (Domain에 `markedAsRead()` 같은 정책 메서드가 없다).
