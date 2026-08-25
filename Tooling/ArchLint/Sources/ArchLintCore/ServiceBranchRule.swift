import Foundation
import SwiftSyntax

/// 규칙⑤ Service 분기 금지 — 경고(warning, report-only).
/// Data의 *Service* 소스에서 if/switch/삼항(?:)을 찾는다.
/// 의도는 "매핑/비즈니스 로직이 얇은 Service에 새는 것" 금지지만, 분기는 그 신호의
/// 프록시일 뿐이라(문법≠의미) 하드 게이트로 두지 않고 warning으로만 surface 한다.
/// guard·에러 전파(GuardStmt)는 목록에 없어 자연히 제외된다.
struct ServiceBranchRule: Rule {
    let id = "service-no-branch"
    let severity: Severity = .warning

    func applies(to path: String) -> Bool {
        guard path.hasSuffix(".swift") else { return false }
        guard path.contains("/Projects/Data/"), path.contains("/Sources/") else { return false }
        let file = (path as NSString).lastPathComponent
        return file.contains("Service")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = ServiceBranchVisitor(ruleID: id, severity: severity, path: path, converter: converter)
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class ServiceBranchVisitor: SyntaxVisitor {
    private(set) var violations: [Violation] = []
    private let ruleID: String
    private let severity: Severity
    private let path: String
    private let converter: SourceLocationConverter

    init(ruleID: String, severity: Severity, path: String, converter: SourceLocationConverter) {
        self.ruleID = ruleID
        self.severity = severity
        self.path = path
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        record(node, "Service에 if 분기 — 매핑/판단 로직은 Repository·매퍼로 옮긴다")
        return .visitChildren
    }

    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        record(node, "Service에 switch 분기 — 매핑/판단 로직은 Repository·매퍼로 옮긴다")
        return .visitChildren
    }

    // 삼항(?:)은 연산자 폴딩 전 raw 트리에서 SequenceExpr 안의 UnresolvedTernaryExprSyntax 로
    // 나타난다(폴딩된 TernaryExprSyntax 가 아님) — 폴딩을 돌리지 않으므로 Unresolved 쪽을 잡는다.
    override func visit(_ node: UnresolvedTernaryExprSyntax) -> SyntaxVisitorContinueKind {
        record(node, "Service에 삼항 분기 — 매핑/판단 로직은 Repository·매퍼로 옮긴다")
        return .visitChildren
    }

    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        record(node, "Service에 삼항 분기 — 매핑/판단 로직은 Repository·매퍼로 옮긴다")
        return .visitChildren
    }

    private func record(_ node: some SyntaxProtocol, _ message: String) {
        let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
        violations.append(
            Violation(path: path, line: line, ruleID: ruleID, message: message, severity: severity)
        )
    }
}
