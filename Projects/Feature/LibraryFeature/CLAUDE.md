<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# LibraryFeature

서재 탭 화면 — 사용자가 등록·기록한 작품 목록(`LibraryNovel`)을 필터·정렬로 조회한다.

- 식별자: `ModuleType.feature(.library)` / 의존: `BaseDomain`, **`NovelDomain`**(서재 Domain 코드가 별도 LibraryDomain이 아니라 여기 있음 — `LoadMyLibraryUseCase`·`LoadUserLibraryUseCase`·`LibraryNovel(s)`·`LibraryFilter`·`MyLibraryFilter`), `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `LibraryFactory` (골격 작성 중)

## 핵심 시나리오

- (화면 골격 확정 후 작성)

## 주의사항 (작업 중 발견 시 누적)

- 서재 Domain을 찾을 때 `LibraryDomain`을 만들지 말 것 — 정본은 `NovelDomain/Sources/Entity/Library/`와 `NovelDomain/Sources/UseCase/`다.
