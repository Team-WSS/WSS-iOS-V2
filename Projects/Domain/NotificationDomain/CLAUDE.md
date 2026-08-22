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
- **`NotificationDeeplink` 네 갈래는 전부 Data가 실제로 만든다** — 매퍼 분기 우선순위는 `isNotice` → `feedId` →
  `novelId` → `.unknown` 순이고, 이 순서는 **작품 알림이 `isNotice: false`로 온다는 서버 스펙에 기대고 있다**.
  서버가 작품 알림에도 `isNotice: true`를 주기 시작하면 novelId가 채워져 있어도 알림 상세로 새는데,
  `NotificationMapperTests`의 "공지 플래그가 켜져 있으면…" 테스트가 그 변화를 먼저 알린다.
- `NotificationType`(feed/like/hot/event/notice/unknown)은 **정의만 있고 아무도 쓰지 않는다** — `NotificationItem`은
  타입 대신 서버가 준 `iconURL`을 들고 화면은 그 이미지를 그린다. 아이콘을 타입으로 분기하려 들지 말 것.
