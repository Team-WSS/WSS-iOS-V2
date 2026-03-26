# WSS-iOS-V2

<div align="center">
<img src="https://github.com/user-attachments/assets/6a77d2c5-2f10-4889-a2e8-5a8838c3bf71">
<br/><br/>

**웹소소** 앱의 차세대 iOS 클라이언트입니다.

장기 운영으로 쌓인 의존성 문제를 해결하고 확장성을 확보하고자,<br/>
**Tuist 기반 멀티 모듈 + Clean Architecture**로 전면 재설계했습니다.

<a href="https://apps.apple.com/kr/app/%EC%9B%B9%EC%86%8C%EC%86%8C-%EC%9B%B9%EC%86%8C%EC%84%A4%EB%8F%84-%EC%86%8C%EC%84%A4%EC%9D%B4%EB%8B%A4/id6738299124">
    <img src="https://github.com/user-attachments/assets/ff532d33-22b8-40a0-bfa0-76375c0742ca" width="180" alt="App Store">
</a>
<a href="https://www.websoso.kr">
    <img src="https://github.com/user-attachments/assets/ca18711b-bc6a-4408-b15a-1f9a34d7108a" width="180" alt="Website">
</a>

</div>

<br/>

## V1 → V2: 무엇이 달라졌는가

| | V1 (WSS-iOS) | V2 (WSS-iOS-V2) |
|---|---|---|
| **프로젝트 관리** | 단일 Xcode 프로젝트 | Tuist 기반 멀티 모듈 |
| **아키텍처** | MVC / MVVM 혼재 | Clean Architecture (Domain → Data → Feature) |
| **비동기 처리** | RxSwift | Swift Concurrency (async/await) |
| **에러 처리** | 일반 throws | Typed Throws (`throws(RepositoryError)`) |
| **UI 프레임워크** | UIKit | SwiftUI |
| **테스트** | 미비 | Swift Testing + Domain 전 모듈 커버리지 |
| **CI/CD** | — | GitHub Actions (도메인별 병렬 테스트 + 커버리지 리포트) |
| **외부 의존성** | SnapKit, RxSwift, Then 등 8개+ | 0개 (Apple 프레임워크만 사용) |

<br/>

## 아키텍처

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

## 기술적 개선 포인트

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
- **Typed Throws** (`throws(RepositoryError)`)로 에러 타입이 명확해져, 호출부에서 exhaustive한 에러 처리 가능
- 서드파티 의존성 0개 — Apple 프레임워크만으로 동작

### 2. Tuist 기반 모듈화 — 복잡한 의존성 해소

Tuist Plugin DSL을 직접 설계해 모듈 생성을 템플릿화했습니다.

```swift
// 한 줄로 모듈 생성 — 4가지 타겟(Sources, Testing, Tests, Demo) 자동 구성
Project.createDomainModule(
    name: "NotificationDomain",
    targets: [.sources, .testing, .tests],
    internalDependencies: [.Domain.BaseDomain]
)
```

- **모듈 간 의존성이 단방향**으로 강제되어 순환 참조 원천 차단
- 새로운 도메인 추가 시 `ModuleType` enum에 case 하나 추가 + `Project.swift` 생성으로 완료
- 모듈별 **독립 빌드 · 독립 테스트** 가능 → 빌드 시간 단축

### 3. Domain 계층 독립 — 테스트 가능한 비즈니스 로직

Domain 모듈은 **외부 프레임워크에 대한 의존성이 전혀 없습니다.** 순수 Swift 코드로만 구성되어 있어:

- UI 프레임워크(SwiftUI/UIKit) 변경에 영향받지 않음
- 네트워크 계층 교체에 영향받지 않음
- Mock 주입만으로 빠르게 단위 테스트 가능

