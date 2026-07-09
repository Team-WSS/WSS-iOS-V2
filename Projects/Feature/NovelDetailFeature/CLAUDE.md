<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# NovelDetailFeature

소설 상세(NovelDetail) 화면 — 몰입형 헤더 + 유저 평가 + 탭(정보/피드). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.novelDetail)` / 의존: **전용 `NovelDetailDomain`은 없고 `NovelDomain` + `FeedDomain`(피드 탭)을 쓴다**(#154 명세)
- 진입점: `NovelDetailFactory.makeView(novelID:loadNovelUseCase:novelInterestUseCase:loadNovelFeedsUseCase:logger:onReviewTapped:onCreateFeedTapped:)`
  - **`onReviewTapped(NovelInformation, ReadingStatus)`**: 평가 화면 진입 콜백. status는 평가 초안 seed — 평가 없음이면 셀렉터에서 탭한 상태, 있으면 현재 상태. 화면 전환은 호출자(App)가 NovelReviewFactory로 조립.
  - **`onCreateFeedTapped()`**: 피드 작성 진입 콜백 — "나도 한마디" 버튼과 피드 탭 플로팅 버튼이 공유.

## 핵심 시나리오

- **로드**: `LoadNovelUseCase` 1회(`hasLoaded` 가드)로 `NovelInformation` 확보. 피드 목록은 **피드 탭 첫 진입 시 지연 로드**, 이후 `lastFeedID` 커서 페이지네이션(첫 페이지 커서 0).
- **관심 토글**: 정책은 엔티티 `Novel.toggleInterest()`에 위임, UI 낙관 반영 후 서버 실패 시 롤백. `isInterested == nil`(비로그인 등)이면 엔티티가 no-op → 서버 호출도 스킵.
- **정보 탭 조건부 표시**: 매력포인트/키워드/읽기상태그래프는 각각 값 없으면 숨김, 전부 없으면 빈 상태(제목도 "독자들의 평가"로 변경). 그래프 우세 상태·동률 우선순위는 도메인 `dominantReadStatus`가 결정.

## 주의사항 (작업 중 발견 시 누적)

- 대응 `NovelDetailDomain`이 없다 — UseCase는 `NovelDomain`/`FeedDomain` 것을 주입받는다. `new-module` 기본 추론(`domain(.<같은이름>)`)과 다른 지점.
- **`state.novel`을 `state.information.novel`과 분리 보유** — `NovelInformation.novel`이 `let`이라 관심 토글(mutating)을 반영할 수 없어서다. 헤더/관심 버튼은 `state.novel`을 읽는다.
- **몰입형 헤더 = 시스템 네비바 숨김**(`.toolbar(.hidden)`) + 커스텀 고정 오버레이. `icNavigateLeft`/`icThreedots` 에셋은 **원색이 연회색(wssGray100)이라 밝은 배경에서 안 보임** → `renderingMode(.template)`로 색을 입혀야 한다.
- 빈 상태는 `NovelDetailEmptyView`(화면 전용) — WSSComponent `WSSEmptyView`는 검색 빈 상태 전용(고정 문구+버튼 필수)이라 재사용 불가.
- 피드 셀의 좋아요/threedots/프로필 탭, 드롭다운(오류 제보/평가 삭제) 액션은 **TODO(#154 범위 밖)** — UI만 배치됨.
- 유저 평가 없음 셀렉터와 있음 상태바는 같은 3분할 레이아웃이지만 **없음=상태별 개별 진입, 있음=박스 전체가 단일 진입점**.
