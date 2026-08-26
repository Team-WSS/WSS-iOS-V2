import Foundation
import SwiftSyntax

/// 규칙⑨/⑩ 프로토콜 네이밍 — 하드 게이트(error).
/// Domain의 특정 폴더에 놓인 **protocol**은 이름이 정해진 접미사로 끝나야 한다.
///   ⑨ usecase-naming:    `/Sources/UseCase/`     의 protocol → `*UseCase`
///   ⑩ repository-naming: `/Sources/Repository/`  의 protocol → `*Repository`
///
/// **왜 protocol만 보나**: 두 폴더에는 계약(protocol) 외에 co-locate된 타입이 섞여 있다
/// — UseCase 폴더엔 `DefaultXxxUseCase`(구현체)와 반환 Entity(`HomeData` 등),
///   Repository 폴더엔 `AuthError`·`ProfileTarget`(에러/타깃 enum)이 함께 산다.
/// 이들은 접미사 관례 대상이 아니므로, "폴더가 정의하는 추상(=protocol)"에만 접미사를 강제한다.
/// (현재 두 폴더의 protocol 전부 이미 접미사 준수 → 베이스라인 초록.)
struct ProtocolNamingRule: Rule {
    let id: String
    let severity: Severity = .error
    /// 레이어 스코프 조각(예: "/Projects/Domain/").
    let layerPathFragment: String
    /// 폴더 스코프 조각(예: "/Sources/UseCase/").
    let folderFragment: String
    /// 요구 접미사(예: "UseCase").
    let requiredSuffix: String

    func applies(to path: String) -> Bool {
        path.hasSuffix(".swift")
            && path.contains(layerPathFragment)
            && path.contains(folderFragment)
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = ProtocolNamingVisitor(
            ruleID: id, severity: severity, path: path,
            converter: converter, requiredSuffix: requiredSuffix
        )
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class ProtocolNamingVisitor: SyntaxVisitor {
    private(set) var violations: [Violation] = []
    private let ruleID: String
    private let severity: Severity
    private let path: String
    private let converter: SourceLocationConverter
    private let requiredSuffix: String

    init(ruleID: String, severity: Severity, path: String,
         converter: SourceLocationConverter, requiredSuffix: String) {
        self.ruleID = ruleID
        self.severity = severity
        self.path = path
        self.converter = converter
        self.requiredSuffix = requiredSuffix
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        if !name.hasSuffix(requiredSuffix) {
            let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
            violations.append(Violation(
                path: path, line: line, ruleID: ruleID,
                message: "\(name): 이 폴더의 protocol은 이름이 \(requiredSuffix)로 끝나야 한다",
                severity: severity
            ))
        }
        return .visitChildren
    }
}
