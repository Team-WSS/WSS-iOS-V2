import Foundation
import SwiftSyntax

/// 선언 수식어에 `public`/`open`이 있는가.
func isPublicOrOpen(_ modifiers: DeclModifierListSyntax) -> Bool {
    modifiers.contains { $0.name.text == "public" || $0.name.text == "open" }
}

/// 모듈 안 파일들의 **최상위 타입 선언 이름** 집합(class/struct/enum/protocol/actor, 접근수준 무관).
/// extension이 이 모듈의 로컬 타입을 확장하는지 판정하는 데 쓴다(로컬 타입 확장은 멤버가 public이어도
/// 바깥으로 안 샌다 — 확장 멤버 접근수준은 대상 타입 접근수준을 못 넘고, 로컬 타입은 internal이거나 Factory다).
func collectLocalTypeNames(_ files: [ParsedFile]) -> Set<String> {
    var names: Set<String> = []
    for file in files {
        for statement in file.tree.statements {
            let item = statement.item
            if let d = item.as(ClassDeclSyntax.self) { names.insert(d.name.text) }
            else if let d = item.as(StructDeclSyntax.self) { names.insert(d.name.text) }
            else if let d = item.as(EnumDeclSyntax.self) { names.insert(d.name.text) }
            else if let d = item.as(ProtocolDeclSyntax.self) { names.insert(d.name.text) }
            else if let d = item.as(ActorDeclSyntax.self) { names.insert(d.name.text) }
        }
    }
    return names
}

/// 확장 대상 타입의 **첫 세그먼트 이름**(`Foo.Bar` → `Foo`, `Array<X>` → `Array`).
private func extendedBaseName(_ type: TypeSyntax) -> String {
    let text = type.trimmedDescription
    let head = text.prefix { $0 != "." && $0 != "<" && $0 != " " }
    return String(head)
}

/// extension이 **모듈 밖으로 public 심볼을 내보내는가** — 확장 자체가 public/open이거나, 멤버 중
/// public/open이 하나라도 있으면 true(단, 대상이 로컬 internal 타입이면 호출부에서 걸러진다).
private func extensionExportsPublic(_ ext: ExtensionDeclSyntax) -> Bool {
    if isPublicOrOpen(ext.modifiers) { return true }
    return ext.memberBlock.members.contains { member in
        guard let decl = member.decl.asProtocol(WithModifiersSyntax.self) else { return false }
        return isPublicOrOpen(decl.modifiers)
    }
}

/// 파일 **최상위** 선언 하나를 보고, `public`/`open` 심볼을 모듈 밖으로 노출하는데 허용 대상이 아니면
/// (위반 라벨, 노드)를 반환한다. 허용이거나 애초에 노출이 아니면 nil.
///
/// 두 배타성 규칙(⑫ `factory-exclusivity`·⑬ `feature-exclusivity`)이 **허용 접미사만 바꿔 공유**한다
/// (Data="DataFactory" / Feature="Factory"). 타입 내부 멤버는 바깥 타입이 internal이면 안 새므로 top-level만 본다.
/// `extension`은 확장 대상이 로컬 타입(`localTypeNames`)이면 제외 — 그 멤버 public은 대상이 internal이라 안 새거나
/// 대상이 Factory라 정당하다. 로컬이 아닌(=외부 public) 타입을 확장해 public 멤버를 붙이면 진짜 노출이라 위반.
func publicTopLevelOffense(
    _ item: CodeBlockItemSyntax.Item, allowedSuffix: String, localTypeNames: Set<String>
) -> (label: String, node: Syntax)? {
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
    if let d = item.as(ExtensionDeclSyntax.self) {
        // 로컬 타입 확장은 제외(대상이 internal→안 샘 / 대상이 Factory→정당). 외부 public 타입 확장만 노출로 본다.
        guard !localTypeNames.contains(extendedBaseName(d.extendedType)), extensionExportsPublic(d) else { return nil }
        return ("public extension \(d.extendedType.trimmedDescription)", Syntax(d))
    }
    return nil
}
