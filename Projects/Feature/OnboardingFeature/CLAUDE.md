<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# OnboardingFeature

앱 첫 실행~가입 온보딩 플로우(서비스 소개 슬라이드 → 닉네임/성별/출생년도/장르 선택 → 권한 요청). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.feature(.onboarding)` / 의존: `ProfileDomain`(전용 `OnboardingDomain`은 없다)
- 진입점: `OnboardingFactory.makeView(...)`(예정)

## 핵심 시나리오

- **전용 Domain 모듈이 없다** — 닉네임/성별/출생년도/장르 선택 화면은 `ProfileDomain`의 `RegisterProfileUseCase(ProfileRegistration)`를 그대로 재사용한다(닉네임 중복 확인은 `ValidateNicknameUseCase`). 이 UseCase는 이번 온보딩이 처음 연결하는 자리다(그전엔 어떤 Feature도 안 씀). 소개 슬라이드·권한 요청 화면은 UseCase가 필요 없는 순수 UI/시스템 API.

## 주의사항 (작업 중 발견 시 누적)

- (아직 없음 — 구현하며 발견 시 추가)
