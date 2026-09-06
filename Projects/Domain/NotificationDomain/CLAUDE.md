<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationDomain

알림 도메인 — **세 개의 하위 영역**으로 갈린다: `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰) + `NovelNotification/`(작품별 완결·휴재복귀 알림 — **구독 목록**(#188) + **작품 하나의 on/off 설정**(#189)을 한 Repository가 함께 관리).

- 식별자: `ModuleType.domain(.notification)` / 의존: `BaseDomain`

## 핵심 시나리오

- **Notification** (`NotificationRepository`): 목록(`PagedNotifications`, 커서 `lastNotificationID`), 상세, 읽음 처리(`markAsRead`), 미읽음 상태(`UnreadNotificationStatus`).
- **Push** (`PushSettingRepository`): 푸시 설정 조회/변경(`PushPreference`), 디바이스 토큰 등록(`DevicePushToken`).
- **NovelNotification** (`NovelNotificationRepository`) — 완결/휴재복귀(`NovelNotificationType`) 알림 전반을 다루는 단일 계약, 성격이 다른 두 조회 단위를 함께 갖는다:
  - **구독 목록**(#188): 구독한 작품 목록 조회(`PagedNovelNotificationSubscriptions`, 커서는 서버가 명시적으로 내려주는 `nextSubscriptionID` — `Notification`처럼 마지막 항목 id로 유추하지 않는다) + 선택한 작품들 일괄 구독 해제(`novelID` 기준, `subscriptionID` 아님).
  - **작품 하나의 설정**(#189): 작품 상세 종 모양 아이콘 시트에서 쓰는 `GET`/`PUT /novels/{novelId}/notification` — 여러 작품 목록이 아니라 **단일 작품**의 현재 on/off 상태(`NovelNotificationSetting`)만 다룬다. `PUT`은 멱등이라 항상 두 값을 함께 보낸다(부분 갱신 없음).
- 알림 탭 → `NotificationDeeplink`/`NotificationType`로 화면 분기.

## 주의사항 (작업 중 발견 시 누적)

- **Repository가 3개**다. 알림 데이터·푸시 설정·작품 알림(구독 목록+개별 설정)은 각각 별개 계약 — 섞지 말 것. Data 쪽도 `Notification`/`Push`/`NovelNotification` 세 Repository로 구현됨.
- **`NovelNotificationRepository` 안에서 "구독 목록" 메서드와 "설정" 메서드를 이름만 보고 헷갈리지 말 것** — `loadSubscriptions`/`deleteSubscriptions`는 "구독 중인 작품들의 목록"(여러 작품, 커서 페이지네이션), `loadNotificationSetting`/`updateNotificationSetting`은 "작품 하나의 현재 on/off 상태"(단일 작품, 페이지네이션 없음). 같은 완결/휴재복귀 개념을 다른 두 화면(설정의 목록 화면 vs 작품 상세 시트)에서 다른 각도로 다뤄 한 Repository에 합쳤을 뿐 — 엔드포인트·응답 모양은 전혀 다르다(Data의 `NovelNotificationEndpoint`가 서로 다른 두 경로를 갖는다).
- **`NotificationDeeplink` 네 갈래는 전부 Data가 실제로 만든다** — 매퍼 분기 우선순위는 **id 존재를 먼저**:
  `feedId` → `novelId` → `isNotice` → `.unknown` 순이다. 즉 **피드·작품 상세로 가는 알림은 id로만 판정**하고,
  isNotice는 id가 하나도 없는 **순수 공지**를 알림 상세로 보낼 때만 쓴다. 완결·휴재 복귀 알림은 novelId만 있으면
  서버가 isNotice를 뭘로 주든 작품 상세로 간다("novelId 있으면 다 작품 상세" 규칙 — id-우선이라 서버 스펙에
  의존하지 않는다). ⚠️ 예전엔 `isNotice`를 먼저 봐서, 완결 알림이 `isNotice: true`로 오면 알림 상세로 새는
  위험이 있었다 — id-우선으로 바꿔 그 취약점을 없앴다(`NotificationMapperTests`가 id가 isNotice를 이기는 걸 고정).
- `NotificationType`(feed/like/hot/event/notice/unknown)은 **정의만 있고 아무도 쓰지 않는다** — `NotificationItem`은
  타입 대신 서버가 준 `iconURL`을 들고 화면은 그 이미지를 그린다. 아이콘을 타입으로 분기하려 들지 말 것.
