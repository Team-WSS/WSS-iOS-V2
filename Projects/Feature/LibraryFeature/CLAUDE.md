<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# LibraryFeature

서재 탭 화면 — 사용자가 등록·기록한 작품 목록(`LibraryNovel`)을 필터·정렬로 조회한다.

- 식별자: `ModuleType.feature(.library)` / 의존: `BaseDomain`, **`NovelDomain`**(서재 Domain 코드가 별도 LibraryDomain이 아니라 여기 있음 — `LoadMyLibraryUseCase`·`LoadMyLibraryKeywordsUseCase`·`LibraryNovel(s)`·`MyLibraryFilter`), `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `LibraryFactory.makeView(loadMyLibraryUseCase:loadMyLibraryKeywordsUseCase:logger:onNovelSelected:onSearchTapped:onRegisterTapped:onNotificationTapped:onAuthenticationRequired:)` — 탭 **콘텐츠만** 반환(탭바·화면 전환은 App 몫)

## 핵심 시나리오

- **로드**: 첫 페이지(`hasLoaded` 가드, 성공 시만 소진) → 커서 무한 스크롤(마지막 셀 onAppear → `.loadMore`, 서버 발급 `nextCursor` 왕복). 필터/정렬 변경은 `reloadFromScratch()` — **세대(generation) 카운터**로 진행 중이던 이전 로드의 늦은 결과·defer가 새 목록을 덮지 않게 가드한다.
- **필터**: 메인 칩 행 = 관심(즉시 토글) + 시트 필터 6종(탭 시 해당 탭으로 필터 시트 진입). 시트는 순수 입력 VM(`LibraryFilterSheetViewModel`)이 필터 **복사본**을 편집하고, "작품 찾기"에서 View가 `onApply`로 부모에 올린다(ReadingPeriodSheet 패턴). 등록 키워드 목록은 **부모 VM이 로드**해 시트에 값으로 내려준다.
- **에러 3분화**: 첫 페이지 실패=**헤더(타이틀·등록 버튼)만 남기고** 그 아래를 실패 뷰(`NetworkErrorView`+재시도)로 대체(컨트롤·카운트·목록은 함께 숨김 — 실패 상태에서 조작할 게 없음), 더보기·키워드 실패=토스트, 인증 만료=`requiresAuthentication` 신호 → `onAuthenticationRequired` 콜백(NovelDetail 배관과 동일).

## 주의사항 (작업 중 발견 시 누적)

- 서재 Domain을 찾을 때 `LibraryDomain`을 만들지 말 것 — 정본은 `NovelDomain/Sources/Entity/Library/`와 `NovelDomain/Sources/UseCase/`다.
- ⚠️ **그리드 셀(`LibraryGridCell`)의 표지 아래 정보 스택은 고정 높이(`Metric.infoHeight` 65)** — 제목 줄 수(1~2)·내 별점 유무·날짜 유무가 작품마다 달라서, 자연 높이로 두면 `LazyVGrid` 행이 어긋나 목록이 삐뚤빼뚤해진다(실제 발생). 스택 **내부는 자연스럽게 흐르게** 두고(1줄 제목이면 별점이 바로 따라옴 — Figma와 동일) 스택 **자체만** 고정한다. 별점·날짜를 빈 자리로 채우거나 제목을 2줄로 강제하지 말 것.
  - **표지는 고정 높이가 아니라 비율**(`Metric.thumbnailAspectRatio` = 108:160) — 열 너비를 따라 커진다. 화면 폭이 달라져도 비율이 유지돼야 하므로 `height:` 고정으로 되돌리지 말 것.
  - ⚠️ `.frame(maxWidth:height:)` 조합은 컴파일 안 된다(`maxWidth` 오버로드엔 `height`가 없음) — `minHeight`/`maxHeight`를 같은 값으로 주거나 `.frame`을 두 번 건다.
- **iOS 26 시트 기본 배경은 글래스(반투명)** — 디자인은 불투명 흰색이라 정렬/필터 시트 모두 `.presentationBackground(Color.wssWhite)` 명시 필수. 빼면 뒤 콘텐츠가 비쳐 보인다.
- **필터 시트 탭 행(6탭)은 화면 폭보다 넓어 가로 스크롤** — 디자인 시안에서도 우측 탭이 잘려 있다. 고정 HStack으로 두면 "매력포인트"가 2줄로 꺾인다(`fixedSize()`+ScrollView).
- ⚠️ **필터 시트 레이아웃 골격은 구 WSSiOS `LibraryFilterView`(UIKit)가 정본** — 시트 높이가 고정(516)인데 탭마다 콘텐츠 자연 높이가 크게 달라, **탭 콘텐츠 영역이 남은 공간을 전부 차지하고(`.frame(maxHeight:.infinity, alignment:.top)`) 넘치면 그 안에서 스크롤**해야 한다. 콘텐츠 뒤에 `Spacer()`를 놓아 CTA를 바닥으로 미는 구조로 되돌리지 말 것 — 탭을 옮길 때마다 콘텐츠가 위아래로 튀고, 긴 탭(키워드)은 잘린다. 탭별 내부 스크롤(키워드만 별도 ScrollView)도 중복이라 두지 않는다.
  - **선택 칩 행은 칩이 없으면 구분선까지 통째로 사라진다**(정본 동작). 빈 높이를 남겨 "점프 방지"할 필요가 없다 — 위 콘텐츠 영역이 유연해서 그 차이를 흡수한다.
  - `presentationCornerRadius` 금지 규약은 정렬 시트뿐 아니라 **필터 시트에도 동일 적용**(아래 시트 공통 항목 참고).
- ⚠️ **`LibraryRatingSlider`의 트랙은 전체 폭이 아니라 핸들 반지름만큼 안쪽**(x: 8 ~ width-8, 정본 `WSSRangeSlider`와 동일). `position = fraction * width`로 두면 0.0/5.0에서 **핸들이 슬라이더 밖으로 반쪽 잘린다**. 값→좌표와 좌표→값 두 함수 모두 같은 보정을 써야 탭 지점과 핸들이 어긋나지 않는다.
- **매력포인트·장르의 시트 표시 순서는 디자인 전용 로컬 배열** — `AttractivePoint.allCases`(필력이 마지막)·`NovelGenre.filterGenre`(로맨스 먼저)와 순서가 다르다. 임의로 공용 순서로 되돌리지 말 것.
- **메인 필터 칩은 WSSComponent `WSSFilterButton`(h33·body4)과 다른 화면 전용 칩(h30·body5)** — 서재 디자인이 검색 필터 칩보다 작다. 컴포넌트 재사용으로 교체하지 말 것.
- 상단 아이콘 3종(`icAlarm`·`icBookRegister`·`icReset`)은 이 작업(#166)에서 DesignSystem에 추가한 신규 에셋.
- 별점 범위 필터의 "전체 범위(0.0~5.0) = 필터 없음(nil)" 정규화는 도메인(`MyLibraryFilter.setRatingRange`)이 담당 — 시트 VM은 슬라이더 편집값(`ratingMin/Max`)을 **별도 보유**한다(필터 nil이어도 슬라이더는 전체 범위를 그려야 해서).
- 정렬 시트 선택 즉시 적용·닫기(확인 버튼 없음). 디자인상 상단 그래버 없음(`.presentationDragIndicator(.hidden)`). presentation 설정·배경·높이는 **시트 뷰가 자체 보유**하고 콘텐츠는 `.padding(.horizontal,20)`(행마다 X, VStack 전체에 한 번) + `.frame(maxHeight:.infinity, alignment:.top)` + 흰 배경(ReadingPeriodSheet 패턴). `sheetHeight`(detent)는 콘텐츠에 딱 맞춘다(상단여백 + 행 + 간격 + 하단여백) — 쿠션 더하기 ❌(빈 공간만 생김).
  - ⚠️ **`presentationCornerRadius`를 쓰지 말 것** — `presentationBackground(Color)`(iOS 26 글래스 방지용 불투명 흰색)와 함께 쓰면 **배경 사각형이 시트 둥근 모서리에 클립되지 않아 양 옆·하단이 화면 프레임 밖으로 삐져나온다**(실제 발생, 오진으로 헤맴). `presentationBackground`만 두면 시스템 기본 둥근 모서리가 배경까지 제대로 클립한다(ReadingPeriodSheet도 CornerRadius 안 씀).
  - ⚠️ **선택 체크는 `HStack`에 넣지 말고(넣으면 글씨가 가운데 정렬에 밀려 오른쪽으로 이동) 글씨의 `.overlay(alignment:.leading)` + `offset`으로** 얹는다 — overlay는 레이아웃에 영향을 안 줘 글씨는 가운데 그대로 있고 체크만 왼쪽에 나타난다.
- **그리드/리스트 토글의 흰 원 슬라이드**: 선택된 세그먼트에만 `if`로 원을 그리고 `matchedGeometryEffect`로 잇는 방식은 **이동이 아니라 크로스페이드로 보인다**(SwiftUI가 옛 위치 제거+새 위치 삽입으로 처리 → 슬라이드가 거의 안 보임, 실제 발생). 원 하나를 `.background(alignment:.leading)`에 **항상** 그려두고 `.offset(x:)`만 바꿔야(+`.animation(.spring, value: displayMode)`) 대놓고 미끄러진다.
- **표지는 `AsyncImage`를 직접 쓰지 말고 `WSSNovelCoverImage`(WSSComponent)를 쓴다** — `AsyncImage`는 뷰 정체성이 바뀔 때마다 `.empty` phase부터 다시 시작해 **캐시 히트여도** 빈 표지가 번쩍인다. 그리드↔리스트 토글·스크롤 재활용이 셀을 재생성하므로 이게 매번 도진다. `WSSNovelCoverImage`(범용 `WSSAsyncImage` + 빈 표지 폴백)는 **디코딩된 `UIImage`를 인메모리 캐시에 두고 `init`에서 동기 조회** → 히트면 첫 프레임부터 실제 표지(placeholder 프레임 자체가 안 생김). 처음엔 서재 전용(`LibraryCoverImage`)이었으나 #166에서 WSSComponent로 승격.
