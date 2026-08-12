<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# UserPageFeature

내 화면(MyPage)/남의 화면(UserPage) + 전체 피드 목록(UserFeedList) 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.userPage)` / 의존: `BaseDomain`, `ProfileDomain`, `NovelDomain`, `FeedDomain`,
  `SocialDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점:
  - `MypageFactory.makeView(...)`(내 화면 탭 콘텐츠), `.makeEditView(...)`(프로필 편집), `.makeCharacterEditSheet(...)`(캐릭터 선택 시트)
  - `UserPageFactory.makeView(...)`(유저 페이지), `.makeFeedListView(...)`(전체 피드 목록 — `UserPageView`의 "전체보기"가 내부적으로 호출)

## MyPage

마이페이지 탭 — 프로필 요약(닉네임·소개·프로필 이미지)·서재 통계·컬렉션·장르 뱃지·작품 취향을 보여주고,
프로필 편집(닉네임·소개·프로필 캐릭터·선호장르)으로 진입한다.

### 핵심 시나리오

- **마이페이지(`MypageView`)**: `onAppear`마다 프로필·장르 뱃지·작품 취향·서재 통계 4개를 병렬 로드
  (`MypageViewModel.loadMypage`). **탭 복귀마다 다시 로드**한다(1회 가드 없음) — 프로필 편집에서 저장하고
  돌아왔을 때 바뀐 값을 반영해야 해서.
- **프로필 편집(`MyPageEditView`)**: 연필 아이콘 → `navigationDestination` → `MypageFactory.makeEditView`.
  저장 성공 시 곧바로 `dismiss()`하고, "저장됨" 토스트는 **복귀할 마이페이지가** `onSaved` 콜백을 받아
  띄운다(이 화면에서 sleep으로 노출 시간을 벌면 닫힘이 부자연스럽게 지연되므로).
- **캐릭터 선택(`MypageCharacterEditSheet`)**: 프로필 편집 화면의 `+` 버튼 → `.sheet(item:)`으로 진입.
  확인 결과(선택 캐릭터 ID)는 `onApply` 콜백으로 부모(`MyPageEditView`)에 위임하고, draft 반영·시트
  dismiss는 부모 책임.

### 주의사항 (작업 중 발견 시 누적)

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

## UserPage

남의 프로필 화면 — 통계/활동(피드 미리보기) + 전체 피드 목록(`UserFeedListView`), 차단·신고.

### 핵심 시나리오

