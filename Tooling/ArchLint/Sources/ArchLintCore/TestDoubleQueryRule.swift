import Foundation
import SwiftSyntax

/// 가짜 객체의 조회 메서드(`fetch…`·`load…`·`search…`)는 호출을 기록하지 않는다(#293 원칙 4) — error.
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
        for prefix in ["fetch", "load", "search"] where name.hasPrefix(prefix) {
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
        let locals = LocalNameCollector()
        locals.walk(body)
        let finder = MutationFinder(locals: locals.names)
        finder.walk(body)
        if finder.mutates { found.append(node) }
        return .skipChildren
    }
}

/// 메서드 안에서 선언한 지역 변수 이름 — 이것을 바꾸는 건 결과를 만드는 일이지 호출 기록이 아니다.
private final class LocalNameCollector: SyntaxVisitor {
    private(set) var names: Set<String> = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.identifier.text)
        return .skipChildren
    }
}

/// 저장 프로퍼티에 대입·`+=`·`append`/`insert` 같은 상태 변경을 하는가. 지역 변수를 바꾸는 것은 세지 않는다.
private final class MutationFinder: SyntaxVisitor {
    private let locals: Set<String>
    private(set) var mutates = false

    init(locals: Set<String>) {
        self.locals = locals
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        let elements = Array(node.elements)
        for (index, element) in elements.enumerated() where index > 0 && isMutatingOperator(element) {
            if isStored(elements[index - 1]) { mutates = true }
        }
        return .visitChildren
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if isMutatingOperator(node.operator), isStored(node.leftOperand) { mutates = true }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           ["append", "insert", "removeAll", "removeLast", "removeFirst"].contains(member.declName.baseName.text),
           let base = member.base, isStored(base) {
            mutates = true
        }
        return .visitChildren
    }

    private func isMutatingOperator(_ expression: ExprSyntax) -> Bool {
        if expression.is(AssignmentExprSyntax.self) { return true }
        guard let binary = expression.as(BinaryOperatorExprSyntax.self) else { return false }
        return ["+=", "-=", "*=", "/="].contains(binary.operator.text)
    }

    /// 바꾸는 대상이 지역 변수가 아닌가(`self.x`, 또는 메서드 안에서 선언하지 않은 이름).
    private func isStored(_ expression: ExprSyntax) -> Bool {
        if let subscriptCall = expression.as(SubscriptCallExprSyntax.self) { return isStored(subscriptCall.calledExpression) }
        if let member = expression.as(MemberAccessExprSyntax.self) {
            guard let base = member.base else { return true }
            if base.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self) { return true }
            return isStored(base)
        }
        if let reference = expression.as(DeclReferenceExprSyntax.self) {
            return !locals.contains(reference.baseName.text)
        }
        return true
    }
}
