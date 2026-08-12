<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# OnboardingFeature

앱 첫 실행~가입 온보딩 플로우. 전체 플로우는 **인트로+소셜로그인 → 가입약관 동의 시트 → 닉네임 → 성별/출생년도 → 장르 선택**(5단계)이지만, **이번 이슈(#176)는 1단계(인트로+소셜로그인)만** — 나머지는 후속 이슈에서 이어간다. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.onboarding)` / 의존: `AuthDomain`(전용 `OnboardingDomain`은 없다). `ProfileDomain`은 후속 이슈에서 추가 예정.
- 진입점: `OnboardingFactory.makeIntroView(socialLoginUseCase:logger:onLoginSucceeded:)` — 인트로 화면(1단계)만. 후속 이슈에서 화면이 늘어나면 `makeXxxView`가 더 생긴다(그래서 이름이 `makeView`가 아니라 `makeIntroView`).
- **비로그인(게스트) 진입 경로는 없다** — 제품 결정으로 "회원가입 없이 둘러보기" 버튼과 `onContinueWithoutSignIn` 콜백을 제거했다(2026-08). 소셜 로그인(Apple/Kakao)만 남는다. 되살리지 말 것.

## 핵심 시나리오

- **전용 Domain 모듈이 없다** — 인트로 화면의 소셜 로그인은 `AuthDomain`의 `SocialLoginUseCase(SocialLoginCredential)`를 그대로 재사용한다. 응답 `NeedOnboarding`이 `false`(기존 유저)면 나머지 온보딩 단계를 건너뛰고 바로 완료 콜백을 호출, `true`(신규 유저)면 다음 단계(가입약관 시트, 후속 이슈)로 진행한다.
- **소셜 로그인 SDK는 `KakaoSDK`를 `Tuist/Package.swift`에 새 SPM 의존성으로 추가해 연동**했다(사용자 승인, 2026-08). Apple은 시스템 `AuthenticationServices`(`SignInWithAppleButton`)라 추가 의존성 없음. `KAKAO_APP_KEY`는 `Config/Config_Shared.xcconfig`에 이미 있던 실제 키를 그대로 씀 — `Info.plist`(App·`ModuleInfoPlist.featureDemo`)에 `KAKAO_APP_KEY`+`CFBundleURLTypes`(`kakao$(KAKAO_APP_KEY)`)로 노출, App 진입점(`WSSIOSV2App.swift`)에서 `KakaoSDK.initSDK(appKey:)` 호출.
- **`OnboardingIntroViewModel`은 Apple/Kakao credential을 그대로 `SocialLoginUseCase`에 넘긴다** — Kakao는 `UserApi.shared.loginWithKakaoAccount(completion:)`(웹 기반 `ASWebAuthenticationSession`, KakaoTalk 앱 전환 아님 — 시뮬레이터에서도 동작). SDK 실패(취소 포함)는 provider 구분 없이 `.loginFailed` 하나로 처리(카피가 갈릴 이유가 없어서, `UserPageFeature`와 같은 판단).
- **푸시 알림 권한 요청은 이 모듈 범위 밖** — 온보딩이 다 끝나고 Home 진입 시점에 별도로 뜬다(App/Home 쪽 책임).
- **온보딩 완료·로그인 후 라우팅은 App 책임** — 이 Feature는 `Factory`가 콜백만 노출하고, 어느 화면으로 이동할지는 관여하지 않는다.

## 주의사항 (작업 중 발견 시 누적)

- **`KakaoSDK*`(와 전이 의존 `Alamofire`)는 반드시 `Tuist/Package.swift`의 `productTypes`에서 `.framework`(dynamic)로 강제해야 한다 — Tuist 기본값(`.staticFramework`)을 쓰면 실기기/시뮬레이터에서 크래시난다.** `OnboardingFeature.framework`(로그인 호출부)와 `OnboardingFeatureDemo`/App(초기화 호출부)이 각자 별도 정적 사본을 링크하게 되어, 한쪽에서 부른 `KakaoSDK.initSDK(appKey:)`가 다른 쪽 사본엔 반영 안 됨 → `UserApi.shared.loginWithKakaoAccount` 호출 시 `KakaoSDKCommon.SdkError.ClientFailed(.MustInitAppKey)` fatal error. 실측(2026-08, XcodeBuildMCP 시뮬레이터 테스트 중 재현) — 증상은 런타임 로그의 `objc[...]: Class ... is implemented in both ...` 중복 경고로 미리 알아챌 수 있다(경고가 보이면 무시하지 말 것).
- **Apple 로그인 capability(entitlement)는 `Demo/OnboardingFeatureDemo.entitlements` + `Project.swift`의 `demoEntitlements:`로 등록돼 있다**(`com.apple.developer.applesignin: [Default]`). 같은 걸 App 타깃에도 `Support/WSS-iOS.entitlements`로 등록함. `createFeatureModule`에 `demoEntitlements: Entitlements?` 파라미터가 새로 생겼다(`Project+Templates.swift`) — 다른 Feature 모듈이 Demo에서 capability가 필요하면 이 파라미터를 쓰면 된다. entitlement가 없을 땐 버튼 탭이 즉시 실패했지만, 지금은 시스템이 정상적으로 "설정에서 Apple 계정에 로그인해야 합니다" 안내를 띄운다(시뮬레이터에 테스트용 Apple ID가 로그인 안 돼 있을 뿐 — 코드/설정 문제 아님, 실기기·Apple ID 로그인된 환경에서는 실제 인증까지 진행됨).
