import Foundation
import SwiftSyntax

/// 모듈의 테스트 목록 파일(`TEST_SPEC.md`) — 사람이 PR에서 주로 읽는 곳(#293).
/// 스위트·테스트 이름과 `arguments:` 항목을 뽑아 적는다. 테스트 이름이 바뀌면 이 파일의 diff로 보인다.
/// 손으로 고치지 않는다: `ArchLint --write-test-specs`가 만들고, 일반 실행은 최신인지 검사한다.
public enum TestSpecDocument {
    public static let fileName = "TEST_SPEC.md"
    static let ruleID = "test-spec-file"

    static func render(module: String, files: [ParsedFile]) -> String {
        var lines = [
            "# \(module) 테스트 명세",
            "",
            "<!-- 자동 생성 파일 — 손으로 고치지 않는다. 갱신: swift run --package-path Tooling/ArchLint ArchLint --write-test-specs . -->"
        ]

        for file in files.sorted(by: { $0.path < $1.path }) {
            let collector = SpecTestCollector()
            collector.walk(file.tree)
            let fileName = file.path.components(separatedBy: "/Tests/").last ?? file.path
            for suite in collector.suites {
                let tests = collector.tests.filter { $0.suiteID == suite.node.id }
                guard !tests.isEmpty else { continue }
                lines += ["", "## \(suite.displayName ?? "(이름 없음)")", "", "`Tests/\(fileName)`", ""]
                for test in tests {
                    lines.append("- \(test.displayName ?? test.function.name.text)")
                    lines += argumentLines(test.arguments)
                }
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// `arguments:` 항목을 하위 목록으로. 배열이 아니면(`X.allCases`) 식을 그대로 적는다.
    private static func argumentLines(_ arguments: ExprSyntax?) -> [String] {
        guard let arguments else { return [] }
        guard let array = arguments.as(ArrayExprSyntax.self) else {
            return ["  - `\(arguments.trimmedDescription)`"]
        }
        return array.elements.map { element in
            let comment = (Array(element.leadingTrivia) + Array(element.trailingTrivia)).compactMap { piece -> String? in
                guard case .lineComment(let text) = piece else { return nil }
                return text.dropFirst(2).trimmingCharacters(in: .whitespaces)
            }.first
            let value = "`\(element.expression.trimmedDescription)`"
            return comment.map { "  - \(value) — \($0)" } ?? "  - \(value)"
        }
    }
}
