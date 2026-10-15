import Testing
@testable import ArchLintCore

// #293 테스트 명세 규칙의 자체 테스트. 규칙마다 "잡아야 할 것"과 "잡으면 안 되는 것"을 함께 둔다.
// 레포가 이미 초록이라 위반 경로는 여기서만 검증된다.

private let specTestPath = "/Projects/Domain/AuthDomain/Tests/Entity/SampleTests.swift"
private let specTestingPath = "/Projects/Domain/AuthDomain/Testing/Mock/MockSampleRepository.swift"
private let specSourcePath = "/Projects/Domain/AuthDomain/Sources/Entity/Sample.swift"
private let outOfScopeTestPath = "/Projects/Domain/NovelDomain/Tests/Entity/SampleTests.swift"

/// 규칙에 걸리지 않는 기준 테스트. 각 테스트는 여기서 한 군데만 망가뜨려 본다.
private let cleanSpec = """
import Testing

import AuthDomain

@Suite("샘플 작성")
struct SampleTests {

    @Test("내용은 80자까지 저장된다")
    func keepsUpTo80() {
        var draft = Draft()
        let text = String(repeating: "가", count: 80)

        draft.setText(text)

        #expect(draft.text == text)
    }
}
"""

private func ids(_ violations: [Violation]) -> [String] {
    violations.map(\.ruleID)
}

@Suite("ArchLint 테스트 명세 규칙 자체 검증")
struct TestSpecRuleTests {

    // MARK: - 기준·범위

    @Test("규칙에 맞는 테스트는 어떤 명세 규칙에도 걸리지 않는다")
    func cleanSpecPassesEveryRule() {
        #expect(lint(source: cleanSpec, path: specTestPath).isEmpty)
    }

    @Test("명세 모듈이 아닌 곳의 테스트는 검사하지 않는다")
    func outOfScopeModuleIsSkipped() {
        let source = "@testable import NovelDomain\n@Test func a() { for _ in 0..<1 {} }"
        #expect(lint(source: source, path: outOfScopeTestPath).isEmpty)
    }

    // MARK: - test-name

    @Test(
        "이름이 명세 문장이 아니면 잡는다",
        arguments: [
            ("WithdrawalReasonDraft를 만든다", "코드 식별자"), // 타입 이름
            ("setText(_:)를 부르면 저장된다", "코드 식별자"),  // 함수 호출
            ("draft.text가 바뀐다", "코드 식별자"),          // 멤버 접근
            ("isSubmittable이 참이 된다", "코드 식별자"),     // camelCase
            ("저장한다/불러온다", "'/'"),                   // 리포터가 스위트로 쪼갠다
            ("성공적으로 저장된다", "모호한 말"),             // 무엇이 되는지 말하지 않는다
            ("저장됨", "'~다'"),                          // 문장이 아니다
            ("saves text", "한국어")                      // 영어
        ]
    )
    func namingCatchesNonSpecNames(name: String, expectedProblem: String) {
        let problems = TestNamingRule.problems(in: name)

        #expect(problems.contains { $0.contains(expectedProblem) })
    }

    @Test("@Suite 밖 테스트·한국어 이름 없는 스위트·이름 없는 테스트·같은 이름을 잡는다")
    func namingCatchesStructureProblems() {
        let source = """
        @Test("밖에 있다") func loose() {}
        @Suite struct Unnamed {}
        @Suite("샘플") struct Named {
            @Test func unnamed() {}
            @Test("같은 이름이다") func a() {}
            @Test("같은 이름이다") func b() {}
        }
        """

        let violations = lint(source: source, path: specTestPath, rules: [TestNamingRule()])

        #expect(violations.count == 4)
    }

    // MARK: - test-assert

