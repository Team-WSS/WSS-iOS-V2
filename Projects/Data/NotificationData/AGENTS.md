<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/AGENTS.md(레이어 규칙)와 함께 자동 로드됨. -->
# NotificationData

`NotificationDomain`의 두 Repository를 구현 — `Notification/`(인앱 알림) + `Push/`(푸시 설정/토큰).

- 식별자: `ModuleType.data(.notification)` / 의존: `NotificationDomain`, `BaseDomain`, `BaseData`, `Networking`
- 진입점 2개:
  - `NotificationDataFactory.makeNotificationRepository(client:logger:)` → `NotificationRepository`
  - `NotificationDataFactory.makePushSettingRepository(client:logger:)` → `PushSettingRepository`

## 주의사항 (작업 중 발견 시 누적)

- **Repository·Service·Endpoint가 Notification/Push 2세트**로 분리돼 있다. 작업 시 `Notification/`인지 `Push/`인지 폴더 먼저 확인.
