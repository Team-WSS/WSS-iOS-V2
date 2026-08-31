<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Feature/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SplashFeature

런치 스플래시 화면(#225) — 부트스트랩(`BootstrapAppUseCase`) 동안 보이고, 결과를 App에 올리기만 한다.

- 식별자: `ModuleType.feature(.splash)` / 의존: `BaseDomain`, `SplashDomain`, `DesignSystem`
  (**WSSComponent·Logger 의도적 제외** — 컴포넌트·알럿 없음(강제 업데이트 알럿은 App 몫), VM에 실패 경로 없음)
- 진입점: `SplashFeatureFactory.makeView(bootstrapAppUseCase:onFinish:)`
- **이 화면은 아무 데도 전환하지 않는다** — `BootstrapOutcome`(forceUpdate/intro/main)을 `onFinish`로
  올리면 라우팅·강제 업데이트 알럿·약관 시트는 전부 App이 한다.

## 화면 동작 계약

- **최소 노출 1.0초**(사용자 확정, V1 체감 유지) — 부트스트랩과 타이머를 **병렬**로 돌려 둘 다 끝나야
  `onFinish`. 빨라도 깜빡 사라지지 않고, 느려도 추가 지연이 없다(직렬 1초+네트워크 ❌).
- 레이아웃은 V1 SplashView 파리티: 배경 전면 + 로고(상단~워드마크 사이 세로 중앙) + 워드마크(하단 safe area inset 30).

## 주의사항 (작업 중 발견 시 누적)

- 배경은 `scaledToFill`(비율 유지·크롭) — V1은 스트레치(scaleToFill, 비율 무시)였지만 기기 비율에 따라
  왜곡되는 방식이라 **의도적으로 개선**했다(사용자 확정, 2026-08-31). V1 파리티로 되돌리지 말 것.

- **`.load`의 "1회만" 가드는 레이어 규칙("최초 1회 가드 금지")의 의도된 예외다** — 그 규칙은 탭 복귀마다
  갱신해야 하는 탭 콘텐츠 얘기고, 스플래시는 런치당 한 번 실행되는 화면이라 onAppear 재발화가 부트스트랩을
  다시 돌리면 안 된다.
- `SplashViewModel.init`의 `waitMinimumDisplayTime` 파라미터는 **테스트 시임(seam)** — 프로덕션 조립에서는
  절대 넘기지 말 것(기본값 1.0초가 정답). `bootstrapTask`가 internal인 것도 테스트가 완료를 폴링 없이
  기다리기 위함(`await bootstrapTask?.value`). SplashDomain `launchInBackground`와 같은 철학.
- **Demo는 실서버 조립이 없다(Mock 시나리오 방식)** — `SplashData` 실서버 조립은 도메인 6종 Repository
  인스턴스가 전부 필요해 사실상 App DI 복제라, `MockBootstrapAppUseCase`(SplashDomainTesting)로 outcome
  분기·지연만 재현한다. "다른 Feature Demo와 다르다"고 실서버 모드를 채워 넣지 말 것.
