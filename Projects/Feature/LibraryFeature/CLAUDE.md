<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# LibraryFeature

서재 탭 화면 — 사용자가 등록·기록한 작품 목록(`LibraryNovel`)을 필터·정렬로 조회한다.

- 식별자: `ModuleType.feature(.library)` / 의존: `BaseDomain`, **`NovelDomain`**(서재 Domain 코드가 별도 LibraryDomain이 아니라 여기 있음 — `LoadMyLibraryUseCase`·`LoadMyLibraryKeywordsUseCase`·`LibraryNovel(s)`·`MyLibraryFilter`), `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `LibraryFactory.makeView(loadMyLibraryUseCase:loadMyLibraryKeywordsUseCase:logger:onNovelSelected:onSearchTapped:onRegisterTapped:onNotificationTapped:onAuthenticationRequired:)` — 탭 **콘텐츠만** 반환(탭바·화면 전환은 App 몫)

## 핵심 시나리오

- **로드**: 첫 페이지(`hasLoaded` 가드, 성공 시만 소진) → 커서 무한 스크롤(마지막 셀 onAppear → `.loadMore`, 서버 발급 `nextCursor` 왕복). 필터/정렬 변경은 `reloadFromScratch()` — **세대(generation) 카운터**로 진행 중이던 이전 로드의 늦은 결과·defer가 새 목록을 덮지 않게 가드한다.
- **필터**: 메인 칩 행 = 관심(즉시 토글) + 시트 필터 6종(탭 시 해당 탭으로 필터 시트 진입). 시트는 순수 입력 VM(`LibraryFilterSheetViewModel`)이 필터 **복사본**을 편집하고, "작품 찾기"에서 View가 `onApply`로 부모에 올린다(ReadingPeriodSheet 패턴). 등록 키워드 목록은 **부모 VM이 로드**해 시트에 값으로 내려준다.
- **에러 3분화**: 첫 페이지 실패=전면 실패 뷰(`NetworkErrorView`+재시도), 더보기·키워드 실패=토스트, 인증 만료=`requiresAuthentication` 신호 → `onAuthenticationRequired` 콜백(NovelDetail 배관과 동일).

## 주의사항 (작업 중 발견 시 누적)

- 서재 Domain을 찾을 때 `LibraryDomain`을 만들지 말 것 — 정본은 `NovelDomain/Sources/Entity/Library/`와 `NovelDomain/Sources/UseCase/`다.
- **iOS 26 시트 기본 배경은 글래스(반투명)** — 디자인은 불투명 흰색이라 정렬/필터 시트 모두 `.presentationBackground(Color.wssWhite)` 명시 필수. 빼면 뒤 콘텐츠가 비쳐 보인다.
- **필터 시트 탭 행(6탭)은 화면 폭보다 넓어 가로 스크롤** — 디자인 시안에서도 우측 탭이 잘려 있다. 고정 HStack으로 두면 "매력포인트"가 2줄로 꺾인다(`fixedSize()`+ScrollView).
- **매력포인트·장르의 시트 표시 순서는 디자인 전용 로컬 배열** — `AttractivePoint.allCases`(필력이 마지막)·`NovelGenre.filterGenre`(로맨스 먼저)와 순서가 다르다. 임의로 공용 순서로 되돌리지 말 것.
- **메인 필터 칩은 WSSComponent `WSSFilterButton`(h33·body4)과 다른 화면 전용 칩(h30·body5)** — 서재 디자인이 검색 필터 칩보다 작다. 컴포넌트 재사용으로 교체하지 말 것.
- 상단 아이콘 3종(`icAlarm`·`icBookRegister`·`icReset`)은 이 작업(#166)에서 DesignSystem에 추가한 신규 에셋.
- 별점 범위 필터의 "전체 범위(0.0~5.0) = 필터 없음(nil)" 정규화는 도메인(`MyLibraryFilter.setRatingRange`)이 담당 — 시트 VM은 슬라이더 편집값(`ratingMin/Max`)을 **별도 보유**한다(필터 nil이어도 슬라이더는 전체 범위를 그려야 해서).
- 정렬 시트 선택 즉시 적용·닫기(확인 버튼 없음). 시트 높이는 고정값(`sheetHeight`) — detent 계산에 쓴다.
