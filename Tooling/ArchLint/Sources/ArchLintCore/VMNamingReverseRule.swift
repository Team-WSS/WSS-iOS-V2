import Foundation
import SwiftSyntax

/// 규칙⑧ VM 네이밍(역방향) — 하드 게이트(error).
/// Feature/UI Sources에서 `@Observable`를 붙인 class는 이름이 반드시 `ViewModel`로 끝나야 한다.
/// ②(vm-observable-state)가 "이름이 *ViewModel이면 @Observable + state 강제"(정방향)라면,
/// 이건 그 **역방향** — @Observable을 붙였는데 이름이 *ViewModel이 아니면 ②의 네이밍 그물을
/// 빠져나간다(@Observable인데 state 계약을 안 지켜도 안 걸린다). 이 규칙이 그 구멍을 막아
/// "@Observable class ⇔ *ViewModel"을 양방향으로 고정한다.
/// (@Observable는 class 전용 매크로라 class만 본다. 현재 @Observable class 전부 이미 *ViewModel
///  → 베이스라인 초록. 문법==의미(예외 없음)라 error로 둔다.)
struct VMNamingReverseRule: Rule {
    let id = "vm-naming-reverse"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        guard path.hasSuffix(".swift"), path.contains("/Sources/") else { return false }
        return path.contains("/Projects/Feature/") || path.contains("/Projects/UI/")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = VMNamingReverseVisitor(ruleID: id, severity: severity, path: path, converter: converter)
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class VMNamingReverseVisitor: SyntaxVisitor {
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
        let hasObservable = node.attributes.contains { element in
            element.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "Observable"
        }
        guard hasObservable else { return .visitChildren }

        let name = node.name.text
        if !name.hasSuffix("ViewModel") {
            let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
            violations.append(Violation(
                path: path, line: line, ruleID: ruleID,
                message: "\(name): @Observable class는 이름이 ViewModel로 끝나야 한다 — @Observable ⇔ ViewModel 계약(②의 역방향)",
                severity: severity
            ))
        }
        return .visitChildren
    }
}
