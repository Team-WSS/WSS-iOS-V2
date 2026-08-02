<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# LibraryFeature

서재 화면 **2개**를 담는다 — 작품 목록(`LibraryNovel`)을 그리드/리스트로 조회한다는 뼈대가 같아 셀·정렬 시트를 공유한다.

| 화면 | 성격 | 상단 구성 |
|---|---|---|
| **내 서재**(`Library/`) | 탭 콘텐츠(앱 세션 내내 삶) | "서재" 타이틀 + 등록 버튼 / 필터 칩 7종 + 캡슐 세그먼트 토글 / 카운트·알림관리·정렬 |
| **타유저 서재**(`UserLibrary/`) | `NavigationStack` push(dismiss로 빠짐) | 커스텀 네비바(뒤로가기 + 중앙 "서재") / 카운트·정렬·아이콘 토글 **(필터 없음)** |

- 식별자: `ModuleType.feature(.library)` / 의존: `BaseDomain`, **`NovelDomain`**(서재 Domain 코드가 별도 LibraryDomain이 아니라 여기 있음 — `LoadMyLibraryUseCase`·`LoadUserLibraryUseCase`·`LoadMyLibraryKeywordsUseCase`·`LibraryNovel(s)`·`MyLibraryFilter`·`LibraryFilter`), `DesignSystem`, `WSSComponent`, `Logger`
- 진입점(둘 다 `LibraryFactory`):
  - `makeMyLibraryView(loadMyLibraryUseCase:loadMyLibraryKeywordsUseCase:logger:onNovelSelected:onSearchTapped:onRegisterTapped:onNotificationTapped:onAuthenticationRequired:)` — 탭 **콘텐츠만** 반환(탭바·화면 전환은 App 몫)
  - `makeUserLibraryView(userID:loadUserLibraryUseCase:logger:onNovelSelected:onAuthenticationRequired:)` — **push 대상**. 대상 사용자는 진입 시점(유저 프로필 등)에서 `UserID`로 넘긴다.
- 공유 자산: `LibraryGridCell`·`LibraryListCell`(셀), `LibrarySortSheet`(정렬 6종), `LibraryDisplayMode(+Icon)`(표시 모드·아이콘), `LibrarySortType+Library`(카피).

## 핵심 시나리오

- **로드**: 첫 페이지(`hasLoaded` 가드, 성공 시만 소진) → 커서 무한 스크롤(마지막 셀 onAppear → `.loadMore`, 서버 발급 `nextCursor` 왕복). 필터/정렬 변경은 `reloadFromScratch()` — **세대(generation) 카운터**로 진행 중이던 이전 로드의 늦은 결과·defer가 새 목록을 덮지 않게 가드한다.
- **필터**: 메인 칩 행 = 관심(즉시 토글) + 시트 필터 6종(탭 시 해당 탭으로 필터 시트 진입). 시트는 순수 입력 VM(`LibraryFilterSheetViewModel`)이 필터 **복사본**을 편집하고, "작품 찾기"에서 View가 `onApply`로 부모에 올린다(ReadingPeriodSheet 패턴). 등록 키워드 목록은 **부모 VM이 로드**해 시트에 값으로 내려준다.
- **에러 3분화**: 첫 페이지 실패=**헤더(타이틀·등록 버튼)만 남기고** 그 아래를 실패 뷰(`NetworkErrorView`+재시도)로 대체(컨트롤·카운트·목록은 함께 숨김 — 실패 상태에서 조작할 게 없음), 더보기·키워드 실패=토스트, 인증 만료=`requiresAuthentication` 신호 → `onAuthenticationRequired` 콜백(NovelDetail 배관과 동일).
- **빈 상태 2분화**: 서재 자체가 빔=`emptySection`("서재가 비어있어요" + 웹소설 찾기 CTA), 필터로 걸러져 0건=`noMatchSection`("해당하는 작품이 없어요" 2줄, CTA 없음). 가르는 기준은 `filter.hasActiveSheetFilter || filter.isInterest`(정렬은 개수를 안 바꾸니 제외).

