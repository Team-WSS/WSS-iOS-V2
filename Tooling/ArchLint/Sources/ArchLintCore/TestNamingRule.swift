import Foundation
import SwiftSyntax

/// 테스트 이름 = 기능 명세 한 줄(#293 원칙 1 "읽힌다") — error.
/// - `@Test`는 `@Suite` 안에 있고, `@Suite`는 한국어 이름을 갖는다.
/// - `@Test("…")` 이름은 "~다"로 끝나는 한국어 문장이다.
/// - 이름에 코드 식별자(`draft.option`·`setOption(`·camelCase)를 쓰지 않는다 — 동작을 말로 쓴다.
/// - `/`를 쓰지 않는다(XcodeBuildMCP 리포터가 스위트 구분자로 읽어 이름을 쪼갠다).
/// - 모호한 말(성공적으로·정상적으로·올바르게·제대로)을 쓰지 않는다 — 무엇이 어떻게 되는지 쓴다.
/// - 한 스위트 안에서 이름이 겹치지 않는다.
struct TestNamingRule: Rule {
    let id = "test-name"
    let severity: Severity = .error

    static let vagueWords = ["성공적으로", "정상적으로", "올바르게", "제대로"]

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

        for suite in collector.suites where !SpecSyntax.hasHangul(suite.displayName ?? "") {
            report(suite.node, "@Suite에 한국어 이름이 없다 — 무엇의 명세인지 @Suite(\"…\")로 쓴다")
        }

        var seen: [SyntaxIdentifier: Set<String>] = [:]
        for test in collector.tests {
            if test.suiteID == nil {
                report(test.function, "@Test가 @Suite 밖에 있다 — 기능 단위 @Suite 안에 둔다")
            }
            guard let name = test.displayName else {
                report(test.function, "@Test에 이름이 없다 — @Test(\"~다\") 형태의 한국어 문장으로 쓴다")
                continue
            }
            for problem in Self.problems(in: name) {
                report(test.function, problem)
            }
            if let suiteID = test.suiteID {
                if seen[suiteID, default: []].contains(name) {
                    report(test.function, "같은 스위트에 이름이 같은 테스트가 있다: \(name)")
                }
                seen[suiteID, default: []].insert(name)
            }
        }
        return violations
    }

    /// 이름 하나의 문제 목록. 비어 있으면 통과.
    static func problems(in name: String) -> [String] {
        var problems: [String] = []
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !SpecSyntax.hasHangul(trimmed) {
            problems.append("이름이 한국어 문장이 아니다")
        }
        if !trimmed.hasSuffix("다") {
            problems.append("이름이 '~다'로 끝나는 문장이 아니다")
        }
        if trimmed.contains("/") {
            problems.append("이름에 '/'가 있다 — 테스트 리포터가 스위트 구분자로 읽는다")
        }
        if let identifier = firstIdentifier(in: trimmed) {
            problems.append("이름에 코드 식별자 '\(identifier)'가 있다 — 동작을 말로 쓴다")
        }
        for word in vagueWords where trimmed.contains(word) {
            problems.append("이름에 모호한 말 '\(word)'이 있다 — 무엇이 어떻게 되는지 쓴다")
        }
        return problems
    }

    private static let identifierPatterns = [
        "`[^`]+`",                              // 백틱
        "[A-Za-z_][A-Za-z0-9_]*\\(",            // 함수 호출 setOption(
        "[A-Za-z_][A-Za-z0-9_]*\\.[A-Za-z_]+",  // 멤버 접근 draft.option
        "[a-z]+[A-Z][A-Za-z0-9]*",              // camelCase
        "[A-Z][a-z0-9]+[A-Z][A-Za-z0-9]*"       // PascalCase 복합어(타입 이름). 한 단어(Apple)는 브랜드일 수 있어 두지 않는다
    ].map { try! NSRegularExpression(pattern: $0) }

    private static func firstIdentifier(in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        for pattern in identifierPatterns {
            if let match = pattern.firstMatch(in: text, range: range), let found = Range(match.range, in: text) {
                return String(text[found])
            }
        }
        return nil
    }
}
