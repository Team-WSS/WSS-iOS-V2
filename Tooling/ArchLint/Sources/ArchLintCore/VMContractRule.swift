import Foundation
import SwiftSyntax

/// 규칙① VM 계약(네거티브) — 하드 게이트(error).
/// Feature/UI의 Sources에서 ObservableObject 계열을 금지한다.
/// (프로젝트 규약: ViewModel은 @Observable + 단일 state. ObservableObject/@Published/
///  @StateObject/@ObservedObject/@EnvironmentObject 는 쓰지 않는다.)
/// 이 규칙은 문법==의미다 — 위 토큰은 예외 없이 항상 위반이라 하드 게이트로 안전하다.
struct VMContractRule: Rule {
    let id = "vm-contract"
    let severity: Severity = .error

    private let bannedAttributes: Set<String> = [
        "Published", "StateObject", "ObservedObject", "EnvironmentObject"
    ]

    func applies(to path: String) -> Bool {
        guard path.hasSuffix(".swift") else { return false }
        // 제품 소스만(Demo/Tests/Testing 제외 = "/Sources/" 로 한정).
        guard path.contains("/Sources/") else { return false }
        return path.contains("/Projects/Feature/") || path.contains("/Projects/UI/")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = VMContractVisitor(
            ruleID: id, severity: severity, path: path,
            converter: converter, bannedAttributes: bannedAttributes
        )
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class VMContractVisitor: SyntaxVisitor {
    private(set) var violations: [Violation] = []
    private let ruleID: String
    private let severity: Severity
    private let path: String
    private let converter: SourceLocationConverter
    private let bannedAttributes: Set<String>

    init(ruleID: String, severity: Severity, path: String,
         converter: SourceLocationConverter, bannedAttributes: Set<String>) {
        self.ruleID = ruleID
        self.severity = severity
        self.path = path
        self.converter = converter
        self.bannedAttributes = bannedAttributes
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        let name = node.attributeName.trimmedDescription
        if bannedAttributes.contains(name) {
            record(node, "@\(name) 사용 금지 — ViewModel은 @Observable + 단일 state 를 쓴다")
        }
        return .visitChildren
    }

    override func visit(_ node: InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
        for inherited in node.inheritedTypes where inherited.type.trimmedDescription == "ObservableObject" {
            record(inherited, "ObservableObject 채택 금지 — @Observable 를 쓴다")
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
