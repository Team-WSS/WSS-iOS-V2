import Foundation
import SwiftSyntax

/// 테스트는 공개된 결과만 본다(#293 원칙 4 "버그 아니면 실패 안 함") — error.
/// - `@testable import` 금지: internal을 열어 보면 구현을 바꿀 때마다 테스트가 깨진다.
/// - Entity 테스트(`Tests/Entity/`)에 Mock 금지: Entity는 값과 규칙뿐이라 결과로 확인한다.
struct TestResultOnlyRule: Rule {
    let id = "test-result-only"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Tests")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = ResultOnlyVisitor(checksMocks: path.contains("/Tests/Entity/"))
        visitor.walk(tree)
        return visitor.found.map { node, message in
            Violation(
                path: path, line: SpecSyntax.line(of: node, converter),
                ruleID: id, message: message, severity: severity
            )
        }
    }
}

private final class ResultOnlyVisitor: SyntaxVisitor {
    private(set) var found: [(Syntax, String)] = []
    private let checksMocks: Bool

    init(checksMocks: Bool) {
        self.checksMocks = checksMocks
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if SpecSyntax.attribute(named: "testable", in: node.attributes) != nil {
            found.append((Syntax(node), "@testable import — 공개 API로만 테스트한다(internal에 기대면 리팩터링마다 깨진다)"))
        }
        return .skipChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if checksMocks, Self.isMockName(node.baseName.text) {
            found.append((Syntax(node), "Entity 테스트에 \(node.baseName.text) — Entity는 Mock 없이 결과로 확인한다"))
        }
        return .visitChildren
    }

    private static func isMockName(_ name: String) -> Bool {
        guard name.hasPrefix("Mock"), let next = name.dropFirst(4).first else { return false }
        return next.isUppercase
    }
}
