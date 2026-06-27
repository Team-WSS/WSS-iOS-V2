# 네이밍 · 코드 스타일 · 에러 규약

레이어 공통 규약. 레이어별 세부는 각 `Projects/<Layer>/CLAUDE.md` 참고.

## 네이밍

### 타입 접두/접미
| 패턴 | 의미 | 예 |
|---|---|---|
| `Xxx` (protocol) | 계약 | `NovelRepository`, `NovelService`, `LoadNovelUseCase` |
| `DefaultXxx` | 기본 구현체 | `DefaultNovelRepository`, `DefaultLoadNovelUseCase` |
| `MockXxx` | 테스트용 Mock | `MockNovelRepository` |
| `XxxRepository` | 데이터 접근 계약(Domain)/구현(Data) | |
| `XxxService` | 네트워크 호출 (Data) | `DefaultNovelService` |
| `XxxMapper` | DTO ↔ Entity 변환 (Data, `enum` + static) | `NovelMapper` |
| `XxxFactory` | 조립 진입점 (Data, `enum` + static) | `NovelDataFactory` |
| `XxxEndPoint`/`XxxEndpoint` | API 경로 정의 (Data) | `NovelEndPoint` |
| `XxxAction` | 로깅 액션 식별자 (Data) | `NovelAction` |
| `XxxResponse`/`XxxRequest`/`XxxQuery` | DTO (Data) | `SearchNovelsResponse` |
| `XxxDraft` | 작성/수정 입력 모델 (Domain) | `FeedDraft`, `CommentDraft` |

### 함수·기타
- UseCase 진입점은 `execute(...)`.
- 테스트 helper는 `make~` (`makeNovel`, `makeNovelInformation`).
- 식별자는 raw 타입 금지 → `BaseDomain`의 ID 래퍼 (`NovelID`, `UserID`, `FeedID`, `CommentID`...).
- 모듈명은 `ModuleType.swift`가 단일 진실 소스 (`XxxDomain`/`XxxData`, Core/UI는 suffix 없음).

## Import 순서

세 그룹, 그룹 사이 **빈 줄 1개**. 각 그룹 내부 규칙:

1. **Apple 프레임워크** — 알파벳순 (`Foundation`, `Observation`, `SwiftUI`…).
2. **외부 라이브러리** — 알파벳순. (현재 "외부 의존성 없음 원칙"이라 보통 비어 있음.)
3. **자체 모듈** — 레이어 순서 **Feature → Domain → Data → Core → UI**.
   각 레이어 안에서는 **Base 모듈 우선**(`BaseDomain`, `BaseData`), 그 뒤 알파벳순.

```swift
// Data Repository
import Foundation

import BaseDomain         // Domain (Base 우선)
import NovelDomain        // Domain
import BaseData           // Data (Base 우선)
import Networking         // Core
```
```swift
// Feature Factory/View
import SwiftUI

import BaseDomain         // Domain (Base 우선)
import NovelReviewDomain  // Domain
import Logger             // Core
import DesignSystem       // UI
import WSSComponent       // UI
```

## 접근제어

- 모듈의 **공개 표면은 최소화**한다. 조립 진입점 **Factory**(`enum` + static)와 그것이 노출하는 **계약(Protocol)·Entity·입력 모델(Draft)**만 `public`.
- **구현체는 internal**: `DefaultXxxRepository`·`DefaultXxxService`·`XxxView`/`XxxViewModel`·Mapper 등은 public일 필요 없다 — Factory가 프로토콜/`some View`로 감싸 반환한다.
  모범: `NovelReviewFactory`("모듈의 유일한 public 진입점", View/VM internal + opaque 반환).
- **예외(현실)**: App(DI)이 **직접 생성·주입**하는 타입은 public이 필요하다. 현재 UseCase 구현체(`DefaultLoadNovelUseCase` 등)는 App이 조립하므로 public 유지 — Domain에 조립 Factory가 생기기 전까지의 한시적 예외.

## 주석

- **코드를 읽어 알 수 있는 것(what)은 적지 않는다.** 코드만 봐선 모르는 **"왜"·정책·불변식·함정**만 남긴다. (root CLAUDE.md 문서 철학의 코드판.)
- 공개 API·계약·정책은 `///` doc comment, **한글**. 예: `ReadingPeriod` 불변식, `NovelReviewFactory` 진입점/주입 설명.
- 함정·주의는 인라인 `//`. 함정 없으면 주석이 없어도 된다.

## 비동기

- Domain / Data / Core: **Swift Concurrency** (`async/await`).
- Feature: **SwiftUI Observation** (`@Observable` VM · `@State` View).
- UI / App: 순수 SwiftUI.
- Domain/Data의 throwing은 **typed throws** (`throws(RepositoryError)`, 로그인만 `throws(AuthError)`).

## 에러 처리 계약

### 타입과 책임
| 레이어 | 에러 타입 | 책임 |
|---|---|---|
| Core(Networking) | `NetworkingError` | 통신 실패 표현 (도메인 모름) |
| Data | (변환) | `NetworkingError`/`MappingError` → 도메인 에러로 **변환** |
| Domain | `RepositoryError` (로그인 `AuthError`) | 비즈니스 에러 계약 |

### 변환표 (Data 레이어가 수행)
**일반** — `NetworkingError.toRepositoryError()` (BaseData):
| 원인 | 결과 |
|---|---|
| 401 | `.authenticationRequired` |
| 404 | `.notFound` |
| 5xx | `.serverUnavailable` |
| decoding | `.invalidData` |
| requiresReauthentication | `.authenticationRequired` |
| unknown | `.networkUnavailable` |
| `MappingError` | `.invalidData` |
| 그 외 | `.unknown` |

**로그인 전용** — `NetworkingError.toAuthError()` (AuthData):
| 원인 | 결과 |
|---|---|
| 4xx | `.invalidCredential` |
| 5xx | `.providerUnavailable` |
| decoding | `.invalidData` |
| invalidURL/requiresReauthentication | `.unknown` |
| unknown | `.networkUnavailable` |

### Repository 구현 규칙
- 모든 `catch` 분기에서 `logger`로 기록 후 변환된 에러를 throw.
- 패턴: `catch NetworkingError → toRepositoryError()`, `catch MappingError → .invalidData`, `catch → .unknown`.

## 주의사항 (작업 중 발견 시 누적)

- `EndPoint`/`Endpoint` 표기가 모듈마다 섞여 있음 (`NovelEndPoint` vs `AuthEndpoint`). 새 코드는 기존 모듈 표기를 따르되 신규는 `Endpoint` 권장.
