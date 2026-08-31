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
  - **게이트 예산 초과 = 통과** — "실패는 통과"는 **응답이 돌아와야** 작동한다. `URLSession` 기본 타임아웃(60초)에
    맡기면 반쯤 연결된 망(호텔 wifi·약전계)에서 게이트 2개 × 60초 동안 스플래시가 잠기므로 예산으로 끊는다(#225 리뷰).
    예산(`gateBudget`, 기본 4초)은 **게이트마다가 아니라 부트스트랩 전체에 한 번** — 두 게이트가 공유 마감을
    나눠 쓰고, 앞 게이트가 다 쓰면 뒤 게이트는 조회 없이 곧장 통과한다(게이트당이면 최악 대기가 2배로 늘어난다).
  - **단, 약관 조회의 `.authenticationRequired`만은 `.intro`로** — 세션이 소실된 상태라 main으로 보내면
    메인 탭이 401을 맞고 온보딩으로 되돌려 화면이 번쩍인다. 그 왕복을 없애는 유일한 예외(사용자 확정).
  - **부수 태스크 4종은 fire-and-forget** — 완료를 기다리지 않고 main을 반환(사용자 확정). 세션 없으면 시작조차 안 한다.

## 주의사항 (작업 중 발견 시 누적)

- `DefaultBootstrapAppUseCase.init`의 `launchInBackground` 파라미터는 **fire-and-forget을 결정적으로 테스트하기 위한 시임(seam)**이다. 프로덕션 조립에서는 절대 넘기지 말 것(기본값 `Task {}`가 정답) — 테스트만 `BackgroundWorkSpy`를 꽂는다. `waitGateBudget`도 같은 성격(테스트는 즉시 끝나는 타이머를 꽂아 실시간 대기 없이 예산 초과 경로를 탄다).
- ⚠️ **typed throws는 클로저 리터럴 안에서 `any Error`로 넓어진다** — `withinBudget { try await gate.check() }`
  처럼 클로저 안에서 `throws(RepositoryError)` 호출을 감싸면 `invalid conversion of thrown error type`으로
  **컴파일이 깨진다**. do/catch를 `loadForceUpdateRequired()`처럼 **함수 본문**에 두고 `Result`로 감싸 넘겨야
  catch의 `error`가 `RepositoryError`로 좁혀진다(#225에서 실제로 두 번 걸렸다).
- 예산 초과 판정에 `withTaskGroup`을 쓰는데, **레이스에서 진 쪽을 `cancelAll()`로 반드시 취소**한다 —
  `URLSession`은 취소에 반응하므로 매달린 요청도 함께 풀린다. 취소를 무시하는 대기(예: 아무도 resume하지 않는
  `withCheckedContinuation`)를 게이트 안에 두면 그룹이 끝나지 않아 **행**이 된다.
- ⚠️ **예산이 안 걸리는 구멍이 하나 있다 — 401 재발급 대기**(#225 리뷰). `SessionRefreshCoordinator.refresh`는
  공유 갱신 Task를 `try await task.value`로 기다리는데, **이 대기는 취소에 반응하지 않는다**(대기자 하나가
  취소돼도 공유 갱신이 죽지 않게 한 의도적 설계). 그래서 만료 토큰 + 느린 망이면 **약관 게이트**가 401 →
  refresh 대기에 앉아 예산 4초를 넘겨도 못 빠져나오고, `URLSession` 기본 60초까지 스플래시가 고정될 수 있다.
  (강제 업데이트 게이트는 `.withoutToken`이라 이 경로가 없다.) 근본 해결은 refresh 대기를 취소 가능하게
  만들거나 Networking에 request timeout을 두는 것 — 둘 다 Core 변경이라 이 모듈 밖이다.
- `.intro`로 낙착해도 **이미 던진 부수 태스크는 되돌리지 않는다**. 죽은 세션에선 4종 전부 실패하고 끝나
  무해하다 — 홈 프리페치 3종도 **전부 `requireToken`**이라(2026-08-31, today/trending을
  `usesTokenIfAvailable`에서 전환) 익명 200으로 슬롯이 채워지는 일이 없다(fail-closed).
  과거엔 today/trending이 익명으로도 채워져 "세션 소실 → 인트로 → 재로그인 뒤 첫 홈 로드가 런치 시점
  데이터를 소비"하는 함정이 있었다 — **추천 엔드포인트를 `usesTokenIfAvailable`로 되돌리면 이 함정이
  부활한다**(개인화인 taste는 유출 성격까지 생김). 되돌리지 말 것. 세션 전환 시 store 교체(TODO 11절)는
  "유효 토큰으로 채워진 뒤 소비 전에 세션이 바뀌는" 좁은 레이스 대비로 여전히 권장된다.
  부수 태스크를 약관 게이트 뒤로 미루면 막히지만 프리페치 이득(런치→홈 dwell)이 거의 사라져 **일부러 두었다** —
  세션 전환 시 store를 새로 만드는 쪽이 옳은 해결이고, 그건 App 배선 몫이다(`docs/TODO.md` 11절).
