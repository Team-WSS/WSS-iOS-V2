<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationData

`NotificationDomain`의 두 Repository를 구현 — `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰).

- 식별자: `ModuleType.data(.notification)` / 의존: `NotificationDomain`, `BaseDomain`, `BaseData`, `Networking`
- 진입점 2개:
  - `NotificationDataFactory.makeNotificationRepository(client:logger:)` → `NotificationRepository`
  - `NotificationDataFactory.makePushSettingRepository(client:logger:)` → `PushSettingRepository`

## 주의사항 (작업 중 발견 시 누적)

- **Repository·Service·Endpoint가 Notification/Push 2세트**로 분리돼 있다. 작업 시 `Notification/`인지 `Push/`인지 폴더 먼저 확인.
- ⚠️ **`GET /notifications/{id}`(상세 조회)는 조회 부수효과로 서버가 읽음 처리까지 한다** — #181에서 실서버로 실측했다
  (미읽음 알림을 상세로 열고 **`read`를 한 번도 안 보낸 채** 앱을 재실행하니 그 알림만 `isRead: true`로 내려왔다.
  같은 화면의 안 연 미읽음 알림은 그대로였다).
  `NotificationEndpoint`의 `getNotificationDetail`/`postNotificationRead` 선언만 봐선 알 수 없고, 응답
  (`NotificationDetailResponse`)에도 `isRead`가 없어 흔적이 남지 않는다. 그래서 화면은 **상세로 가는 알림에
  `markAsRead`를 따로 보내지 않는다**(→ [NotificationFeature](../../Feature/NotificationFeature/CLAUDE.md)) —
  "상세 화면에서 읽음 처리가 빠졌네" 하고 다시 붙이면 같은 일을 두 번 시키게 된다.
