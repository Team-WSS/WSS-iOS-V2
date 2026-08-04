<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# OnboardingFeature

앱 첫 실행~가입 온보딩 플로우. 전체 플로우는 **인트로+소셜로그인 → 가입약관 동의 시트 → 닉네임 → 성별/출생년도 → 장르 선택**(5단계). **이슈 #176이 1단계(인트로+소셜로그인), #178이 2단계(가입약관 동의 시트)** — 나머지(닉네임·성별/출생년도·장르 선택)는 후속 이슈에서 이어간다. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.onboarding)` / 의존: `AuthDomain`(인트로 소셜로그인), `SettingDomain`(가입약관 동의 — 전용 `OnboardingDomain`은 없다). `ProfileDomain`은 후속 이슈(닉네임 등)에서 추가 예정.
- 진입점: `OnboardingFactory.makeIntroView(socialLoginUseCase:logger:onLoginSucceeded:)`(1단계) / `makeTermsAgreementView(loadUseCase:saveUseCase:logger:onAgreed:onAuthenticationRequired:)`(2단계). 후속 이슈에서 화면이 늘어나면 `makeXxxView`가 더 생긴다(그래서 이름이 `makeView`가 아니라 `makeXxxView`).
- **비로그인(게스트) 진입 경로는 없다** — 제품 결정으로 "회원가입 없이 둘러보기" 버튼과 `onContinueWithoutSignIn` 콜백을 제거했다(2026-08). 소셜 로그인(Apple/Kakao)만 남는다. 되살리지 말 것.

## 화면 동작 계약

### 가입약관 동의 시트 (`TermsAgreementView`, #178)

- **필수 온보딩 단계** — `.interactiveDismissDisabled()`로 스와이프/바깥 탭 닫기를 막는다. 사용자 확정(설계 질문 결과).
- **"전체 동의" 행은 토글형**이다 — `TermsType.allCases`가 이미 전부(필수+선택) 동의 상태면 탭 시 전부 해제, 아니면 전부 동의로 설정(`TermsAgreementViewModel.toggleAgreeAll`). 도메인의 `agreeToAll()`은 단방향(전부 true)만 제공하므로 해제는 각 타입에 `setAgreed(false, for:)`를 개별 호출.
- **"다음으로" 활성화 조건은 `TermsAgreementDraft.isSubmittable`**(필수 항목만 전부 동의) 그대로 — 마케팅(선택) 동의 여부는 무관. Figma의 Cta `default`/`activated` 2-variant가 이 값과 정확히 대응.
- **밑줄 텍스트(서비스 이용약관·개인정보 항목)는 탭하면 `openURL`로 외부 Safari를 연다.** 마케팅(선택) 항목은 상세 약관이 없어 밑줄·탭 대상이 아니다(라벨만). `TermsType.detailURL`(View 로컬 확장)은 `BaseDomain.AppURL.serviceAgreement`/`.privacyPolicy`를 그대로 연결(노션 페이지).
- **저장은 "다음으로" 탭 시 1회**(입력 폼 패턴, `NovelReviewFeature` 정본) — 개별 토글은 로컬 상태만 바꾸고 서버 호출 없음(낙관 업데이트 개념 없음).
- **로드 실패 = 전면 `NetworkErrorView`+재시도**(`NovelReviewViewModel.loadDraft` 정본과 동일 분화). 저장 실패는 토스트(`.unknownError`).
- 체크 아이콘 눌림 애니메이션은 `CreateFeedConnectNovelRow`(같은 `icSelectNovelDefault`/`icSelectNovelSelected` 아이콘 쌍)와 동일한 크로스페이드+스케일 스프링(`.spring(response: 0.32, dampingFraction: 0.6)`)으로 통일(사용자 요청).
- 시트 높이는 Figma 실측대로 `.presentationDetents([.height(670)])` 고정, `.presentationDragIndicator(.hidden)`(어차피 닫기 막혀 있어 그래버 노출 의미 없음).

## 핵심 시나리오

