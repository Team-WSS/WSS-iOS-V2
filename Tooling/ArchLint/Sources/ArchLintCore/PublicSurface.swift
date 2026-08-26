import Foundation
import SwiftSyntax

/// 선언 수식어에 `public`/`open`이 있는가.
func isPublicOrOpen(_ modifiers: DeclModifierListSyntax) -> Bool {
    modifiers.contains { $0.name.text == "public" || $0.name.text == "open" }
}

/// 파일 **최상위** 선언 하나를 보고, `public`/`open`인데 이름이 `allowedSuffix`로 끝나는 **타입**이
/// 아니면 (위반 라벨, 노드)를 반환한다. 그 허용 타입이거나 애초에 public/open이 아니면 nil.
///
/// 두 배타성 규칙(⑫ `factory-exclusivity`·⑬ `feature-exclusivity`)이 **허용 접미사만 바꿔 공유**한다
/// (Data="DataFactory" / Feature="Factory"). 타입 외 최상위 public(func·var·typealias·extension)은
/// 접미사 타입일 수 없으므로 전부 위반이다. 타입 내부 멤버는 바깥이 internal이면 안 새므로 top-level만 본다.
func publicTopLevelOffense(_ item: CodeBlockItemSyntax.Item, allowedSuffix: String) -> (label: String, node: Syntax)? {
    func typeOffense(
        _ name: TokenSyntax, _ modifiers: DeclModifierListSyntax, _ kind: String, _ node: some SyntaxProtocol
    ) -> (label: String, node: Syntax)? {
        guard isPublicOrOpen(modifiers), !name.text.hasSuffix(allowedSuffix) else { return nil }
        return ("public \(kind) \(name.text)", Syntax(node))
    }
    if let d = item.as(ClassDeclSyntax.self) { return typeOffense(d.name, d.modifiers, "class", d) }
    if let d = item.as(StructDeclSyntax.self) { return typeOffense(d.name, d.modifiers, "struct", d) }
    if let d = item.as(EnumDeclSyntax.self) { return typeOffense(d.name, d.modifiers, "enum", d) }
    if let d = item.as(ProtocolDeclSyntax.self) { return typeOffense(d.name, d.modifiers, "protocol", d) }
    if let d = item.as(ActorDeclSyntax.self) { return typeOffense(d.name, d.modifiers, "actor", d) }
    if let d = item.as(TypeAliasDeclSyntax.self) { return typeOffense(d.name, d.modifiers, "typealias", d) }
    // 아래는 이름이 접미사 타입일 수 없는 종류 — public/open이면 무조건 위반.
    if let d = item.as(FunctionDeclSyntax.self), isPublicOrOpen(d.modifiers) {
        return ("public func \(d.name.text)", Syntax(d))
    }
    if let d = item.as(VariableDeclSyntax.self), isPublicOrOpen(d.modifiers) {
        return ("public 전역 프로퍼티", Syntax(d))
    }
    if let d = item.as(ExtensionDeclSyntax.self), isPublicOrOpen(d.modifiers) {
        return ("public extension \(d.extendedType.trimmedDescription)", Syntax(d))
    }
    return nil
}
