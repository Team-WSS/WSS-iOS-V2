# WSS-iOS-V2

<div align="center">
<img src="https://github.com/user-attachments/assets/6a77d2c5-2f10-4889-a2e8-5a8838c3bf71">
<br/><br/>

**웹소소** 앱의 차세대 iOS 클라이언트 저장소입니다.

장기 운영 과정에서 복잡해진 의존성을 정리하고,<br/>
기능 확장과 테스트가 쉬운 구조를 만들기 위해<br/>
**Tuist 기반 멀티 모듈 + Clean Architecture** 방향으로 재설계를 진행하고 있습니다.

<a href="https://apps.apple.com/kr/app/%EC%9B%B9%EC%86%8C%EC%86%8C-%EC%9B%B9%EC%86%8C%EC%84%A4%EB%8F%84-%EC%86%8C%EC%84%A4%EC%9D%B4%EB%8B%A4/id6738299124">
    <img src="https://github.com/user-attachments/assets/ff532d33-22b8-40a0-bfa0-76375c0742ca" width="180" alt="App Store">
</a>
<a href="https://www.websoso.kr">
    <img src="https://github.com/user-attachments/assets/ca18711b-bc6a-4408-b15a-1f9a34d7108a" width="180" alt="Website">
</a>

</div>

<br/>

## ⚖️ Architecture: As-Is vs To-Be

| 구분 | 🚨 As-Is (V1) | ✨ To-Be (V2) |
| --- | --- | --- |
| **의존성 방향** | 양방향 및 복잡한 의존성 존재 | **단방향 (UI -> Domain <- Data)** |
| **비동기 처리** | RxSwift 중심 | **Domain/Data는 Swift Concurrency, UI는 Combine 예정** |
| **테스트 환경** | UI/비즈니스 로직 경계가 모호함 | **Domain 중심 테스트 가능한 구조** |
| **빌드/확장성** | 단일 프로젝트 중심 | **Tuist 기반 멀티 모듈 + 모듈 단위 확장** |

<br/>

## 🚧 현재 상황

- `WSS-iOS`(V1)는 현재 운영 중인 클라이언트입니다.
- `WSS-iOS-V2`는 구조 개선과 점진적 기능 이전을 위한 차세대 코드베이스입니다.
- 현재 우선순위는 **Core / Domain / Data 정비와 테스트 가능한 기반 구축**입니다.

## 🔄 진행 중인 작업

- V1 기능의 도메인 단위 이전
- Domain 비즈니스 로직 정리와 테스트 보강
- Data 계층 역할 분리와 의존성 정비
- Domain/Data의 Swift Concurrency 전환과 UI 단 Combine 적용 준비
- App / Feature 연결 구조 준비

## ✅ 현재까지의 변화

- `Core 3개`, `Data 3개`, `Domain 12개` 모듈 분리
- 외부 패키지 의존성 0개
- Swift Testing 기반 모듈 테스트 작성
- `/domain-test` 기반 Domain 테스트 워크플로 운영
- 현재 워크스페이스 빌드 가능

<br/>

## 🤔 왜 V2를 만들었는가

기존 `WSS-iOS`는 실제 서비스 운영을 거치며 기능이 확장되었지만, 그 과정에서 프로젝트 내부 의존성도 함께 복잡해졌습니다.
UI, 비즈니스 로직, 네트워크 구현, 외부 라이브러리 의존성이 여러 계층에 걸쳐 섞이면서 특정 기능을 수정할 때 영향 범위를 파악하기 어려웠고,
새로운 기능을 추가하거나 테스트 환경을 구축하는 데 드는 비용도 점점 커졌습니다.

특히 장기적으로 서비스를 운영하려면 다음 조건을 만족하는 구조가 필요했습니다.

- 기능이 늘어나도 모듈 간 의존성을 통제할 수 있을 것
- 비즈니스 로직이 UI나 외부 구현 세부사항에 흔들리지 않을 것
- 기능 단위로 빠르게 테스트하고 검증할 수 있을 것
- 신규 기능 개발과 리팩토링을 동시에 진행해도 구조가 무너지지 않을 것

V2는 이러한 문제를 해결하기 위해 시작한 리빌드 프로젝트입니다.
핵심 목표는 비즈니스 로직을 Domain 계층으로 분리하고, Core / Domain / Data 레이어를 먼저 안정화한 뒤,
필요한 기능을 점진적으로 App에 연결해 나가면서 유지보수와 확장이 가능한 iOS 코드베이스를 만드는 것입니다.

<br/>

## 🛠 어떤 구조로 재설계했는가

현재 V2는 서비스 기능을 한 번에 모두 옮기기보다, 기반 구조를 먼저 분리하고 검증 가능한 단위로 쪼개는 데 초점을 맞추고 있습니다.
지금까지 정리된 방향은 아래와 같습니다.

