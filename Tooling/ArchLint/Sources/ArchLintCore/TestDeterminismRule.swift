import Foundation
import SwiftSyntax

/// 테스트는 언제 어디서 돌려도 같은 결과(#293 원칙 5 "늘 같다") — error.
/// 지금 시각·기기 설정·난수·테스트 간 공유 상태에 기대지 않는다:
/// `Date()`·`Date.now`·`Calendar.current`·`TimeZone.current`·`Locale.current`·`UUID()`·
/// `.random`·`.randomElement`·`.shuffled`·`static var`.
/// 날짜가 필요하면 고정 값을 만들고, 기준 시각은 인자로 넘긴다.
struct TestDeterminismRule: Rule {
    let id = "test-determinism"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Tests")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = DeterminismVisitor()
        visitor.walk(tree)
        return visitor.found.map { node, what in
            Violation(
                path: path, line: SpecSyntax.line(of: node, converter), ruleID: id,
                message: "\(what)는 돌릴 때마다 달라진다 — 고정 값을 만들어 쓴다", severity: severity
            )
        }
    }
}

private final class DeterminismVisitor: SyntaxVisitor {
    private(set) var found: [(Syntax, String)] = []

    private static let deviceSettings: Set<String> = ["Calendar", "TimeZone", "Locale"]
    private static let randomMembers: Set<String> = ["random", "randomElement", "shuffled"]

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
           ["Date", "UUID"].contains(callee.baseName.text),
           node.arguments.isEmpty, node.trailingClosure == nil {
            found.append((Syntax(node), "\(callee.baseName.text)()"))
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let member = node.declName.baseName.text
        let base = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text
        if base == "Date", member == "now" {
            found.append((Syntax(node), "Date.now"))
        } else if let base, Self.deviceSettings.contains(base), member == "current" || member == "autoupdatingCurrent" {
            found.append((Syntax(node), "\(base).\(member)"))
        } else if Self.randomMembers.contains(member) {
            found.append((Syntax(node), ".\(member)"))
        }
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let isStatic = node.modifiers.contains { $0.name.text == "static" || $0.name.text == "class" }
        if isStatic, node.bindingSpecifier.text == "var" {
            found.append((Syntax(node), "static var(테스트끼리 공유하는 상태)"))
        }
        return .visitChildren
    }
}
