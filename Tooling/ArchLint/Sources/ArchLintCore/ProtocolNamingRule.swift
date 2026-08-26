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
///
/// ⚠️ **스코프는 폴더명을 경로 세그먼트로 매칭한다(중첩·대소문자 무시)**. 이 레포는 UseCase/Repository를
/// `Sources/UseCase/` 처럼 평평하게만 두지 않고 **기능 그룹 하위 폴더**로도 둔다(예:
/// `SettingDomain/Sources/AppUpdate/UseCase/`·`NotificationDomain/Sources/Push/Repository/`),
/// 또 일부는 소문자 `Usecase/`(RecommendationDomain·BaseDomain)를 쓴다. `"/Sources/UseCase/"` 완전일치로
/// 스코프하면 이들을 통째로 놓친다 → `/<folderName>/`를 대소문자 무시로 매칭해 전부 커버한다.
struct ProtocolNamingRule: Rule {
    let id: String
    let severity: Severity = .error
    /// 레이어 스코프 조각(예: "/Projects/Domain/").
    let layerPathFragment: String
    /// 폴더명(예: "UseCase"). 경로에 `/<folderName>/` 세그먼트로 등장하면 스코프(중첩·대소문자 무시).
    let folderName: String
    /// 요구 접미사(예: "UseCase").
    let requiredSuffix: String

    func applies(to path: String) -> Bool {
        guard path.hasSuffix(".swift"),
              path.contains(layerPathFragment),
              path.contains("/Sources/") else { return false }
        // 폴더명이 경로 세그먼트로 등장하는지 — 중첩(`.../Push/UseCase/...`)·대소문자(`Usecase`) 무관.
        return path.lowercased().contains("/\(folderName.lowercased())/")
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
