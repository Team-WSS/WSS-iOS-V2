<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SettingFeature

설정 화면. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.setting)` / 의존: `BaseDomain`, `SettingDomain`, `ProfileDomain`, `DesignSystem`, `WSSComponent`, `Logger`
- 진입점: `Factory/SettingFactory.swift` — `makeView(logger:)`(설정 목록), `makeChangeGenderOrAgeView(loadLocalGenderAndBirthUseCase:saveAccountInfoDraftUseCase:logger:)`(성별/나이 변경)

## 핵심 시나리오

- **성별/나이 변경 화면**은 `ProfileDomain`에 의존한다(`SettingDomain`만으로는 부족) — 성별/출생연도는 userDefaults에서 읽고(`LoadLocalGenderAndBirthUseCase`), 저장 시 서버 PUT + userDefaults 갱신을 함께 하는 `SaveAccountInfoDraftUseCase`(`AccountInfoDraft`, ProfileDomain 기존 계약)를 재사용한다.
- **`SettingChangeBirthYearPickerSheet`는 커밋-온-확인 패턴**: 시트 내부 `draftYear`만 스크롤로 바뀌고, "완료"를 눌러야 부모 `selectedYear`(Binding)에 반영된다. X는 커밋 없이 닫기만.

## 주의사항 (작업 중 발견 시 누적)

- `SettingBirthYearWheel`(`ChangeGenderOrAge/`)은 **연도 1열 전용**이다. `NovelReviewFeature`의 연/월/일 3열 `WSSDateWheel`과 이름은 비슷하지만 다른 컴포넌트(Feature 모듈 간 직접 의존 금지라 복사본이 아니라 화면 전용으로 새로 축소한 버전)다. 연도 배열 자체가 `BirthYear.minYear...maxYear`로 하드 바운드돼 있어 오버슈트(미래 연도) 방지용 되돌림 로직이 필요 없다 — 원본의 settle/bounce 로직을 그대로 가져오지 말 것.
- **`SettingFactory.makeView(...)`가 모듈의 유일한 public 진입점**이다(`SettingView` → `SettingAccountInfoView` → 성별/나이 변경·차단유저 목록·회원탈퇴, `SettingView` → 프로필 공개 설정·알림 설정). Demo/App은 이 하나에 모든 UseCase를 한 번에 주입만 하면 된다. **내부 네비게이션도 개별 `makeXxxView`를 그대로 재사용**한다 — `SettingView`/`SettingAccountInfoView`는 `navigationDestination` 안에서 ViewModel을 직접 만들지 않고 `SettingFactory.makeXxxView(...)`를 호출한다(VM 조립 로직을 Factory 한 곳에 모으기 위함). 딥링크 등 단독 진입 시에도 같은 메서드를 그대로 쓴다.
- 회원탈퇴 실서버 조립 시 `BaseData`의 `DemoSessionTokenStore`는 `SessionTokenStore`만 구현해 `AuthDataFactory.makeRepository(tokenStore:)`가 요구하는 **`TokenStore`(저장/갱신 포함 상위 프로토콜)에는 못 쓴다** — save/refresh까지 갖춘 별도 TokenStore가 필요(Demo에선 `DemoAuthTokenStore` 참고).
- **`WithdrawReasonView`에서 `.disabled`와 `@FocusState`를 같은 탭 핸들러로 함께 갱신할 때, 상태 변경(`selectReason`)과 포커스 요청(`isKeyboardFocused = true`)을 같은 틱에 실행하면 포커스가 씹힌다** — `.disabled`가 아직 갱신 전 렌더값(true)으로 평가되는 시점이라 비활성 뷰는 포커스를 못 받는다. 포커스 요청을 `Task { @MainActor in }`으로 한 틱 미뤄 상태 변경 렌더 뒤에 실행해야 탭 한 번에 선택+포커스가 같이 된다.
- **같은 소스 뷰에 `navigationDestination(isPresented:)`를 두 개 걸어 A→B로 체이닝하면(A의 콜백이 B의 bool을 true로) 두 bool이 동시에 true가 되어 스택 push가 깨진다** — `WithdrawConfirmView`→`WithdrawReasonView`가 이 문제였다. 해결: B의 트리거를 A가 아니라 **A가 이미 push된 지점(별도 컨테이너 뷰)** 으로 옮긴다(`WithdrawFlowView` 참고). 화면 체이닝이 필요하면 항상 이 패턴을 쓸 것 — 부모 뷰에 bool을 계속 추가하지 말 것.
- **Demo `실서버` 모드는 로그인 플로우가 없어 `refreshToken`/`deviceIdentifier`가 비어있으면 로그아웃이 `DefaultAuthRepository.logout()`의 guard에서 바로 `RepositoryError.unknown`으로 막힌다**(`LogoutUseCase` 배선 자체의 버그 아님) — `makeLiveSettingView()`가 `DemoAuthTokenStore.saveRefreshToken(_:)` / `DefaultDeviceIdentifierStore.saveDeviceIdentifier(_:)`로 더미 값을 미리 심어 이 guard는 통과하지만, 그 뒤 실제 서버 `postLogout` 호출은 가짜 값이라 정상적으로 네트워크 에러(401 등)로 실패한다 — 이건 의도된 동작이다(guard 실패의 애매한 `unknown`보다 진짜 네트워크 실패가 보이는 게 더 현실적인 데모). `DefaultDeviceIdentifierStore`는 실제 Keychain을 쓰므로 이 시드는 시뮬레이터에 앱을 재실행해도 유지된다.
