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
