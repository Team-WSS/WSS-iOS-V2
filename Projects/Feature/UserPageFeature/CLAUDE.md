<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# UserPageFeature

내 화면(MyPage)/남의 화면(UserPage) + 전체 피드 목록(UserFeedList) 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.userPage)` / 의존: `BaseDomain`, `ProfileDomain`, `NovelDomain`, `FeedDomain`,
  `SocialDomain`, `CollectionDomain`(#200, MyPage·UserPage 둘 다의 컬렉션 섹션 — 다른 Feature 모듈이
  아니라 이 화면들이 직접 UseCase를 받아 조립한다, 서로 import 못 하는 `CollectionFeature`와는 무관),
  `DesignSystem`, `WSSComponent`, `Logger`
- 진입점:
  - `MypageFeatureFactory.makeView(userID:loadProfileUseCase:loadGenrePreferencesUseCase:loadNovelPreferencesUseCase:loadRegisteredNovelStatsUseCase:loadCollectionPreviewsUseCase:logger:onCollectionTapped:onCollectionItemTapped:onEditProfileTapped:onSettingTapped:onLibraryTapped:)`
    (내 화면 탭 콘텐츠), `.makeEditView(...)`(프로필 편집 — App이 `onEditProfileTapped` 콜백을 받아 조립),
    `.makeCharacterEditSheet(...)`(캐릭터 선택 시트, 예외적으로 Feature 내부에서 직접 연다)
  - `UserPageFeatureFactory.makeView(...)`(유저 페이지) — "활동기록 더보기"도 `onFeedListTapped`
    콜백만 올린다(#201부터, `UserPageView`가 더 이상 로컬로 push하지 않는다).
    `.makeFeedListView(...)`(전체 피드 목록)는 그 콜백을 받은 App이 조립한다.

## MyPage

마이페이지 탭 — 프로필 요약(닉네임·소개·프로필 이미지)·서재 통계·컬렉션·장르 뱃지·작품 취향을 보여주고,
프로필 편집(닉네임·소개·프로필 캐릭터·선호장르)으로 진입한다.

### 핵심 시나리오

- **마이페이지(`MypageView`)**: `onAppear`마다 프로필·장르 뱃지·작품 취향·서재 통계·컬렉션 미리보기
  5개를 병렬 로드(`MypageViewModel.loadMypage`). **탭 복귀마다 다시 로드**한다(1회 가드 없음) — 프로필
  편집에서 저장하고 돌아왔을 때 바뀐 값을 반영해야 해서.
- **컬렉션 섹션(`CollectionSection`, #200)**: "컬렉션 N개" 헤더 행(탭 → `onCollectionTapped`, 목록
  화면으로 이동) + 개수 1 이상이면 그 아래 대표 표지 미리보기 최대 3개(`LoadCollectionPreviewsUseCase.execute(userID:size:3)`,
  마이페이지 전용 API가 없어 컬렉션 목록 API를 `size=3`으로 호출 — `CollectionDomain/CLAUDE.md` 참고).
  `N`은 미리보기 배열 개수가 아니라 그 UseCase가 함께 돌려주는 **전체** 개수다. **미리보기 항목 각각도
  개별로 탭 가능하다(#201)** — `CollectionPreviewRow.onItemTapped(CollectionID)` → `CollectionSection.onItemSelected`
  → `MypageView.onCollectionItemTapped` → `MypageFeatureFactory.makeView`까지 그대로 관통해 App
  (`MypageRootView`)이 그 컬렉션 **상세**로 push한다 — 헤더 탭(목록)과는 별개 목적지·별개 콜백. 실제
  화면 전환은 두 콜백 다 App 몫(`CollectionFeature`와 서로 import 못 함).
  **`UserPageView`(타유저 프로필)도 같은 `CollectionPreviewRow`를 쓰고, 이 항목 탭·헤더 탭(목록) 둘
  다 #201 후속(2026-08-28)으로 마이페이지와 동일하게 App까지 배선됐다** — 아래 UserPage "핵심
  시나리오"·"주의사항" 참고.
- **스크롤 반응형 네비 타이틀·배경(2026-08-28)**: 프로필 섹션이 화면 밖으로 스크롤되면(`minY < -1`,
  `mypageScrollCoordinateSpace` 기준) 툴바 principal에 "마이페이지"가 뜬다 — `UserPageView`와 동일
  패턴(`opacity` 아니라 `if`로 구조적으로 넣고 뺀다, `Feature/CLAUDE.md` 공통 주의사항 참고). **다른
  점 하나**: `UserPageView`는 프로필 헤더가 `wssPrimary20`이라 툴바 배경이 스크롤에 따라
  `wssPrimary20`↔`wssWhite`로 전환되지만, `MypageView`는 그런 색 헤더가 없어 **`.toolbarBackground`를
  스크롤과 무관하게 항상 `wssWhite`로 고정**한다(`.toolbarBackground(.visible, for:)`도 함께 강제 —
  기본값은 스크롤 전 투명이라 안 걸면 콘텐츠가 비친다).
- **프로필 편집(`MyPageEditView`) 진입은 App 몫**(#196~#197) — `MypageView`는 연필 아이콘 탭 시
  `onEditProfileTapped()` 콜백만 부르고, 실제로 `MypageFeatureFactory.makeEditView`를 조립해 push하는 건
  App(`MypageRootView`)이다("화면 간 연결 조립은 무조건 App" 원칙, 사용자 확정 — 컬렉션 섹션과 동일 원칙을
  편집에도 확장 적용, 예전엔 이 화면이 `navigationDestination`으로 `makeEditView`를 직접 push했다).
  `MyPageEditView` 자신은 여전히 저장 성공 시 스스로 `@Environment(\.dismiss)`로 닫힌다(안 바뀜) —
  "저장됨" 토스트는 **App이** `onSaved` 콜백을 받아 띄운다(예전엔 `MypageView`가 띄웠음). App 쪽에서
  `onSaved`에 또 `path.removeLast()`를 넣으면 `dismiss()`와 겹쳐 이중 pop이 되니 주의(`App/CLAUDE.md` 참고).
- **툴바 톱니바퀴(`onSettingTapped`)·서재 블록(`onLibraryTapped`)도 같은 원칙**(#197) — 둘 다
  `MypageView`는 콜백만 부르고 실제 조립은 App(`MypageRootView`)이 한다. 단 **서재는 "화면 전환"이
  아니라 "탭 전환"**이라 App이 `MypageFeatureFactory.makeView`에 push용 콜백이 아니라 `MainTabView`의
  `TabView(selection:)`을 바꾸는 클로저를 그대로 물려준다(`App/CLAUDE.md`의 "다른 탭으로 전환" 항목
  참고) — `MypageView`/`MypageFeatureFactory` 입장에선 둘 다 그냥 `() -> Void` 콜백이라 차이가 안 보인다.
- **캐릭터 선택(`MypageCharacterEditSheet`)은 예외 — App으로 옮기지 않는다**(사용자 확정, #196).
  프로필 편집 화면의 `+` 버튼 → `.sheet(item:)`으로 여전히 `MyPageEditView` 내부에서 직접 진입한다.
  다른 화면으로의 이동이 아니라 **이 화면 자신의 draft를 채우는 로컬 값 선택기**라서다 — App으로
  올리면 결과(선택 캐릭터 ID)를 다시 이 화면 내부 `viewModel`로 넣어주는 `Binding` 왕복이 필요해져
  오히려 더 꼬인다. 확인 결과는 그대로 `onApply` 콜백으로 부모(`MyPageEditView`)에 위임하고, draft
  반영·시트 dismiss는 부모 책임.

### 주의사항 (작업 중 발견 시 누적)

- **네비바 교체(#244)**: `MyPageEditView`(프로필 편집, 완료 버튼=`trailing`)와 `UserFeedListView`(활동 목록)는 플랫 `WSSNavigationBar` + `.wssCustomNavigationBar()`로 교체(정본 [WSSComponent](../../UI/WSSComponent/CLAUDE.md), 둘 다 미저장 확인 알럿이 없어 스와이프백 허용).
- **`MypageView`·`UserPageView`는 `WSSNavigationBar`가 아니라 커스텀 몰입형 상단 바로 교체했다**(#244, `NovelDetailView` 결) — 스크롤 반응형(타이틀·배경 전환)이라 back+title 고정형 `WSSNavigationBar`가 안 맞아서다. 둘 다 시스템 툴바(+`.toolbarBackground`)를 걷어내고 `safeAreaInset(edge:.top)`으로 커스텀 바를 고정한다. **`MypageView`**: 뒤로가기 없는 탭 루트라 우측 설정 아이콘 항상 + "마이페이지" 타이틀 페이드인(`mypageTopBar`, 흰 배경). **`UserPageView`**: back + threedots + 닉네임 페이드인, 바 배경이 히어로와 이어지는 `primary20`↔스크롤 후 `wssWhite`로 전환(`userPageTopBar`, push 화면이라 `.wssCustomNavigationBar()`로 스와이프백). ⚠️ **커스텀 오버레이라 `.opacity`/색 전환이 그대로 반영된다** — 아래 "스크롤 반응형 네비 타이틀" 항목의 `if 구조 토글`(시스템 `.principal` UIKit 브리지 함정 회피책)은 **더 이상 이 두 화면에 적용되지 않는다**(그 함정은 시스템 툴바에서만 났다). ⚠️ **스크롤 전환 애니메이션(`isScrolledFromTop`)은 사용자 선호로 제거돼 즉시 전환한다**(#244 후속, 정본 [WSSComponent](../../UI/WSSComponent/CLAUDE.md) — 되살리지 말 것).
- **미리보기 카드 렌더(`CollectionPreviewRow`, `Sources/Component/`)는 `MypageView.swift`에 미사용
  상태로 있던 죽은 코드(`collectionItem`)를 되살린 것이다**(#200) — 대표 표지 1장 + 뒤에 오프셋된 회색
  사각형 2장(쌓인 카드 장식)이 `CollectionPreview.representativeNovel` 요구사항과 정확히 일치해 그대로
  재활용했다. 단, 원래 코드는 raw `AsyncImage`를 썼는데 **URL이 nil이면 `.empty` phase에서 영영 못
  벗어나 `ProgressView()`가 멈추지 않고 계속 돈다**(죽은 코드라 아무도 이 버그를 못 봤다 — 되살리며
  실측으로 발견) → `WSSNovelCoverImage(url:)`로 교체해 고쳤다(WSS 빈 표지 폴백으로 대체됨,
  `WSSComponent/CLAUDE.md` 정본). 이 화면의 다른 표지 자리에서 raw `AsyncImage`를 새로 쓰지 말 것.
  - **`CollectionSection`(MyPage, "컬렉션 N개" 카운트-인라인 헤더)과 `UserPageView.userPageCollectionSection`
    (UserPage, "컬렉션" 플레인 타이틀+화살표, "서재"/"장르취향"과 동일 헤더 스타일)은 헤더만 각자 로컬로
    짓고 미리보기 항목 렌더는 `CollectionPreviewRow`로 공유한다** — `GenreSection`(이 모듈 로컬)이
    "콘텐츠만" 공용이고 타이틀 행은 화면마다 로컬인 것과 동일 분리(#200 후속). 두 화면의 헤더를
    억지로 하나로 통일하려 하지 말 것 — Figma가 화면마다 다르게 그렸다. **서재 통계 블록은 이 분리에서
    한 걸음 더 나가 `WSSComponent.WSSLibrarySection`으로 완전히 승격됐다**(2026-08-25, 사용자 명시
    요청) — 콘텐츠뿐 아니라 배경·숫자 컬러까지 두 화면이 완전히 같은 값으로 고정됐기 때문
    (`WSSComponent/CLAUDE.md` 참고). 컬렉션 섹션처럼 헤더가 화면마다 다르게 생긴 컴포넌트를 이 방식대로
    또 승격하려 하지 말 것 — 승격은 "완전히 동일해진 것"에 한정된다.
  - ⚠️ **미리보기 좌우 여백(26)·아이템 간격(32)은 개수(1·2·3개)와 무관하게, 그리고 기기 폭과도
    무관하게 항상 정확히 고정한다 — 대신 아이템 폭은 상한 없이 "3칸(API 캡 상한) 기준으로 화면을
    정확히 채우는 값"으로 계산해 기기가 넓을수록 커진다**(사용자 확정, 2026-08-27). 아이템 폭은
    실제 개수가 아니라 **항상 3으로 나눠 계산**한다 — 개수로 나누면 1개일 때 아이템이 3개 꽉 찼을
    때보다 커져버려 "개수가 바뀌면 같은 기기에서도 크기가 달라 보이는" 문제가 생긴다(크기가
    달라지는 축은 오직 화면 폭(기기)이어야 하고, 개수는 "몇 칸을 채우느냐"에만 영향을 준다).
    3개(꽉 찼을 때)는 정확히 화면을 채워 좌우 여백이 항상 정확히 26이고, 1·2개는 3칸분 자리 중
    못 채운 칸만큼이 trailing(맨 오른쪽)에 남는 좌측 정렬이다.
    ⚠️ **한때 아이템 폭에 상한(88)을 뒀다가 되돌렸다** — 상한을 두면 화면이 넓은 기기(Pro Max 등)
    에서 3칸 계산값이 상한을 넘어 남는 공간이 전부 여백으로 몰려, "여백 26 고정"이라는 핵심 약속이
    기기가 넓어질수록 깨졌다(실측 확인 — 17 Pro에서 좌우 여백 약 37pt였던 게 Pro Max에서 약 56pt로
    벌어짐). "여백 고정"과 "아이템 크기 고정" 중 **여백 고정을 우선**하기로 사용자가 확정했다 —
    대신 아이템(표지)은 기기가 넓을수록 그만큼 커진다(원래 처음 상한 없이 시도했을 때 "너무 크다"는
    피드백을 받았던 적이 있으니, 이 트레이드오프를 잘 모르고 상한을 다시 넣지 말 것 — 여백 고정이
    최종 결론이다). **헤더 행의 좌측 패딩(20)과는 의도적으로 다른 값**이라 헤더 타이틀과 미리보기
    시작 위치가 6pt 어긋나지만(1·2개 좌측 정렬 케이스에 한함), 그 어긋남 자체를 사용자가
    받아들였다 — 다시 20으로 맞추려 하지 말 것.
    구현은 `CollectionPreviewRow.swift`의 private `Layout` 구현체(`FillingLeadingRowLayout`,
    `referenceItemCount = 3`을 항상 나눗셈 기준으로 씀, 상한 파라미터 없음) — 표지·장식 사각형은
    `Metric.coverAspectRatio`로 아이템 폭에 비례해 함께 커지고 작아지지만, 장식의 겹침 정도
    (`.offset(x: 7/14)`)는 고정 픽셀로 남겨뒀다(비례시키려면 실제 렌더 폭을 다시 읽어야 해
    `GeometryReader` 재도입이 필요한데, 장식 디테일이라 단순화했다 — 큰 화면에서 어색해 보이면
    그때 확장 검토).
    ⚠️ **표지 컨테이너에 `.padding(.trailing, Metric.decorationOffset)`을 반드시 걸어야 한다** —
    안 걸면 표지가 아이템 칸 폭을 꽉 채운 뒤 장식 사각형(`.offset(x: 14)`)이 그 위로 더 튀어나가
    옆 아이템과의 간격(32)을 침범해 간격이 좁아 보인다(실측, 2026-08-27 — 기존 고정폭(88) 설계는
    표지(73)가 박스(88)보다 좁아 그 여유 안에서 장식이 튀어나왔던 것인데, 표지가 칸 전체를 채우는
    지금 구조에선 그 여유를 명시적으로 남겨줘야 한다).
    ⚠️ **`Layout.sizeThatFits`에서 서브뷰 이상적 높이를 `.unspecified`(폭 무제약)로 물으면 안 된다**
    — 아이템이 `aspectRatio` 기반이라 폭이 무제한이라고 답하면 그 비율에 맞춰 높이도 비정상적으로
    커진 값을 보고해버려, 컨테이너가 그 거대한 높이를 실제 프레임으로 할당해 표지가 화면을 거의
    다 덮고 아래 섹션과 겹쳐 보이는 버그로 실제 재현됐다(1개 데모 시나리오에서 발견) — 반드시
    `placeSubviews`와 동일하게 **실제로 배치될 폭**으로 물어야 한다.
    ⚠️ **이 화면은 거의 같은 방향(동일폭 슬롯 leading 정렬 → `GeometryReader`로 폭을 재 간격 역산)을
    두 번 시도했다가 되돌린 이력이 있다** — `GeometryReader` 방식은 폭 측정에 한 프레임이 걸려
    **처음 그려질 때 항목이 몰려있다가 다음 프레임에 벌어지는 게 눈에 띄었다**(실사용자 리포트).
    세 번째 시도(2026-08-27)가 다른 이유: `GeometryReader`로 후측정 후 state로 반영하는 대신
    **SwiftUI `Layout` 프로토콜**(`placeSubviews`가 실제 레이아웃 계산 단계 안에서 동기적으로
    각 서브뷰 폭을 확정)을 써서, "일단 그리고 → 측정값을 읽어 → state로 반영해 다시 그리는" 2단계
    지연 자체가 없다 — 폭 기준 정밀 대칭이 꼭 필요한 자리가 아니면 여전히
    `CollectionCoverStackView`처럼 역산하지 말고 고정값+정렬로 단순하게 가는 게 기본이지만, 이
    화면처럼 **화면 폭에 따라 실제로 늘고 줄어야 하는 요구가 명확할 땐 `Layout` 프로토콜을
    우선 검토할 것** — `GeometryReader` 기반 후측정으로 되돌리지 말 것.
  - ⚠️ **"왼쪽이 더 밀려 보인다"는 리포트를 받아 `GeometryReader`로 좌우 여백을 실측했더니 39pt로
    완전히 대칭이었다**(레이아웃 버그 아님, 2026-08-21) — 원인은 각 항목 표지 뒤 장식 사각형
    (`offset(x:7)`/`offset(x:14)`, "쌓인 카드" 느낌)이 **항상 오른쪽으로만** 겹쳐 그려져 항목 사이
    공간을 시각적으로 채우고, 바깥쪽(첫 항목 왼쪽) 여백만 상대적으로 휑해 보이는 착시로 결론지었다.
    사용자 확정으로 **그대로 둔다** — 이 착시를 다시 "여백 비대칭"으로 오인해 정렬 계산을 건드리지
    말 것. 장식 방향을 바꾸려면(예: 좌우 대칭 오프셋) Figma 원본 "쌓인 카드" 의도를 먼저 재확인.
- ⚠️ **캐릭터 선택 시트는 반드시 `.sheet(item:)`으로 연다.** 처음엔 `.sheet(isPresented:)` +
  `characterID`/`nickname`을 시트 밖 별도 State로 들고 있었는데, Feature 레이어 공통 함정
  ([상위 CLAUDE.md](../CLAUDE.md) "시트에 진입 파라미터...") 그대로 **세션 첫 오픈에서만** 그 시점의
  값이 굳어 엉뚱한 캐릭터가 선택 상태로 보였다. 진입 파라미터(`characterID`+`nickname`)를
  `CharacterEditSheetContext: Identifiable`로 묶어 `.sheet(item:)`으로 넘기도록 고쳤다 —
  `.sheet(isPresented:)` + 별도 State 조합으로 되돌리지 말 것.
- ⚠️ **마이페이지 재로드는 `MypageViewModel.isInitialLoading`을 통해서만 로딩 뷰를 띄운다.**
  `state.isLoading`을 직접 보면, 탭 복귀마다 다시 로드하는 정책과 만나 이미 그린 화면 위로 전체 화면
  `LoadingView`가 매번 깜빡인다(HomeFeature와 같은 이유·같은 해법 — `hasLoadedContent` 플래그로
  "아직 보여줄 게 없을 때만" 로딩을 씌운다).
- ✅ **`MypageView`는 #244에서 인증 만료 라우팅이 들어왔다** — `MypageViewModel`이 `State.requiresAuthentication` +
  `routeToLoginIfAuthenticationRequired(_:)`를 두고 `presentError` 최상단에서 실패 뷰보다 먼저 걸러 `return`한다
  (그래서 로드 401은 `NetworkErrorView`로 덮이지 않고 로그인 유도로 간다 — 예전엔 조용히 빈/실패 상태로 남았다).
  View가 `onChange(of:requiresAuthentication)` → `onAuthenticationRequired`(`MypageFeatureFactory.makeView`까지
  전달, 기본값 `{}`)로 올리고 App(`MypageRootView`)이 그 탭의 `onAuthenticationRequired`로 연결한다.
  ⚠️ **`UserPageView`(타유저 프로필)·`UserFeedListView`(활동 피드)엔 아직 없다** — 이 두 화면은 이번 범위 밖으로
  `docs/TODO.md`의 "UserPage 계열 인증 만료 로그인 라우팅 배관" 항목에 남아 있다(같은 모듈이라고 이미 됐다고
  넘겨짚지 말 것 — MyPage만 배선됐다).
- ⚠️ **글자수 제한이 있는 `TextField`는 VM 상태에 직접 물리지 않는다.** `Binding(get:set:)`의 `set`에서
  곧바로 clamp하면, `get`이 SwiftUI가 방금 그 필드에 마지막으로 써준 값과 같아져 "변화 없음"으로 판단되고,
  **네이티브 텍스트필드는 사용자가 입력한 초과분을 화면에 그대로 들고 있는다**(카운터는 맞는데 눈에 보이는
  글자 수는 안 맞음 — 시뮬레이터 실측 확인). 로컬 `@State` 문자열에 물린 뒤 `.onChange`에서 "clamp → 다르면
  로컬에 재대입(진짜 변경으로 인식돼 네이티브 필드가 강제로 되돌아감) → 같으면 VM에 전달"의 2단계로
  처리한다. **닉네임 필드는 이 처리를 `WSSComponent`의 `WSSNicknameField`가 내부에서 대신 한다**(2026-08
  승격 — `MyPageEditView`가 로컬 `nicknameFieldText`를 직접 들던 걸 이걸로 교체) — `MyPageEditView`가
  갖는 로컬 버퍼는 소개글(`introductionFieldText`, `ProfileDraft.maxIntroductionLength`=50)뿐이다. 글자수
  제한이 있는 새 `TextField`를 만들 때(닉네임이 아니면) 이 2단계 패턴을 재사용할 것 — 일반 규칙은
  [상위 CLAUDE.md](../CLAUDE.md) 주의사항 참고.
- ⚠️ **`MyPageEditView`의 닉네임/소개 필드는 `@FocusState`를 각자 따로 갖는다**(`isNicknameFocused`/
  `isIntroductionFocused`, #178) — 원래 하나(`isKeyboardFocused`)를 공유했는데, 포커스된 필드만 배경을
  화이트로·테두리를 `wssGray70`으로 보여주는 처리를 추가하면서 공유로는 **어느 필드가 실제로 포커스인지
  구분이 안 돼** 한쪽만 눌러도 둘 다 스타일이 바뀌었다. "빈 곳 탭하면 키보드 내리기"(`content`의
  `onTapGesture`)는 두 `FocusState`를 함께 `false`로 내리면 된다 — 필드별 포커스-구동 스타일이 있는 화면에서
  여러 텍스트필드가 키보드 내리기 목적으로 상태를 공유하던 걸 그대로 새 필드에 복제하지 말 것.
- ⚠️ **`MypageCharacterEditSheet`의 `characterItemSize(for:)`는 결과를 `max(0, ...)`로 클램프한다.**
  `GeometryReader`가 시트 프레젠테이션 애니메이션 도중 과도기적으로 아주 좁은 폭을 보고하는 프레임이 있는데,
  클램프 없이 그 값을 `.frame(height:)`/`GridItem(.fixed:)`에 그대로 흘리면 결과가 음수가 되어 SwiftUI가
  "Invalid frame dimension (negative or non-finite)" 런타임 이슈를 낸다(화면은 다음 프레임에 정상 폭으로
  바로 잡혀 눈에는 안 보일 수 있음 — Xcode 이슈 내비게이터로만 확인됨). `GeometryReader` 폭으로 그리드
  아이템 크기를 계산하는 새 화면을 만들 때 이 클램프를 잊지 말 것.

## UserPage

남의 프로필 화면 — 통계/활동(피드 미리보기) + 전체 피드 목록(`UserFeedListView`), 차단·신고.

### 핵심 시나리오

- **재진입(push 복귀)은 조용한 재조회다**(#236, V1 parity 복원 — `NovelDetailViewModel.load` 정본 패턴):
  `UserPageViewModel.load()`가 `hasLoaded` 후에도 재진입마다 프로필 묶음을 스피너 없이 제자리 교체하고,
  활동 탭 미리보기도 이미 로드된 적 있으면 첫 페이지를 같이 재조회한다(실패 시 기존 화면 유지 —
  단 비공개 전환(`privateProfile`) 반영은 **활동 피드 조회 경로에만** 있다: `loadFirstFeedsPage`가 두 모드
  모두 `isProfilePrivate`를 세우고, 프로필 묶음 silent 실패는 전부 조용히 유지된다). **전체 피드 목록
  (`UserFeedListViewModel`)도 동일** — 재진입 시 첫 페이지 조용한 교체(페이지네이션 리셋, V1의 "비우고
  처음부터 + 로딩뷰" 대신). 모든 로드가 단일 Task 가드(`loadTask`/`feedsTask == nil`)로 직렬화돼 취소 장치
  없이 안전하다.
  - **깊이 스크롤 후 복귀 시 목록이 첫 페이지로 줄어드는 건 판정된 절충이다**(#236 리뷰에서 인지) —
    NovelDetail 피드는 `size = 보던 개수` 정책(`NovelFeedPageSizePolicy`)으로 window를 보존하지만, 이
    화면(과 알림 목록)은 push 복귀의 목적이 "최신순 맨 위 갱신"이고 `LoadUserFeedsUseCase`에 size 배관이
    없어 비용 대비 이득이 작아 1페이지 리셋을 감수한다. 되살리려면 피드 쪽과 같은 Repository size 배관이 선행.
  - **통째 교체는 진행 중 낙관 좋아요를 되덮을 수 있어 병합으로 보호한다**(#236) — 첫 페이지 교체 직전
    "요청 시작 시 in-flight + 요청 중 토글"(`syncingLikeFeedIDs` ∪ `likeToggledDuringRefresh`) 셀만
    `TotalFeed.preservingLikeState`(좋아요 두 필드만 로컬 우선)로 병합한다. `NovelDetailViewModel.refreshFeeds`가
    정본 패턴 — 셀 전체를 로컬로 되돌리면 그 사이 서버 변경(본문 수정 등)까지 버리므로 두 필드만.
- **서재 블록(화살표 아이콘·통계 행) 탭 → 이 유저의 서재 진입은 App 몫**(#196) — `UserPageView`는
  `onLibraryTapped()` 콜백만 부르고, 실제로 `LibraryFactory.makeUserLibraryView`를 조립해 push하는 건
  App(`UserPageAssembly`를 소비하는 탭 Root — 지금은 `FeedRootView`뿐)이다. 두 탭 자리(화살표 아이콘 +
  `LibrarySection` 블록 전체) 모두 같은 콜백을 부른다 — 어느 쪽을 눌러도 같은 화면으로 간다.
- **차단**: 툴바 threedots 드롭다운("차단하기") → `WSSAlertType.blockUser` 확인 알럿 → `BlockUserUseCase`. **성공하면 화면을 dismiss한다**(`state.shouldDismiss`) — 차단하면 상대 프로필을 다시 볼 수 없어 화면에 남아있을 이유가 없다는 판단(사용자 확정).
  - **차단했어요 크로스스크린 안내 seam(#221)** — V1은 차단 성공 시 `NotificationCenter.blockUser(nickname)`를 post해 **복귀 화면**이 "차단했어요" 토스트를 띄웠다(V2 parity 대상, `V1_BEHAVIOR_CONTRACT.md` 4.6). 이 화면은 차단 성공과 동시에 pop되므로 토스트는 자기가 못 띄운다 — `UserPageView.onUserBlocked(nickname)` 콜백을 `shouldDismiss` 전이에서 `dismiss()` **직전**에 부르는 것까지만 뚫어뒀다(Factory·`UserPageAssembly`까지 전달, 전부 기본 no-op). `shouldDismiss`가 **차단 성공에서만** 켜지므로(뒤로가기는 툴바 버튼이 직접 `dismiss`) 이 전이 = 차단 성공으로 봐도 된다. **실제 토스트("{nickname}님을 차단했어요")는 App의 통합 크로스스크린 피드백 채널이 띄운다**(#236 — `App/Sources/Main/CrossScreenFeedback.swift`, `feedEdited`·`novelReviewed`와 한 채널. #221의 4탭 4벌 복붙은 이 채널로 흡수됨). 각 탭 Root가 `onUserBlocked`를 받아 `crossScreenFeedback.present(.userBlocked(nickname:))`로 연결하고, 토스트는 `NavigationStack` **컨테이너** 오버레이라 pop 후 최상단이 된 **직전 뷰**(소소피드/피드상세/작품상세 등) 위에 뜬다. V1은 전역 `NotificationCenter.blockUser`를 **피드 탭 하나(`FeedViewController`)만** 캐치해 띄웠던 것과 달리, V2는 **차단한 바로 그 탭**에서 뜬다(더 정확).
- **피드 신고**: 피드 셀 threedots 드롭다운("스포일러 신고"/"부적절한 표현 신고", 빨강) → 확인→접수완료 2단 알럿(`FeedAlert` 의미값, `NovelDetailFeature`와 동일 패턴) → `ReportSpoilerFeedUseCase`/`ReportImproperFeedUseCase`. 차단·신고 실패는 `hasActionError` 토스트(`.unknownError`)로 공유(카피가 같아 굳이 안 나눔).
- **"활동" 탭은 미리보기(최대 5개)만** 보여준다(`UserPageViewModel.visibleFeeds`). 6개 이상(`hasMoreFeeds`)이면 "전체보기" 버튼 → `UserFeedListView`(무한스크롤 전용 화면, 별도 `UserFeedListViewModel`)로 이동. **#201부터 App이 조립한다** — `UserPageView`는 `onFeedListTapped(userID, nickname, profileImage)` 콜백만 올리고(이미 로드해둔 프로필 값을 그대로 실어 보낸다), 실제로 `UserPageFeatureFactory.makeFeedListView(...)`를 호출하는 건 App(`UserPageAssembly.makeFeedListView`, 그 콜백을 받은 각 탭 Root)이다 — 예전엔 `SettingFeature`의 내부 네비게이션과 같은 패턴으로 View 자신이 로컬 push했지만, 그 패턴 자체가 걷어내는 대상이 됐다.
- **비공개 프로필**: 서버가 `USER-015`로 응답하면(장르/작품 취향/피드 조회 각각) `RepositoryError.privateProfile` → **스티키 헤더(통계/활동 탭)는 그대로 두고 그 아래 콘텐츠 영역만** "비공개 프로필이에요" 안내로 대체한다(사용자 확정 — 처음엔 화면 전체를 대체했다가 탭 자체가 사라지는 문제로 `Section` 내부로 옮김). 재시도 버튼 없음(상대가 설정을 바꾸기 전엔 의미 없음).
- **컬렉션 섹션(#200)의 타이틀 행은 컬렉션 개수와 무관하게 항상 노출된다**(사용자 확정, 2026-08-25 —
  **이전엔** `viewModel.state.collectionCount > 0`일 때만 섹션 전체를 보여줬다). 0개면 타이틀 행만
  보이고 그 아래 미리보기 행(`CollectionPreviewRow`)만 생략되며, **행 전체를 탭하면**(`.contentShape(Rectangle())`
  로 넓힌 히트영역, 마이페이지 `CollectionSection.header`와 동일 패턴) `WSSToastType.noCollections`
  ("컬렉션을 등록하지 않은 유저에요") 토스트로 안내한다(`UserPageViewModel.tapCollectionSection()`).
  컬렉션이 있을 때의 탭은 여전히 목록 이동 TODO뿐이다(아래 항목 참고). `LoadCollectionPreviewsUseCase.execute(userID:size:)`는
  대상 사용자 userID를 명시로 받는 계약이라(`CollectionDomain/CLAUDE.md`) 이 화면의 `userID`(프로필
  대상, `.me`가 아님)를 그대로 넘긴다.
- **스크롤 반응형 네비 타이틀**: 프로필 섹션이 화면 밖으로 스크롤되면(`minY < -1`) 툴바 principal에 닉네임이 페이드인한다 — `PreferenceKey` 대신 `GeometryReader` 안에서 `onChange`로 `@State`를 직접 갱신(`NovelDetailFeature`와 동일 패턴/동일 이유, 이 SDK는 `onPreferenceChange`→`@State` 갱신이 먹지 않는다).
- ⚠️ **핀 고정 스티키 탭 헤더(`stickyHeaderSection`, 통계/활동)엔 불투명 배경(`.background(wssWhite)`)이 필수다** — 이 화면은 `LazyVStack(pinnedViews: [.sectionHeaders])`로 탭 헤더를 고정하는데(NovelDetail·Collection의 "오버레이 2벌"과 다른 방식), 헤더 배경이 없으면 스크롤된 아래 콘텐츠(컬렉션 미리보기 등)가 헤더의 투명 영역을 통해 **네비바 바로 아래로 비쳐 보인다**("틈새로 컬렉션 보임", #244 사용자 실측). NovelDetail 스티키 탭바(`NovelDetailView.tabBar`)도 같은 이유로 흰 배경을 둔다 — pin 방식이든 오버레이 방식이든 **스티키 헤더는 불투명 배경이 원칙**.
- **툴바 배경은 스크롤에 따라 `wssPrimary20`↔`wssWhite`로 전환된다**(닉네임 타이틀 페이드인과 동일 트리거 `isScrolledFromTop`) — `.toolbarBackground(color, for: .navigationBar)`만으로는 기본이 "스크롤 전엔 투명, 후엔 표시"라 `.toolbarBackground(.visible, for: .navigationBar)`를 명시로 강제해야 배경 자체가 항상 보인다(색은 별개로 스크롤 상태에 따라 계산).
- **프로필 헤더 배경(`wssPrimary20`)은 위로만 오버슈트한 사각형으로 확장**해 위로 당겨 바운싱해도 흰 배경이 안 비치게 한다(`profileSection`의 두 번째 `.background(alignment: .top)`, height 1000 + offset -1000).
- **하단 바운싱 배경은 `ScrollView` 자체에 건 `.background(wssWhite)`로 채운다**(`UserPageView.body`, 콘텐츠 안 개별 섹션이 아니라 `ScrollView` 뷰 바로 뒤). `ScrollView`(뷰 자체)에 건 배경은 뷰포트에 고정되어 스크롤과 무관하게 항상 보이는 반면, 콘텐츠(LazyVStack 안 섹션)에 건 배경은 콘텐츠와 함께 스크롤되어 바운싱 시 빈 공간을 못 채운다 — 그래서 profileSection처럼 콘텐츠 쪽에 오버슈트 사각형을 추가하는 대신 뷰포트 레벨 배경을 택함. 상단은 profileSection의 오버슈트가 이 위에 덮여 primary20이 우선한다.

### 주의사항 (작업 중 발견 시 누적)

- **`UserPageFactory.makeView`의 첫 실제 App 소비자는 피드 탭이다**(#196, `App/UserPageAssembly.swift` →
  `FeedRootView`가 피드 셀 프로필 탭에서 push) — 홈·서재 탭엔 아직 진입 경로가 없다(연결 작품 배너만
  뚫려 있고 작성자 프로필 탭 자체가 없는 화면들이라서). 다른 화면에 유저 프로필 진입이 필요해지면
  `UserPageAssembly`를 재사용할 것 — App이 UseCase를 다시 조립하지 않는다. 그 화면에서 다시 여는
  타유저 서재(`onLibraryTapped` → `LibraryFactory.makeUserLibraryView`)도 마찬가지로 지금은
  `FeedRootView`만 배선했다 — `UserPageAssembly.makeView`에 `onLibraryTapped` 콜백이 있으니 다른
  탭이 `UserPageAssembly`를 재사용하면 그 콜백만 채우면 된다.
- ⚠️ **`Demo/UserPageFeatureDemoApp.swift`의 `makeMypageView`는 `onEditProfileTapped`/`onSettingTapped`/
  `onLibraryTapped`를 전부 콘솔 로그만 찍는 no-op으로 연결한다**(`onCollectionTapped`와 동일 패턴) —
  develop 라인 #200 컬렉션 통합과 이 브랜치의 #197 콜백 확장이 각자 진행되며 이 Demo가 컴파일이 안
  되게 어긋났던 걸 rebase 중 최소 수정으로 되살렸다(2026-08-28). 실제 push/무시 여부는 아직 미설계 —
  Demo/Preview 필수 원칙([Feature/CLAUDE.md](../CLAUDE.md))상 완전하진 않다는 것만 기록
  ([docs/TODO.md](../../../docs/TODO.md) 10절 — 절 번호는 정리로 밀릴 수 있으니 Demo 항목을 찾을 것).
- `WSSAlertView`의 버튼은 접근성 트리에 안 잡힌다 — UI 자동화(XcodeBuildMCP `tap`)로 알럿이 뜨는 것까지만 검증 가능, 버튼 탭 이후 동작은 코드 리뷰로 대체(WSSComponent 공용 컴포넌트라 이 모듈 범위 밖).
- 피드 셀 threedots 드롭다운의 앵커(`anchorY`)는 `NovelDetailFeedTab`과 동일하게 "셀 상단 패딩(20) + 헤더 높이(32) = 52" 오프셋을 그대로 재사용한다 — `WSSFeadView` 자체에 내장된 값이라 어느 화면에서 셀을 그리든 동일하다.
- `UserPageView`/`UserFeedListView` 둘 다 피드 셀+신고 드롭다운 렌더링 코드가 거의 동일하게 중복돼 있다 — 의도적 선택(`NovelDetailFeature`도 자기 화면 전용 사본을 갖는 것과 같은 이유, 화면마다 앵커 계산·오버레이 배치가 미묘하게 달라질 수 있어 공용화 대신 화면별 사본 유지).
- **없는 유저(`USER-018`)는 "존재하지 않는 유저예요" 전용 화면으로 분기한다**(#222 V1 parity) —
  `fetchUserProfile`이 `USER-018`을 `RepositoryError.notFound`로 던지고(→ [ProfileData](../../Data/ProfileData/CLAUDE.md)),
  `UserPageViewModel.presentError`가 `.notFound`를 `isUserNotFound`로 잡아(`hasLoadError`와 분리) `userNotFoundView`를
  띄운다. **재시도 버튼 없음**(존재하지 않는 유저는 재시도해도 동일 — `privateProfileView`와 같은 결). 이 분기가 없으면
  018이 일반 로드 실패(`NetworkErrorView`)로 떨어져 재시도만 반복된다(회귀). Demo는 "특수 상태 데모" 바로가기(또는 userID `998`)로 시연.
  - ⚠️ **이건 "탈퇴 유저 탭-차단"과 다른 케이스다(혼동 주의 — #222에서 실제로 헷갈렸다).** 탈퇴 유저
    (`Author.userId == -1` 센티널)는 피드/댓글/작품상세에서 프로필을 탭하는 **그 순간** `Author.accessibleUserId == nil`로
    걸러 "웹소소를 떠난 유저예요"(`WSSToastType.unknownUser`) 토스트만 띄우고 **애초에 UserPage에 진입시키지 않는다**
    (`SosoFeedView`·`FeedDetailView`·`NovelDetailFeedTab` 3곳 — V1 `FeedDetailViewModel:277,457`/`NovelDetailViewModel:516`/
    `FeedPageContentViewModel:139`의 `showToast(.unknownUser)` parity). 반면 `USER-018`은 userID로 **실제 조회를 해봐야**
    서버가 주는 값이라 탭 시점엔 알 수 없고, 이미 진입한 뒤의 **방어 폴백**이다(V1도 `UserPageViewModel:311-326`이 빈
    프로필로 폴백하며 "현재 로직상 진입 불가능하지만 대응" 주석을 달았다). 즉 실사용에서 이 화면에 닿을 경로는 사실상
    없고(모든 진입점이 탈퇴 가드로 이미 막힘, 없는 userID로 들어갈 방법이 없음), Demo의 `998`은 그 방어 경로를 인위적으로
    트리거한 것이다. → 탈퇴 유저 처리를 "여기서 토스트+뒤로가기"로 바꾸려 하지 말 것(그건 탭 시점 ①의 몫이고 이미 됨).
- **`USER-015`(비공개 프로필) 감지는 장르·작품 취향·피드 3곳뿐** — 서재 통계(`LoadUserRegisteredNovelStatsUseCase`)는 일부러 대상에서 뺐다. 서버가 이 엔드포인트엔 그 에러코드 자체를 정의하지 않고, 작품 피드는 서버가 비공개 글을 알아서 걸러주기 때문(사용자 확정). "다른 병렬 호출도 다 해줘야 하지 않나" 싶어도 이 셋 이상으로 넓히지 말 것.
  컬렉션 미리보기(`LoadCollectionPreviewsUseCase`, #200)도 서재 통계와 같은 이유로 대상 밖이다 — `DefaultCollectionRepository.fetchCollectionPreviews`가 `code` 문자열 분기 없이 `NetworkingError.toRepositoryError()`로만 넘겨 `.privateProfile`을 던지지 못한다(`CollectionData/CLAUDE.md` 참고). 이 호출이 실패하면 `loadUserPage()`의 같은 `catch`에서 `presentError`가 일반 `hasLoadError`로 처리한다 — 컬렉션만 골라 조용히 숨기는 동작이 아니다.
- **컬렉션 섹션 타이틀 행(`userPageCollectionSection`)·미리보기 개별 항목 탭 둘 다 #201 후속(2026-08-28)으로
  뚫렸다** — `CollectionPreviewRow.onItemTapped`/헤더 `Button`이 각각 `onCollectionItemTapped`/
  `onCollectionListTapped`로 `UserPageFeatureFactory.makeView` → `UserPageAssembly.makeView`까지
  그대로 관통하고, App(홈/피드/서재/My 4탭 Root 전부)이 새로 뽑은 `CollectionDetailAssembly`/
  `CollectionListAssembly`로 각각 상세/목록을 push한다.
  - **헤더 탭은 `viewModel.hasCollections`로 View가 직접 분기한다**(`collectionSectionHeader`) —
    있으면 `onCollectionListTapped()`를 바로 부르고, 없으면 `viewModel.handle(.collectionSectionTapped)`로
    "컬렉션을 등록하지 않은 유저에요" 토스트만 띄운다("서재" 블록과 동일 원칙 — 순수 네비게이션은
    View가 콜백을 직접 부르고 VM은 상태만 관리, `UserPageViewModel.tapCollectionSection()`도 이제
    토스트 설정 하나만 한다).
  - **`CollectionFeature.CollectionListView`는 "내 컬렉션"/"좋아요한 컬렉션" 2탭인데 "좋아요한" 탭이
    세션 토큰=로그인 사용자 자신 기준이라 타유저 프로필에 그대로 재사용할 수 없었다** — `CollectionListView`/
    `CollectionFeatureFactory.makeCollectionListView`에 `isOwnCollections: Bool`(기본 `true`)을 추가해
    풀었다. `false`(App은 `CollectionListAssembly`로 기본값을 이렇게 둔다)면 세그먼트 탭·"컬렉션
    만들기" 버튼을 숨기고 "내 컬렉션"(`userID` 기준, 항상 타유저) 콘텐츠만 보여준다 — 세그먼트 탭이
    없어 `viewModel.state.selectedTab`이 전환될 방법이 없으므로 `CollectionListViewModel`은 손대지
    않았다(기본값 `.mine`에 계속 머문다). 자세한 계약은 `CollectionFeature/CLAUDE.md` 참고.
  - `onEditTapped`(`CollectionDetailAssembly`)는 기본값 no-op으로 둔다 — 타유저 프로필에서 여는
    컬렉션은 항상 남의 것이라(`detail.isMine == false`) "컬렉션 수정" 버튼 자체가 안 뜬다(마이페이지만
    실제 `onEditTapped`를 채워 자기 컬렉션 편집 진입점으로 쓴다).
- ⚠️ **조용한 재조회(`load()`→`loadUserPage(isSilentRefresh:)`)는 병렬(`async let`) 5개 결과를 로컬
  변수로 다 받은 뒤 `state`에 일괄 대입한다(#236)** — 받는 족족 `state`에 대입하면 중간 하나가 실패했을 때
  실패 지점 앞의 값만 새로 교체돼 프로필 묶음이 부분 갱신된 채 남고(닉네임은 새 값·통계는 옛 값 등),
  "실패해도 기존 화면 유지"라는 조용한 재조회 계약이 깨진다. fresh 경로는 실패 시 `presentError`로 전면
  덮여 안 보이지만 silent는 그대로 드러난다. `MypageViewModel.loadMypage`도 같은 5개 병렬 로드 구조라,
  조용한 재조회를 얹을 땐 동일하게 일괄 대입해야 한다.
  - 알려진 절충(#236 리뷰에서 수용): 재조회 중 프로필 조회와 활동 피드 조회가 병렬이라, 그 사이 상대가
    프로필을 바꾸면 피드 author 닉네임(응답에 없어 호출 측 프로필 값으로 채움)이 한 박자 옛 값일 수 있다 —
    창이 매우 좁고 다음 재진입에 자가 치유되므로 순차화하지 않는다.
