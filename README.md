# WSS-iOS-V2

<div align="center">
<img src="https://github.com/user-attachments/assets/6a77d2c5-2f10-4889-a2e8-5a8838c3bf71">
<br/><br/>

**웹소소** 앱의 차세대 iOS 클라이언트입니다.

장기 운영으로 누적된 의존성 문제를 정리하고,<br/>
기능 확장과 테스트가 쉬운 구조를 만들기 위해<br/>
**Tuist 기반 멀티 모듈 + Clean Architecture**로 재설계를 진행하고 있습니다.

<a href="https://apps.apple.com/kr/app/%EC%9B%B9%EC%86%8C%EC%86%8C-%EC%9B%B9%EC%86%8C%EC%84%A4%EB%8F%84-%EC%86%8C%EC%84%A4%EC%9D%B4%EB%8B%A4/id6738299124">
    <img src="https://github.com/user-attachments/assets/ff532d33-22b8-40a0-bfa0-76375c0742ca" width="180" alt="App Store">
</a>
<a href="https://www.websoso.kr">
    <img src="https://github.com/user-attachments/assets/ca18711b-bc6a-4408-b15a-1f9a34d7108a" width="180" alt="Website">
</a>

</div>

<br/>

## 🚧 현재 상황

- 현재 서비스는 기존 `WSS-iOS`(V1) 클라이언트로 운영되고 있습니다.
- `WSS-iOS-V2`는 기존 앱을 한 번에 교체하는 프로젝트가 아니라, 장기 운영에 적합한 구조로 점진적으로 전환하기 위한 차세대 클라이언트 저장소입니다.
- 기능 이전과 구조 개선을 병행하며, 아키텍처 안정화와 테스트 가능한 개발 환경 구축을 우선적으로 진행하고 있습니다.

## 🔄 진행 중인 작업

- V1 기능을 도메인 단위로 분리해 V2 구조에 맞게 순차적으로 이전
- Domain 중심 비즈니스 로직 정리 및 테스트 코드 보강
- Data 계층의 책임 분리와 모듈 간 의존성 정비
- Swift Concurrency 기반 비동기 흐름 전환
- SwiftUI 기반 Feature 모듈과 공통 UI 자산 정리

## ✅ 현재까지의 변화

- Tuist 기반 멀티 모듈 구조를 도입해 모듈 생성과 의존성 관리를 표준화했습니다.
- Domain 계층을 외부 구현으로부터 분리해 테스트 가능한 비즈니스 로직 구조를 만들었습니다.
- RxSwift 의존성을 제거하고 Swift Concurrency 기반으로 전환했습니다.
- Swift Testing과 CI 파이프라인을 도입해 모듈 단위 검증 기반을 갖췄습니다.

<br/>

## 🤔 왜 V2를 만들었는가

기존 `WSS-iOS`는 실제 서비스 운영을 거치며 기능이 확장되었지만, 그 과정에서 프로젝트 내부 의존성도 함께 복잡해졌습니다.
UI, 비즈니스 로직, 네트워크 구현, 외부 라이브러리 의존성이 여러 계층에 걸쳐 섞이기 시작하면서 특정 기능을 수정할 때 영향 범위를 파악하기 어려웠고,
새로운 기능을 추가하거나 테스트 환경을 구축하는 데 드는 비용도 계속 커졌습니다.

특히 장기적으로 서비스를 운영하려면 다음 문제가 반복되지 않는 구조가 필요했습니다.

- 기능이 늘어나도 모듈 간 의존성이 통제될 것
- 비즈니스 로직이 UI나 외부 라이브러리 변화에 흔들리지 않을 것
- 기능 단위로 빠르게 테스트하고 검증할 수 있을 것
- 신규 기능과 리팩토링을 동시에 진행해도 구조가 유지될 것

V2는 이러한 문제를 해결하기 위해 시작한 리빌드 프로젝트입니다.
핵심 목표는 비즈니스 로직을 Domain 계층으로 독립시키고, Tuist 기반 멀티 모듈 구조 안에서 기능을 점진적으로 이전하며,
장기적으로 유지보수와 확장이 가능한 iOS 코드베이스를 만드는 것입니다.

<br/>

## 🛠 어떤 구조로 재설계했는가

