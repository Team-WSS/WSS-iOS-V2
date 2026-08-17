<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationData

`NotificationDomain`의 세 Repository를 구현 — `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰) + `NovelNotification/`(작품별 완결·휴재복귀 알림 구독, #188).

- 식별자: `ModuleType.data(.notification)` / 의존: `NotificationDomain`, `BaseDomain`, `BaseData`, `Networking`
- 진입점 3개:
  - `NotificationDataFactory.makeNotificationRepository(client:logger:)` → `NotificationRepository`
  - `NotificationDataFactory.makePushSettingRepository(client:logger:)` → `PushSettingRepository`
  - `NotificationDataFactory.makeNovelNotificationRepository(client:logger:)` → `NovelNotificationRepository`

## 주의사항 (작업 중 발견 시 누적)

- **Repository·Service·Endpoint가 Notification/Push/NovelNotification 3세트**로 분리돼 있다. 작업 시 어느 폴더인지 먼저 확인.
- ⚠️ **`GET /notifications/{id}`(상세 조회)는 조회 부수효과로 서버가 읽음 처리까지 한다** — #181에서 실서버로 실측했다
  (미읽음 알림을 상세로 열고 **`read`를 한 번도 안 보낸 채** 앱을 재실행하니 그 알림만 `isRead: true`로 내려왔다.
  같은 화면의 안 연 미읽음 알림은 그대로였다).
  `NotificationEndpoint`의 `getNotificationDetail`/`postNotificationRead` 선언만 봐선 알 수 없고, 응답
  (`NotificationDetailResponse`)에도 `isRead`가 없어 흔적이 남지 않는다. 그래서 화면은 **상세로 가는 알림에
  `markAsRead`를 따로 보내지 않는다**(→ [NotificationFeature](../../Feature/NotificationFeature/CLAUDE.md)) —
  "상세 화면에서 읽음 처리가 빠졌네" 하고 다시 붙이면 같은 일을 두 번 시키게 된다.
- **`NovelNotification` 조회·삭제 둘 다 같은 경로(`/users/me/notification/novels`)를 메서드로만 가른다**(`GET`/`DELETE`, `NovelNotificationEndpoint`) — `Notification`처럼 경로 자체가 액션별로 나뉘어 있지 않다.
- **삭제(`DELETE`)도 body가 있다**(`notificationType`+`novelIds`) — 이 레포에서 `DELETE`에 JSON body를 실은 첫 사례. `Endpoint.body`가 `RequestBody.json(...)`을 반환하도록 케이스별로 분기해야 한다(`method`만 보고 body 없다고 가정하지 말 것).
- **일괄 구독 해제는 `subscriptionID`가 아니라 `novelID` 기준**이다(서버 요청 필드가 `novelIds`) — 목록 항목의 `id`(구독 자체 식별자)를 그대로 보내면 안 된다.
