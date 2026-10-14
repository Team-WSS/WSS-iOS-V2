import Foundation
import SwiftSyntax

/// 가짜 객체의 조회 메서드(`fetch…`·`load…`)는 호출을 기록하지 않는다(#293 원칙 4) — error.
/// 조회는 Stub: 정해 둔 값을 돌려줄 뿐이다. "몇 번 불렀나"를 기록하면 테스트가 그걸 확인하게 되고,
/// 캐시를 넣거나 호출을 합치는 정상적인 리팩터링에도 테스트가 깨진다. 조회 입력이 맞는지는
/// Stub이 입력마다 다른 값을 돌려주게 해서 결과로 확인한다.
/// 명령(저장·삭제·전송)은 Mock: 호출 기록이 곧 결과라 기록해도 된다.
/// 중복 요청 금지처럼 조회 횟수가 진짜 요구사항이면 `// archlint:allow test-double-query — 이유`.
struct TestDoubleQueryRule: Rule {
    let id = "test-double-query"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Testing")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = QueryRecordingVisitor()
        visitor.walk(tree)
        return visitor.found.map { function in
            Violation(
                path: path, line: SpecSyntax.line(of: function, converter), ruleID: id,
                message: "조회 메서드 \(function.name.text)가 호출을 기록한다 — 조회는 값만 돌려주고(Stub) 결과로 확인한다",
                severity: severity
            )
        }
    }

    static func isQueryName(_ name: String) -> Bool {
        for prefix in ["fetch", "load"] where name.hasPrefix(prefix) {
            guard let next = name.dropFirst(prefix.count).first else { return true }
            return next.isUppercase
        }
        return false
    }
}

private final class QueryRecordingVisitor: SyntaxVisitor {
    private(set) var found: [FunctionDeclSyntax] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard TestDoubleQueryRule.isQueryName(node.name.text), let body = node.body else { return .skipChildren }
        let finder = MutationFinder()
        finder.walk(body)
        if finder.mutates { found.append(node) }
        return .skipChildren
    }
}

/// 대입·`+=`·`append`/`insert` 같은 상태 변경이 있는가.
private final class MutationFinder: SyntaxVisitor {
    private(set) var mutates = false

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        mutates = true
        return .skipChildren
    }

    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if ["+=", "-=", "*=", "/="].contains(node.operator.text) { mutates = true }
        return .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
        if let name, ["append", "insert", "removeAll", "removeLast", "removeFirst"].contains(name) { mutates = true }
        return .visitChildren
    }
}
