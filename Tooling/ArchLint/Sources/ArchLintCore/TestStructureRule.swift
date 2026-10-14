import Foundation
import SwiftSyntax

/// 테스트 본문은 준비 / 실행 / 확인(AAA) 구역을 빈 줄로 나눈다(#293 원칙 1 "읽힌다") — error.
/// - 구역은 3개 이하. 확인 구역은 맨 끝이고 `#expect`·`#require`만 담는다. 확인은 다른 구역에 섞지 않는다.
/// - 구역이 하나뿐이면 `#expect(throws:)` 한 줄짜리만 허용한다(실행이 그 안에 들어 있다).
/// - `// Given`·`// When`·`// Then` 같은 구역 라벨은 쓰지 않는다 — 빈 줄이 구역을 말한다.
/// - for·while·if·switch·guard·삼항을 쓰지 않는다 — 분기가 있으면 어느 경우를 확인했는지 읽히지 않는다.
///   여러 입력은 `arguments:`로 나눈다.
struct TestStructureRule: Rule {
    let id = "test-aaa"
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
            guard let body = test.function.body, !body.statements.isEmpty else { continue }
            let sections = SpecSyntax.sections(of: body)

            if sections.count > 3 {
                report(test.function, "구역이 \(sections.count)개다 — 준비 / 실행 / 확인 3구역 이하로 빈 줄로 나눈다")
            }
            if let last = sections.last, let offender = last.first(where: { !SpecSyntax.isAssertion($0) }) {
                report(offender, "마지막 구역(확인)에는 #expect·#require만 둔다 — 실행과 확인 사이에 빈 줄을 넣는다")
            }
            for section in sections.dropLast() {
                for item in section where SpecSyntax.isAssertion(item) {
                    report(item, "확인(#expect·#require)이 마지막 구역이 아닌 곳에 있다 — 확인은 맨 끝 구역에 모은다")
                }
            }
            if sections.count == 1, !(sections[0].count == 1 && SpecSyntax.isThrowsExpectation(sections[0][0])) {
                report(test.function, "준비·실행·확인이 한 덩어리다 — 빈 줄로 구역을 나눈다")
            }

            let labels = SectionLabelFinder()
            labels.walk(body)
            for token in labels.found {
                report(token, "구역 라벨 주석(Given·When·Then 등)은 쓰지 않는다 — 빈 줄이 구역을 나눈다")
            }

            let branches = BranchFinder()
            branches.walk(body)
            for (node, kind) in branches.found {
                report(node, "테스트 본문에 \(kind) — 어느 경우를 확인했는지 안 읽힌다. 입력이 여럿이면 arguments:로 나눈다")
            }
        }
        return violations
    }
}

/// 실행 구역이 여러 문장이면 사람에게 설계를 묻는다 — warning.
/// 한 동작을 여러 호출로 해야 한다면 메서드를 합쳐야 한다는 신호일 수 있다.
/// 유지하기로 했으면 `// archlint:allow test-aaa-act — 이유`를 남긴다(PR 점검 목록에 오른다).
struct TestActSizeRule: Rule {
    let id = "test-aaa-act"
    let severity: Severity = .warning

    func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Tests")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let collector = SpecTestCollector()
        collector.walk(tree)
        return collector.tests.compactMap { test in
            guard let body = test.function.body,
                  let act = Self.actSection(SpecSyntax.sections(of: body)),
                  act.count > 1 else { return nil }
            return Violation(
                path: path, line: SpecSyntax.line(of: act[0], converter), ruleID: id,
                message: "실행 구역이 \(act.count)문장이다 — 한 동작을 여러 호출로 해야 한다면 메서드 설계를 점검한다(사람 확인 필요)",
                severity: severity
            )
        }
    }

    /// 실행 구역: 3구역이면 가운데, 2구역이면 첫 구역(단 확인이 `#expect(throws:)`면 실행이 그 안에 있어 첫 구역은 준비).
    static func actSection(_ sections: [[CodeBlockItemSyntax]]) -> [CodeBlockItemSyntax]? {
        switch sections.count {
        case 3:
            return sections[1]
        case 2:
            let throwsExpectation = sections[1].contains { SpecSyntax.isThrowsExpectation($0) }
            return throwsExpectation ? nil : sections[0]
        default:
            return nil
        }
    }
}

/// 본문이 길면 읽히지 않는다 — warning. 길어지면 준비를 줄일 방법(입력 단순화·설계 점검)을 찾는다.
struct TestBodyLengthRule: Rule {
    let id = "test-body-length"
    let severity: Severity = .warning

    static let maxLines = 15

    func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Tests")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let collector = SpecTestCollector()
        collector.walk(tree)
        return collector.tests.compactMap { test in
            guard let body = test.function.body else { return nil }
            let open = body.leftBrace.startLocation(converter: converter).line
            let close = body.rightBrace.startLocation(converter: converter).line
            let lines = close - open - 1
            guard lines > Self.maxLines else { return nil }
            return Violation(
                path: path, line: SpecSyntax.line(of: test.function, converter), ruleID: id,
                message: "본문이 \(lines)줄이다(상한 \(Self.maxLines)) — 한눈에 읽히도록 준비를 줄인다",
                severity: severity
            )
        }
    }
}

/// `// Given` 같은 구역 라벨 주석을 찾는다.
private final class SectionLabelFinder: SyntaxVisitor {
    private(set) var found: [TokenSyntax] = []

    private static let label = try! NSRegularExpression(
        pattern: "^//\\s*((given|when|then|arrange|act|assert)\\b|(준비|실행|확인)\\s*(:|-|$))",
        options: [.caseInsensitive]
    )

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        let pieces = Array(token.leadingTrivia) + Array(token.trailingTrivia)
        for piece in pieces {
            guard case .lineComment(let text) = piece else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if Self.label.firstMatch(in: text, range: range) != nil {
                found.append(token)
            }
        }
        return .visitChildren
    }
}

/// 분기·반복을 찾는다.
private final class BranchFinder: SyntaxVisitor {
    private(set) var found: [(Syntax, String)] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind { record(node, "for") }
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind { record(node, "while") }
    override func visit(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind { record(node, "repeat") }
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind { record(node, "if") }
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind { record(node, "switch") }
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind { record(node, "guard") }
    override func visit(_ node: UnresolvedTernaryExprSyntax) -> SyntaxVisitorContinueKind { record(node, "삼항") }
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind { record(node, "삼항") }

    private func record(_ node: some SyntaxProtocol, _ kind: String) -> SyntaxVisitorContinueKind {
        found.append((Syntax(node), kind))
        return .visitChildren
    }
}