V2는 서비스 기능을 계속 확장할 수 있도록 프로젝트 구조 자체를 재정비하는 데 초점을 맞췄습니다.
기존 구조와 비교하면 다음과 같은 변화가 있습니다.

| | V1 (WSS-iOS) | V2 (WSS-iOS-V2) |
|---|---|---|
| **프로젝트 관리** | 단일 Xcode 프로젝트 | Tuist 기반 멀티 모듈 |
| **아키텍처** | MVC / MVVM 혼재 | Clean Architecture (Feature → Domain → Data → Core) |
| **비동기 처리** | RxSwift | Swift Concurrency (async/await) |
| **에러 처리** | 일반 throws | Typed Throws (`throws(RepositoryError)`) |
| **UI 프레임워크** | UIKit | SwiftUI |
| **테스트** | 미비 | Swift Testing + Domain 중심 테스트 |
| **CI/CD** | - | GitHub Actions (모듈별 테스트 + 커버리지 리포트) |
| **외부 의존성** | SnapKit, RxSwift, Then 등 | 0개 (Apple 프레임워크만 사용) |

<br/>

## ⚖️ 기술 스택

| 구분 | 기술 |
|---|---|
| **Language** | Swift 6.0 |
| **UI** | SwiftUI |
| **Minimum Target** | iOS 17.0 |
| **비동기 처리** | Swift Concurrency (async/await, Sendable) |
| **프로젝트 관리** | Tuist |
| **아키텍처** | Clean Architecture + 멀티 모듈 |
| **테스트** | Swift Testing (@Suite, @Test, #expect) |
| **CI/CD** | GitHub Actions |
| **외부 의존성** | 없음 (Apple 프레임워크만 사용) |

```bash
# Tuist 설치
mise install

# 의존성 설치 + 프로젝트 생성
tuist install
tuist generate
```

<br/>

## 🏗 아키텍처

### Clean Architecture + 멀티 모듈

비즈니스 로직을 **Domain 계층으로 완전히 독립**시켜, UI나 외부 라이브러리 변화에 영향을 받지 않는 안정적인 구조를 설계했습니다.

```
┌──────────────────────────────────────────────────────────────┐
│  Feature Layer                                               │
│  SwiftUI 기반 화면 단위 모듈                                    │
│  HomeFeature · FeedFeature                                   │
├──────────────────────────────────────────────────────────────┤
│  Domain Layer                                                │
│  순수 비즈니스 로직 · 외부 의존성 없음                             │
│  Entity · UseCase · Repository(Protocol)                     │
├──────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  Repository 구현체 · DTO · Mapper · API Service               │
├──────────────────────────────────────────────────────────────┤
│  Core Layer                                                  │
│  Networking · Keychain · Logger                              │
└──────────────────────────────────────────────────────────────┘
```

**의존성 방향은 항상 안쪽(Domain)으로만 향합니다.** Data 계층이 Domain의 Repository 프로토콜을 구현하며, Domain은 외부 구현을 알지 못합니다.

### 모듈 구성

<table>
  <tr>
    <th>Layer</th>
    <th>Module</th>
    <th>역할</th>
  </tr>
  <tr>
    <td rowspan="12"><b>Domain</b></td>
    <td>BaseDomain</td>
    <td>공통 Entity, RepositoryError, ID Wrapper 등 공유 타입</td>
  </tr>
  <tr><td>AuthDomain</td><td>인증 · 회원가입</td></tr>
  <tr><td>NovelDomain</td><td>웹소설 정보</td></tr>
  <tr><td>NovelReviewDomain</td><td>웹소설 리뷰</td></tr>
  <tr><td>FeedDomain</td><td>피드 CRUD</td></tr>
  <tr><td>CommentDomain</td><td>댓글</td></tr>
  <tr><td>KeywordDomain</td><td>키워드 · 태그</td></tr>
  <tr><td>RecommendationDomain</td><td>추천</td></tr>
  <tr><td>NotificationDomain</td><td>알림 · 푸시 설정</td></tr>
  <tr><td>ProfileDomain</td><td>프로필</td></tr>
  <tr><td>SocialDomain</td><td>소셜</td></tr>
  <tr><td>SettingDomain</td><td>설정</td></tr>
  <tr>
    <td rowspan="3"><b>Data</b></td>
    <td>NotificationData</td><td>알림 API 연동 · Repository 구현</td>
  </tr>
  <tr><td>NovelReviewData</td><td>리뷰 API 연동 · Repository 구현</td></tr>
  <tr><td>RecommendationData</td><td>추천 API 연동 · Repository 구현</td></tr>
  <tr>
    <td rowspan="3"><b>Core</b></td>
    <td>Networking</td><td>URLSession 기반 네트워크 클라이언트</td>
  </tr>
  <tr><td>Keychain</td><td>보안 저장소 (토큰 관리)</td></tr>
  <tr><td>Logger</td><td>로깅 추상화</td></tr>
  <tr>
    <td rowspan="2"><b>UI</b></td>
    <td>DesignSystem</td><td>디자인 토큰 · 공통 스타일</td>
  </tr>
  <tr><td>WSSComponent</td><td>재사용 UI 컴포넌트</td></tr>
</table>

<br/>

## 💡 왜 이런 선택을 했는가

### 1. Swift Concurrency 전면 도입 — RxSwift 의존성 제거

V1에서 전역적으로 사용하던 **RxSwift를 완전히 제거**하고, Swift Concurrency(async/await)로 마이그레이션했습니다.

```swift
// V2: async/await + Typed Throws
public protocol NotificationRepository: Sendable {
    func loadNotifications(lastNotificationID: NotificationID?, size: Int)
        async throws(RepositoryError) -> PagedNotifications
}
```

- **Sendable 프로토콜 준수**로 동시성 안전성을 컴파일 타임에 보장
- **Typed Throws** (`throws(RepositoryError)`)로 에러 타입이 명확해져 호출부에서 에러 처리를 단순화
- 서드파티 의존성 없이 Apple 프레임워크만으로 동작

### 2. Tuist 기반 모듈화 — 복잡한 의존성 해소

Tuist Plugin DSL을 직접 설계해 모듈 생성을 템플릿화했습니다.

```swift
Project.createDomainModule(
    name: "NotificationDomain",
    targets: [.sources, .testing, .tests],
    internalDependencies: [.Domain.BaseDomain]
)
```

- **모듈 간 의존성이 단방향**으로 강제되어 순환 참조를 예방
- 새로운 도메인 추가 시 같은 규칙으로 모듈을 확장 가능
- 모듈별 **독립 빌드 · 독립 테스트** 기반 확보

### 3. Domain 계층 독립 — 테스트 가능한 비즈니스 로직

Domain 모듈은 **외부 프레임워크에 대한 의존성이 없는 순수 Swift 계층**으로 구성했습니다.

- UI 프레임워크 변화에 영향받지 않음
- 네트워크나 저장소 구현 교체에 영향받지 않음
- Mock 주입만으로 단위 테스트 가능

### 4. Data 계층의 관심사 분리

Data 계층은 `Service → Repository → Mapper` 패턴으로 역할을 분리했습니다.

```text
Data/NotificationData/
├── DTO/
├── Endpoint/
├── Service/
├── Repository/
├── Mapper/
├── Logger/
└── Factory/
```

- DTO와 Domain Entity의 경계를 분리해 서버 응답 변경 영향 최소화
- 객체 생성과 의존성 조립을 한 곳에서 관리

### 5. Testing 인프라

**Swift Testing** 프레임워크를 채택하고, 테스트 전용 모듈을 분리해 Mock 재사용 구조를 만들었습니다.

```swift
@Suite("LoadPushPreferenceUseCase")
struct LoadPushPreferenceUseCaseTests {
    @Test("푸시 알림 수신 여부를 조회할 수 있다")
    func loadsPushPreferenceSuccessfully() async throws {
        let repo = MockPushSettingRepository()
        repo.loadResult = .success(PushPreference(isEnabled: false))
        let sut = DefaultLoadPushPreferenceUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadCallCount == 1)
        #expect(result == PushPreference(isEnabled: false))
    }
}
```

- Mock 객체를 별도 Testing 모듈로 분리
- 호출 횟수와 인자 추적이 가능한 패턴 정리
- 정책 위반, 상태 변화, 경계값 관점의 테스트 확장 가능

### 6. CI/CD 파이프라인

GitHub Actions로 **모듈별 병렬 테스트 + 커버리지 리포트**를 구축했습니다.

- 모듈 추가 시 CI 설정 수정 없이 자동 탐색 가능
- Tuist와 DerivedData 캐싱으로 빌드 시간 최적화

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
