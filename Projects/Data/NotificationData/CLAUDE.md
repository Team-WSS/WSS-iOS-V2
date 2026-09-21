<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationData

`NotificationDomain`의 세 Repository를 구현 — `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰) + `NovelNotification/`(작품별 완결·휴재복귀 알림 — **구독 목록**(#188) + **작품 하나의 on/off 설정**(#189)을 한 Repository로 통합).

- 식별자: `ModuleType.data(.notification)` / 의존: `NotificationDomain`, `BaseDomain`, `BaseData`, `Networking`
- 진입점 3개:
  - `NotificationDataFactory.makeNotificationRepository(client:logger:)` → `NotificationRepository`
  - `NotificationDataFactory.makePushSettingRepository(client:logger:)` → `PushSettingRepository`
  - `NotificationDataFactory.makeNovelNotificationRepository(client:logger:)` → `NovelNotificationRepository`(구독 목록 2메서드 + 작품별 설정 2메서드, 총 4메서드)

## 주의사항 (작업 중 발견 시 누적)

- **Repository·Service·Endpoint가 Notification/Push/NovelNotification 3세트**로 분리돼 있다. 작업 시 어느 폴더인지 먼저 확인.
- ⚠️ **`GET /notifications/{id}`(상세 조회)는 조회 부수효과로 서버가 읽음 처리까지 한다** — #181에서 실서버로 실측했다
  (미읽음 알림을 상세로 열고 **`read`를 한 번도 안 보낸 채** 앱을 재실행하니 그 알림만 `isRead: true`로 내려왔다.
  같은 화면의 안 연 미읽음 알림은 그대로였다).
  `NotificationEndpoint`의 `getNotificationDetail`/`postNotificationRead` 선언만 봐선 알 수 없고, 응답
  (`NotificationDetailResponse`)에도 `isRead`가 없어 흔적이 남지 않는다. 그래서 화면은 **상세로 가는 알림에
  `markAsRead`를 따로 보내지 않는다**(→ [NotificationFeature](../../Feature/NotificationFeature/CLAUDE.md)) —
  "상세 화면에서 읽음 처리가 빠졌네" 하고 다시 붙이면 같은 일을 두 번 시키게 된다.
- **`NovelNotification` 폴더 안에 서로 다른 두 경로가 공존한다** — 구독 목록 조회·삭제는 `/users/me/notification/novels`(`GET`/`DELETE`를 메서드로만 가름), 작품별 설정 조회·변경은 `/novels/{novelId}/notification`(`GET`/`PUT`). 둘 다 `Notification`처럼 경로 자체가 액션별로 나뉘어 있지 않은 이 레포의 관례를 따르지만, **두 그룹이 서로 다른 경로라는 점**은 헷갈리기 쉽다 — `NovelNotificationEndpoint`의 4 케이스를 열어서 확인할 것.
- **삭제(`DELETE`)·설정 변경(`PUT`) 둘 다 body가 있다**(전자는 `notificationType`+`novelIds`, 후자는 완결/휴재복귀 두 값). `DELETE`에 JSON body를 실은 건 이 레포에서 `NovelNotification`이 첫 사례. `Endpoint.body`가 `RequestBody.json(...)`을 반환하도록 케이스별로 분기해야 한다(`method`만 보고 body 없다고 가정하지 말 것).
- **일괄 구독 해제는 `subscriptionID`가 아니라 `novelID` 기준**이다(서버 요청 필드가 `novelIds`) — 목록 항목의 `id`(구독 자체 식별자)를 그대로 보내면 안 된다.
- **작품별 설정의 `PUT`은 멱등이라 매번 두 값을 함께 보낸다** — 서버가 부분 갱신(한쪽 필드만 전송)을 지원하지 않는다(서버팀 확인). `PUT` 응답 바디는 디코딩하지 않는다(성공 여부만 확인 — GET 응답과 같은 모양일 수도 있지만 문서화되지 않아 추정하지 않았다).
- **`NovelNotificationMapper`/`NovelNotificationAction`/`NovelNotificationService`도 구독 목록용 메서드와 설정용 메서드가 한 파일에 같이 있다** — 이름이 비슷한 `subscriptions`류/`setting`류를 서로 다른 파일로 착각하지 말 것(#189에서 한 번 통합됨).
