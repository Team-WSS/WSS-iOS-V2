<!-- 모듈 가이드. 이 모듈 작업 시 상위 Projects/Data/CLAUDE.md(레이어 규칙)와 함께 자동 로드됨. -->
# SplashData

`SplashDomain`의 두 포트(`LaunchGateRepository`/`LaunchTaskRepository`) 구현 — **자기 네트워크 호출 없이 다른 도메인 Repository들에 위임만 하는 composite 모듈**(#225). 구성요소는 `Sources/`를 직접 보면 된다.

- 식별자: `ModuleType.data(.splash)` / 의존: Networking + 도메인 6종 프로토콜(**구현체 모름** — 인스턴스는 App DI가 주입)
- 진입점: `SplashDataFactory.makeLaunchGateRepository(...)` / `makeLaunchTaskRepository(...)` —
  다른 Data 팩토리와 달리 `client:`가 아니라 **이미 조립된 Repository 인스턴스들**을 받는다.

## 주의사항 (작업 중 발견 시 누적)

- **표준 Data 구성(DTO·Service·Mapper·BaseData·Logger·Demo·Testing)이 일부러 없다** — 위임뿐이라서. "다른 Data 모듈과 다르다"고 채워 넣지 말 것. 로깅도 위임받는 각 레포가 이미 한다.
- `deviceTokenProvider`가 nil을 주면 FCM 등록은 **조용히 건너뛴다** — 푸시 인프라(APNs/FCM SDK)가 App에 아직 없어서(2026-08-31 기준) 의도된 동작. 인프라가 생기면 App 조립에서 실제 provider만 꽂으면 된다.
- `checkForceUpdateRequired`는 조회 실패를 **그대로 던진다** — "실패는 통과" 정책은 `BootstrapAppUseCase`(SplashDomain)가 한 곳에서 결정한다. 여기서 삼키지 말 것.
- `hasValidSession`은 토큰 **존재 여부만** 본다 — 만료 검증은 401 자동 재발급 경로(#184) 담당.
- ⚠️ **App 배선 때: `makeLaunchTaskRepository(recommendationRepository:)`에 넘길 인스턴스는 프리페치 store를
  주입하지 않은 쪽이어야 한다**(#225 리뷰). App에는 조립된 `RecommendationRepository`가 하나뿐이라 그대로
  넘기면 **프리페치가 스스로를 무효화한다**: `prefetchHomeData()`가 부르는 `fetchTodayDiscoveries()`가
  빈 슬롯에 **consume을 시도해 소비 창을 닫아 버리고**, 그 직후의 `fill`은 `isClosed`에 걸려 폐기된다.
  결과는 **store가 영영 안 채워지고 런치마다 추천 API 3개만 버려지는 것** — 홈은 늘 네트워크를 타므로
  "느려지지 않았다"가 증상이라 아무도 못 알아챈다. store는 **소비하는 쪽에만** 주입한다.
- ⚠️ 같은 이유로 **주입은 짝으로만 의미가 있다** — `SplashDataFactory`에만 store를 넘기고
  `RecommendationDataFactory`에 안 넘기면 런치마다 추천 API 3개를 더 때리고 결과는 아무도 안 쓴다.
  타입이 막아주지 않으니(한쪽은 non-optional, 한쪽은 기본 nil) App DI에서 두 조립을 붙여 둘 것.
- 프리페치 슬롯은 **today·trending·taste 3개**다(taste는 2026-08-31 추가 — 홈의 원자적 첫 페인트가
  제일 느린 taste에 붙잡혀 2종만 데워선 이득이 0이라서). **3종 모두 `requireToken`이라 유효 세션 없인
  실패해 슬롯이 안 채워진다**(fail-closed — today/trending도 2026-08-31 전환). 죽은 세션의 프리페치가
  익명 200으로 슬롯을 채우던 세션 전환 함정은 이로써 닫혔다(→ `SplashDomain` 문서·TODO 11절).
