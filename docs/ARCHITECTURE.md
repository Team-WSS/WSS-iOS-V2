# 아키텍처 개요

웹소소 V2는 V1(단일 Xcode 프로젝트, 양방향 의존성, RxSwift 중심)의 구조적 한계를 풀기 위한
리빌드 프로젝트다. **기능을 한 번에 옮기지 않고**, 기반 레이어(Core/Domain/Data)를 먼저
안정화한 뒤 Feature/App을 점진적으로 연결한다.

## 레이어와 의존성 방향

```text
        App            DI·전역 흐름 조립 (앱 진입점)
         │
         ▼
      Feature          실제 기능·화면 구현 (UI 포함) — 점진 연결 중(NovelReviewFeature 구현됨)
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
| App | DI·조립, 진입점 | SwiftUI | App, 전역 흐름 |
| Feature | 화면·기능 | SwiftUI Observation | View, ViewModel |
| UI | 재사용 컴포넌트·디자인 토큰 | SwiftUI | DesignSystem, WSSComponent |
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

## 현재 구현 현황 (비자명한 것만 — 모듈 목록의 진실은 ModuleType.swift)

모듈 개수·이름은 [`ModuleType.swift`](../Plugins/DependencyPlugin/ProjectDescriptionHelpers/ModuleType.swift)가
단일 진실 소스다. 여기엔 **코드만 봐선 모르는 구현 단계**만 남긴다:

- **Feature**: 레지스트리엔 `home`/`feed`/`novelReview`가 있으나 **디스크 구현은 `NovelReviewFeature`뿐**.
  `home`/`feed`는 **계획 단계**(레지스트리에만 존재).
- **App**: 진입점 스켈레톤(`WSSIOSV2App`, `ContentView`)만 존재.

> ⚠️ **유령 폴더 주의**: `Projects/Domain|Data/`에 suffix 없는 폴더(`Comment/`, `Feed/`, `KeywordData/` 등)나
> 미등록 폴더가 디스크에 보일 수 있다. 모듈 rename·브랜치 전환이 남긴 **gitignore된 잔재**(`.xcodeproj`/`Derived`)로
> **레포에 없고 삭제해도 재발**한다. 모듈 목록은 `ls`가 아니라 **ModuleType.swift로만 판단**(정식은 `XxxDomain`/`XxxData` 형태만).