- **차단**: 툴바 threedots 드롭다운("차단하기") → `WSSAlertType.blockUser` 확인 알럿 → `BlockUserUseCase`. **성공하면 화면을 dismiss한다**(`state.shouldDismiss`) — 차단하면 상대 프로필을 다시 볼 수 없어 화면에 남아있을 이유가 없다는 판단(사용자 확정).
- **피드 신고**: 피드 셀 threedots 드롭다운("스포일러 신고"/"부적절한 표현 신고", 빨강) → 확인→접수완료 2단 알럿(`FeedAlert` 의미값, `NovelDetailFeature`와 동일 패턴) → `ReportSpoilerFeedUseCase`/`ReportImproperFeedUseCase`. 차단·신고 실패는 `hasActionError` 토스트(`.unknownError`)로 공유(카피가 같아 굳이 안 나눔).
- **"활동" 탭은 미리보기(최대 5개)만** 보여준다(`UserPageViewModel.visibleFeeds`). 6개 이상(`hasMoreFeeds`)이면 "전체보기" 버튼 → `UserFeedListView`(무한스크롤 전용 화면, 별도 `UserFeedListViewModel`)로 push. **`SettingFeature`의 내부 네비게이션과 동일 패턴** — `UserPageView`가 VM이 아니라 View 자신의 `init`으로 필요한 UseCase(`loadUserFeedsUseCase` 등)를 직접 받아뒀다가 `.navigationDestination`에서 `UserPageFactory.makeFeedListView(...)`를 직접 호출(콜백을 App까지 올리지 않음).
- **비공개 프로필**: 서버가 `USER-015`로 응답하면(장르/작품 취향/피드 조회 각각) `RepositoryError.privateProfile` → **스티키 헤더(통계/활동 탭)는 그대로 두고 그 아래 콘텐츠 영역만** "비공개 프로필이에요" 안내로 대체한다(사용자 확정 — 처음엔 화면 전체를 대체했다가 탭 자체가 사라지는 문제로 `Section` 내부로 옮김). 재시도 버튼 없음(상대가 설정을 바꾸기 전엔 의미 없음).
- **스크롤 반응형 네비 타이틀**: 프로필 섹션이 화면 밖으로 스크롤되면(`minY < -1`) 툴바 principal에 닉네임이 페이드인한다 — `PreferenceKey` 대신 `GeometryReader` 안에서 `onChange`로 `@State`를 직접 갱신(`NovelDetailFeature`와 동일 패턴/동일 이유, 이 SDK는 `onPreferenceChange`→`@State` 갱신이 먹지 않는다).
- **툴바 배경은 스크롤 여부와 무관하게 항상 `wssPrimary20`** — `.toolbarBackground(color, for: .navigationBar)`만으로는 기본이 "스크롤 전엔 투명, 후엔 표시"라 `.toolbarBackground(.visible, for: .navigationBar)`를 명시로 강제해야 한다.
- **프로필 헤더 배경(`wssPrimary20`)은 위로만 오버슈트한 사각형으로 확장**해 위로 당겨 바운싱해도 흰 배경이 안 비치게 한다(`profileSection`의 두 번째 `.background(alignment: .top)`, height 1000 + offset -1000).
- **하단 바운싱 배경은 `ScrollView` 자체에 건 `.background(wssWhite)`로 채운다**(`UserPageView.body`, 콘텐츠 안 개별 섹션이 아니라 `ScrollView` 뷰 바로 뒤). `ScrollView`(뷰 자체)에 건 배경은 뷰포트에 고정되어 스크롤과 무관하게 항상 보이는 반면, 콘텐츠(LazyVStack 안 섹션)에 건 배경은 콘텐츠와 함께 스크롤되어 바운싱 시 빈 공간을 못 채운다 — 그래서 profileSection처럼 콘텐츠 쪽에 오버슈트 사각형을 추가하는 대신 뷰포트 레벨 배경을 택함. 상단은 profileSection의 오버슈트가 이 위에 덮여 primary20이 우선한다.

### 주의사항 (작업 중 발견 시 누적)

- `WSSAlertView`의 버튼은 접근성 트리에 안 잡힌다 — UI 자동화(XcodeBuildMCP `tap`)로 알럿이 뜨는 것까지만 검증 가능, 버튼 탭 이후 동작은 코드 리뷰로 대체(WSSComponent 공용 컴포넌트라 이 모듈 범위 밖).
- 피드 셀 threedots 드롭다운의 앵커(`anchorY`)는 `NovelDetailFeedTab`과 동일하게 "셀 상단 패딩(20) + 헤더 높이(32) = 52" 오프셋을 그대로 재사용한다 — `WSSFeadView` 자체에 내장된 값이라 어느 화면에서 셀을 그리든 동일하다.
- `UserPageView`/`UserFeedListView` 둘 다 피드 셀+신고 드롭다운 렌더링 코드가 거의 동일하게 중복돼 있다 — 의도적 선택(`NovelDetailFeature`도 자기 화면 전용 사본을 갖는 것과 같은 이유, 화면마다 앵커 계산·오버레이 배치가 미묘하게 달라질 수 있어 공용화 대신 화면별 사본 유지).
- **`USER-015`(비공개 프로필) 감지는 장르·작품 취향·피드 3곳뿐** — 서재 통계(`LoadUserRegisteredNovelStatsUseCase`)는 일부러 대상에서 뺐다. 서버가 이 엔드포인트엔 그 에러코드 자체를 정의하지 않고, 작품 피드는 서버가 비공개 글을 알아서 걸러주기 때문(사용자 확정). "다른 병렬 호출도 다 해줘야 하지 않나" 싶어도 이 셋 이상으로 넓히지 말 것.
