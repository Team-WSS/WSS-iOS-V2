# App 레이어

앱 진입점. **의존성 주입(DI)과 전역 흐름 조립**을 담당한다. 비즈니스 로직은 두지 않는다.

> 🚧 **현재 스켈레톤 단계.** `Projects/App/Sources/`에 `WSSIOSV2App.swift`, `ContentView.swift`만 존재.

- 디렉토리: `Projects/App/`
- 비동기/상태: SwiftUI App lifecycle

## 책임

- 앱 진입점(`@main`), 전역 환경 구성.
- 각 레이어 조립 — Data 구현체와 Domain 프로토콜이 만나는 **유일한 지점**.
- 화면 전환·딥링크 등 전역 흐름 조정.

## 의존 규칙

- ✅ Feature, Domain, Data(Factory), Core, UI — 조립을 위해 거의 모든 레이어를 알 수 있다.
- App은 의존성 그래프의 최상위이므로 누구도 App을 import 하지 않는다.

## 코드 규칙 (초안 — 조립 구현 시 확정)

조립 골격(예시 — DI 컨테이너 방식 정해지면 표준 패턴으로 갱신):

```swift
let repository = XxxDataFactory.makeXxxRepository(...)        // Data 구현체
let useCase    = DefaultXxxUseCase(repository: repository)    // Domain 프로토콜에 주입
let view       = XxxFactory.makeView(useCase: useCase)        // Feature에 전달
```

## 주의사항 (작업 중 발견 시 누적)

- 조립 코드가 실제로 들어오면 README의 "DI·전역 흐름 조립" 의도와 맞는지 점검 후 갱신.
