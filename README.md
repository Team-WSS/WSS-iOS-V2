# WSS-iOS-V2

<div align="center">
<img src="https://github.com/user-attachments/assets/6a77d2c5-2f10-4889-a2e8-5a8838c3bf71">
<br/><br/>

**웹소소** 앱의 차세대 iOS 클라이언트 저장소입니다.

서비스 성장에 따라 빠르게 늘어나는 기능 요구사항에 대응하고,<br/>
안정적으로 기능을 확장할 수 있는 구조를 만들기 위해<br/>
**Tuist 기반 멀티 모듈 + Clean Architecture** 방향으로 재설계를 진행하고 있습니다.

<a href="https://apps.apple.com/kr/app/%EC%9B%B9%EC%86%8C%EC%86%8C-%EC%9B%B9%EC%86%8C%EC%84%A4%EB%8F%84-%EC%86%8C%EC%84%A4%EC%9D%B4%EB%8B%A4/id6738299124">
    <img src="https://github.com/user-attachments/assets/ff532d33-22b8-40a0-bfa0-76375c0742ca" width="180" alt="App Store">
</a>
<a href="https://www.websoso.kr">
    <img src="https://github.com/user-attachments/assets/ca18711b-bc6a-4408-b15a-1f9a34d7108a" width="180" alt="Website">
</a>

</div>

<br/>

## ⚖️ As-Is vs To-Be

| 구분 | 🚨 As-Is (V1) | ✨ To-Be (V2) |
| --- | --- | --- |
| **프로젝트 구조** | 단일 Xcode 프로젝트 | **Tuist 기반 멀티 모듈** |
| **의존성 방향** | 양방향 및 복잡한 의존성 존재 | **단방향 (UI -> Domain <- Data)** |
| **비동기 처리** | RxSwift 중심 | **Domain/Data는 Swift Concurrency, UI는 Combine 예정** |
| **테스트 환경** | UI/비즈니스 로직 경계가 모호함 | **Domain 중심 테스트 가능한 구조** |
| **기능 확장 방식** | 영향 범위 파악이 어려움 | **도메인별 독립 개발 가능** |

<br/>

## 🚧 현재 상황

- `WSS-iOS`(V1)는 현재 운영 중인 클라이언트입니다.
- `WSS-iOS-V2`는 구조 개선과 점진적 기능 이전을 위한 차세대 코드베이스입니다.
- 현재는 **Core / Domain / Data 레이어 정비와 테스트 가능한 기반 구축**을 우선하고 있습니다.

## 🔄 진행 중인 작업

- V1 기능의 도메인 단위 이전
- Domain 비즈니스 로직 정리와 테스트 보강
- Data 계층 역할 분리와 의존성 정비
- Domain/Data의 Swift Concurrency 전환

## ✅ 현재까지의 변화

- `Core 3개`, `Data 3개`, `Domain 12개` 모듈 분리
- Swift Testing 기반 모듈 테스트 작성
- `/domain-test` 기반 Domain 테스트 워크플로 운영

<br/>

## 🤔 왜 V2를 만들었는가

웹소소는 서비스 운영과 함께 추천, 기록, 커뮤니티 기능이 빠르게 확장되었고,
그 과정에서 UI, 비즈니스 로직, 네트워크 구현, 외부 라이브러리 의존성이 여러 계층에 걸쳐 섞이기 시작했습니다.
이 구조에서는 작은 변경도 영향 범위를 예측하기 어려웠고, 기능 추가와 테스트 비용도 계속 커졌습니다.

V2는 이런 문제를 줄이기 위해 시작한 리빌드 프로젝트입니다.
핵심 목표는 비즈니스 로직을 Domain 계층으로 분리하고, Core / Domain / Data 레이어를 먼저 안정화한 뒤,
필요한 기능을 점진적으로 App에 연결해 유지보수와 확장에 강한 iOS 코드베이스를 만드는 것입니다.

<br/>

## 🛠 어떤 구조로 재설계했는가

현재 V2는 기능을 한 번에 모두 옮기기보다, 기반 구조를 먼저 분리하고 검증 가능한 단위로 쪼개는 데 초점을 맞추고 있습니다.

