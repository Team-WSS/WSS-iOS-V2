<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Domain/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SplashDomain

런치 부트스트랩 정책 — 앱 진입 시 게이트 판정(강제 업데이트→세션→약관)과 부수 태스크 실행 순서·실패 분기를 전담한다(#225). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.domain(.splash)` / 의존: `BaseDomain`뿐
- **포트 2개는 Splash의 언어로 새로 선언한 것** — `LaunchGateRepository`(판정 질문) / `LaunchTaskRepository`(부수 태스크). 실제 답은 다른 도메인들(Profile·Setting·Notification·Base·Recommendation)에 있지만, **도메인 간 직접 의존 금지 규칙 때문에 여기선 프로토콜만 선언**하고 구현은 `SplashData`가 그 도메인들의 repo에 위임한다(구조 확정: 사용자, 2026-08-31).

## 핵심 시나리오

- `DefaultBootstrapAppUseCase.execute()` 하나가 전부다: SplashFeature가 호출 → `BootstrapOutcome`(forceUpdate/intro/main)을 콜백으로 App에 넘겨 App이 라우팅.
- 게이트 순서·실패 정책은 의도된 결정이다(버그 아님):
  - **강제 업데이트가 세션보다 먼저** — 세션 없는 유저도 구버전이면 온보딩 전에 차단.
  - **게이트 조회 실패 = 통과** — 서버 장애가 앱을 잠그면 안 된다(TODO 2절 확정). 약관 조회 실패도 동의로 간주.
  - **부수 태스크 4종은 fire-and-forget** — 완료를 기다리지 않고 main을 반환(사용자 확정). 세션 없으면 시작조차 안 한다.

## 주의사항 (작업 중 발견 시 누적)

- `DefaultBootstrapAppUseCase.init`의 `launchInBackground` 파라미터는 **fire-and-forget을 결정적으로 테스트하기 위한 시임(seam)**이다. 프로덕션 조립에서는 절대 넘기지 말 것(기본값 `Task {}`가 정답) — 테스트만 `BackgroundWorkSpy`를 꽂는다.