    @Test("#expect 없이 #require만 있으면 잡는다")
    func assertionCatchesRequireOnly() {
        let source = cleanSpec.replacingOccurrences(of: "#expect(draft.text == text)", with: "try #require(draft.text == text)")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestAssertionRule()])) == ["test-assert"])
    }

    @Test("!= nil 확인을 잡는다")
    func assertionCatchesNotNil() {
        let source = cleanSpec.replacingOccurrences(of: "draft.text == text", with: "draft.text != nil")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestAssertionRule()])) == ["test-assert"])
    }

    // MARK: - test-name-number

    @Test("이름의 숫자가 본문에 없으면 잡는다")
    func assertionCatchesMissingNumber() {
        let source = cleanSpec.replacingOccurrences(of: "count: 80", with: "count: 81")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestNameNumberRule()])) == ["test-name-number"])
    }

    @Test("이름의 숫자가 arguments 안에만 있어도 본문에 있는 것으로 본다")
    func assertionFindsNumberInArguments() {
        let source = """
        @Suite("샘플") struct S {
            @Test("0.5 단위만 허용한다", arguments: [
                0.5  // 가장 작은 단위
            ])
            func a(value: Double) {
                let rating = Rating(value)

                #expect(rating.value == value)
            }
        }
        """

        #expect(lint(source: source, path: specTestPath, rules: [TestNameNumberRule()]).isEmpty)
    }

    @Test("숫자가 단위를 말할 뿐이면 이유를 단 allow 주석으로 뺀다")
    func nameNumberAllowsUnitWithReason() {
        let source = """
        @Suite("샘플") struct S {
            // archlint:allow test-name-number — 0.5는 단위를 말한다(넣는 값이 아니다)
            @Test("0.5점 단위가 아니면 평점이 아니다", arguments: [
                4.7  // 단위에서 벗어났다
            ])
            func a(value: Double) {
                #expect(throws: Rating.ValidationError.invalidStep) {
                    try Rating(value)
                }
            }
        }
        """

        let violations = lint(source: source, path: specTestPath, rules: [TestNameNumberRule()])

        #expect(violations.isEmpty)
    }

    // MARK: - test-aaa

    @Test("확인 구역에 실행이 섞이면 잡는다")
    func structureCatchesActInAssertSection() {
        let source = cleanSpec.replacingOccurrences(of: "draft.setText(text)\n\n", with: "draft.setText(text)\n")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestStructureRule()])) == ["test-aaa"])
    }

    @Test("확인이 중간 구역에 있으면 잡는다")
    func structureCatchesEarlyAssertion() {
        let source = cleanSpec.replacingOccurrences(of: "draft.setText(text)\n", with: "#expect(draft.text == \"\")\n        draft.setText(text)\n")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestStructureRule()])).contains("test-aaa"))
    }

    @Test("구역이 4개 이상이면 잡는다")
    func structureCatchesTooManySections() {
        let source = cleanSpec.replacingOccurrences(of: "var draft = Draft()\n", with: "var draft = Draft()\n\n")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestStructureRule()])) == ["test-aaa"])
    }

    @Test(
        "본문의 분기·반복을 잡는다",
        arguments: [
            "for _ in 0..<1 {}",           // for
            "if draft.text.isEmpty {}",    // if
            "_ = draft.text.isEmpty ? 1 : 2"  // 삼항
        ]
    )
    func structureCatchesBranches(statement: String) {
        let source = cleanSpec.replacingOccurrences(of: "var draft = Draft()\n", with: "var draft = Draft()\n        \(statement)\n")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestStructureRule()])) == ["test-aaa"])
    }

    @Test("// Given 같은 구역 라벨을 잡는다")
    func structureCatchesSectionLabels() {
        let source = cleanSpec.replacingOccurrences(of: "        var draft = Draft()", with: "        // Given\n        var draft = Draft()")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestStructureRule()])) == ["test-aaa"])
    }

    @Test("설명 주석은 구역 라벨로 보지 않는다")
    func structureAllowsExplanationComments() {
        let source = cleanSpec.replacingOccurrences(of: "        var draft = Draft()", with: "        // 확인하려는 값보다 하나 길게 둔다\n        var draft = Draft()")

        #expect(lint(source: source, path: specTestPath, rules: [TestStructureRule()]).isEmpty)
    }

    @Test("#expect(throws:) 한 줄짜리 테스트는 구역이 하나여도 통과한다")
    func structureAllowsSingleThrowsExpectation() {
        let source = """
        @Suite("샘플") struct S {
            @Test("음수는 만들 수 없다")
            func a() {
                #expect(throws: SampleError.negative) { try Sample(-1) }
            }
        }
        """

        #expect(lint(source: source, path: specTestPath, rules: [TestStructureRule()]).isEmpty)
    }

    // MARK: - test-aaa-act · test-body-length (warning)

    @Test("실행 구역이 여러 문장이면 warning으로 묻는다")
    func actSizeWarnsOnMultipleStatements() {
        let source = cleanSpec.replacingOccurrences(of: "draft.setText(text)\n", with: "draft.setText(text)\n        draft.setText(text)\n")

        let violations = lint(source: source, path: specTestPath, rules: [TestActSizeRule()])

        #expect(violations.map(\.severity) == [.warning])
    }

    @Test("이유를 단 allow 주석이 있으면 그 위반을 뺀다")
    func allowCommentSuppressesWithReason() {
        let source = cleanSpec.replacingOccurrences(of: "        draft.setText(text)\n", with: "        // archlint:allow test-aaa-act — 두 번 저장해도 마지막 값만 남는지 보는 테스트\n        draft.setText(text)\n        draft.setText(text)\n")

        #expect(lint(source: source, path: specTestPath, rules: [TestActSizeRule()]).isEmpty)
    }

    @Test(
        "이유가 없거나 다른 규칙을 가리키는 allow 주석은 무시한다",
        arguments: [
            "// archlint:allow test-aaa-act",       // 이유 없음
            "// archlint:allow test-aaa — 이유가 있다"  // 다른 규칙(접두만 같음)
        ]
    )
    func allowCommentNeedsReasonAndExactRule(comment: String) {
        let source = cleanSpec.replacingOccurrences(of: "        draft.setText(text)\n", with: "        \(comment)\n        draft.setText(text)\n        draft.setText(text)\n")

        #expect(lint(source: source, path: specTestPath, rules: [TestActSizeRule()]).count == 1)
    }

    @Test("allow 주석은 아키텍처 규칙을 끄지 못한다")
    func allowCommentCannotSilenceArchitectureRules() {
        let line = "// archlint:allow dependency-direction — 이유가 있다"

        let allowed = AllowComment.allows(line, ruleID: "dependency-direction")

        #expect(allowed == false)
    }

    @Test("본문이 15줄을 넘으면 warning이다")
    func bodyLengthWarnsOver15Lines() {
        let padding = String(repeating: "        draft.setText(text)\n", count: 15)
        let source = cleanSpec.replacingOccurrences(of: "        var draft = Draft()\n", with: "        var draft = Draft()\n\(padding)")

        let violations = lint(source: source, path: specTestPath, rules: [TestBodyLengthRule()])

        #expect(violations.map(\.severity) == [.warning])
    }

    // MARK: - test-arguments

    @Test("arguments 항목이 한 줄에 여럿이면 잡는다")
    func argumentsCatchesSameLine() {
        let source = """
        @Suite("샘플") struct S {
            @Test("둘 다 거절한다", arguments: [Option.a, .b])
            func a(option: Option) {
                let result = check(option)

                #expect(result == false)
            }
        }
        """

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestArgumentsRule()])) == ["test-arguments"])
    }

    @Test("리터럴 항목에 이유 주석이 없으면 잡고, enum case는 주석 없이 통과한다")
    func argumentsRequiresCommentOnLiteralsOnly() {
        let source = """
        @Suite("샘플") struct S {
            @Test("빈 값은 거절한다", arguments: [
                "",
                "   "  // 공백만
            ])
            func a(text: String) {
                let result = check(text)

                #expect(result == false)
            }

            @Test("모든 항목을 거절한다", arguments: [
                Option.a,
                .b
            ])
            func b(option: Option) {
                let result = check(option)

                #expect(result == false)
            }
        }
        """

        let violations = lint(source: source, path: specTestPath, rules: [TestArgumentsRule()])

        #expect(violations.map(\.line) == [3])
    }

    @Test("타입을 붙인 arguments 배열도 항목마다 이유 주석을 본다")
    func argumentsChecksTypedArray() {
        let source = """
        @Suite("샘플") struct S {
            @Test("하나만 있어도 된다", arguments: [
                (day, nil),  // 시작일만
                (nil, day)
            ] as [(Date?, Date?)])
            func a(start: Date?, end: Date?) {
                let result = check(start, end)

                #expect(result == true)
            }
        }
        """

        let violations = lint(source: source, path: specTestPath, rules: [TestArgumentsRule()])

        #expect(violations.map(\.line) == [4])
    }

    // MARK: - test-determinism

    @Test(
        "실행마다 달라지는 값을 잡는다",
        arguments: [
            "let now = Date()",                // 지금 시각
            "let now = Date.now",              // 지금 시각
            "let calendar = Calendar.current", // 기기 설정
            "let locale = Locale.current",     // 기기 설정
            "let id = UUID()",                 // 난수
            "let n = Int.random(in: 0...1)"    // 난수
        ]
    )
    func determinismCatchesVaryingValues(statement: String) {
        let source = cleanSpec.replacingOccurrences(of: "        var draft = Draft()\n", with: "        var draft = Draft()\n        \(statement)\n")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestDeterminismRule()])) == ["test-determinism"])
    }

    @Test("고정 날짜와 static var를 구분한다")
    func determinismAllowsFixedDateButNotStaticVar() {
        let source = """
        let fixed = Date(timeIntervalSince1970: 0)
        enum Shared { static var count = 0 }
        """

        let violations = lint(source: source, path: specTestPath, rules: [TestDeterminismRule()])

        #expect(violations.map(\.line) == [2])
    }

    // MARK: - test-result-only

    @Test("@testable import를 잡는다")
    func resultOnlyCatchesTestable() {
        let source = cleanSpec.replacingOccurrences(of: "import AuthDomain", with: "@testable import AuthDomain")

        #expect(ids(lint(source: source, path: specTestPath, rules: [TestResultOnlyRule()])) == ["test-result-only"])
    }

    @Test("Entity 테스트의 Mock은 잡고, UseCase 테스트의 Mock은 두며, MockingBird 같은 이름은 Mock으로 보지 않는다")
    func resultOnlyCatchesMockOnlyInEntityTests() {
        let source = "let a = MockSampleRepository()\nlet b = Mockingbird()"
        let useCasePath = "/Projects/Domain/AuthDomain/Tests/UseCase/SampleUseCaseTests.swift"

        let entity = lint(source: source, path: specTestPath, rules: [TestResultOnlyRule()])
        let useCase = lint(source: source, path: useCasePath, rules: [TestResultOnlyRule()])

        #expect(entity.map(\.line) == [1])
        #expect(useCase.isEmpty)
    }

    // MARK: - test-double-query

    @Test("가짜 객체의 조회 메서드가 호출을 기록하면 잡고, 명령 메서드의 기록과 지역 변수로 결과를 만드는 것은 둔다")
    func doubleQueryCatchesRecordingInQueriesOnly() {
        let source = """
        public final class MockSampleRepository {
            public var fetchResult: Result<Int, Error> = .success(0)
            public private(set) var fetchCount = 0
            public private(set) var saved: [Int] = []

            public func fetchSample() throws -> Int {
                fetchCount += 1
                return try fetchResult.get()
            }

            public func loadAll() throws -> Int {
                try fetchResult.get()
            }

            public func save(_ value: Int) {
                saved.append(value)
            }

            public func searchSample(_ query: String) -> [Int] {
                var results = [1]
                results.append(2)
                results += [3]
                _ = query
                return results
            }

            public func loadAll(_ groups: [[Int]]) -> [Int] {
                let flat = groups.reduce(into: []) { result, group in result.append(contentsOf: group) }
                return groups.reduce(into: flat) { $0.append($1.count) }
            }
        }
        """

        let violations = lint(source: source, path: specTestingPath, rules: [TestDoubleQueryRule()])

        #expect(violations.map(\.line) == [6])
    }

    @Test(
        "조회 메서드 이름을 fetch·load·search 접두로 가린다",
        arguments: [
            ("fetchNovel", true),   // 조회
            ("load", true),         // 접두만
            ("searchKeywords", true),  // 검색도 조회다
            ("searcher", false),    // 다른 단어
            ("loader", false),      // 다른 단어
            ("save", false)         // 명령
        ]
    )
    func doubleQueryRecognizesQueryNames(name: String, isQuery: Bool) {
        let result = TestDoubleQueryRule.isQueryName(name)

        #expect(result == isQuery)
    }

    // MARK: - 모듈 단위 규칙

    @Test("넘기기만 하는 UseCase를 테스트하면 잡고, 바꾸거나 거르는 UseCase는 테스트해도 된다")
    func passThroughCatchesForwardingUseCaseTests() {
        let sources = [
            (path: "/Projects/Domain/AuthDomain/Sources/UseCase/Forward.swift", source: """
            public final class DefaultForwardUseCase {
                private let repository: Repo
                public func execute(id: Int) async throws -> Int {
                    return try await repository.fetch(id: id)
                }
            }
            public final class DefaultSelfForwardUseCase {
                private let repository: Repo
                public func execute(id: Int) async throws -> Int {
                    try await self.repository.fetch(id: id)
                }
            }
            public final class DefaultLogicUseCase {
                private let repository: Repo
                public func execute(id: Int) async throws -> Int {
                    try await repository.fetch(id: id + 1)
                }
            }
            public final class DefaultFilterUseCase {
                private let repository: Repo
                public func execute() async throws -> [Int] {
                    try await repository.fetch().filter { $0 > 0 }
                }
            }
            public final class DefaultObserveUseCase {
                private let repository: Repo
                public func execute(id: Int) -> Stream {
                    repository.observe(id: id) { $0 * 2 }
                }
            }
            public final class DefaultChainUseCase {
                private let repository: Repo
                public func execute(id: Int) async throws -> [Int] {
                    try await repository.fetch(id: id).sorted()
                }
            }
            """),
            (path: "/Projects/Domain/AuthDomain/Tests/UseCase/ForwardTests.swift", source: """
            let a = DefaultForwardUseCase(repository: stub)
            let b = DefaultSelfForwardUseCase(repository: stub)
            let c = DefaultLogicUseCase(repository: stub)
            let d = DefaultFilterUseCase(repository: stub)
            let e = DefaultChainUseCase(repository: stub)
            let f = DefaultObserveUseCase(repository: stub)
            """)
        ]

        let violations = lintModule(sources: sources, moduleName: "AuthDomain", rule: TestPassThroughRule())

        #expect(violations.map(\.line).sorted() == [1, 2])
    }

    @Test("분기·throw가 있는 타입이 테스트에 한 번도 안 나오면 잡는다")
    func requiredCatchesUntestedBranchingType() {
        let sources = [
            (path: specSourcePath, source: """
            public struct Tested { public func f(_ x: Int) -> Int { x > 0 ? x : 0 } }
            public struct Untested { public func g() throws { throw E.x } }
            public struct NoRule { public let value: Int }
            """),
            (path: specTestPath, source: "let t = Tested()")
        ]

        let violations = lintModule(sources: sources, moduleName: "AuthDomain", rule: TestRequiredRule())

        #expect(violations.map(\.message).allSatisfy { $0.hasPrefix("Untested") })
        #expect(violations.count == 1)
    }

    @Test("Entity 에러 case 중 #expect(throws:)에 안 나온 것을 잡는다(타입만 적은 확인은 세지 않는다)")
    func errorCaseCatchesMissingCases() {
        let sources = [
            (path: specSourcePath, source: """
            public struct Draft {
                public enum ValidationError: Error {
                    case tooLong(max: Int)
                    case empty
                    case duplicated
                }
            }
            """),
            (path: specTestPath, source: """
            func a() { #expect(throws: Draft.ValidationError.tooLong(max: 20)) { try f() } }
            func b() { #expect(throws: Draft.ValidationError.self) { try g() } }
            func c() { #expect(draft.error == .empty) }
            """)
        ]

        let violations = lintModule(sources: sources, moduleName: "AuthDomain", rule: TestErrorCaseRule())

        #expect(violations.map(\.message).sorted() == [
            "ValidationError.duplicated가 나는 상황을 #expect(throws:)로 확인하는 테스트가 없다",
            "ValidationError.empty가 나는 상황을 #expect(throws:)로 확인하는 테스트가 없다"
        ])
    }

    @Test("저장소 에러(RepositoryError·Repository 폴더)는 대상이 아니다")
    func errorCaseSkipsRepositoryErrors() {
        let sources = [
            (path: "/Projects/Domain/AuthDomain/Sources/Repository/AuthError.swift",
             source: "public enum AuthError: Error { case unknown }"),
            (path: "/Projects/Domain/AuthDomain/Sources/RepositoryError.swift",
             source: "public enum RepositoryError: Error { case notFound }")
        ]

        #expect(lintModule(sources: sources, moduleName: "AuthDomain", rule: TestErrorCaseRule()).isEmpty)
    }

    @Test("Entity 폴더 밖이나 다른 이름의 검증 에러도 검사한다")
    func errorCaseChecksErrorsOutsideEntity() {
        let sources = [
            (path: "/Projects/Domain/AuthDomain/Sources/Rating.swift", source: """
            public struct Rating {
                public enum ValidationError: Error { case outOfRange }
            }
            """),
            (path: "/Projects/Domain/AuthDomain/Sources/Entity/Feed.swift", source: """
            public struct Feed {
                public enum PolicyError: LocalizedError { case notOwner }
            }
            """)
        ]

        let violations = lintModule(sources: sources, moduleName: "AuthDomain", rule: TestErrorCaseRule())

        #expect(violations.count == 2)
    }

    @Test("테스트가 소스의 static let 상수를 쓰면 잡는다")
    func sourceConstantCatchesStaticLetReference() {
        let sources = [
            (path: specSourcePath, source: "public struct Draft { public static let maxLength = 80 }"),
            (path: specTestPath, source: """
            let a = String(repeating: "가", count: Draft.maxLength)
            let b = Option.maxLengthLabel
            """)
        ]

        let violations = lintModule(sources: sources, moduleName: "AuthDomain", rule: TestSourceConstantRule())

        #expect(violations.map(\.line) == [1])
    }

    @Test("다른 타입의 같은 이름은 소스 상수로 보지 않는다")
    func sourceConstantMatchesTypeAndName() {
        let sources = [
            (path: specSourcePath, source: """
            public enum DeepLink {
                case novelDetail(Int)
                private enum View { static let novelDetail = "novelDetail" }
            }
            """),
            (path: specTestPath, source: "let link = DeepLink.novelDetail(7)")
        ]

        let violations = lintModule(sources: sources, moduleName: "AuthDomain", rule: TestSourceConstantRule())

        #expect(violations.isEmpty)
    }
}
