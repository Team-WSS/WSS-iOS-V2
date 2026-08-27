<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SettingFeature

설정 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.setting)` / 의존: `BaseDomain`, `ProfileDomain`, `NotificationDomain`, `SocialDomain`, `AuthDomain`, `NovelDomain`, `DesignSystem`, `WSSComponent`, `Logger`, `PushAuthorization`(#193 — "알림 설정" 메뉴 탭 시 시스템 권한 확인용) (`SettingDomain`은 실제로 쓰이는 곳이 없어 `Project.swift`에서 제외했다 — 필요해지면 다시 추가)
- 진입점: `Factory/SettingFeatureFactory.swift` — `makeView(logger:)`(설정 목록), `makeChangeGenderOrAgeView(loadLocalGenderAndBirthUseCase:saveAccountInfoDraftUseCase:logger:)`(성별/나이 변경)

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
  - 목록이 비면 `WSSEmptyView(type: .novelNotification)`의 "작품 둘러보기" CTA가 뜨는데, 검색 화면은 다른 Feature 모듈이라 이 화면이 직접 못 연다 — `onBrowseNovels` 콜백으로 `SettingFeatureFactory.makeView(...)`까지 흘려보내고, 실제 이동은 App이 정한다(지금은 미배선, Demo는 로그만 찍음).
  - ⚠️ **이 두 화면(과 `NotificationSettingView`)은 모듈 내 다른 서버 호출 화면과 달리 인증 만료(`RepositoryError.authenticationRequired`) 라우팅이 없다** — `Feature/CLAUDE.md`의 "인증 만료 처리 계약"이 원칙상 전 서버 호출 화면에 요구하지만, `SettingFeature`는 애초에 어느 화면도(`SettingBlockUserListView` 포함) 이걸 구현하지 않은 상태라 새 화면만 예외로 만들지 않고 기존 패턴을 따랐다 — 모듈 전체에 걸친 기존 갭이니 새 화면 추가 시 되풀이하지 말고, 고칠 땐 모듈 전체를 한 번에 볼 것.

## 주의사항 (작업 중 발견 시 누적)

- **`SettingChangeBirthYearPickerSheet`가 쓰는 연도 휠은 `WSSComponent`의 `WSSBirthYearWheel`이다** — Feature 화면 전용이 아니라 UI 레이어로 승격된 **공용** 컴포넌트다(과거엔 `ChangeGenderOrAge/` 안의 화면 전용 타입이었다가 이동했다). `NovelReviewFeature`의 연/월/일 3열 `WSSDateWheel`과 이름은 비슷하지만 다른 컴포넌트다(연도 1열 전용). 연도 배열 자체가 `BirthYear.minYear...maxYear`로 하드 바운드돼 있어 오버슈트(미래 연도) 방지용 되돌림 로직이 필요 없다 — `WSSDateWheel`의 settle/bounce 로직을 그대로 가져오지 말 것. 수정은 `Projects/UI/WSSComponent/Sources/WSSBirthYearWheel.swift`에서.
- **`SettingFeatureFactory.makeView(...)`가 모듈의 유일한 public 진입점**이다(`SettingView` → `SettingAccountInfoView` → 성별/나이 변경·차단유저 목록·회원탈퇴, `SettingView` → 프로필 공개 설정·알림 설정). Demo/App은 이 하나에 모든 UseCase를 한 번에 주입만 하면 된다. **내부 네비게이션도 개별 `makeXxxView`를 그대로 재사용**한다 — `SettingView`/`SettingAccountInfoView`는 `navigationDestination` 안에서 ViewModel을 직접 만들지 않고 `SettingFeatureFactory.makeXxxView(...)`를 호출한다(VM 조립 로직을 Factory 한 곳에 모으기 위함). 딥링크 등 단독 진입 시에도 같은 메서드를 그대로 쓴다.
- 회원탈퇴 실서버 조립 시 `BaseData`의 `DemoSessionTokenStore`는 `SessionTokenStore`만 구현해 `AuthDataFactory.makeRepository(tokenStore:)`가 요구하는 **`TokenStore`(저장/갱신 포함 상위 프로토콜)에는 못 쓴다** — save/refresh까지 갖춘 별도 TokenStore가 필요(Demo에선 `DemoAuthTokenStore` 참고).
- **`WithdrawReasonView`에서 `.disabled`와 `@FocusState`를 같은 탭 핸들러로 함께 갱신할 때, 상태 변경(`selectReason`)과 포커스 요청(`isKeyboardFocused = true`)을 같은 틱에 실행하면 포커스가 씹힌다** — `.disabled`가 아직 갱신 전 렌더값(true)으로 평가되는 시점이라 비활성 뷰는 포커스를 못 받는다. 포커스 요청을 `Task { @MainActor in }`으로 한 틱 미뤄 상태 변경 렌더 뒤에 실행해야 탭 한 번에 선택+포커스가 같이 된다.
- **같은 소스 뷰에 `navigationDestination(isPresented:)`를 두 개 걸어 A→B로 체이닝하면(A의 콜백이 B의 bool을 true로) 두 bool이 동시에 true가 되어 스택 push가 깨진다** — `WithdrawConfirmView`→`WithdrawReasonView`가 이 문제였다. 해결: B의 트리거를 A가 아니라 **A가 이미 push된 지점(별도 컨테이너 뷰)** 으로 옮긴다(`WithdrawFlowView` 참고). 화면 체이닝이 필요하면 항상 이 패턴을 쓸 것 — 부모 뷰에 bool을 계속 추가하지 말 것.
- **Demo `실서버` 모드는 로그인 플로우가 없어 `refreshToken`/`deviceIdentifier`가 비어있으면 로그아웃이 `DefaultAuthRepository.logout()`의 guard에서 바로 `RepositoryError.unknown`으로 막힌다**(`LogoutUseCase` 배선 자체의 버그 아님) — `makeLiveSettingView()`가 `DemoAuthTokenStore.saveRefreshToken(_:)` / `DefaultDeviceIdentifierStore.saveDeviceIdentifier(_:)`로 더미 값을 미리 심어 이 guard는 통과하지만, 그 뒤 실제 서버 `postLogout` 호출은 가짜 값이라 정상적으로 네트워크 에러(401 등)로 실패한다 — 이건 의도된 동작이다(guard 실패의 애매한 `unknown`보다 진짜 네트워크 실패가 보이는 게 더 현실적인 데모). `DefaultDeviceIdentifierStore`는 실제 Keychain을 쓰므로 이 시드는 시뮬레이터에 앱을 재실행해도 유지된다.
