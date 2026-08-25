import Foundation
import SwiftSyntax

/// 규칙③ 의존성 방향 — 하드 게이트(error). (non-negotiable #1)
/// 각 모듈의 `Project.swift`가 선언한 internalDependencies를 읽어 레이어 방향을 강제한다.
/// 소스 `import`이 아니라 **매니페스트 선언**을 보는 이유: 선언 안 한 모듈 import는 Tuist가
/// 컴파일 단에서 이미 막는다. 사람이 실수하는 진짜 지점은 Project.swift에 나쁜 의존을 선언하는 순간.
///
/// 허용 방향(실제 클린 코드 엣지 + CLAUDE.md에서 도출):
///   App → Feature → (UI / Domain) ← Data → Core
///   - domain은 domain(+core)만. data/feature/app/ui 의존 금지(#1: Domain은 상위·구현체 모름).
///   - core는 core만(최하위).
///   - data는 domain/core/data. feature/app/ui 금지.
///   - feature는 domain/ui/core/feature. app 금지 + data 금지(Data는 Demo 전용, internalDeps 아님).
///   - ui는 ui/domain(+core). data/feature/app 금지 — ⚠️ ui→domain은 **허용**이다
///     (WSSComponent가 도메인 타입을 렌더하려고 의존, 실제 코드에 있는 정상 엣지).
struct DependencyDirectionRule: Rule {
    let id = "dependency-direction"
    let severity: Severity = .error

    private static let createLayer: [String: String] = [
        "createFeatureModule": "feature",
        "createDomainModule": "domain",
        "createDataModule": "data",
        "createCoreModule": "core",
        "createUIModule": "ui"
    ]
    static let layers: Set<String> = ["domain", "data", "core", "ui", "feature", "app"]
    private static let forbidden: [String: Set<String>] = [
        "domain": ["data", "feature", "app", "ui"],
        "core": ["domain", "data", "feature", "app", "ui"],
        "data": ["feature", "app", "ui"],
        "feature": ["app", "data"],
        "ui": ["data", "feature", "app"]
    ]

    func applies(to path: String) -> Bool {
        path.hasSuffix("/Project.swift") && path.contains("/Projects/")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let finder = CreateCallFinder(createLayer: Self.createLayer)
        finder.walk(tree)
        guard let ownLayer = finder.ownLayer, let depsExpr = finder.internalDepsExpr else { return [] }
        guard let forbid = Self.forbidden[ownLayer], !forbid.isEmpty else { return [] }

        let collector = LayerCollector(layers: Self.layers)
        collector.walk(depsExpr)

        var violations: [Violation] = []
        for (layer, node) in collector.found where forbid.contains(layer) {
            let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
            violations.append(Violation(
                path: path, line: line, ruleID: id,
                message: "\(ownLayer) 모듈이 \(layer)를 의존 — 레이어 방향 위반(App→Feature→(UI/Domain)←Data→Core)",
                severity: severity
            ))
        }
        return violations
    }
}

/// create<Layer>Module(...) 호출을 찾아 자기 레이어와 internalDependencies 인자 식을 잡는다.
private final class CreateCallFinder: SyntaxVisitor {
    private(set) var ownLayer: String?
    private(set) var internalDepsExpr: ExprSyntax?
    private let createLayer: [String: String]

    init(createLayer: [String: String]) {
        self.createLayer = createLayer
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
              let layer = createLayer[member.declName.baseName.text] else {
            return .visitChildren
        }
        ownLayer = layer
        for arg in node.arguments where arg.label?.text == "internalDependencies" {
            internalDepsExpr = arg.expression
        }
        return .skipChildren
    }
}

/// 주어진 식(internalDependencies 배열) 안에서 `.<layer>(...)` 레이어 지시자를 모은다.
/// `.module`·`.base`·`.novelReview` 등은 레이어명이 아니라 걸러진다(모듈명은 레이어명과 겹치지 않음).
private final class LayerCollector: SyntaxVisitor {
    private(set) var found: [(layer: String, node: MemberAccessExprSyntax)] = []
    private let layers: Set<String>

    init(layers: Set<String>) {
        self.layers = layers
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        // 선행 점(base 없음) + 이름이 레이어 집합에 속하면 레이어 지시자.
        if node.base == nil, layers.contains(node.declName.baseName.text) {
            found.append((node.declName.baseName.text, node))
        }
        return .visitChildren
    }
}
