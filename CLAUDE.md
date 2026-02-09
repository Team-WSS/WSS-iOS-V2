# Claude Code - WSS-iOS-V2

## Quick Commands

- `도메인 테스트` — 변경된 소스 파일을 감지하고, 아래 컨벤션에 맞춰 테스트 코드를 자동 생성합니다.

## Test Code Convention

### Framework
- Swift Testing (`@Test`, `#expect`, `@Suite`)
- XCTest 사용 금지

### Naming
- 테스트 함수명은 **한국어**로 작성 (backtick 사용)
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
Projects/Domain/[Module]/Tests/
├── Entity/
│   └── [Entity]Tests.swift
├── Mock/
│   └── Mock[Repository].swift
└── Usecase/
    └── [Usecase]Tests.swift
```

## Project Structure
- Tuist 기반 모듈화
- Clean Architecture (Domain / Data / Feature)
- Domain 모듈: BaseDomain, Comment, Feed, Keyword, Community