```
Domain/NotificationDomain/
├── Sources/
│   ├── Notification/
│   │   ├── Entity/          # 불변 값 객체
│   │   ├── Repository/      # 프로토콜 (인터페이스)
│   │   └── UseCase/         # 비즈니스 규칙
│   └── Push/
│       ├── Entity/
│       ├── Repository/
│       └── UseCase/
├── Testing/                 # Mock 객체 (테스트 전용 모듈)
└── Tests/                   # 단위 테스트
```

### 4. Data 계층의 관심사 분리

Data 계층은 `Service → Repository → Mapper` 패턴으로 역할을 명확히 분리했습니다.

```
Data/NotificationData/
├── DTO/          # 서버 응답/요청 모델 (Codable)
├── Endpoint/     # API 경로 + HTTP 메서드 정의
├── Service/      # 네트워크 호출 (저수준)
├── Repository/   # Domain Repository 구현체
├── Mapper/       # DTO ↔ Domain Entity 변환
├── Logger/       # 도메인별 로깅
└── Factory/      # 의존성 조립
```

- **Mapper**가 DTO와 Entity 사이 변환을 전담 → 서버 응답 구조가 바뀌어도 Domain은 영향 없음
- **Factory 패턴**으로 객체 생성과 의존성 주입을 한 곳에서 관리

### 5. Testing 인프라

**Swift Testing** 프레임워크를 채택하고, 체계적인 Mock 패턴을 도입했습니다.

```swift
@Suite("LoadPushPreferenceUseCase")
struct LoadPushPreferenceUseCaseTests {
    @Test("푸시 알림 수신 여부를 조회할 수 있다")
    func loadsPushPreferenceSuccessfully() async throws {
        // Given
        let repo = MockPushSettingRepository()
        repo.loadResult = .success(PushPreference(isEnabled: false))
        let sut = DefaultLoadPushPreferenceUseCase(repository: repo)

        // When
        let result = try await sut.execute()

        // Then
        #expect(repo.loadCallCount == 1)
        #expect(result == PushPreference(isEnabled: false))
    }
}
```

- **Testing 모듈 분리** — Mock 객체를 별도 프레임워크(`~Testing`)로 빌드해, 테스트 코드 간 재사용
- **Tracking Array + Result 패턴** — 호출 횟수·인자를 추적하고, 반환값을 자유롭게 제어
- 정상 / 경계값 / 정책 위반 / 상태 변화 — 4가지 관점의 커버리지 확보

### 6. CI/CD 파이프라인

GitHub Actions로 **도메인별 병렬 테스트 + 자동 커버리지 리포트**를 구축했습니다.

```
PR 코멘트 "/domain-test" 트리거
    │
    ├─ Discover ──→ Domain 모듈 자동 탐색
    │
    ├─ Test (병렬) ──→ 모듈별 독립 테스트 + 커버리지 수집
    │   ├─ BaseDomain
    │   ├─ FeedDomain
    │   ├─ NotificationDomain
    │   └─ ...
    │
    └─ Report ──→ PR에 커버리지 테이블 자동 코멘트
```

- 모듈 추가 시 CI 설정 수정 불필요 — `Projects/Domain/` 하위를 자동 탐색
- Tuist + DerivedData **캐싱**으로 CI 빌드 시간 최적화

<br/>

## 기술 스택

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

<br/>

## 개발 환경 설정

```bash
# 1. Tuist 설치 (mise 사용)
mise install

# 2. 의존성 설치 + 프로젝트 생성
tuist install
tuist generate
```

<br/>

## Contributors

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

## 관련 링크

- [WSS-iOS (V1)](https://github.com/Team-WSS/WSS-iOS) — 기존 프로젝트
- [웹소소 공식 사이트](https://www.websoso.kr)
- [App Store](https://apps.apple.com/kr/app/%EC%9B%B9%EC%86%8C%EC%86%8C-%EC%9B%B9%EC%86%8C%EC%84%A4%EB%8F%84-%EC%86%8C%EC%84%A4%EC%9D%B4%EB%8B%A4/id6738299124)
