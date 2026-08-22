<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# UserPageFeature

내 화면(MyPage)/남의 화면(UserPage) + 전체 피드 목록(UserFeedList) 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.userPage)` / 의존: `BaseDomain`, `ProfileDomain`, `NovelDomain`, `FeedDomain`,
  `SocialDomain`, `CollectionDomain`(#200, MyPage·UserPage 둘 다의 컬렉션 섹션 — 다른 Feature 모듈이
  아니라 이 화면들이 직접 UseCase를 받아 조립한다, 서로 import 못 하는 `CollectionFeature`와는 무관),
  `DesignSystem`, `WSSComponent`, `Logger`
- 진입점:
  - `MypageFactory.makeView(userID:loadProfileUseCase:loadGenrePreferencesUseCase:loadNovelPreferencesUseCase:loadRegisteredNovelStatsUseCase:loadCollectionPreviewsUseCase:loadInitialProfileUseCase:loadProfileCharacterUseCase:validateNicknameUseCase:updateProfileUseCase:onCollectionTapped:logger:)`
    (내 화면 탭 콘텐츠), `.makeEditView(...)`(프로필 편집), `.makeCharacterEditSheet(...)`(캐릭터 선택 시트)
  - `UserPageFactory.makeView(...)`(유저 페이지), `.makeFeedListView(...)`(전체 피드 목록 — `UserPageView`의 "전체보기"가 내부적으로 호출)

## MyPage

마이페이지 탭 — 프로필 요약(닉네임·소개·프로필 이미지)·서재 통계·컬렉션·장르 뱃지·작품 취향을 보여주고,
프로필 편집(닉네임·소개·프로필 캐릭터·선호장르)으로 진입한다.

### 핵심 시나리오

- **마이페이지(`MypageView`)**: `onAppear`마다 프로필·장르 뱃지·작품 취향·서재 통계·컬렉션 미리보기
  5개를 병렬 로드(`MypageViewModel.loadMypage`). **탭 복귀마다 다시 로드**한다(1회 가드 없음) — 프로필
  편집에서 저장하고 돌아왔을 때 바뀐 값을 반영해야 해서.
- **컬렉션 섹션(`CollectionSection`, #200)**: "컬렉션 N개" 헤더 행(탭 → `onCollectionTapped`, 실제
  화면 전환은 App 몫 — `CollectionFeature`와 서로 import 못 함) + 개수 1 이상이면 그 아래 대표 표지
  미리보기 최대 3개(`LoadCollectionPreviewsUseCase.execute(userID:size:3)`, 마이페이지 전용 API가 없어
  컬렉션 목록 API를 `size=3`으로 호출 — `CollectionDomain/CLAUDE.md` 참고). `N`은 미리보기 배열 개수가
  아니라 그 UseCase가 함께 돌려주는 **전체** 개수다.
- **프로필 편집(`MyPageEditView`)**: 연필 아이콘 → `navigationDestination` → `MypageFactory.makeEditView`.
  저장 성공 시 곧바로 `dismiss()`하고, "저장됨" 토스트는 **복귀할 마이페이지가** `onSaved` 콜백을 받아
  띄운다(이 화면에서 sleep으로 노출 시간을 벌면 닫힘이 부자연스럽게 지연되므로).
- **캐릭터 선택(`MypageCharacterEditSheet`)**: 프로필 편집 화면의 `+` 버튼 → `.sheet(item:)`으로 진입.
  확인 결과(선택 캐릭터 ID)는 `onApply` 콜백으로 부모(`MyPageEditView`)에 위임하고, draft 반영·시트
  dismiss는 부모 책임.

### 주의사항 (작업 중 발견 시 누적)

- **미리보기 카드 렌더(`CollectionPreviewRow`, `Sources/Component/`)는 `MypageView.swift`에 미사용
  상태로 있던 죽은 코드(`collectionItem`)를 되살린 것이다**(#200) — 대표 표지 1장 + 뒤에 오프셋된 회색
  사각형 2장(쌓인 카드 장식)이 `CollectionPreview.representativeNovel` 요구사항과 정확히 일치해 그대로
  재활용했다. 단, 원래 코드는 raw `AsyncImage`를 썼는데 **URL이 nil이면 `.empty` phase에서 영영 못
  벗어나 `ProgressView()`가 멈추지 않고 계속 돈다**(죽은 코드라 아무도 이 버그를 못 봤다 — 되살리며
  실측으로 발견) → `WSSNovelCoverImage(url:)`로 교체해 고쳤다(WSS 빈 표지 폴백으로 대체됨,
  `WSSComponent/CLAUDE.md` 정본). 이 화면의 다른 표지 자리에서 raw `AsyncImage`를 새로 쓰지 말 것.
  - **`CollectionSection`(MyPage, "컬렉션 N개" 카운트-인라인 헤더)과 `UserPageView.userPageCollectionSection`
    (UserPage, "컬렉션" 플레인 타이틀+화살표, "서재"/"장르취향"과 동일 헤더 스타일)은 헤더만 각자 로컬로
    짓고 미리보기 항목 렌더는 `CollectionPreviewRow`로 공유한다** — `LibrarySection`/`GenreSection`이
    "콘텐츠만" 공용이고 타이틀 행은 화면마다 로컬인 것과 동일 분리(#200 후속). 두 화면의 헤더를
    억지로 하나로 통일하려 하지 말 것 — Figma가 화면마다 다르게 그렸다.
  - **미리보기 항목 사이 간격은 고정 30. 3개가 꽉 찼을 때는 묶음 전체를 화면 가운데 정렬, 2개·1개일
    땐 헤더 행과 동일한 좌측 인셋(20)에 맞춰 왼쪽 정렬한다**(개수 기준 분기는 사용자 확정,
    2026-08-22 — 처음엔 개수 무관 항상 가운데 정렬이었는데, 2개 이하일 때 가운데 정렬하면 헤더
    타이틀과 미리보기 시작 위치가 어긋나 보여 분기를 추가했다). 3개일 땐 좌우 여백을 얼마로 맞출지
    신경 쓰는 대신 `HStack`(내용물 크기만큼만 차지)을 `.frame(maxWidth: .infinity)`(기본 정렬
    `.center`)로 감싸 가운데로 밀어낸다. 화면 폭에 딱 맞춰 늘어나게 만드는 시도를 두 번(동일폭 슬롯
    leading 정렬 → `GeometryReader`로 폭을 재 간격 역산) 거쳤다가 전부 되돌렸다 — `GeometryReader`
    방식은 폭 측정에 한 프레임이 걸려 **처음 그려질 때 항목이 몰려있다가 다음 프레임에 벌어지는 게
    눈에 띄었다**(실사용자 리포트). 폭 기준 정밀 대칭이 꼭 필요한 자리가 아니면
    `CollectionCoverStackView`처럼 역산하지 말고 이 화면처럼 고정값+정렬로 단순하게 갈 것.
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

- **차단**: 툴바 threedots 드롭다운("차단하기") → `WSSAlertType.blockUser` 확인 알럿 → `BlockUserUseCase`. **성공하면 화면을 dismiss한다**(`state.shouldDismiss`) — 차단하면 상대 프로필을 다시 볼 수 없어 화면에 남아있을 이유가 없다는 판단(사용자 확정).
- **피드 신고**: 피드 셀 threedots 드롭다운("스포일러 신고"/"부적절한 표현 신고", 빨강) → 확인→접수완료 2단 알럿(`FeedAlert` 의미값, `NovelDetailFeature`와 동일 패턴) → `ReportSpoilerFeedUseCase`/`ReportImproperFeedUseCase`. 차단·신고 실패는 `hasActionError` 토스트(`.unknownError`)로 공유(카피가 같아 굳이 안 나눔).
- **"활동" 탭은 미리보기(최대 5개)만** 보여준다(`UserPageViewModel.visibleFeeds`). 6개 이상(`hasMoreFeeds`)이면 "전체보기" 버튼 → `UserFeedListView`(무한스크롤 전용 화면, 별도 `UserFeedListViewModel`)로 push. **`SettingFeature`의 내부 네비게이션과 동일 패턴** — `UserPageView`가 VM이 아니라 View 자신의 `init`으로 필요한 UseCase(`loadUserFeedsUseCase` 등)를 직접 받아뒀다가 `.navigationDestination`에서 `UserPageFeatureFactory.makeFeedListView(...)`를 직접 호출(콜백을 App까지 올리지 않음).
- **비공개 프로필**: 서버가 `USER-015`로 응답하면(장르/작품 취향/피드 조회 각각) `RepositoryError.privateProfile` → **스티키 헤더(통계/활동 탭)는 그대로 두고 그 아래 콘텐츠 영역만** "비공개 프로필이에요" 안내로 대체한다(사용자 확정 — 처음엔 화면 전체를 대체했다가 탭 자체가 사라지는 문제로 `Section` 내부로 옮김). 재시도 버튼 없음(상대가 설정을 바꾸기 전엔 의미 없음).
- **컬렉션 섹션(#200)은 "타유저의 컬렉션이 존재할 경우에만" 통째로 노출된다**(`viewModel.state.collectionCount > 0`, 사용자 확정) — MyPage의 `CollectionSection`이 0개여도 헤더 행을 항상 보여주는 것과 다르다. 장르 취향 섹션이 `hasNoGenrePreferenceData`면 통째로 숨는 것과 같은 패턴을 그대로 따랐다. `LoadCollectionPreviewsUseCase.execute(userID:size:)`는 대상 사용자 userID를 명시로 받는 계약이라(`CollectionDomain/CLAUDE.md`) 이 화면의 `userID`(프로필 대상, `.me`가 아님)를 그대로 넘긴다.
- **스크롤 반응형 네비 타이틀**: 프로필 섹션이 화면 밖으로 스크롤되면(`minY < -1`) 툴바 principal에 닉네임이 페이드인한다 — `PreferenceKey` 대신 `GeometryReader` 안에서 `onChange`로 `@State`를 직접 갱신(`NovelDetailFeature`와 동일 패턴/동일 이유, 이 SDK는 `onPreferenceChange`→`@State` 갱신이 먹지 않는다).
- **툴바 배경은 스크롤에 따라 `wssPrimary20`↔`wssWhite`로 전환된다**(닉네임 타이틀 페이드인과 동일 트리거 `isScrolledFromTop`) — `.toolbarBackground(color, for: .navigationBar)`만으로는 기본이 "스크롤 전엔 투명, 후엔 표시"라 `.toolbarBackground(.visible, for: .navigationBar)`를 명시로 강제해야 배경 자체가 항상 보인다(색은 별개로 스크롤 상태에 따라 계산).
- **프로필 헤더 배경(`wssPrimary20`)은 위로만 오버슈트한 사각형으로 확장**해 위로 당겨 바운싱해도 흰 배경이 안 비치게 한다(`profileSection`의 두 번째 `.background(alignment: .top)`, height 1000 + offset -1000).
- **하단 바운싱 배경은 `ScrollView` 자체에 건 `.background(wssWhite)`로 채운다**(`UserPageView.body`, 콘텐츠 안 개별 섹션이 아니라 `ScrollView` 뷰 바로 뒤). `ScrollView`(뷰 자체)에 건 배경은 뷰포트에 고정되어 스크롤과 무관하게 항상 보이는 반면, 콘텐츠(LazyVStack 안 섹션)에 건 배경은 콘텐츠와 함께 스크롤되어 바운싱 시 빈 공간을 못 채운다 — 그래서 profileSection처럼 콘텐츠 쪽에 오버슈트 사각형을 추가하는 대신 뷰포트 레벨 배경을 택함. 상단은 profileSection의 오버슈트가 이 위에 덮여 primary20이 우선한다.

### 주의사항 (작업 중 발견 시 누적)

- `WSSAlertView`의 버튼은 접근성 트리에 안 잡힌다 — UI 자동화(XcodeBuildMCP `tap`)로 알럿이 뜨는 것까지만 검증 가능, 버튼 탭 이후 동작은 코드 리뷰로 대체(WSSComponent 공용 컴포넌트라 이 모듈 범위 밖).
- 피드 셀 threedots 드롭다운의 앵커(`anchorY`)는 `NovelDetailFeedTab`과 동일하게 "셀 상단 패딩(20) + 헤더 높이(32) = 52" 오프셋을 그대로 재사용한다 — `WSSFeadView` 자체에 내장된 값이라 어느 화면에서 셀을 그리든 동일하다.
- `UserPageView`/`UserFeedListView` 둘 다 피드 셀+신고 드롭다운 렌더링 코드가 거의 동일하게 중복돼 있다 — 의도적 선택(`NovelDetailFeature`도 자기 화면 전용 사본을 갖는 것과 같은 이유, 화면마다 앵커 계산·오버레이 배치가 미묘하게 달라질 수 있어 공용화 대신 화면별 사본 유지).
- **`USER-015`(비공개 프로필) 감지는 장르·작품 취향·피드 3곳뿐** — 서재 통계(`LoadUserRegisteredNovelStatsUseCase`)는 일부러 대상에서 뺐다. 서버가 이 엔드포인트엔 그 에러코드 자체를 정의하지 않고, 작품 피드는 서버가 비공개 글을 알아서 걸러주기 때문(사용자 확정). "다른 병렬 호출도 다 해줘야 하지 않나" 싶어도 이 셋 이상으로 넓히지 말 것.
- **컬렉션 섹션의 화살표 버튼(`userPageCollectionSection`)은 아직 `//TODO: - 컬렉션 뷰로 이동`뿐이다** — "서재" 섹션의 화살표(`//TODO: - 서재 뷰로 이동`)와 동일하게 실제 네비게이션이 없다. 이 화면에서 다른 유저의 컬렉션 "목록"(전체보기) 화면으로 갈 수 있는 곳 자체가 아직 없다 — `CollectionFeature.CollectionListView`는 "내 컬렉션"/"좋아요한 컬렉션" 2탭이라 **로그인 사용자 자신 기준**으로만 동작해 타유저 프로필에 그대로 재사용할 수 없다(좋아요한 탭이 세션 토큰 기준). 타유저의 컬렉션 전체 목록 화면이 별도로 필요해지면 그때 설계할 것 — 지금은 마이페이지처럼 미리보기(최대 3개)만 보여주는 게 이번 범위(Figma 노드 31756:94603)다.
