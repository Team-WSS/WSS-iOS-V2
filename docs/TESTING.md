# 테스트 가이드

> **테스트는 필수다.** 새 UseCase·Entity·정책 메서드는 테스트 없이 머지하지 않는다. (현재 Domain 레이어 한정)

## 철학 — 테스트는 "읽히는 기능 명세"다

이 프로젝트의 테스트는 통과/실패를 넘어, **그 도메인이 무엇을 보장하는지** 코드를 안 봐도 읽어낼 수 있어야 한다.
`@Test("한글 문장")`의 설명이 곧 **명세 한 줄**이다.

좋은 예 — 테스트 이름만 읽어도 정책이 보인다:
```swift
@Suite("작품 관심")
struct NovelTests {
    // MARK: - markAsInterested
    @Test("관심 없는 작품을 관심 등록하면 관심 상태가 켜지고 관심 수가 늘어난다") ...
    @Test("이미 관심 등록된 작품을 다시 관심 등록해도 상태가 변하지 않는다") ...
    @Test("관심 여부를 모르는 작품은 관심 등록해도 상태가 변하지 않는다") ...
    // MARK: - unmarkAsInterested
    @Test("관심 수가 0일 때 관심을 해제해도 관심 수가 0 아래로 내려가지 않는다") ...
}
```
원칙:
1. **이름 = 명세 문장**: "〜하면 〜가 된다 / 〜하지 않는다" 형태. 동작과 기대 결과를 한 문장에 담는다. ("test1", "성공 케이스" 같은 이름 금지)
   - **무엇이 어떻게 되는지**를 쓴다. "성공적으로 불러온다"는 무엇을 확인하는지 감춘다 → "작품 id로 저장소를 한 번 조회해 받은 작품을 돌려준다".
   - **구현 이름 대신 동작**을 쓴다. 메서드·프로퍼티 이름(`markAsInterested`·`isInterested`)은 이름에서 빼고 `// MARK:`로 둔다. 타입 이름(`RepositoryError`)은 도메인 용어라 괜찮다.
2. **`@Suite("한국어 기능 단위 명사구")`**(`작품 관심` · `컬렉션 생성`)가 명세 대상, `// MARK: - 메서드명`으로 시나리오를 그룹핑.
3. **한 테스트 = 하나의 규칙**. 한 테스트에서 여러 행동을 검증하지 않는다.
4. **Given-When-Then**으로 본문도 읽히게. 준비 → 실행 → 단언이 시각적으로 구분되도록 빈 줄 사용.
5. 테스트 묶음을 위에서 아래로 읽으면 **그 도메인의 행동 사양서**가 되도록 배열한다.

## 기계 검사 — ArchLint `test-spec`

위 원칙 중 문법으로 판정되는 것은 ArchLint 규칙⑮ `test-spec`이 검사한다(→ `Tooling/ArchLint/README.md`). **적용 모듈**(`Tooling/ArchLint/Sources/ArchLintCore/Linter.swift`의 `TestSpecRule(enforcedModules:)`)에서만 돌고, error가 있으면 `All Tests Passed`가 실패해 머지가 막힌다.

| 심각도 | 규칙 |
|---|---|
| error | `@Test`는 `@Suite` 타입 안 · `@Suite("한국어")` + 타입 이름 `…Tests` · `@Test("…다")` 보간 없는 한국어 문장(끝 괄호 보충·마침표 허용) · 표시 이름 `/` 금지 · 같은 파일의 같은 Suite 안 표시 이름 중복 금지 |
| warning | 본문에 `#expect`/`#require` · 함수 이름 3인칭 동사 시작 · 모호어(성공적으로·정상적으로·올바르게·제대로) · Domain·Feature 표시 이름의 메서드·프로퍼티 이름 |

- 적용 모듈은 warning도 0으로 유지한다. 새 모듈을 적용하려면 목록에 넣고 `swift run --package-path Tooling/ArchLint ArchLint .`로 드러난 위반을 모두 청소한 뒤 머지한다.
- 표시 이름을 바꾸는 건 명세 문장을 바꾸는 일이라 사람이 확인한다. 함수 이름은 표시 이름을 옮긴 것이라 그대로 따라 바꾼다.
- 검사는 형식만 본다 — 이름과 본문이 일치하는지, 입력이 헐거워 무조건 통과하지 않는지는 사람(리뷰)이 본다.

## 프레임워크·위치·임포트

- **Swift Testing** (`@Test` / `#expect` / `@Suite`). **XCTest 금지.**
```
Projects/Domain/<Module>Domain/
├── Testing/Mock/Mock[Protocol].swift   # Mock — 별도 타깃 <Module>DomainTesting
└── Tests/{Entity,UseCase}/[X]Tests.swift
```
```swift
import Testing
@testable import [Module]Domain
import [Module]DomainTesting   // Mock이 든 Testing 타깃
import BaseDomain
```
- **타 모듈의 Testing 타깃(Mock) 재사용**은 그 모듈 `Project.swift`에 `testDependencies: [.module(.domain(.base), type: .testing)]` 선언이 있어야 import 된다 — 없으면 "No such module"(템플릿 기본값은 빈 배열). 예: NovelDomain 테스트가 BaseDomain의 `MockKeywordRepository`를 재사용.

## 작성 규칙

