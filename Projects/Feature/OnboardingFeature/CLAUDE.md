<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# OnboardingFeature

앱 첫 실행~가입 온보딩 플로우. 전체 플로우는 **인트로+소셜로그인 → 가입약관 동의 시트 → 닉네임 → 성별/출생년도 → 장르 선택**(5단계)이지만, **이번 이슈(#176)는 1단계(인트로+소셜로그인)만** — 나머지는 후속 이슈에서 이어간다. 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.onboarding)` / 의존: `AuthDomain`(전용 `OnboardingDomain`은 없다). `ProfileDomain`은 후속 이슈에서 추가 예정.
- 진입점: `OnboardingFactory.makeView(...)`(예정)

## 핵심 시나리오

- **전용 Domain 모듈이 없다** — 인트로 화면의 소셜 로그인은 `AuthDomain`의 `SocialLoginUseCase(SocialLoginCredential)`를 그대로 재사용한다. 응답 `NeedOnboarding`이 `false`(기존 유저)면 나머지 온보딩 단계를 건너뛰고 바로 완료 콜백을 호출, `true`(신규 유저)면 다음 단계(가입약관 시트, 후속 이슈)로 진행한다.
- **소셜 로그인 SDK가 이 레포에 아직 없다** — Apple은 시스템 `AuthenticationServices`로 충분하지만, Kakao는 `KakaoSDK`를 `Tuist/Package.swift`에 새 SPM 의존성으로 추가해야 한다(사용자 승인 완료, 2026-08). `KAKAO_APP_KEY`는 `Config/Config_Shared.xcconfig`에 이미 있음(placeholder 아님, 실제 키).
- **푸시 알림 권한 요청은 이 모듈 범위 밖** — 온보딩이 다 끝나고 Home 진입 시점에 별도로 뜬다(App/Home 쪽 책임).
- **온보딩 완료·로그인 후 라우팅은 App 책임** — 이 Feature는 `Factory`가 콜백만 노출하고, 어느 화면으로 이동할지는 관여하지 않는다.

## 주의사항 (작업 중 발견 시 누적)

- (아직 없음 — 구현하며 발견 시 추가)
