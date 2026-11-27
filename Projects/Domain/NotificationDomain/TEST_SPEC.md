# NotificationDomain 테스트 명세

<!-- 자동 생성 파일 — 손으로 고치지 않는다. 갱신: swift run --package-path Tooling/ArchLint ArchLint --write-test-specs . -->

## 알림 목록 불러오기

`Tests/Notification/UseCase/LoadPagedNotificationsUseCaseTests.swift`

- 개수를 0 이하로 요청하면 20개씩 불러온다
  - `0` — 경계
  - `-1` — 음수
- 개수를 1 이상으로 요청하면 그 개수대로 불러온다
  - `1` — 경계
  - `30` — 일반값

## 작품 알림 구독 목록 불러오기

`Tests/NovelNotification/UseCase/LoadNovelNotificationSubscriptionsUseCaseTests.swift`

- 개수를 0 이하로 요청하면 20개씩 불러온다
  - `0` — 경계
  - `-1` — 음수
- 개수를 1 이상으로 요청하면 그 개수대로 불러온다
  - `1` — 경계
  - `30` — 일반값
