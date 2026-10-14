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
├── TEST_SPEC.md       # 자동 생성 테스트 목록(ArchLint --write-test-specs, 손으로 고치지 않음)
├── Testing/           # Mock[Repository].swift — 가짜 객체가 필요한 모듈만
└── Tests/
    ├── Entity/
    └── UseCase/
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
    // 캐시 미스 시 서버 재동기화까지 하는 건 KeywordRepository가 아니라 이 UseCase(BaseDomain)
    // 몫이다 — Repository를 직접 잡지 말고 이걸 통해 캐시를 읽는다(BaseDomain/CLAUDE.md 참고).
    private let loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase
    public init(novelRepository: NovelRepository, loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase) { ... }
    public func execute(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        let cachedKeywords = (try? await loadTotalKeywordsUseCase.execute())?.flatMap(\.keywords) ?? []
        return try await novelRepository.fetchNovel(id: id, cachedKeywords: cachedKeywords)
    }
}
```

## 공통 타입 (BaseDomain)

- `RepositoryError`: `networkUnavailable / authenticationRequired / serverUnavailable / invalidData / notFound / unknown`
- `Paginated<T>`, ID 래퍼(`WSSIdentifiers`), `Keyword`, `Rating`, `NovelGenre` 등
- 공통 UseCase도 일부 존재 (예: `LoadTotalKeywordsUseCase`)

## 테스트 (필수 — 이 레이어 한정)

분기·검증·계산이 있는 Entity·정책·UseCase는 **테스트 없이 머지 금지**. 저장소 호출을 넘기기만 하는 UseCase는 테스트하지 않는다.

> 📖 **테스트를 작성/수정하기 전에 [docs/TESTING.md](../../docs/TESTING.md)를 먼저 읽어라.**
> (5원칙과 그 이유, 작업 순서, 사람이 판단할 곳, Stub/Mock, 예시가 거기 있음. 검사 규칙 목록은 `Tooling/ArchLint/README.md`)

빠른 요약:
- **Swift Testing** (`@Test`/`#expect`/`@Suite`), XCTest·`@testable import` 금지. 가짜 객체는 `Testing/`(`<Module>DomainTesting` 타깃) — 조회는 Stub, 명령은 Mock.
- `@Suite("기능")` 안에 `@Test("~다")` — 이름이 곧 명세. 테스트 목록은 모듈 루트 `TEST_SPEC.md`로 PR에 보인다.
- CI: develop 대상 PR마다 자동 실행(`Project.swift`에 `.tests` 선언한 정식 모듈만 — 유령 폴더는 자동 제외).

## 주의사항 (작업 중 발견 시 누적)

- **유령 폴더**: `Projects/Domain/`의 `XxxDomain` 아닌 폴더(`Comment/`, `Feed/` 등)는 gitignore된 rename 잔재 → root `CLAUDE.md` #3 참조. `ls` 아닌 ModuleType.swift로 모듈 판단, 정식 모듈만 수정.
- **Domain 계약·값 타입은 전부 `Sendable`이다(A4 #219).** 새로 만드는 **UseCase/Repository 프로토콜은
  `: Sendable`**, **Entity/VO/Draft(struct·enum)도 `: Sendable`**을 유지해야 한다 — **Domain은 이제 Swift 6
  language mode(#219 A4 5단계, `SWIFT_VERSION = 6`)라 안 붙이면 Feature/Data가 그 값을 async 경계로 넘길 때
  "sending … risks data races"가 경고가 아니라 컴파일 error다**(빌드가 깨진다). ⚠️ **`Default*UseCase`는
  `final class`여야 한다** — 프로토콜이 Sendable이면 non-final class는 Sendable 준수가 불가해 error가 뜬다
  (ProfileDomain에서 실제로 6개가 걸렸다). 검사: **`XxxDomain` 스킴을 빌드하면 컴파일러가 잡는다**(mode 6이라
  회귀가 즉시 error — 별도 스캐너 불필요).
