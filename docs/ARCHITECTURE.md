# 아키텍처 개요

웹소소 V2는 V1(단일 Xcode 프로젝트, 양방향 의존성, RxSwift 중심)의 구조적 한계를 풀기 위한
리빌드 프로젝트다. **기능을 한 번에 옮기지 않고**, 기반 레이어(Core/Domain/Data)를 먼저
안정화한 뒤 Feature/App을 점진적으로 연결한다.

## 레이어와 의존성 방향

```text
        App            DI·전역 흐름 조립 (앱 진입점)
         │
         ▼
      Feature          실제 기능·화면 구현 (UI 포함) — 계획 단계
       ╱     ╲
      ▼       ▼
     UI      Domain    UI: 재사용 컴포넌트 헬퍼 / Domain: 비즈니스 로직·계약
              ▲
              │ (프로토콜 구현)
            Data        Repository 구현·외부 데이터 연결
              │
              ▼
            Core        Networking·Keychain·Logger (의존성 최소 기반 기술)
```

- **단방향 원칙**: 화살표 역방향 import 금지.
- **Domain은 중심이자 무지(無知)** — 구현체(Data)도, 상위 레이어(Feature/App)도 모른다.
  필요한 것은 프로토콜(`Repository`)로만 선언한다.
- **Data는 Domain에 의존** — Domain의 `Repository` 프로토콜을 구현하고, Core(Networking 등)를 사용한다.

## 데이터 흐름 (조회 예시)

```text
Feature  ──(UseCase.execute)──▶  Domain UseCase
                                      │ Repository 프로토콜 호출
                                      ▼
                                 Data Repository 구현체
                                      │ Service 호출 (네트워크)
                                      ▼
                                 Core Networking ──▶ 서버
                                      │ Response(DTO)
                                      ▼
                                 Mapper: DTO → Domain Entity
                                      │
                                 (에러: NetworkingError → RepositoryError)
                                      ▼
                            Domain Entity 반환 ──▶ Feature
```

## 레이어 요약

| 레이어 | 책임 | 비동기 | 주요 구성요소 |
|---|---|---|---|
| App | DI·조립, 진입점 | Combine | App, 전역 흐름 |
| Feature | 화면·기능 (계획) | Combine | View, ViewModel |
| UI | 재사용 컴포넌트·디자인 토큰 | Combine | DesignSystem, WSSComponent |
| Domain | 비즈니스 로직·계약 | async/await | Entity, UseCase, Repository(protocol) |
| Data | 외부 데이터 연결 | async/await | DTO, Service, Mapper, Repository(impl), Factory |
| Core | 기반 기술 | async/await | Networking, Keychain, Logger |

## 모듈 구성 방식 (Tuist)

- 모든 모듈은 `Project.swift`에서 `Project.create{Layer}Module(...)` 템플릿으로 생성된다.
  → [Tuist/ProjectDescriptionHelpers/Project+Templates.swift](../Tuist/ProjectDescriptionHelpers/Project+Templates.swift)
- 모듈 식별자는 `ModuleType` enum이 단일 진실 소스다.
  → [Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift](../Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift)
- 타깃 종류: `sources` / `demo` / `testing` / `tests` (`TargetType`)
- 의존성은 `internalDependencies: [.module(.domain(.base))]` 형태로 선언한다.

## 현재 구현 현황 (참고용 — 정확한 목록은 ModuleType.swift 확인)

- **Core(3)**: Keychain, Networking, Logger
- **Domain(11)**: Base, Auth, Recommendation, Feed, Comment, Novel, NovelReview, Setting, Notification, Profile, Social
- **Data(11)**: Domain과 대응 (Base, Novel, Auth, ... )
- **UI(2)**: DesignSystem, WSSComponent
- **Feature**: `home`, `feed` 가 레지스트리에 선언됨 (디스크 폴더는 아직 없음 = 계획 단계)
- **App**: 진입점 스켈레톤(`WSSIOSV2App`, `ContentView`)만 존재

> ⚠️ `Projects/Domain/` 에 suffix 없는 폴더(`Comment/`, `Feed/`, `Novel/` 등)는
> 레지스트리에 없는 **잔재**일 수 있다. 정식 모듈은 `XxxDomain` 형태만 인정한다.
