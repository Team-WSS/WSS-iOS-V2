# SearchFeature

일반 검색 화면(`NormalSearchView`). 5개 섹션 중 **소소픽만 실제 UseCase로 연동**됐고 나머지(최근 검색어/장르별 검색/키워드 검색/검색 실행)는 정적 UI + TODO 액션 상태.

- 식별자: `ModuleType.feature(.search)` / 의존: `BaseDomain`, `NovelDomain`, `RecommendationDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `SearchFactory.makeView(loadSosoPickUseCase:logger:)`

## 핵심 시나리오

- `NormalSearchView` = 상단바(뒤로가기+검색바) + 최근 검색어 + 장르별 검색 + 키워드 검색 + 소소픽, 세로 나열.
- `onAppear` → `.loadSosoPick` 액션 → `NormalSearchViewModel`이 `RecommendationDomain.LoadSosoPickUseCase`로 소소픽 목록을 로드해 가로 스크롤로 노출(로드 1회만, `hasLoaded` 가드).
- 나머지 섹션(최근 검색어 삭제/개별 삭제, 장르 탭 이동, 키워드 탭 이동, 검색 실행, 뒤로가기)은 하드코딩 더미 데이터만 있고 버튼 액션은 전부 TODO.

## 주의사항 (작업 중 발견 시 누적)

- **전용 SearchDomain은 없다.** 검색 관련 UseCase는 도메인별로 흩어져 있다: 작품 검색은 `NovelDomain.SearchNovelUseCase`, 키워드 검색은 `BaseDomain.SearchKeywordsUseCase`, 소소픽은 `RecommendationDomain.LoadSosoPickUseCase`(연동 완료). 나머지 섹션 구현 시 어떤 UseCase를 쓸지 확정하고 필요하면 `Project.swift`의 `internalDependencies`를 갱신할 것.
- 장르별 검색 그리드는 `BaseDomain.NovelGenre.searchGenre`(필터용 `filterGenre`와 순서가 다른 별개 목록) 순서를 그대로 쓴다.
- `.tests` 타깃은 아직 없다. 화면 로직(특히 나머지 섹션의 UseCase 연동)이 늘어나면 `Project.swift`의 `targets`에 `.tests`를 추가하고 `Tests/` 폴더를 만든다.