- **전용 Domain 모듈이 없다** — 인트로 화면의 소셜 로그인은 `AuthDomain`의 `SocialLoginUseCase(SocialLoginCredential)`를 그대로 재사용한다. 응답 `NeedOnboarding`이 `false`(기존 유저)면 나머지 온보딩 단계를 건너뛰고 바로 완료 콜백을 호출, `true`(신규 유저)면 다음 단계(가입약관 시트, 후속 이슈)로 진행한다.
- **소셜 로그인 SDK는 `KakaoSDK`를 `Tuist/Package.swift`에 새 SPM 의존성으로 추가해 연동**했다(사용자 승인, 2026-08 — REST API 직접 연동 대신 SDK를 택함). Apple은 시스템 `AuthenticationServices`(`SignInWithAppleButton`)라 추가 의존성 없음. `KAKAO_APP_KEY`는 `Config/Config_Shared.xcconfig`에 이미 있던 실제 키를 그대로 씀 — `Info.plist`(App·`ModuleInfoPlist.featureDemo`)에 `KAKAO_APP_KEY`+`CFBundleURLTypes`(`kakao$(KAKAO_APP_KEY)`)로 노출, App 진입점(`WSSIOSV2App.swift`)에서 `KakaoSDK.initSDK(appKey:)` 호출.
- **이번 이슈(#176)는 App의 인프라 배선(Kakao 초기화·entitlement·URL scheme)까지만이고, `OnboardingFactory.makeIntroView`를 실제로 호출해 화면을 붙이는 건 후속 이슈 범위다** — 그래서 지금 App(`ContentView`)은 여전히 placeholder이고 Feature 모듈은 아직 아무 데서도 소비되지 않는다. "인프라만 있고 안 쓰인다"는 의도된 중간 상태이지 배선 누락이 아니다.
- **`OnboardingIntroViewModel`은 Apple/Kakao credential을 그대로 `SocialLoginUseCase`에 넘긴다** — Kakao는 `UserApi.shared.loginWithKakaoAccount(completion:)`(웹 기반 `ASWebAuthenticationSession`, KakaoTalk 앱 전환 아님 — 시뮬레이터에서도 동작). SDK 실패(취소 포함)는 provider 구분 없이 `.loginFailed` 하나로 처리(카피가 갈릴 이유가 없어서, `UserPageFeature`와 같은 판단).
- **푸시 알림 권한 요청은 이 모듈 범위 밖** — 온보딩이 다 끝나고 Home 진입 시점에 별도로 뜬다(App/Home 쪽 책임).
- **온보딩 완료·로그인 후 라우팅은 App 책임** — 이 Feature는 `Factory`가 콜백만 노출하고, 어느 화면으로 이동할지는 관여하지 않는다.

## 주의사항 (작업 중 발견 시 누적)

- **`KakaoSDK*`(와 전이 의존 `Alamofire`)는 반드시 `Tuist/Package.swift`의 `productTypes`에서 `.framework`(dynamic)로 강제해야 한다 — Tuist 기본값(`.staticFramework`)을 쓰면 실기기/시뮬레이터에서 크래시난다.** `OnboardingFeature.framework`(로그인 호출부)와 `OnboardingFeatureDemo`/App(초기화 호출부)이 각자 별도 정적 사본을 링크하게 되어, 한쪽에서 부른 `KakaoSDK.initSDK(appKey:)`가 다른 쪽 사본엔 반영 안 됨 → `UserApi.shared.loginWithKakaoAccount` 호출 시 `KakaoSDKCommon.SdkError.ClientFailed(.MustInitAppKey)` fatal error. 실측(2026-08, XcodeBuildMCP 시뮬레이터 테스트 중 재현) — 증상은 런타임 로그의 `objc[...]: Class ... is implemented in both ...` 중복 경고로 미리 알아챌 수 있다(경고가 보이면 무시하지 말 것).
- **Apple 로그인 capability(entitlement)는 `Demo/OnboardingFeatureDemo.entitlements` + `Project.swift`의 `demoEntitlements:`로 등록돼 있다**(`com.apple.developer.applesignin: [Default]`). 같은 걸 App 타깃에도 `Support/WSS-iOS.entitlements`로 등록함. `createFeatureModule`에 `demoEntitlements: Entitlements?` 파라미터가 새로 생겼다(`Project+Templates.swift`) — 다른 Feature 모듈이 Demo에서 capability가 필요하면 이 파라미터를 쓰면 된다. entitlement가 없을 땐 버튼 탭이 즉시 실패했지만, 지금은 시스템이 정상적으로 "설정에서 Apple 계정에 로그인해야 합니다" 안내를 띄운다(시뮬레이터에 테스트용 Apple ID가 로그인 안 돼 있을 뿐 — 코드/설정 문제 아님, 실기기·Apple ID 로그인된 환경에서는 실제 인증까지 진행됨).
- **`OnboardingIntroView.content`의 배너↔`bottomSection` 사이 `Spacer()`(유연)는 지우면 안 된다** — 하단 요소(도트+소셜 버튼)를 화면 아래로 밀어붙이는 유일한 메커니즘이다(비로그인 버튼 제거 때 이걸 없애고 고정 `Spacer().frame(height:)`로만 대체했다가 리뷰에서 걸림).
- **배너(`bannerCarousel`)는 디자인팀 확정 수치로 `.frame(height: 567)` 고정, `bottomSection` 뒤는 `.padding(.bottom, 24)` 대신 `Spacer().frame(height: 67)`을 쓴다**(2026-08). 위 유연 `Spacer()`는 남아있어 화면 밖으로 밀려나는 '깨짐'은 없음을 실기기 대신 SE(3rd gen)·iPhone 16·iPhone 17 Pro Max 시뮬레이터로 확인했다(2026-08-18) — 다만 배너가 고정 크기라 **화면이 커질수록 남는 여유 공간이 전부 버튼 아래 여백으로 쌓여 기기별 하단 여백 편차가 크다**(SE는 적당, 17 Pro Max는 훨씬 넓음). 디자인 검수에서 큰 기기 여백이 과하다고 나오면 이 고정값들부터 의심할 것.
