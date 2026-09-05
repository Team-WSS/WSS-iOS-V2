<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SettingFeature

설정 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.setting)` / 의존: `BaseDomain`, `ProfileDomain`, `NotificationDomain`, `SocialDomain`, `AuthDomain`, `NovelDomain`, `DesignSystem`, `WSSComponent`, `Logger`, `PushAuthorization`(#193 — "알림 설정" 메뉴 탭 시 시스템 권한 확인용) (`SettingDomain`은 실제로 쓰이는 곳이 없어 `Project.swift`에서 제외했다 — 필요해지면 다시 추가)
- 진입점 (#201부터 — **화면 간 이동은 전부 App이 조립한다.** 예외는 `makeWithdrawFlowView` 하나뿐,
  "확인→사유" 2단계는 그 화면 안에서 여전히 로컬로 진행된다(사용자 확정) — App은 그 진입점 하나만
  조립하면 된다. 성별/나이 변경 화면의 생년 선택 시트도 그 화면 자신의 draft를 채우는 로컬 값
  선택기라 그대로 둔다): `Factory/SettingFeatureFactory.swift`의 `makeView`(설정 목록)·
  `makeAccountInfoView`(계정정보)·`makeChangeGenderOrAgeView`·`makeBlockUserListView`·
  `makeWithdrawFlowView`·`makeProfilePublicView`·`makeNotificationSettingView`·
  `makeCompletionNotificationListView`/`makeHiatusReturnNotificationListView` — 각 화면은 자기
  하위 화면을 만들지 않고 탭 콜백만 올린다(`onXxxTapped`). "저장됨" 계열 토스트(성별/나이 변경,
  프로필 공개 설정)도 그 화면 자신이 아니라 돌아온 화면 쪽(App)이 `onSaveSuccess` 시점에 띄운다.

## 핵심 시나리오

- **성별/나이 변경 화면**은 `ProfileDomain`에 의존한다 — 성별/출생연도는 userDefaults에서 읽고(`LoadLocalGenderAndBirthUseCase`), 저장 시 서버 PUT + userDefaults 갱신을 함께 하는 `SaveAccountInfoDraftUseCase`(`AccountInfoDraft`, ProfileDomain 기존 계약)를 재사용한다.
- **`SettingChangeBirthYearPickerSheet`는 커밋-온-확인 패턴**: 시트 내부 `draftYear`만 스크롤로 바뀌고, "완료"를 눌러야 부모 `selectedYear`(Binding)에 반영된다. X는 커밋 없이 닫기만.
- **"알림 설정" 메뉴 탭 시점에 시스템 푸시 권한 확인(#193)**: 체크·알럿은 `NotificationSettingView`가
  아니라 **`SettingView`가 "알림 설정" 메뉴를 탭한 순간** 한다(`SettingViewModel.notificationMenuTapped`).
  `PushAuthorizationChecker`로 확인해 `notDetermined`(아직 안 물어봄)면 시스템 프롬프트를 바로 띄우고
  이동 신호(`shouldNavigateToNotificationSetting`)를 올린다. **`denied`(거부됨)면 이동하지 않고**
  `WSSAlertType.setAppNotification`("앱 알림이 꺼져있어요") 알럿만 띄운다 — "다음에 하기"·"설정하러
  가기" 어느 버튼이든 **알럿을 닫기만 할 뿐 알림 설정 화면으로 이동시키지 않는다**(사용자 확정 — 권한이
  없는 채로 그 화면에 들어갈 이유가 없다는 판단). 권한을 실제로 켜고 왔으면 "알림 설정" 메뉴를 다시
  눌러야 한다(그때는 `authorized`라 바로 이동). `showWSSAlert`가 `.overlay` 기반이라 push 전환과 동시에
  띄우면 화면 전환에 밀려 사라지기 때문에, `HomeFeature`의 알림 벨(이동과 알럿을 동시에 올림)과 정반대
  순서를 쓴다(자세한 이유는
  [HomeFeature](../HomeFeature/CLAUDE.md) 참고). 이건 앱 안의 알림 on/off 토글(`isNotificationOn`,
  서버 저장값)과는 **완전히 별개** — 토글이 켜져 있어도 iOS 자체 권한이 꺼져 있으면 알림이 안 온다.
  "설정하러 가기" 탭 시 `UIApplication.openNotificationSettingsURLString`(iOS 15.4+, 배포 타깃
  17.0이라 안전)으로 iOS 설정 앱의 **이 앱 알림 설정 하위 페이지로 바로** 연다(VM은 판단만, 여는
  행위는 View).
  ⚠️ **`NotificationSettingView`는 더 이상 자체적으로 권한을 재확인하지 않는다**(과거엔
  `onAppear`마다 재확인해 자체 알럿을 띄웠으나 제거함) — `SettingView`에서 이미 denied 알럿을 보고 닫은
  직후 도착 화면에서 같은 알럿이 한 번 더 뜨는 중복을 피하기 위해서다. 이 때문에 **딥링크 등으로
  `NotificationSettingView`에 직접 진입하는 경로는 이 권한 안내를 받지 못한다** — 현재 App 레이어에
  딥링크 라우팅 자체가 없어(스켈레톤 단계) 당장은 실질적 공백이 아니지만, 나중에 딥링크가 생기면 이
  화면 진입 지점에서 별도로 처리해야 한다.
  ⚠️ **`notDetermined` 분기는 이 메뉴에서 사실상 거의 안 탄다** — `HomeFeature`가 첫 홈 진입 시점에
  이미 권한을 확정짓기 때문(회원가입 직후 첫 홈이 유저가 이 앱에서 처음 겪는 권한 결정 시점). 여기 오는
  대부분의 유저는 이미 `authorized`/`denied`로 확정된 뒤다.
- **완결 알림/휴재 복귀 알림 목록(`NovelNotificationListView`, #188)** — `NotificationSettingView`의 두 row에서 push. **화면 구조가 완전히 같아**(사용자 확정) 별도 View 두 개를 만들지 않고 `NovelNotificationType`(`.completion`/`.hiatusReturn`)만 다르게 주입해 같은 View/VM을 재사용한다 — `SettingFeatureFactory`에 `makeCompletionNotificationListView`/`makeHiatusReturnNotificationListView` 두 진입점은 있지만 내부에서 같은 `NovelNotificationListView`(제목만 다름)를 만든다.
  - **툴바 우측은 "수정"↔"삭제" 전환 버튼 하나**(`state.isEditing`, 사용자 확정) — 기본은 "수정"(gray300, 항상 탭 가능)이고, 누르면 "삭제"로 바뀌며 그때부터 행 선택이 가능해진다(`NovelNotificationRow`는 행 전체가 탭 영역이지만 `isEditing`이 아니면 `toggleSelection`이 VM에서 no-op). **체크 버튼 자체가 `isEditing`이 아니면 렌더되지 않는다**(숨김이 아니라 조건부 렌더 — "수정"을 눌러야 비로소 나타남). "삭제"는 하나 이상 선택해야 활성(primary100)이고, 선택 없이는 비활성(gray200) — "수정"의 gray300과는 다른 톤이라 섞어 쓰지 말 것. 편집 모드를 취소할 방법은 따로 없다(뒤로가기로 화면을 나가면 초기화). 삭제 성공 시 `isEditing`도 함께 꺼져 다음 진입은 항상 "수정"부터 다시 시작한다.
  - **`NovelNotificationRow`는 `Button`이 아니라 `onTapGesture`**(사용자 확정) — `.disabled`를 얹은 `Button`은 비편집 상태에서 행 전체가 옅게 흐려 보이는 부작용이 있었다(no-op이어야 할 상태가 "비활성화된 것처럼" 보임). 체크 아이콘은 `WSSComponent`의 `WSSSelectionCheckIcon`(#188 — 여러 화면에 흩어져 있던 크로스페이드+스케일 스프링 구현을 공용 컴포넌트로 승격)을 그대로 쓴다 — 새 화면에서 같은 아이콘 쌍이 필요하면 직접 구현하지 말고 이 컴포넌트를 재사용할 것.
  - 삭제는 `WSSAlertType.deleteNovelNotificationSubscriptions(summary:)`(신규, `WSSComponent`) 확인 알럿을 거친다. `summary`는 **목록에 보이는 순서 기준 첫 선택 항목 제목**("{제목} 외 N작품", View의 `Presentation` 확장이 조합 — 알럿 컴포넌트는 문구를 모른다).
  - 페이지네이션은 서버가 명시적으로 내려주는 `nextSubscriptionID` 커서를 쓴다(`NotificationDomain`의 `Notification`처럼 마지막 항목 id로 유추하지 않음).
  - ⚠️ **현재 로드된 페이지를 통째로 선택 삭제하면 목록은 비지만 다음 페이지가 남아있을 수 있다** — `state.subscriptions.isEmpty`만 보고 빈 상태(`WSSEmptyView`)로 판정하면 서버에 남은 구독이 화면에서 사라진 것처럼 보인다. VM이 삭제 직후 `subscriptions.isEmpty && hasNextPage`면 자동으로 다음 페이지를 이어 로드하고(`loadMore()`), View는 그 과도기를 빈 상태 대신 `LoadingView()`로 가린다. 삭제 로직을 만질 땐 이 자동 이어받기를 빠뜨리지 말 것.
  - 목록이 비면 `WSSEmptyView(type: .novelNotification)`의 "작품 둘러보기" CTA가 뜨는데, 검색 화면은 다른 Feature 모듈이라 이 화면이 직접 못 연다 — `onBrowseNovels` 콜백을 그대로 받아 실제 이동은 App이 정한다(#201부터 `MypageRootView`/`LibraryRootView` 둘 다 일반 검색 화면으로 push해 배선 완료).
  - ✅ **인증 만료(`authenticationRequired`) 로그인 라우팅은 이제 모듈 전 서버 호출 화면에 들어와 있다**(#244 — 예전엔 모듈 전체에 없던 갭이었고, "고칠 땐 모듈 전체를 한 번에"라는 방침대로 한 번에 배선했다). 각 VM이 `State.requiresAuthentication` + `routeToLoginIfAuthenticationRequired(_:)`를 두고 catch(에러 매핑 헬퍼 `presentXxxError`/`presentError` 최상단)에서 실패 플래그·토스트보다 **먼저** 걸러 `return`한다(정본은 `NotificationFeature/NotificationListViewModel`, 계약은 `Feature/CLAUDE.md` "인증 만료 처리 계약"). 각 View는 `onChange(of: state.requiresAuthentication)` → `onAuthenticationRequired` 콜백으로 올리고 App(`MypageRootView`/`LibraryRootView`)이 로그인/온보딩 라우팅에 연결한다. **예외 둘**: (1) `SettingView`(설정 목록)는 서버 호출이 아예 없어(pushAuthorizationChecker만) 대상이 아니다. (2) `SettingChangeGenderOrAgeView`의 `loadDraft`는 userDefaults 로컬 읽기라 401이 없어 저장(서버 PUT)만 라우팅한다. **로그아웃·탈퇴 401**은 이미 세션이 끝난 것이라 실패 토스트 대신 이 신호로 로그인/온보딩으로 되돌린다(성공 경로 `onLogoutSuccess`/`onWithdrawSuccess`=`onSessionEnded`와 결과는 같지만 App이 딥링크 복원 여부를 달리 걸어 별개 콜백, `App/CLAUDE.md`). 새 서버 호출 화면을 추가하면 이 패턴을 되풀이할 것.

## 주의사항 (작업 중 발견 시 누적)

- **설정 트리 9화면의 네비바는 플랫 `WSSNavigationBar` + `.wssCustomNavigationBar()`다**(#244, 정본 [WSSComponent](../../UI/WSSComponent/CLAUDE.md)) — 시스템 툴바(iOS 26 리퀴드 글래스)에서 교체. 우측 액션이 있는 화면(프로필공개설정·성별나이변경 "완료", 완결/휴재알림목록 "수정↔삭제")은 `WSSNavigationBar`의 `trailing` 슬롯에 넣는다. 전부 미저장 초안 확인 알럿이 없어(NovelNotificationList의 알럿은 삭제 확인 전용) `swipeBackEnabled` 기본값(스와이프백 허용)이다.
- **`SettingChangeBirthYearPickerSheet`가 쓰는 연도 휠은 `WSSComponent`의 `WSSBirthYearWheel`이다** — Feature 화면 전용이 아니라 UI 레이어로 승격된 **공용** 컴포넌트다(과거엔 `ChangeGenderOrAge/` 안의 화면 전용 타입이었다가 이동했다). `NovelReviewFeature`의 연/월/일 3열 `WSSDateWheel`과 이름은 비슷하지만 다른 컴포넌트다(연도 1열 전용). 연도 배열 자체가 `BirthYear.minYear...maxYear`로 하드 바운드돼 있어 오버슈트(미래 연도) 방지용 되돌림 로직이 필요 없다 — `WSSDateWheel`의 settle/bounce 로직을 그대로 가져오지 말 것. 수정은 `Projects/UI/WSSComponent/Sources/WSSBirthYearWheel.swift`에서.
- ⚠️ **`SettingFeatureFactory`는 화면마다 독립된 진입점이다(#201부터) — 더 이상 `makeView(...)` 하나가
  하위 화면까지 전부 조립하지 않는다.** `SettingView`/`SettingAccountInfoView`/`NotificationSettingView`는
  `onXxxTapped` 콜백만 올리고, 그 콜백을 받아 실제로 다음 화면을 조립(`SettingFeatureFactory.makeXxxView`
  호출)하는 건 App(`MypageRootView`)이다 — CollectionFeature #201 이관과 동일 원칙. 이 덕분에 각
  `makeXxxView`가 받는 UseCase도 그 화면 자신이 실제로 쓰는 것만으로 줄었다(예: `makeView`는
  `pushAuthorizationChecker` 하나뿐, 하위 화면용 UseCase 10여 개를 더 안 받는다). 유일한 예외는
  `makeWithdrawFlowView` — "확인→사유" 2단계는 여전히 그 화면 내부에서 로컬로 진행되므로 App은 이
  진입점 하나만 조립하면 된다(사용자 확정, 아래 "체이닝" 주의사항 참고). 딥링크 등으로 특정 화면에
  단독 진입해야 하면 해당 `make<Screen>View`를 그대로 쓰면 된다.
- 회원탈퇴 실서버 조립 시 `BaseData`의 `DemoSessionTokenStore`는 `SessionTokenStore`만 구현해 `AuthDataFactory.makeRepository(tokenStore:)`가 요구하는 **`TokenStore`(저장/갱신 포함 상위 프로토콜)에는 못 쓴다** — save/refresh까지 갖춘 별도 TokenStore가 필요(Demo에선 `DemoAuthTokenStore` 참고).
- **`WithdrawReasonView`에서 `.disabled`와 `@FocusState`를 같은 탭 핸들러로 함께 갱신할 때, 상태 변경(`selectReason`)과 포커스 요청(`isKeyboardFocused = true`)을 같은 틱에 실행하면 포커스가 씹힌다** — `.disabled`가 아직 갱신 전 렌더값(true)으로 평가되는 시점이라 비활성 뷰는 포커스를 못 받는다. 포커스 요청을 `Task { @MainActor in }`으로 한 틱 미뤄 상태 변경 렌더 뒤에 실행해야 탭 한 번에 선택+포커스가 같이 된다.
- **같은 소스 뷰에 `navigationDestination(isPresented:)`를 두 개 걸어 A→B로 체이닝하면(A의 콜백이 B의 bool을 true로) 두 bool이 동시에 true가 되어 스택 push가 깨진다** — `WithdrawConfirmView`→`WithdrawReasonView`가 이 문제였다. 해결: B의 트리거를 A가 아니라 **A가 이미 push된 지점(별도 컨테이너 뷰)** 으로 옮긴다(`WithdrawFlowView` 참고). #201 이후 모듈의 다른 화면 전환은 전부 App으로 옮겨갔지만 **`WithdrawFlowView` 내부의 이 2단계 체이닝만은 그대로 남겨두기로 사용자가 확정했다** — App이 "확인→사유"를 각각 별도 push로 쪼개려 하면 이 함정이 App 쪽 `NavigationPath`에서도 그대로 재현될 수 있으니, 그 대신 App은 `makeWithdrawFlowView` 진입점 하나만 조립하고 내부 체이닝은 이 패턴 그대로 둘 것.
- **Demo `실서버` 모드는 로그인 플로우가 없어 `refreshToken`/`deviceIdentifier`가 비어있으면 로그아웃이 `DefaultAuthRepository.logout()`의 guard에서 바로 `RepositoryError.unknown`으로 막힌다**(`LogoutUseCase` 배선 자체의 버그 아님) — Demo의 `makeLiveDependencies()`(#201부터 화면마다 이걸 호출해 Repository 묶음을 만든다, 예전엔 `makeLiveSettingView()` 하나였다)가 `DemoAuthTokenStore.saveRefreshToken(_:)` / `DefaultDeviceIdentifierStore.saveDeviceIdentifier(_:)`로 더미 값을 미리 심어 이 guard는 통과하지만, 그 뒤 실제 서버 `postLogout` 호출은 가짜 값이라 정상적으로 네트워크 에러(401 등)로 실패한다 — 이건 의도된 동작이다(guard 실패의 애매한 `unknown`보다 진짜 네트워크 실패가 보이는 게 더 현실적인 데모). `DefaultDeviceIdentifierStore`는 실제 Keychain을 쓰므로 이 시드는 시뮬레이터에 앱을 재실행해도 유지된다.