| | V1 (WSS-iOS) | V2 (WSS-iOS-V2) |
|---|---|---|
| **프로젝트 관리** | 단일 Xcode 프로젝트 | Tuist 기반 멀티 프로젝트 |
| **아키텍처 방향** | MVC / MVVM 혼재 | Core / Domain / Data 분리 중심 |
| **비동기 처리** | RxSwift | Domain/Data는 Swift Concurrency, UI는 Combine 예정 |
| **에러 처리** | 일반 throws | 일부 Domain / Data 모듈에서 Typed Throws 사용 |
| **UI 상태** | UIKit 기반 운영 앱 | SwiftUI App 셸 + 단계적 기능 이전 |
| **테스트** | 제한적 | Swift Testing 기반 모듈 테스트 확장 중 |
| **CI/CD** | - | Domain 스킴 병렬 테스트 워크플로 운영 |
| **외부 의존성** | SnapKit, RxSwift, Then 등 | 0개 |

<br/>

## ⚖️ 기술 스택

| 구분 | 기술 |
|---|---|
| **Language** | Swift |
| **UI** | SwiftUI |
| **Minimum Target** | iOS 17.0 |
| **비동기 처리** | Domain/Data는 Swift Concurrency, UI는 Combine |
| **프로젝트 관리** | Tuist |
| **아키텍처 방향** | Clean Architecture 기반 멀티 모듈 |
| **테스트** | Swift Testing |
| **CI/CD** | GitHub Actions |
| **외부 의존성** | 없음 |

```bash
# Tuist 설치
mise install

# 의존성 설치 + 프로젝트 생성
tuist install
tuist generate
```

<br/>

## 🏗 아키텍처

현재 코드베이스는 `App / Core / Domain / Data` 구조를 중심으로 분리되어 있습니다.
README에서 설명하는 아키텍처는 이미 완성된 화면 레이어까지 모두 구현된 상태가 아니라,
**비즈니스 로직과 데이터 흐름을 먼저 분리하고 이후 App에 연결해 나가는 구조적 방향**을 의미합니다.

### 최종적으로 지향하는 구조

현재는 `Core / Domain / Data` 레이어를 먼저 정리하고 있으며,
이후 `Feature`와 `App` 레이어를 연결해 실제 기능과 화면까지 포함하는 앱 구조로 확장해갈 계획입니다.

```text
App
└── DI와 전역 흐름 조립

Feature
└── 실제 기능 구현(UI 포함)

Domain
└── 비즈니스 로직과 Repository 프로토콜

Data
└── Repository 구현

Core
└── 의존성을 최소화한 외부 기술 자체
```

- `App`: 각 Feature와 Data 구현체를 조립하고, 앱 진입점과 전역 DI를 담당합니다.
- `Feature`: 화면과 사용자 인터랙션을 포함한 실제 기능 구현 레이어이며, 필요한 Domain 모듈만 import합니다.
- `Domain`: Entity, UseCase, Repository 프로토콜 등 순수 비즈니스 로직을 담당합니다.
- `Data`: Domain의 Repository를 구현하고, API/저장소/매핑 책임을 맡습니다.
- `Core`: Networking, Keychain, Logger처럼 외부 기술을 얇고 재사용 가능한 형태로 제공합니다.

### 현재 구현된 레이어

```text
App
├── WSS-iOS
│
Core
├── Logger
├── Networking
└── Keychain
│
Domain
├── AuthDomain
├── BaseDomain
├── Comment
├── Feed
├── Keyword
├── NotificationDomain
├── Novel
├── NovelReviewDomain
├── Profile
├── Recommendation
├── Setting
└── SocialDomain
│
Data
├── NotificationData
├── NovelReviewData
└── RecommendationData
```

### 레이어 역할

- `Core`: 네트워킹, 키체인, 로깅처럼 여러 모듈에서 공통으로 사용하는 기반 기능
- `Domain`: Entity, Repository 프로토콜, UseCase 등 순수 비즈니스 로직
- `Data`: API 연동, DTO, Mapper, Repository 구현체
- `App`: 현재는 최소한의 SwiftUI 진입점이며, 이후 기능 모듈 연결 예정

### 현재 문서화 기준

- 이미 구현된 구조: Core / Domain / Data 중심의 멀티 모듈
- 진행 중인 구조: V1 기능의 점진적 이전과 App 연결
- 다음 단계 목표: Feature 레이어를 도입해 화면 단위 기능 구현과 DI 흐름 정리
- 아직 구현되지 않은 항목: 독립적인 Feature / UI 모듈 분리의 본격 적용

<br/>

## 💡 왜 이런 선택을 했는가

### 1. Tuist 기반 모듈화

