<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# HomeFeature

앱의 홈(탭) 화면 — 오늘의 발견 / 트렌딩 피드 / 관심 피드 / 선호 장르 작품을 한 화면에 모아 보여준다.

- 식별자: `ModuleType.feature(.home)` / 의존: `BaseDomain`, **`RecommendationDomain`**(홈의 Domain 코드가
  별도 `HomeDomain`이 아니라 여기 있음 — `LoadHomeDataUseCase`·`HomeData`·`TodayDiscovery`·`TrendingFeed`·
  `InterestFeedState`·`PreferenceGenreNovelState`), `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `HomeFactory` (현재는 골격 placeholder — UseCase·콜백 주입은 골격 단계에서 확정)

## 핵심 시나리오

- (골격 단계에서 채운다)

## 화면 동작 계약

- (Figma 대조 단계 3B에서 확인받은 것만 채운다)

## 주의사항 (작업 중 발견 시 누적)

- 홈 Domain을 찾을 때 `HomeDomain`을 만들지 말 것 — 정본은 `RecommendationDomain/Sources/`다
  (`LibraryFeature`↔`NovelDomain`과 같은 형태의 이름 불일치).
- `LoadHomeDataUseCase`의 구현 클래스명은 `DefaultLoadDataUseCase`다(프로토콜명과 불일치 — 오타성).
  Demo·App에서 조립할 때 이름으로 검색하면 안 잡힌다.