- 함수명: **`@Test("…하면 …한다") func returns…()`** — 한글은 설명에, 함수명은 표시 이름을 옮긴 영어 lowerCamelCase로 **3인칭 동사로 시작**한다(`rejects…` · `returns…` · `propagates…` · `doesNot…`). (CI 호환, backtick 한글 함수명 금지)
- helper는 `make~` prefix, 보통 `extension XxxTests`에 `private func`로 분리. 파라미터 기본값으로 변형 케이스를 만든다.
- 에러 검증: `await #expect(throws: RepositoryError.unknown) { try await sut.execute(...) }`.
- **커버리지 4종 필수 고려**: 정상 / 경계값 / 정책 위반 / 상태 변화.

### Entity 테스트 (정책 검증)
순수 함수/`mutating` 정책을 직접 호출해 상태 전이를 단언. (위 `NovelTests` 예시)

### UseCase 테스트 (협력 검증)
Mock Repository를 주입해 결과 + **호출 사실**을 함께 검증.
```swift
@Suite("작품 정보 조회")
struct LoadNovelUseCaseTests {
    @Test("작품 id로 저장소를 한 번 조회해 받은 작품을 돌려준다")
    func returnsNovelFetchedOnceByID() async throws {
        let mock = MockNovelRepository()              // Given
        let expected = makeNovelInformation()
        mock.fetchNovelResult = .success(expected)
        let usecase = DefaultLoadNovelUseCase(novelRepository: mock)

        let result = try await usecase.execute(id: NovelID(1))   // When

        #expect(result.novel.id == expected.novel.id)            // Then
        #expect(mock.fetchedNovelIDs.last == NovelID(1))         // 협력(호출) 검증
        #expect(mock.fetchedNovelIDs.count == 1)
    }
}
```

## Mock 패턴 (tracking array + Result)

```swift
public final class MockNovelRepository: NovelRepository {
    public var fetchNovelResult: Result<NovelInformation, RepositoryError>!    // 반환 있는 메서드
    public var addInterestResult: Result<Void, RepositoryError> = .success(()) // void는 기본 성공
    public private(set) var fetchedNovelIDs: [NovelID] = []                    // 호출 추적
    public init() {}

    public func fetchNovel(id: NovelID) async throws(RepositoryError) -> NovelInformation {
        fetchedNovelIDs.append(id)        // 입력 기록
        return try fetchNovelResult.get() // 주입된 결과 반환/throw
    }
}
```
- 결과는 `Result` 프로퍼티로 주입, 입력은 배열/`last`/`callCount`로 기록 → `#expect`로 협력 검증.
- Mock은 `Testing/` 타깃(`<Module>DomainTesting`)에 둔다 (테스트와 분리, 다른 모듈도 재사용 가능).

## CI

- 트리거: **develop 대상 PR을 올리면 자동 실행**. `/domain-test` 댓글·수동 `workflow_dispatch`는 재실행용. `.github/workflows/test.yml`.
- `Project.swift`가 `.tests` 타깃을 선언한 **정식 모듈(Domain·Data·Feature)** 을 자동 스캔 → 선언만 하면 자동 포함.
- 유령 폴더는 `Project.swift`가 없어 자동 제외된다(폴더 잔재가 매트릭스를 깨지 않는다).
- `All Tests Passed` job이 모듈 테스트 + `Architecture Rules`(ArchLint) + `Swift Format` 결과를 함께 판정한다 → develop·main 보호의 **유일한 필수 체크**다.

## 주의사항 (작업 중 발견 시 누적)

- Mock·테스트가 프로토콜/UseCase 시그니처 변경을 못 따라가 컴파일이 깨지는 drift가 있을 수 있다. 시그니처를 바꾸면 **같은 PR에서 Mock·테스트도 갱신**.
- ⚠️ **`tuist test`의 `Executed 0 tests, with 0 failures`는 테스트가 안 돌았다는 뜻이 아니다.** 그 줄은 XCTest 카운터라
  Swift Testing(`@Test`)을 세지 않는다. 실제 실패는 `Failing tests:` + `** TEST FAILED **`로, 성공은 `Test Succeeded`로 나온다.
  의심되면 일부러 실패하는 테스트를 하나 넣어 러너가 잡는지 확인하면 된다(카나리) — `0 tests`만 보고 러너가 죽었다고 판단하지 말 것.
- ⚠️ **`@Test("…")` 설명에 `/`를 넣지 말 것** — XcodeBuildMCP `test_sim` 리포터가 `/`를 스위트 구분자로 읽어 이름을 쪼갠다
  (`"websoso://collections/{id}를 파싱하면…"` → 스위트 `websoso:/collections` + 테스트 `{id}를 파싱하면…`으로 보고됨, #228 실측).
  URL·경로가 들어가는 명세는 "websoso 스킴에 collections host와 id가 붙은 URL"처럼 말로 풀어 쓴다.
- ⚠️ **XcodeBuildMCP `test_sim` 리포터는 표시 이름 중간의 `.`에서도 이름을 쪼갠다**(#290 실측) —
  `"평점은 0.5부터 5.0까지 0.5 단위로만 허용된다"` → 스위트 `평점은 0.5부터 5.0까지 0` + 테스트 `5 단위로만 허용된다`.
  문장 끝 마침표는 멀쩡하다. 리포트 표시만 어긋나고 결과는 맞으며, 소수는 명세에 필요한 값이라 `/`와 달리 검사로 막지 않는다.
