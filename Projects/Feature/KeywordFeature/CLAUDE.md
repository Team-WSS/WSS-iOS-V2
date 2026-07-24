<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# KeywordFeature

키워드 검색 화면. 골격만 있는 상태(View/ViewModel/Factory는 다음 단계에서 채운다).

- 식별자: `ModuleType.feature(.keyword)` / 의존: `BaseDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- ⚠️ **별도 `KeywordDomain` 없음** — 키워드 검색 UseCase(`SearchKeywordsUseCase`)·Repository·Entity(`Keyword`, `KeywordGroup`)는 전부 `BaseDomain/Sources/Keyword/`에 있다. Demo 앱은 실서버 조립을 위해 `BaseData`(`DefaultKeywordRepository`)를 의존한다.

## 핵심 시나리오

- (아직 없음 — View/ViewModel 구현 후 채운다)

## 주의사항 (작업 중 발견 시 누적)

- (아직 없음)
