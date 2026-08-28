# App 레이어

앱 진입점. **의존성 주입(DI)과 전역 흐름 조립**을 담당한다. 비즈니스 로직은 두지 않는다.

- 디렉토리: `Projects/App/`
- 비동기/상태: SwiftUI App lifecycle

## 구성

```
Sources/
├── WSSIOSV2App.swift        # @main. 폰트 등록·KakaoSDK 초기화 등 앱 시작 시 1회 처리.
├── ContentView.swift        # 앱 루트. AppDependencies를 한 번 만들어 두 플로우에 내려주고,
│                             # Route(.onboarding/.main)로 전환한다(로그인 상태 분기는 여기).
├── DI/
│   └── AppDependencies.swift  # 유일한 조립 지점 — NetworkingClient·TokenStore·Repository 조립.
└── Onboarding/
    └── OnboardingRootView.swift  # 온보딩 플로우 배선(OnboardingFactory 호출 + 화면 전환).
                                   # 끝나면(기존 유저 로그인 / 온보딩 완료) onFinished()만 부른다 —
                                   # 어디로 갈지는 정하지 않고 ContentView에 위임.
```

**메인 탭(홈/피드/서재/My)은 아직 없다** — `ContentView`의 `case .main`은 placeholder다. 온보딩
완료·기존 유저 로그인 이후 갈 곳은 후속 이슈에서 이 자리를 실제 메인 탭 루트로 교체한다.

- **원칙: 화면 간 연결 조립은 무조건 App이 한다**(사용자 확정) — Feature 안에 "다른 화면으로
  이동하는 로직"(다른 Feature의 View를 직접 구성해 push/present)이 있으면 안 된다. Feature는 콜백
  (`onLoginSucceeded`, `onAgreed` 등)만 밖으로 노출하고, 실제로 그 콜백을 받아 화면을 조립하는 건
  App(`OnboardingRootView`)이 한다.

## 책임

- 앱 진입점(`@main`), 전역 환경 구성.
- 각 레이어 조립 — Data 구현체와 Domain 프로토콜이 만나는 **유일한 지점**.
- 화면 전환·딥링크 등 전역 흐름 조정.

## 의존 규칙

- ✅ Feature, Domain, Data(Factory), Core, UI — 조립을 위해 거의 모든 레이어를 알 수 있다.
- App은 의존성 그래프의 최상위이므로 누구도 App을 import 하지 않는다.

## 조립 패턴 (`AppDependencies`, #196에서 확정)

```swift
let repository = XxxDataFactory.makeXxxRepository(client:...)  // Data 구현체
let useCase    = DefaultXxxUseCase(repository: repository)     // Domain 프로토콜에 주입
let view       = XxxFactory.makeView(someUseCase: useCase)     // Feature에 전달
```

- **DI는 클래스(`AppDependencies`) 하나로 모은다**, View 안에서 낱개로 조립하지 않는다. 루트 View가
  `@State private var dependencies = AppDependencies()`로 한 번만 만들어 들고, 화면 전환마다 그 안의
  Repository로 UseCase를 즉석 생성해 Factory에 넘긴다(UseCase 자체는 가벼운 struct/class라 매번
  새로 만들어도 무방 — Repository/NetworkingClient/TokenStore만 공유되면 된다).
- **`NetworkingClient`는 2개**(무한 재귀 방지, `AuthData/CLAUDE.md` 경고 그대로 적용):
  - `refresherClient` — `authSessionRefresher`를 물리지 않은 client. `AuthDataFactory.makeSessionRefresher`
    전용으로만 쓴다.
  - `client` — 위에서 만든 refresher를 `authSessionRefresher:`로 물린 메인 client. 실제 API 호출은
    전부 이걸로 나간다.
  - 둘 다 같은 `DefaultTokenStore()`(Keychain)를 공유해야 갱신된 토큰이 바로 반영된다.
- 로그인 성공 시 토큰 저장은 **Data 레이어(`DefaultAuthRepository.login`)가 이미 처리**한다 — App은
  `TokenStore`를 만들어 Repository에 주입하기만 하면 된다(App이 직접 Keychain을 만지지 않음).

## 주의사항 (작업 중 발견 시 누적)

- ⚠️ **`Support/Info.plist`는 Tuist `.extendingDefault(with:)`가 아니라 `.file(path:)`로 직접 지정**돼 있어
  (Feature Demo 앱들과 달리 `ModuleInfoPlist` 헬퍼를 안 씀), Xcode가 표준으로 자동 채워주는
  `CFBundleIdentifier`/`CFBundleExecutable`이 **없으면 시뮬레이터 설치 자체가 실패**한다
  (`Missing bundle ID` → `missing or invalid CFBundleExecutable`, #196에서 실측). 이 plist에 새 키를
  추가할 땐 표준 키가 여전히 살아있는지 함께 확인할 것 — 지우면 조용히 안 죽고 빌드는 되는데 설치가 깨진다.
- **Apple 로그인 버튼은 시뮬레이터에 Apple ID가 로그인돼 있으면 시스템 계정 선택/Face ID 시트로,
  없으면 설정 앱의 "Apple 계정" 화면으로 튄다**(둘 다 정상 — `OnboardingFeature/CLAUDE.md` 참고).
  Kakao 로그인은 `kauth.kakao.com` `ASWebAuthenticationSession` 동의 시트가 뜨는 게 정상(실측,
  시뮬레이터에서도 동작) — 취소하면 `.loginFailed` → "알 수 없는 에러가 발생했어요" 토스트로 낙착.
- **온보딩 완료(`OnboardingRootView.handleOnboardingCompleted`)·기존 유저 로그인 둘 다 `onFinished()`
  하나로 수렴**해 `ContentView`가 `route = .main`으로 전환한다 — 신규/기존 유저를 구분해 다른 곳으로
  보낼 이유가 아직 없어서 일부러 하나로 합쳤다. 나중에 갈림이 필요해지면(예: 신규 유저만 튜토리얼)
  `onFinished`를 매개변수 있는 콜백으로 바꿀 것.
