import Foundation
import SwiftSyntax

/// 테스트가 이름이 말한 것을 실제로 확인한다(#293 원칙 3 "버그면 실패") — error.
/// - 본문에 `#expect`가 하나 이상 있다(`#require`만 있으면 값이 맞는지는 안 본다).
/// - `!= nil`로 확인하지 않는다 — 값이 "있다"만 보고 무엇인지는 안 본다. 기대값을 `==`로 쓴다.
/// - 이름에 나온 숫자가 본문(인자 포함)에 보인다 — "80자"라고 했으면 80을 실제로 넣어 본다.
struct TestAssertionRule: Rule {
    let id = "test-assert"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Tests")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let collector = SpecTestCollector()
        collector.walk(tree)
        var violations: [Violation] = []
        func report(_ node: some SyntaxProtocol, _ message: String) {
            violations.append(Violation(
                path: path, line: SpecSyntax.line(of: node, converter),
                ruleID: id, message: message, severity: severity
            ))
        }

        for test in collector.tests {
            guard let body = test.function.body else { continue }

            let macros = MacroCounter()
            macros.walk(body)
            if !macros.names.contains("expect") {
                report(test.function, "#expect가 없다 — 이름이 말한 결과를 #expect로 확인한다(#require만으로는 값을 보지 않는다)")
            }

            let nilChecks = NotNilFinder()
            nilChecks.walk(body)
            for node in nilChecks.found {
                report(node, "`!= nil`은 값이 무엇인지 확인하지 않는다 — 기대값을 ==로 쓴다")
            }

            if let name = test.displayName {
                // 이름 문자열 자체는 빼고, 본문과 arguments만 본다.
                let literals = LiteralCollector()
                literals.walk(body)
                if let arguments = test.arguments { literals.walk(arguments) }
                for number in Self.numbers(in: name) where !literals.contains(number) {
                    report(test.function, "이름의 숫자 \(number)이(가) 본문에 없다 — 이름이 말한 값을 실제로 넣어 확인한다")
                }
            }
        }
        return violations
    }

    static func numbers(in text: String) -> [String] {
        let pattern = try! NSRegularExpression(pattern: "[0-9]+(\\.[0-9]+)?")
        let range = NSRange(text.startIndex..., in: text)
        return pattern.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }
}

/// `x != nil` 모양을 찾는다(연산자 폴딩 전 SequenceExpr 기준).
private final class NotNilFinder: SyntaxVisitor {
    private(set) var found: [SequenceExprSyntax] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        let elements = Array(node.elements)
        for (index, element) in elements.enumerated() {
            guard element.as(BinaryOperatorExprSyntax.self)?.operator.text == "!=" else { continue }
            let neighbors = [index - 1, index + 1].filter { elements.indices.contains($0) }
            if neighbors.contains(where: { elements[$0].is(NilLiteralExprSyntax.self) }) {
                found.append(node)
            }
        }
        return .visitChildren
    }
}

/// 숫자 리터럴과 문자열 리터럴 내용을 모은다.
private final class LiteralCollector: SyntaxVisitor {
    private var numbers: Set<String> = []
    private var strings: [String] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case .integerLiteral(let text), .floatLiteral(let text):
            numbers.insert(text.replacingOccurrences(of: "_", with: ""))
        case .stringSegment(let text):
            strings.append(text)
        default:
            break
        }
        return .visitChildren
    }

    func contains(_ number: String) -> Bool {
        numbers.contains(number) || strings.contains { $0.contains(number) }
    }
}
