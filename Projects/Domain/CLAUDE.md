# Domain 레이어

비즈니스 로직과 **계약(Repository 프로토콜)** 을 담는 레이어. 앱의 중심.

- 모듈 식별자: `ModuleType.domain(.xxx)` → 모듈명 `XxxDomain`
- 디렉토리: `Projects/Domain/<Module>Domain/`
- 비동기: **Swift Concurrency** (`async/await`)

## 의존 규칙

- ✅ `BaseDomain` (공통 타입) 만 internal 의존으로 둔다. 보통 `internalDependencies: [.module(.domain(.base))]`.
- ❌ Data / Feature / App / Core(Networking·Keychain 등) **import 금지**.
  Domain은 구현체와 외부 기술을 모른다.
- ❌ 서드파티 라이브러리 의존 금지 (순수 Swift).

## 디렉토리 구조

```text
Projects/Domain/<Module>Domain/
├── Project.swift
├── Sources/
│   ├── Entity/        # 도메인 모델 (struct, 정책 메서드 포함)
│   ├── UseCase/       # 비즈니스 흐름 (프로토콜 + Default 구현)
│   └── Repository/    # 데이터 접근 계약 (프로토콜만)
├── Testing/           # Mock[Repository].swift
└── Tests/
    ├── Entity/
    └── Usecase/
```

## 코드 규칙

### Entity
- `public struct`. 식별자는 `BaseDomain`의 ID 래퍼 사용 (`NovelID`, `UserID` 등).
- 상태를 바꾸는 정책은 **Entity 안의 `mutating` 메서드**로 표현한다 (예: 관심 토글).

```swift
public struct Novel {
    public let id: NovelID
    public private(set) var interestCount: Int
    public private(set) var isInterested: Bool?

    // MARK: - Policy
    public mutating func markAsInterested() {
        guard isInterested == false else { return }
        isInterested = true
        interestCount += 1
    }
}
```

### Repository (프로토콜)
- 계약만 정의. 구현은 Data 레이어.
- 모든 throwing 함수는 **`throws(RepositoryError)`** (typed throws) 사용.
- 페이지네이션은 `BaseDomain`의 `Paginated<T>` 사용.

```swift
public protocol NovelRepository {
    func fetchNovel(id: NovelID, cachedKeywords: [Keyword]) async throws(RepositoryError) -> NovelInformation
    func searchNovelByText(_ text: String) async throws(RepositoryError) -> (Paginated<Novel>, Int)
}
```

### UseCase
- `protocol XxxUseCase` + `final class DefaultXxxUseCase` 쌍.
- 단일 진입점 `func execute(...)`.
- 의존성은 **Repository 프로토콜**을 생성자 주입. 구현체를 알지 못한다.
- 여러 Repository를 조합하는 로직을 여기 둔다.

```swift
public protocol LoadNovelUseCase {
    func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation
}

public final class DefaultLoadNovelUseCase: LoadNovelUseCase {
    private let novelRepository: NovelRepository
    private let keywordRepository: KeywordRepository
    public init(novelRepository: NovelRepository, keywordRepository: KeywordRepository) { ... }
    public func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        let cachedKeywords = (try? await keywordRepository.fetchKeywords())?.flatMap(\.keywords) ?? []
        return try await novelRepository.fetchNovel(id: id, cachedKeywords: cachedKeywords)
    }
}
```

## 공통 타입 (BaseDomain)

- `RepositoryError`: `networkUnavailable / authenticationRequired / serverUnavailable / invalidData / notFound / unknown`
- `Paginated<T>`, ID 래퍼(`WSSIdentifiers`), `Keyword`, `Rating`, `NovelGenre` 등
- 공통 UseCase도 일부 존재 (예: `LoadTotalKeywordsUseCase`)

## 테스트 (이 레이어에만 작성)

- **Swift Testing** (`@Test`, `#expect`, `@Suite`). XCTest 금지.
- 함수명: `@Test("한글 이름") func englishName()` (CI 호환, backtick 한글 금지).
- Given-When-Then. Mock은 `Mock[Protocol]`, helper는 `make~` prefix.
- Mock 위치: `Testing/`, 테스트 구현: `Tests/Entity/`, `Tests/Usecase/`.
- 커버리지: 정상 / 경계값 / 정책 위반 / 상태 변화.
- 새 Domain 모듈 추가 시 `.github/workflows/test.yml`에 테스트 step 추가.

## 주의사항 (작업 중 발견 시 누적)

- `Projects/Domain/` 에 `XxxDomain` 외 폴더(`Comment/`, `Feed/` 등)는 잔재일 수 있음. 정식 모듈만 수정.