- `Core`는 Networking, Keychain, Logger처럼 재사용 가능한 기반 기술을 담당합니다.
- `Domain`은 Entity, UseCase, Repository 프로토콜 등 비즈니스 로직을 담당합니다.
- `Data`는 DTO, Mapper, Service, Repository 구현체를 통해 외부 데이터를 연결합니다.
- 이후 `Feature`와 `App` 레이어를 연결해 실제 기능과 화면을 단계적으로 옮겨갈 계획입니다.

<br/>

## ⚖️ 기술 스택

- `Language`: Swift
- `UI`: SwiftUI
- `Minimum Target`: iOS 17.0
- `Async`: Domain/Data는 Swift Concurrency, UI는 Combine
- `Project`: Tuist
- `Architecture`: Clean Architecture 기반 멀티 모듈
- `Test`: Swift Testing
- `CI/CD`: GitHub Actions
- `Dependencies`: 없음

```bash
# Tuist 설치
mise install

# 의존성 설치 + 프로젝트 생성
tuist install
tuist generate
```

<br/>

## 🏗 아키텍처

현재는 `Core / Domain / Data` 레이어를 먼저 정리하고 있으며,
이후 `Feature`와 `App` 레이어를 연결해 실제 기능과 화면까지 포함하는 앱 구조로 확장해갈 계획입니다.

### To-Be

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

### As-Is

```text
App
├── WSS-iOS               # SwiftUI 앱 진입점과 조립 대상
│
Core
├── Logger                # 로깅 추상화와 콘솔 로거
├── Networking            # 네트워크 클라이언트와 요청/응답 추상화
└── Keychain              # 보안 저장소와 키체인 접근 래퍼
│
Domain
├── AuthDomain            # 사용자 인증, 로그아웃, 탈퇴
├── BaseDomain            # 공통 식별자, 평점, 장르, 에러 등 기본 타입
├── Comment               # 댓글 작성, 수정, 삭제, 조회
├── Feed                  # 피드 작성/수정/삭제, 상세 조회, 좋아요
├── Keyword               # 키워드 조회와 검색
├── NotificationDomain    # 알림 조회와 푸시 설정
├── Novel                 # 작품 조회, 검색, 서재, 관심 등록
├── NovelReviewDomain     # 리뷰 초안 조회, 저장, 삭제
├── Profile               # 프로필, 닉네임, 선호 장르/작품 설정
├── Recommendation        # 홈 추천, 소소픽, 트렌딩 피드
├── Setting               # 앱 업데이트 정책과 약관 동의
└── SocialDomain          # 차단 사용자 관리와 신고 기능
│
Data
├── NotificationData      # 알림/푸시 API 연동과 Repository 구현
├── NovelReviewData       # 리뷰 API 연동, DTO 매핑, Repository 구현
└── RecommendationData    # 추천 데이터 연동 모듈
```

<br/>

## 💡 왜 이런 선택을 했는가

### 1. Tuist 기반 모듈화

Tuist 템플릿으로 Core / Domain / Data 모듈 생성 방식을 통일했습니다.
모듈별 설정을 같은 규칙으로 관리할 수 있고, 새로운 기능도 동일한 방식으로 확장할 수 있습니다.

### 2. Domain 계층 분리

비즈니스 로직을 Domain에 두고, Data가 Repository를 구현하는 구조를 택했습니다.
이렇게 하면 UI 변경과 핵심 정책 변경의 영향을 분리하기 쉽고, 테스트에서도 Mock 주입이 단순해집니다.

### 3. 계층별 비동기 처리 분리

현재 Domain / Data 모듈은 `async/await` 기반으로 작성하고 있으며,
UI 레이어는 상태 바인딩과 이벤트 처리를 위해 Combine을 사용하는 방향을 고려하고 있습니다.

```swift
public protocol NotificationRepository: Sendable {
    func loadNotifications(lastNotificationID: NotificationID?, size: Int)
        async throws(RepositoryError) -> PagedNotifications
}
```

### 4. Data 계층의 역할 분리

Data 모듈은 `Service → Repository → Mapper` 구조로 나누어 작성하고 있습니다.
이 구조는 네트워크 호출, 도메인 매핑, 저장 책임을 분리해 변경 영향을 줄이는 데 목적이 있습니다.

### 5. Swift Testing과 CI

테스트는 Swift Testing 기반으로 작성되어 있으며,
CI는 현재 Domain 스킴 병렬 테스트를 중심으로 검증 흐름을 운영하고 있습니다.

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
