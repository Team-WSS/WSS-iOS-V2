import Testing
@testable import MutationCore

private let path = "/Projects/Domain/SampleDomain/Sources/Entity/Sample.swift"

private func summaries(_ source: String) -> [String] {
    MutantGenerator.mutants(in: source, path: path).map(\.summary)
}

@Suite("뮤테이션 도구 — 심을 버그 만들기")
struct MutantGeneratorTests {

    @Test(
        "비교·논리·산술 연산자를 뒤집는다",
        arguments: [
            ("a < b", "`<` → `<=`"),     // 경계 하나 차이
            ("a >= b", "`>=` → `>`"),    // 경계 하나 차이
            ("a == b", "`==` → `!=`"),   // 정반대
            ("a && b", "`&&` → `||`"),   // 조건 하나만 맞아도 통과
            ("a + 1", "`+` → `-`")       // 계산 방향
        ]
    )
    func swapsOperators(expression: String, expected: String) {
        let found = summaries("let x = \(expression)")

        #expect(found.contains(expected))
    }

    @Test("부정(!)을 지우고, true와 false를 바꾸고, 정수를 1 키운다")
    func flipsNegationBooleansAndIntegers() {
        let found = summaries("let x = !flag\nlet y = true\nlet z = prefix(80)")

        #expect(found == ["`!flag` → `flag`", "`true` → `false`", "`80` → `81`"])
    }

    @Test("가장 큰 정수는 키우지 않는다(넘친다)")
    func skipsLargestInteger() {
        let found = summaries("let x = 9_223_372_036_854_775_807")

        #expect(found.isEmpty)
    }

    @Test("함수 본문의 대입·호출·guard·if 문장을 지우고, 선언과 return은 두지 않는다")
    func deletesStatementsButNotDeclarationsOrReturns() {
        let source = """
        func f() -> Int {
            let a = 1
            guard ready else { return 0 }
            if reset { text = "" }
            save()
            return a
        }
        """

        let deleted = summaries(source).filter { $0.hasSuffix("삭제") }

        #expect(deleted == ["`guard ready else { return 0 }` 삭제", "`if reset { text = \"\" }` 삭제", "`text = \"\"` 삭제", "`save()` 삭제"])
    }

    @Test("넘기기만 하는 UseCase는 변이 대상에서 뺀다")
    func skipsPassThroughUseCases() {
        let source = """
        public final class DefaultForwardUseCase {
            public func execute(id: Int) async throws -> Int {
                return try await repository.fetch(id: id)
            }
        }
        """

        #expect(summaries(source).isEmpty)
    }

    @Test("버그를 심으면 그 구간만 바뀐다")
    func applyReplacesOnlyTheRange() {
        let source = "let a = x < 80 // 가나다"
        let mutant = MutantGenerator.mutants(in: source, path: path).first { $0.original == "<" }

        let mutated = mutant?.apply(to: source)

        #expect(mutated == "let a = x <= 80 // 가나다")
    }
}