## 화면 동작 계약 — 타유저 서재 (#166)

정적 디자인으로는 안 잡혀 **사람에게 확인받아 확정한 것**만 적는다(정본·컨벤션으로 정해지는 건 제외).

- **데이터는 내 서재와 같은 V2 엔드포인트**를 대상 userID로 호출한다 → 커서 무한 스크롤·키워드 칩이 내 서재와 동일하게 동작한다. 구 V1(`LoadUserLibraryUseCase` 이전 버전)은 첫 20개 고정·필터 무시라 버렸다.
- **정렬은 내 서재와 같은 6종**(`LibrarySortSheet` 재사용). ⚠️ **Figma 시안의 "최신 순"(공용 `SortType` 2종)과 다른 건 의도된 결정**이다 — 시안만 보고 2종으로 되돌리지 말 것.
- **그리드↔리스트 토글은 아이콘 버튼 하나**이고, 아이콘은 **지금 보고 있는 모드**를 나타낸다(누르면 갈 모드 ❌). 내 서재의 캡슐 세그먼트와 컨트롤 모양이 다른 건 디자인이 화면별로 다르게 잡힌 결과다.
- **상단은 커스텀 헤더**(뒤로가기 `icNavigateLeft` + 중앙 "서재" title2). 시스템 네비바를 쓰지 않는 이유는 폰트·back 아이콘이 디자인과 달라서다 → 그 대가로 `SwipeBackEnabler`가 필요하다(아래 주의사항).
- **타이틀은 "서재" 고정** — 대상 유저의 닉네임을 넣지 않는다(디자인).
- **빈 상태는 한 가지뿐**(`"보관함이 비어있어요"`, CTA 없음, 남은 공간 가운데). 필터가 없으니 내 서재의 "필터로 0건" 분화가 존재하지 않는다. 카운트·정렬·토글 행은 **빈 상태에서도 유지**한다(디자인 시안 그대로).
- **첫 페이지 실패는 네비게이션 바만 남기고** 그 아래를 `NetworkErrorView`로 대체한다(카운트·정렬·토글 함께 숨김 — 내 서재와 같은 규칙).
  - ⚠️ **인증 만료도 여기 포함한다 — 내 서재와 갈리는 지점이다.** 내 서재는 탭이라 다시 들어오면 `onAppear`가 재발화해 복구되지만, 타유저 서재는 **push라 그 경로가 없다** → 로그인 콜백이 화면을 치우지 않는 배선(시트로 띄우는 등)이면 목록이 "보관함이 비어있어요"로 **영구히 굳고 재시도 버튼조차 없다**. 실패 뷰를 세워 두면 스택을 교체하는 배선에선 어차피 화면이 사라져 손해가 없다. 정본(NovelDetail)의 "인증은 실패 뷰 대신 로그인 유도로 일원화"를 그대로 복사하지 말 것.

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`icNavigateLeft`를 그냥 쓰면 디자인보다 훨씬 흐리다** — 이 에셋의 원색은 연회색(#C7C7D0)인데 시안의 뒤로가기 화살표는 검정이다. `renderingMode(.template)` + `foregroundStyle(Color.wssBlack)`으로 색을 입혀야 한다(DesignSystem CLAUDE.md의 "아이콘 SVG는 원색 고정" 항목이 이 화면에서 실제로 걸렸다). 위치도 화면 왼쪽 끝이 아니라 **6pt 안쪽**에서 시작한다.
- ⚠️ **커스텀 헤더를 쓰면(`toolbar(.hidden, for: .navigationBar)`) 스와이프 뒤로가기가 함께 죽는다** → WSSComponent의 **`.enableSwipeBack()`** 을 걸어 되살린다. 화면 안에 자체 구현을 두지 말 것 — 이 모듈에도 `Support/SwipeBackEnabler.swift`로 복제돼 있었으나 `NovelDetailFeature` 복제본과 갈라져 사고가 나 #166에서 공용으로 통합했다. **delegate 수명·반납이 왜 함정인지는 [WSSComponent](../../UI/WSSComponent/CLAUDE.md)의 같은 항목이 정본.**
- **`reloadFromScratch()`에서 `totalCount`를 비우는지는 두 화면이 다르다** — 타유저 서재는 **정렬만** 바꿀 수 있어 개수가 불변이라 보존하고(비우면 로딩 동안 "n개"가 "0개"로 깜빡인다), 내 서재는 필터로 개수가 실제로 바뀌므로 비운다. 한쪽에 맞춰 통일하지 말 것.
- ⚠️ **Demo 실서버 모드는 키워드 캐시가 준비된 뒤에 화면을 세워야 한다**(내 서재·타유저 서재 **둘 다**) — 캐시가 비어 있어도 UseCase가 `try?` + `?? []`로 폴백해 **에러 없이 키워드 칩만 통째로 빈 채** 그려진다. "키워드가 안 나온다"를 화면 버그로 오진하기 딱 좋으니, Demo는 준비 플래그로 가드하고 그동안 `ProgressView`를 띄운다.
  - `authExpired` 시나리오의 **2회차 발화**를 확인할 땐 정렬 변경이 아니라 `NetworkErrorView`의 "페이지 다시 불러오기"를 쓴다 — 타유저 서재는 인증 만료도 실패 뷰로 덮어(위 동작 계약) **정렬 행 자체가 안 보인다**.
- 서재 Domain을 찾을 때 `LibraryDomain`을 만들지 말 것 — 정본은 `NovelDomain/Sources/Entity/Library/`와 `NovelDomain/Sources/UseCase/`다.
- ⚠️ **`requiresAuthentication`은 View가 소비한 뒤 `.consumeAuthenticationRequired`로 반드시 되돌려야 한다** — 서재는 **탭 콘텐츠라 VM이 앱 세션 내내 산다**(`LibraryFactory`가 탭 콘텐츠만 반환). 신호가 true로 굳으면 `onChange`가 다시 발화하지 않아 **2회차 인증 만료가 조용히 삼켜지고**(토스트도 인증 에러를 먼저 걸러냄) 빈 목록에 "서재가 비어있어요"가 뜬다. `NovelDetail`·`NovelReview`는 push 후 dismiss돼 VM이 사라지므로 소진 없이도 굴러가지만, **그 배관을 그대로 복사하면 안 된다.**
  - 소진을 넣은 대가로 "두 번째 `true`는 값 변화가 아니라 무시"되던 중복 억제가 사라진다 — 목록 로드와 키워드 로드가 **시간차를 두고 각각** 인증 실패하면 콜백이 2회 발화한다. **`onAuthenticationRequired`는 idempotent해야 한다**(루트 교체는 무해, `path.append(.login)`류면 로그인 화면이 두 겹 쌓인다). Feature 안에서 막으려면 별도 플래그가 필요한데 그럼 래치(영구 삼킴) 문제가 되살아난다.
- ⚠️ **그리드 셀(`LibraryGridCell`)의 표지 아래 정보 스택은 고정 높이(`Metric.infoHeight` 65)** — 제목 줄 수(1~2)·내 별점 유무·날짜 유무가 작품마다 달라서, 자연 높이로 두면 `LazyVGrid` 행이 어긋나 목록이 삐뚤빼뚤해진다(실제 발생). 스택 **내부는 자연스럽게 흐르게** 두고(1줄 제목이면 별점이 바로 따라옴 — Figma와 동일) 스택 **자체만** 고정한다. 별점·날짜를 빈 자리로 채우거나 제목을 2줄로 강제하지 말 것.
  - **표지는 고정 높이가 아니라 비율**(`Metric.thumbnailAspectRatio` = 108:160) — 열 너비를 따라 커진다. 화면 폭이 달라져도 비율이 유지돼야 하므로 `height:` 고정으로 되돌리지 말 것.
  - ⚠️ `.frame(maxWidth:height:)` 조합은 컴파일 안 된다(`maxWidth` 오버로드엔 `height`가 없음) — `minHeight`/`maxHeight`를 같은 값으로 주거나 `.frame`을 두 번 건다.
- ⚠️ **필터 시트는 진입 탭을 `.sheet(item: $filterSheetTab)`으로 넘긴다** — `isPresented:` + 별도 탭 State로 열면 **앱 실행 후 첫 시트만** 항상 읽기상태 탭으로 열린다(실제 발생). 두 번째부터는 정상이라 "가끔 그러네"로 넘기기 쉬우니, `isPresented`로 되돌리지 말 것. 원리는 Feature CLAUDE.md의 "표시 상태 소유 구분" 항목이 정본.
- **iOS 26 시트 기본 배경은 글래스(반투명)** — 디자인은 불투명 흰색이라 정렬/필터 시트 모두 `.presentationBackground(Color.wssWhite)` 명시 필수. 빼면 뒤 콘텐츠가 비쳐 보인다.
- **필터 시트 탭 행(6탭)은 화면 폭보다 넓어 가로 스크롤** — 디자인 시안에서도 우측 탭이 잘려 있다. 고정 HStack으로 두면 "매력포인트"가 2줄로 꺾인다(`fixedSize()`+ScrollView).
- ⚠️ **필터 시트 레이아웃 골격은 구 WSSiOS `LibraryFilterView`(UIKit)가 정본** — 시트 높이가 고정(516)인데 탭마다 콘텐츠 자연 높이가 크게 달라, **탭 콘텐츠 영역이 남은 공간을 전부 차지하고(`.frame(maxHeight:.infinity, alignment:.top)`) 넘치면 그 안에서 스크롤**해야 한다. 콘텐츠 뒤에 `Spacer()`를 놓아 CTA를 바닥으로 미는 구조로 되돌리지 말 것 — 탭을 옮길 때마다 콘텐츠가 위아래로 튀고, 긴 탭(키워드)은 잘린다.
  - ⚠️ **공통 세로 ScrollView는 두지 않는다 — 가변 길이 탭이 자기 스크롤을 갖는다.** 현재 6탭 중 길이가 유동적인 건 키워드뿐이라 `keywordContent`의 칩 영역만 자체 `ScrollView`고 나머지는 고정 콘텐츠다(남는 가용 높이 약 272pt에 나머지 탭 자연 높이가 전부 들어간다). **가변 높이 탭을 새로 추가하면 그 탭도 자체 스크롤을 가져야 한다** — `.frame(maxHeight:.infinity)`는 클립하지 않아서, 넘치면 잘리는 게 아니라 **CTA 버튼 위로 그려진다**.
  - ⚠️ **읽기상태·매력포인트 선택만 `handleWithoutAnimation`으로 반영한다**(Feature 기본 규칙인 "선택엔 짧은 색 애니메이션"의 **이 시트 한정 예외** — 앱 전반의 토글은 그대로 애니메이션을 가진다). 첫 선택으로 위쪽에 선택 칩 행이 생기면서 항목 행 전체가 아래로 밀리는데, 애니메이션이 살아 있으면 **방금 누른 항목만** 늦게 미끄러져 내려온다.
    - ⚠️ **`.animation` modifier 제거만으론 안 고쳐진다** — 떼고도 증상이 그대로임을 연사 캡처로 실측했다. 액션 시점 **트랜잭션**이 살아 있으면 그게 레이아웃 변화를 애니메이트하므로, `Transaction.disablesAnimations`로 `viewModel.handle` 호출 자체를 감싸야 한다(그 대가로 색 전환도 즉시가 된다).
    - 장르·연재상태·키워드는 WSSComponent 칩(`CapsuleSelectableKeywordChip`·`RectangleSelectableKeywordChip`)이라 애초에 애니메이션이 없어 증상이 없다 — **세 탭 첫 선택을 눈으로 확인함**(#166). 통일한답시고 이쪽에 애니메이션을 넣지 말 것.
  - **선택 칩 행은 칩이 없으면 구분선까지 통째로 사라진다**(정본 동작). 빈 높이를 남겨 "점프 방지"할 필요가 없다 — 위 콘텐츠 영역이 유연해서 그 차이를 흡수한다.
  - `presentationCornerRadius` 금지 규약은 정렬 시트뿐 아니라 **필터 시트에도 동일 적용**(아래 시트 공통 항목 참고).
- ⚠️ **`LibraryRatingSlider`의 트랙은 전체 폭이 아니라 핸들 반지름만큼 안쪽**(x: 8 ~ width-8, 정본 `WSSRangeSlider`와 동일). `position = fraction * width`로 두면 0.0/5.0에서 **핸들이 슬라이더 밖으로 반쪽 잘린다**. 값→좌표와 좌표→값 두 함수 모두 같은 보정을 써야 탭 지점과 핸들이 어긋나지 않는다.
- **매력포인트·장르의 시트 표시 순서는 디자인 전용 로컬 배열** — `AttractivePoint.allCases`(필력이 마지막)·`NovelGenre.filterGenre`(로맨스 먼저)와 순서가 다르다. 임의로 공용 순서로 되돌리지 말 것.
- **메인 필터 칩은 WSSComponent `WSSFilterButton`(h33·body4)과 다른 화면 전용 칩(h30·body5)** — 서재 디자인이 검색 필터 칩보다 작다. 컴포넌트 재사용으로 교체하지 말 것.
  - ⚠️ 이 칩·토글·시트 버튼의 테두리는 **`.strokeBorder`로 그린다**. `.stroke`면 선의 절반이 프레임 밖으로 나가, 칩 행(가로 ScrollView)·키워드 탭(세로 ScrollView, 첫 줄이 y=0에 붙음)·선택 칩 행에서 **클립돼 테두리가 잘린다**(실제 발생). → WSSComponent CLAUDE.md의 같은 항목이 정본.
- 상단 아이콘 3종(`icAlarm`·`icBookRegister`·`icReset`)은 이 작업(#166)에서 DesignSystem에 추가한 신규 에셋.
- 별점 범위 필터의 "전체 범위(0.0~5.0) = 필터 없음(nil)" 정규화는 도메인(`MyLibraryFilter.setRatingRange`)이 담당 — 시트 VM은 슬라이더 편집값(`ratingMin/Max`)을 **별도 보유**한다(필터 nil이어도 슬라이더는 전체 범위를 그려야 해서).
- 정렬 시트 선택 즉시 적용·닫기(확인 버튼 없음). 디자인상 상단 그래버 없음(`.presentationDragIndicator(.hidden)`). presentation 설정·배경·높이는 **시트 뷰가 자체 보유**하고 콘텐츠는 `.padding(.horizontal,20)`(행마다 X, VStack 전체에 한 번) + `.frame(maxHeight:.infinity, alignment:.top)` + 흰 배경(ReadingPeriodSheet 패턴). `sheetHeight`(detent)는 콘텐츠에 딱 맞춘다(상단여백 + 행 + 간격) — 쿠션 더하기 ❌(빈 공간만 생김).
  - ⚠️ **하단 여백은 콘텐츠에 넣지 않는다** — 시스템이 detent 높이 **아래에 홈 인디케이터 safe area를 더해** 시트를 그린다. 콘텐츠에서 또 주면 여백이 두 겹이 되어 마지막 행 아래가 휑해진다(정렬 시트에서 실제 발생, `bottomPadding` 24 제거). 상단 여백만 명시하면 된다.
  - ⚠️ **`presentationCornerRadius`를 쓰지 말 것** — `presentationBackground(Color)`(iOS 26 글래스 방지용 불투명 흰색)와 함께 쓰면 **배경 사각형이 시트 둥근 모서리에 클립되지 않아 양 옆·하단이 화면 프레임 밖으로 삐져나온다**(실제 발생, 오진으로 헤맴). `presentationBackground`만 두면 시스템 기본 둥근 모서리가 배경까지 제대로 클립한다(ReadingPeriodSheet도 CornerRadius 안 씀).
  - ⚠️ **선택 체크는 `HStack`에 넣지 말고(넣으면 글씨가 가운데 정렬에 밀려 오른쪽으로 이동) 글씨의 `.overlay(alignment:.leading)` + `offset`으로** 얹는다 — overlay는 레이아웃에 영향을 안 줘 글씨는 가운데 그대로 있고 체크만 왼쪽에 나타난다.
- ⚠️ **그리드↔리스트는 스크롤 뷰를 각각 갖고, 안 보이는 쪽도 지우지 않고 숨기기만 한다**(두 화면 공통 `novelScroll(for:)`). 스크롤 뷰 **하나** 안에서 `switch displayMode`로 콘텐츠만 갈아끼우면 SwiftUI가 그 스크롤 뷰의 정체성을 유지해 **contentOffset이 두 모드에 공유된다** — 그리드에서 내린 만큼 리스트도 내려가 있다(실제 발생). 배포 타깃이 iOS 17이라 오프셋을 저장·복원하는 `ScrollPosition`/`onScrollGeometryChange`(iOS 18+)를 쓸 수 없어, **동시에 살려두고 숨기는 것이 유일하게 견고한 방법**이다. 겹쳐 있으므로 `opacity` 외에 `allowsHitTesting(false)`·`accessibilityHidden(true)`를 함께 걸어 탭·VoiceOver가 새지 않게 한다.
  - ⚠️ **숨은 쪽의 `loadMore`(마지막 셀 `onAppear`)를 "지금 보는 모드만"으로 가드하지 말 것** — 그 셀이 이미 `onAppear`를 소진해 **나중에 그 모드로 전환했을 때 무한 스크롤이 되살아나지 않는다.** 열어둬도 중복 요청은 VM의 `loadTask == nil` 가드가 막는다(양쪽 다 25개 끝까지 로드됨을 실측).
  - 필터·정렬 변경 시 두 위치가 함께 맨 위로 돌아가는 건 의도다 — `reloadFromScratch()`가 `isLoading`을 세워 두 스크롤 뷰가 통째로 사라졌다 다시 생기기 때문(목록이 바뀌었으니 위치를 지킬 이유가 없다).
- **그리드/리스트 토글의 흰 원 슬라이드**: 선택된 세그먼트에만 `if`로 원을 그리고 `matchedGeometryEffect`로 잇는 방식은 **이동이 아니라 크로스페이드로 보인다**(SwiftUI가 옛 위치 제거+새 위치 삽입으로 처리 → 슬라이드가 거의 안 보임, 실제 발생). 원 하나를 `.background(alignment:.leading)`에 **항상** 그려두고 `.offset(x:)`만 바꿔야(+`.animation(.spring, value: displayMode)`) 대놓고 미끄러진다.
- **표지는 `AsyncImage`를 직접 쓰지 말고 `WSSNovelCoverImage`(WSSComponent)를 쓴다** — `AsyncImage`는 뷰 정체성이 바뀔 때마다 `.empty` phase부터 다시 시작해 **캐시 히트여도** 빈 표지가 번쩍인다. 그리드↔리스트 토글·스크롤 재활용이 셀을 재생성하므로 이게 매번 도진다. `WSSNovelCoverImage`(범용 `WSSAsyncImage` + 빈 표지 폴백)는 **디코딩된 `UIImage`를 인메모리 캐시에 두고 `init`에서 동기 조회** → 히트면 첫 프레임부터 실제 표지(placeholder 프레임 자체가 안 생김). 처음엔 서재 전용(`LibraryCoverImage`)이었으나 #166에서 WSSComponent로 승격.
