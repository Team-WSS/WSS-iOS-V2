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
            for suite in collector.suites where suite.parentID == nil {
                lines += suiteLines(suite, depth: 0, fileName: fileName, collector: collector)
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// 스위트 하나와 그 안의 하위 스위트. 하위 스위트는 제목을 한 단계씩 내려 부모 아래에 둔다.
    /// 파일 경로는 맨 위 스위트에만 적고, 테스트가 하나도 없는 스위트는 뺀다.
    private static func suiteLines(_ suite: SpecSuite, depth: Int, fileName: String, collector: SpecTestCollector) -> [String] {
        let tests = collector.tests.filter { $0.suiteID == suite.node.id }
        let children = collector.suites
            .filter { $0.parentID == suite.node.id }
            .flatMap { suiteLines($0, depth: depth + 1, fileName: fileName, collector: collector) }
        guard !tests.isEmpty || !children.isEmpty else { return [] }

        let heading = String(repeating: "#", count: min(depth + 2, 6))
        var lines = ["", "\(heading) \(suite.displayName ?? "(이름 없음)")", ""]
        if depth == 0 { lines += ["`Tests/\(fileName)`", ""] }
        // 직접 붙은 테스트가 없으면 하위 스위트의 앞 빈 줄과 겹치지 않게 뺀다.
        if tests.isEmpty { lines.removeLast() }
        for test in tests {
            lines.append("- \(test.displayName ?? test.function.name.text)")
            lines += argumentLines(test.arguments)
        }
        return lines + children
    }

    /// `arguments:` 항목을 하위 목록으로. 배열이 아니면(`X.allCases`) 식을 그대로 적는다.
    private static func argumentLines(_ arguments: ExprSyntax?) -> [String] {
        guard let arguments else { return [] }
        guard let array = SpecSyntax.argumentArray(arguments) else {
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
