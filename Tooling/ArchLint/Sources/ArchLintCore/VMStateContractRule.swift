import Foundation
import SwiftSyntax

/// 규칙②-포지티브 VM 상태 계약 — 하드 게이트(error). (non-negotiable #2의 포지티브 쪽)
/// Feature/UI의 `*ViewModel` 클래스는 반드시 `@Observable` + `private(set) var state`를 갖는다.
/// ①(vm-contract)이 "쓰면 안 되는 것(ObservableObject 계열)"을 막는다면, 이건 "있어야 하는 것"을 강제한다.
/// `*ViewModel` 네이밍 휴리스틱이지만 VM은 항상 그 접미사라 신뢰도가 높고, @Observable/state 누락은
/// 예외 없는 위반이라 error로 둔다(현재 34개 VM 전부 준수 → 베이스라인 초록).
struct VMStateContractRule: Rule {
    let id = "vm-observable-state"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        guard path.hasSuffix(".swift"), path.contains("/Sources/") else { return false }
        return path.contains("/Projects/Feature/") || path.contains("/Projects/UI/")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = VMStateContractVisitor(ruleID: id, severity: severity, path: path, converter: converter)
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class VMStateContractVisitor: SyntaxVisitor {
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

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        guard name.hasSuffix("ViewModel") else { return .visitChildren }

        let hasObservable = node.attributes.contains { element in
            element.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "Observable"
        }
        let hasState = node.memberBlock.members.contains { member in
            guard let v = member.decl.as(VariableDeclSyntax.self) else { return false }
            let isVar = v.bindingSpecifier.text == "var"
            let isPrivateSet = v.modifiers.contains { m in
                m.name.text == "private" && m.detail?.detail.text == "set"
            }
            let namedState = v.bindings.contains { b in
                b.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "state"
            }
            return isVar && isPrivateSet && namedState
        }

        if !hasObservable {
            record(node, "\(name): @Observable 누락 — ViewModel은 @Observable 로 선언한다")
        }
        if !hasState {
            record(node, "\(name): `private(set) var state` 누락 — 상태는 단일 private(set) var state 로 노출한다")
        }
        return .visitChildren
    }

    private func record(_ node: some SyntaxProtocol, _ message: String) {
        let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
        violations.append(Violation(path: path, line: line, ruleID: ruleID, message: message, severity: severity))
    }
}
