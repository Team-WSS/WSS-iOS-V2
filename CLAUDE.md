# Claude Code - WSS-iOS-V2

## Quick Commands

- `도메인 테스트` — 변경된 소스 파일을 감지하고, 아래 컨벤션에 맞춰 테스트 코드를 자동 생성합니다.

## Test Code Convention

### Framework
- Swift Testing (`@Test`, `#expect`, `@Suite`)
- XCTest 사용 금지

### Naming
- 테스트 함수명은 `@Test("한글 이름") func englishName()` 패턴으로 작성 (GitHub Actions CI 호환)
- backtick 한글 함수명 사용 금지 (`@Test func \`한글\`()` ← 사용하지 않음)
- Helper 함수는 `make~` prefix (e.g., `makeDraft()`, `makeComment()`)
- Mock 클래스는 `Mock[ProtocolName]` (e.g., `MockCommentRepository`)

### Structure
- Given-When-Then 패턴
- Entity 테스트: helper를 struct 내부에 정의
- Usecase 테스트: helper를 extension으로 분리

### Suite
- `@Suite` 사용 (Tag 기능 사용하지 않음)

### Import
```swift
@testable import [Module]Domain
@testable import BaseDomain
```

### Coverage
1. 정상 케이스
2. 경계값
3. 정책 위반 케이스
4. 상태 변화 검증

### Mock 패턴
- tracking arrays + Result 프로퍼티 패턴
- 도메인별 `MockError` 또는 `RepositoryError` 사용

### Test 디렉토리 구조
```
Projects/Domain/[Module]/
├── Testing/
│   └── Mock[Repository].swift
└── Tests/
    ├── Entity/
    │   └── [Entity]Tests.swift
    └── Usecase/
        └── [Usecase]Tests.swift
```

- **Testing 폴더**: Mock 파일 위치 (e.g., `MockCommentRepository.swift`)
- **Tests 폴더**: 테스트 함수 구현 파일 위치 (Entity, Usecase 하위 분류)

## Test Scope
- **Domain 모듈에만 테스트 코드를 작성한다** (Data, Feature, Core 등 다른 레이어는 아직 적용하지 않음)
- 새로운 Domain 모듈 추가 시 `.github/workflows/test.yml`에 해당 도메인 테스트 step을 함께 추가한다

## Project Structure
- Tuist 기반 모듈화
- Clean Architecture (Domain / Data / Feature)
- Domain 모듈: BaseDomain, Comment, Feed, Keyword, Community
