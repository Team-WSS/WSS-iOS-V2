import Foundation
import SwiftSyntax

/// 규칙⑪ Factory 존재성 — 하드 게이트(error). **모듈 단위 규칙**(`ModuleRule`).
/// 각 Data 모듈은 조립 진입점인 `public *DataFactory`(enum/struct/class)를 1개 이상 노출해야 한다.
/// "상위 레이어는 Factory만 알면 된다"는 Data 레이어 규약(→ Projects/Data/CLAUDE.md)을 구조적으로 고정.
///
/// - **BaseData 제외**: 공용 토대 모듈이라 도메인 repository용 Factory 의무 대상이 아니다
///   (실제로 `KeywordDataFactory`를 갖고 있긴 하나, 그 존재를 강제하지는 않는다).
/// - **정식 모듈만**: 드라이버가 Project.swift 가진 디렉토리만 넘기므로, 레지스트리 밖 유령 폴더
///   (예: `KeywordData/` — Derived/.xcodeproj 잔재, Project.swift 없음)는 애초에 대상이 아니다.
/// - 파일 단위 `Rule`로는 "모듈에 X가 있다"를 표현할 수 없어 `ModuleRule`로 둔다.
/// (현재 12개 비-Base Data 모듈 전부 public *DataFactory 보유 → 베이스라인 초록.)
struct FactoryExistenceRule: ModuleRule {
    let id = "factory-existence"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        path.hasSuffix(".swift")
            && path.contains("/Projects/Data/")
            && path.contains("/Sources/")
    }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        // Data 레이어 모듈만(이름이 Data로 끝남 — Domain/Feature/Core/UI와 겹치지 않음). BaseData는 제외.
        guard moduleName.hasSuffix("Data"), moduleName != "BaseData" else { return [] }

        let hasFactory = files.contains { file in
            file.tree.statements.contains { Self.isPublicDataFactory($0.item) }
        }
        guard !hasFactory else { return [] }

        return [Violation(
            path: "Projects/Data/\(moduleName)",
            line: 1,
            ruleID: id,
            message: "\(moduleName): public *DataFactory 없음 — 각 Data 모듈은 조립 진입점 Factory를 노출한다",
            severity: severity
        )]
    }

    /// top-level 선언이 `public`(또는 `open`) + 이름이 `DataFactory`로 끝나는 타입(enum/struct/class/actor)인가.
    private static func isPublicDataFactory(_ item: CodeBlockItemSyntax.Item) -> Bool {
        func hit(_ name: TokenSyntax, _ modifiers: DeclModifierListSyntax) -> Bool {
            isPublic(modifiers) && name.text.hasSuffix("DataFactory")
        }
        if let d = item.as(EnumDeclSyntax.self) { return hit(d.name, d.modifiers) }
        if let d = item.as(StructDeclSyntax.self) { return hit(d.name, d.modifiers) }
        if let d = item.as(ClassDeclSyntax.self) { return hit(d.name, d.modifiers) }
        if let d = item.as(ActorDeclSyntax.self) { return hit(d.name, d.modifiers) }
        return false
    }

    private static func isPublic(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.text == "public" || $0.name.text == "open" }
    }
}
