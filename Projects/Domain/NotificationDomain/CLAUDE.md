<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationDomain

알림 도메인 — **네 개의 하위 영역**으로 갈린다: `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰) + `NovelNotification/`(작품별 완결·휴재복귀 알림 **구독 목록**, #188) + `NovelNotificationSetting/`(작품 하나의 완결·휴재복귀 알림 **on/off**, #189).

- 식별자: `ModuleType.domain(.notification)` / 의존: `BaseDomain`

## 핵심 시나리오

- **Notification** (`NotificationRepository`): 목록(`PagedNotifications`, 커서 `lastNotificationID`), 상세, 읽음 처리(`markAsRead`), 미읽음 상태(`UnreadNotificationStatus`).
- **Push** (`PushSettingRepository`): 푸시 설정 조회/변경(`PushPreference`), 디바이스 토큰 등록(`DevicePushToken`).
- **NovelNotification** (`NovelNotificationRepository`, #188): 완결/휴재복귀(`NovelNotificationType`) 알림을 구독한 작품 목록 조회(`PagedNovelNotificationSubscriptions`, 커서는 서버가 명시적으로 내려주는 `nextSubscriptionID` — `Notification`처럼 마지막 항목 id로 유추하지 않는다) + 선택한 작품들 일괄 구독 해제(`novelID` 기준, `subscriptionID` 아님).
- **NovelNotificationSetting** (`NovelNotificationSettingRepository`, #189): 작품 상세 종 모양 아이콘 시트에서 쓰는, **작품 하나**의 완결/휴재복귀 알림 on/off(`GET`/`PUT /novels/{novelId}/notification`) — `NovelNotification`(구독 목록)과는 조회 단위가 다른 별개 계약이라 Repository를 분리했다. `PUT`은 멱등이라 항상 두 값을 함께 보낸다(부분 갱신 없음).
- 알림 탭 → `NotificationDeeplink`/`NotificationType`로 화면 분기.

## 주의사항 (작업 중 발견 시 누적)

- **Repository가 4개**다. 알림 데이터·푸시 설정·작품별 알림 구독 목록·작품 하나의 알림 설정은 각각 별개 계약 — 섞지 말 것. Data 쪽도 `Notification`/`Push`/`NovelNotification`/`NovelNotificationSetting` 네 Repository로 구현됨.
- **`NovelNotification`과 `NovelNotificationSetting`을 이름만 보고 헷갈리지 말 것** — 전자는 "구독 중인 작품들의 목록"(여러 작품, 커서 페이지네이션), 후자는 "작품 하나의 현재 on/off 상태"(단일 작품, 페이지네이션 없음). 같은 완결/휴재복귀 개념을 다른 두 화면(설정의 목록 화면 vs 작품 상세 시트)에서 다른 각도로 다룬다.
- **`NotificationDeeplink` 네 갈래는 전부 Data가 실제로 만든다** — 매퍼 분기 우선순위는 `isNotice` → `feedId` →
  `novelId` → `.unknown` 순이고, 이 순서는 **작품 알림이 `isNotice: false`로 온다는 서버 스펙에 기대고 있다**.
  서버가 작품 알림에도 `isNotice: true`를 주기 시작하면 novelId가 채워져 있어도 알림 상세로 샌다.
  ⚠️ **이 변화는 테스트가 못 잡는다** — `NotificationMapperTests`는 입력을 직접 만들어 순서만 고정하므로
  그 조합이 와도 통과한다. 증상("완결 알림을 탭했더니 알림 상세가 열린다")으로만 드러나니, 그때 이 분기를 볼 것.
- `NotificationType`(feed/like/hot/event/notice/unknown)은 **정의만 있고 아무도 쓰지 않는다** — `NotificationItem`은
  타입 대신 서버가 준 `iconURL`을 들고 화면은 그 이미지를 그린다. 아이콘을 타입으로 분기하려 들지 말 것.
