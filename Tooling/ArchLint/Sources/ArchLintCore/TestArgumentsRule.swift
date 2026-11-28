import Foundation
import SwiftSyntax

/// `@Test(arguments: [...])`의 입력 목록이 읽힌다(#293 원칙 1 "읽힌다") — error.
/// - 항목마다 줄을 바꾼다 — 어떤 경우들을 확인하는지 목록으로 보인다.
/// - 리터럴(문자열·숫자 등) 항목에는 왜 그 값인지 주석을 단다. `""`·`"   "`만으로는 의도가 안 보인다.
///   enum case처럼 이름이 곧 뜻인 항목은 주석이 없어도 된다.
/// 배열 리터럴이 아닌 인자(`Option.allCases` 등)는 대상이 아니다. 타입을 붙인 배열(`[…] as [T]`)은 대상이다.
struct TestArgumentsRule: Rule {
    let id = "test-arguments"
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
            guard let array = SpecSyntax.argumentArray(test.arguments) else { continue }
            var previousLine = SpecSyntax.line(of: array.leftSquare, converter)
            var sharesLine = false
            for element in array.elements {
                let line = SpecSyntax.line(of: element, converter)
                if line == previousLine { sharesLine = true }
                previousLine = line
                if Self.isLiteral(element), !Self.hasComment(element) {
                    report(element, "리터럴 항목 \(element.expression.trimmedDescription)에 이유 주석이 없다 — 왜 이 값을 넣는지 // 로 쓴다")
                }
            }
            if sharesLine {
                report(array, "arguments 항목은 한 줄에 하나씩 쓴다 — 어떤 경우들을 확인하는지 목록으로 보이게")
            }
        }
        return violations
    }

    private static func isLiteral(_ element: ArrayElementSyntax) -> Bool {
        element.expression.tokens(viewMode: .sourceAccurate).contains { token in
            switch token.tokenKind {
            case .stringQuote, .multilineStringQuote, .stringSegment, .integerLiteral, .floatLiteral:
                return true
            case .keyword(let keyword):
                return keyword == .true || keyword == .false || keyword == .nil
            default:
                return false
            }
        }
    }

    private static func hasComment(_ element: ArrayElementSyntax) -> Bool {
        let pieces = Array(element.leadingTrivia) + Array(element.trailingTrivia)
        return pieces.contains { piece in
            if case .lineComment = piece { return true }
            if case .blockComment = piece { return true }
            return false
        }
    }
}
