import Foundation
import SwiftSyntax

/// 규칙⑦ Service 쿼리 조립 금지 — 경고(warning, report-only).
/// Data의 *Service* 소스에서 `XxxQuery(...)` 생성자 호출을 찾는다.
/// ⑤(분기 금지)가 "leak이 생기면 잡는" 사후 그물이라면, 이건 "Service가 완성된 Query를
/// Input으로 받게" 강제해 **매핑 leak을 문법적으로 불가능**하게 만드는 예방 규칙이다.
/// 단 `*Query` 네이밍 휴리스틱에 의존하고(SwiftSyntax는 타입 정보가 없어 QueryItemConvertible
/// 채택을 못 봄) 순수 포장까지 막는 건 아키텍처 취향이라, ⑤처럼 하드게이트가 아닌 warning으로 둔다.
struct ServiceNoQueryBuildRule: Rule {
    let id = "service-no-query-build"
    let severity: Severity = .warning

    func applies(to path: String) -> Bool {
        guard path.hasSuffix(".swift") else { return false }
        guard path.contains("/Projects/Data/"), path.contains("/Sources/") else { return false }
        return (path as NSString).lastPathComponent.contains("Service")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = ServiceNoQueryBuildVisitor(ruleID: id, severity: severity, path: path, converter: converter)
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class ServiceNoQueryBuildVisitor: SyntaxVisitor {
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

    // `GetNovelFeedsQuery(...)` 같은 생성자 호출 = calledExpression 이 대문자로 시작하고
    // "Query"로 끝나는 타입 참조인 FunctionCall. `client.request(...)`·`Endpoint.case(...)`는
    // MemberAccess라 걸리지 않고, 시그니처의 `query: XxxQuery` 파라미터도 호출이 아니라 제외된다.
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let callee = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            let name = callee.baseName.text
            if name.hasSuffix("Query"), name.count > "Query".count, name.first?.isUppercase == true {
                record(node, "Service에서 쿼리(\(name)) 조립 금지 — 완성된 Query를 Input으로 받아 통과시킨다(매핑 leak 예방)")
            }
        }
        return .visitChildren
    }

    private func record(_ node: some SyntaxProtocol, _ message: String) {
        let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
        violations.append(
            Violation(path: path, line: line, ruleID: ruleID, message: message, severity: severity)
        )
    }
}
