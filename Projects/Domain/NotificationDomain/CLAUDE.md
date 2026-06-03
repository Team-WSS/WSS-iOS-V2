<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationDomain

알림 도메인 — **두 개의 하위 영역**으로 갈린다: `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰).

- 식별자: `ModuleType.domain(.notification)` / 의존: `BaseDomain`

## 핵심 시나리오

- **Notification** (`NotificationRepository`): 목록(`PagedNotifications`, 커서 `lastNotificationID`), 상세, 읽음 처리(`markAsRead`), 미읽음 상태(`UnreadNotificationStatus`).
- **Push** (`PushSettingRepository`): 푸시 설정 조회/변경(`PushPreference`), 디바이스 토큰 등록(`DevicePushToken`).
- 알림 탭 → `NotificationDeeplink`/`NotificationType`로 화면 분기.

## 주의사항 (작업 중 발견 시 누적)

- **Repository가 2개**다. 알림 데이터와 푸시 설정은 별개 계약 — 섞지 말 것. Data 쪽도 `Notification`/`Push` 두 Repository로 구현됨.
