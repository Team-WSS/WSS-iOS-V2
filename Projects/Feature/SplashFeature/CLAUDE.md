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
- **App 배선 시: `onFinish`가 불리기 전까지 스플래시 뷰를 계층에서 빼지 말 것** — 완료 신호가
  `onChange(of: state.outcome)`라 뷰가 떼어진 사이 세팅된 outcome은 감지되지 않아 `onFinish`가 영영 안 불린다.
  (런치 루트로 상시 마운트하는 정상 배선에선 문제없음 — 리뷰 지적, #225.)
- **Demo는 실서버 조립이 없다(Mock 시나리오 방식)** — `SplashData` 실서버 조립은 도메인 6종 Repository
  인스턴스가 전부 필요해 사실상 App DI 복제라, `MockBootstrapAppUseCase`(SplashDomainTesting)로 outcome
  분기·지연만 재현한다. "다른 Feature Demo와 다르다"고 실서버 모드를 채워 넣지 말 것.
- ⚠️ **아직 App에 배선되지 않았다**(2026-08-31 기준) — `Projects/App`에 Splash 참조가 0건이고 `ContentView`는
  여전히 `route = .main`으로 시작한다. 즉 **앱을 실행해도 이 화면은 뜨지 않고 게이트도 돌지 않는다**.
  배선은 별도 PR 몫(사용자 확정) — "왜 안 뜨지"를 코드 버그로 오진하지 말 것.
- ⚠️ **"병렬 시작"을 검증하는 테스트는 상한 없이 짜면 실패가 아니라 행(hang)이 된다**(실측, #225 리뷰).
  두 fake의 `waitUntilStarted()`를 그냥 `await`하면 직렬 구현일 때 한쪽이 영영 시작되지 않아 테스트가
  120초를 넘겨도 안 끝난다. 두 겹으로 막아 뒀으니 걷어내지 말 것:
  1. 시작 대기를 `withTaskCancellationHandler`로 **취소 반응형**으로 만들고 `raceStart`로 5초 상한을 건다
     (취소를 무시하는 continuation이면 상한 래퍼의 task group 자체가 안 끝난다).
  2. **둘 다 시작됐을 때만** 완료 경로로 진행하는 `guard` — 없으면 시작 안 된 쪽을 `complete()`해도 풀
     continuation이 없어 뒤의 `await bootstrapTask?.value`에서 다시 매달린다.
  검증법: `bootstrap()`을 직렬로 바꿔 보면 이 테스트만 실패해야 한다(나머지 5개는 직렬에서도 통과한다).