Tuist 템플릿을 사용해 Core / Domain / Data 모듈 생성 방식을 통일했습니다.
현재 `Project+Templates.swift`에 모듈 생성 규칙이 정리되어 있고, 각 모듈은 동일한 패턴으로 확장할 수 있습니다.

```swift
Project.createDomainModule(
    name: ModuleType.Domain.recommendation.name,
    targets: [.sources, .tests, .testing],
    internalDependencies: [.Domain.BaseDomain]
)
```

- 모듈별 설정 방식이 일관됩니다.
- Domain / Data / Core 프로젝트를 같은 규칙으로 확장할 수 있습니다.
- 의존성 정리를 코드 수준에서 반복 가능한 방식으로 관리할 수 있습니다.

### 2. Domain 계층 분리

비즈니스 로직을 외부 구현으로부터 분리하기 위해 Domain 모듈을 먼저 정리했습니다.
Repository 프로토콜과 UseCase를 Domain에 두고, Data가 이를 구현하는 방향을 채택했습니다.

- UI 변경과 비즈니스 로직 변경의 영향을 분리할 수 있습니다.
- 테스트에서 Mock Repository를 주입하기 쉽습니다.
- 실제 기능 이전 전에 정책과 흐름을 먼저 검증할 수 있습니다.

### 3. 계층별 비동기 처리 분리

현재 Domain / Data 모듈 다수는 `async/await` 기반으로 작성되어 있고, 일부 Repository와 UseCase는 Typed Throws를 사용합니다.
UI 레이어는 이후 상태 바인딩과 화면 이벤트 처리를 위해 Combine을 사용하는 방향을 고려하고 있습니다.

```swift
public protocol NotificationRepository: Sendable {
    func loadNotifications(lastNotificationID: NotificationID?, size: Int)
        async throws(RepositoryError) -> PagedNotifications
}
```

- 비동기 흐름을 언어 차원에서 다룰 수 있습니다.
- 에러 타입을 명시해 호출부에서 더 분명하게 처리할 수 있습니다.
- V1의 RxSwift 의존성 없이 새로운 계층을 구성할 수 있습니다.
- 계층별 역할에 따라 비동기 모델을 구분해 적용할 수 있습니다.

### 4. Data 계층의 역할 분리

현재 Data 모듈은 `Service → Repository → Mapper` 역할을 나누는 방향으로 작성되어 있습니다.

```text
Data/NotificationData/
├── Sources/Notification
│   ├── DTO
│   ├── Endpoint
│   ├── Logger
│   ├── Mapper
│   ├── Repository
│   └── Service
└── Sources/Push
```

- DTO와 Domain Entity를 분리해 서버 응답 변화의 영향을 줄입니다.
- 네트워크 호출, 매핑, 저장 로직의 책임을 분리할 수 있습니다.
- 도메인별 로깅과 오류 매핑을 구분해 관리할 수 있습니다.

### 5. Swift Testing과 CI

테스트는 Swift Testing 기반으로 작성되어 있으며, Domain/Data 모듈에 테스트와 Testing 타깃이 함께 구성되어 있습니다.
CI는 모든 앱 기능을 검증하는 형태가 아니라, 현재는 **Domain 스킴 병렬 테스트**에 초점을 맞추고 있습니다.

- 테스트 더블을 재사용할 수 있는 Testing 타깃이 있습니다.
- Domain 스킴을 자동 탐색해 `/domain-test` 트리거로 실행합니다.
- 현재 구조가 유지되는지 지속적으로 검증할 수 있습니다.

<br/>

## 🧑‍💻 Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/Guryss"><img src="https://avatars.githubusercontent.com/u/102604192?v=4" width="100px;" alt=""/><br/><sub><b>최서연</b></sub></a>
    </td>
    <td align="center">
      <a href="https://github.com/Naknakk"><img src="https://avatars.githubusercontent.com/u/87518742?v=4" width="100px;" alt=""/><br/><sub><b>이윤학</b></sub></a>
    </td>
    <td align="center">
      <a href="https://github.com/onesunny2"><img src="https://avatars.githubusercontent.com/u/162902591?v=4" width="100px;" alt=""/><br/><sub><b>이원선</b></sub></a>
    </td>
  </tr>
</table>

<br/>

## 🔗 관련 링크

- [WSS-iOS (V1)](https://github.com/Team-WSS/WSS-iOS) — 기존 프로젝트
- [웹소소 공식 사이트](https://www.websoso.kr)
- [App Store](https://apps.apple.com/kr/app/%EC%9B%B9%EC%86%8C%EC%86%8C-%EC%9B%B9%EC%86%8C%EC%84%A4%EB%8F%84-%EC%86%8C%EC%84%A4%EC%9D%B4%EB%8B%A4/id6738299124)
