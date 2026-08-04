<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# OnboardingFeature

앱 첫 실행~가입 온보딩 플로우. 전체 플로우는 **인트로+소셜로그인 → 가입약관 동의 시트 → 닉네임 → 성별/출생년도 → 장르 선택**(5단계). **이슈 #176이 1단계(인트로+소셜로그인), #178이 나머지 4단계(약관 동의·닉네임·성별출생년도·장르선택)** 전부를 다룬다. **성별/출생년도(2단계, `#178` 잔여 항목)는 아직 미구현** — 닉네임 다음 화면은 현재 Demo에서 장르 선택으로 바로 건너뛰며, `gender`/`birthYear`는 임시 고정값(`Gender.female`/`BirthYear(2000)`)을 쓴다(`OnboardingFeatureDemoApp.placeholderGender`/`placeholderBirthYear`). 그 화면이 생기면 이 임시값을 실제 입력으로 교체할 것. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.onboarding)` / 의존: `AuthDomain`(인트로 소셜로그인), `SettingDomain`(가입약관 동의), `ProfileDomain`(닉네임·장르 선택 — 전용 `OnboardingDomain`은 없다).
- 진입점(전부 `OnboardingFactory`):
  - `makeIntroView(socialLoginUseCase:logger:onLoginSucceeded:)` — 1단계.
  - `makeTermsAgreementView(loadUseCase:saveUseCase:logger:onAgreed:onAuthenticationRequired:)` — 2단계(시트).
  - `makeNicknameView(validateNicknameUseCase:logger:onConfirmed:onAuthenticationRequired:)` — 3단계. 저장 UseCase 없이 로컬 검증만 통과시켜 값을 넘긴다(실제 등록은 마지막 단계에서 한 번에).
  - `makeGenreSelectionView(nickname:gender:birthYear:registerProfileUseCase:logger:onCompleted:onAuthenticationRequired:)` — 마지막 단계. 앞 단계에서 확정된 값을 값으로 받아 `ProfileRegistration`을 완성하고 `RegisterProfileUseCase`로 실제 등록까지 이 화면이 담당한다.
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

### 닉네임 입력 (`NicknameView`, #178)

- **필수 온보딩 단계** — Figma에 back chevron이 없다. 뒤로가기·건너뛰기 둘 다 없음(약관 동의와 동일한 "필수 단계" 취급).
- **필드 정책·구조는 `MypageFeature`의 `MyPageEditView` 닉네임 섹션(#147)을 그대로 따른다** — 같은 `ProfileDomain.NicknameDraft`를 쓰는 두 화면이 서로 다른 판단 기준을 보이지 않도록. 캡션을 보이는 조건(공백/형식오류/중복/사용가능 4종 + `notStarted`·`needDuplicatedCheck`·`notChanged`는 숨김), 필드 테두리 색(에러=`wssSecondary100`, 사용가능=`wssPrimary100`, 그 외 없음), 중복확인 버튼 활성 조건(`validationState == .needDuplicatedCheck`)과 배경/글자색(활성 `primary50`/`primary100`, 비활성 `gray70`/`gray200`)은 동일. **단, 캡션 문구 자체(한글 카피)는 이 화면만의 워딩으로 갈렸다** — 온보딩 톤에 맞춰 별도 조정한 결과라 `MyPageEditView`와 1:1로 동기화할 필요 없음(구조·조건만 맞추면 됨).
- **"다음으로" 활성화 조건은 `validationState == .available`** — 로컬 검증만 통과시키고 저장 UseCase는 없다. 실제 서버 등록은 저장하지 않고 값(`String`)만 `onConfirmed`로 호출자에 넘긴다 — 최종 등록은 마지막 단계(장르 선택)에서 `RegisterProfileUseCase`로 한 번에 이뤄진다.
- **중복확인은 수동 탭 1회성**(자동 디바운스 없음) — 텍스트가 바뀌면 `NicknameDraft.setText`가 내부적으로 확인 상태를 `.notYet`으로 되돌려 재확인을 요구한다(도메인 정책, Feature는 관여 안 함).
- `validateNickname(_:)`의 `Bool` 반환 의미(`true`=사용 가능)는 `ProfileDomain/CLAUDE.md`에 명시해 둠 — 헷갈리기 쉬우니(도메인 테스트 변수명이 `isDuplicated`로 잘못 붙어 있어 더 헷갈린다) 그쪽을 먼저 볼 것.

### 장르 선택 (`GenreSelectionView`, #178, 마지막 단계)

- **유일하게 필수가 아닌 단계** — Figma에 실제로 back chevron(이전 단계로 pop)과 "건너뛰기"가 있다. 커스텀 헤더(`.toolbar(.hidden, for: .navigationBar)`)라 `.enableSwipeBack()`으로 스와이프 뒤로가기를 별도 복원했다(다른 온보딩 화면과 반대 — 그 화면들은 의도적으로 뒤로가기를 막아 `.enableSwipeBack()`을 쓰지 않는다).
- **다중 선택** — `Set<NovelGenre>` 토글. "완료"는 **하나 이상 선택했을 때만 활성화**, "건너뛰기"는 **현재 선택과 무관하게 항상 빈 장르 목록으로 등록**(선택된 걸 무시하고 "장르 없이 시작"으로 취급 — 선택하다 만 상태를 애매하게 반영하지 않기 위한 설계).
- **이 화면이 곧 온보딩 완료 처리다** — "완료"/"건너뛰기" 둘 다 `ProfileRegistration(nickname:gender:birthYear:genrePreferences:)`을 구성해 `RegisterProfileUseCase.execute(_:)`를 호출한다. 성공 시 `onCompleted`(Home 진입은 App 책임).
- **선택 배지는 아이콘을 통째로 체크마크로 교체**(오버레이 아님) — 미선택: `wssGray50` 배경 + `NovelGenre.iconImage`. 선택: `wssPrimary50` 배경 + `wssPrimary100` 2pt 테두리 + `WSSImage.icCheckMark`(장르 아이콘은 사라짐). Figma엔 이 체크 전용 에셋(`icOnboardingCheck`)이 있었지만 기존 `icCheckMark`(같은 `#6A5DFD` 스트로크 체크마크, `WSSBirthYearWheel`/`LibrarySortSheet` 등에서 이미 쓰는 자산)과 시각적으로 동일해 새 에셋을 추가하지 않고 재사용했다.
- **그리드 순서는 `NovelGenre.onboardingGenre`**(WSSComponent `DomainPresentation`, 신규) — `myFeedFilter`/`searchGenre`와 다른 세 번째 순서(로맨스·로판·현판·판타지·무협·BL·라노벨·드라마·미스터리). 화면별 순서는 의도적으로 갈라져 있으니 다른 화면 순서에 맞추지 말 것.

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
