import Foundation
import SwiftSyntax

// 규칙이 있는 코드를, 그 규칙이 사는 곳에서 직접 테스트한다(#293 원칙 2) — 모듈 단위, error.
// Sources와 Tests를 함께 봐야 해서 ModuleRule로 둔다.

/// 명세 모듈의 Sources·Tests 파일을 나눈 것.
struct SpecModuleFiles {
    let sources: [ParsedFile]
    let tests: [ParsedFile]

    init?(moduleName: String, files: [ParsedFile]) {
        guard TestSpecScope.modules.contains(moduleName) else { return nil }
        sources = files.filter { TestSpecScope.locate($0.path)?.part == "Sources" }
        tests = files.filter { TestSpecScope.locate($0.path)?.part == "Tests" }
    }

    static func applies(to path: String) -> Bool {
        TestSpecScope.contains(path, part: "Sources") || TestSpecScope.contains(path, part: "Tests")
    }
}

private func converter(_ file: ParsedFile) -> SourceLocationConverter {
    SourceLocationConverter(fileName: file.path, tree: file.tree)
}

// MARK: - 넘기기만 하는 코드는 테스트하지 않는다

/// `Default…UseCase`가 저장소 호출을 그대로 넘기기만 하면 그 테스트는 "Mock을 불렀다"만 확인한다.
/// 실제 동작(토큰 저장·삭제 등)은 구현 레이어(Data) 몫이라, 여기 테스트는 아무것도 지키지 못하면서
/// 시그니처를 바꿀 때마다 깨진다. 로직이 생기면(분기·조합·변환) 그때 테스트를 쓴다.
struct TestPassThroughRule: ModuleRule {
    let id = "test-passthrough"
    let severity: Severity = .error

    func applies(to path: String) -> Bool { SpecModuleFiles.applies(to: path) }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        guard let module = SpecModuleFiles(moduleName: moduleName, files: files) else { return [] }
        let passThrough = Set(module.sources.flatMap { PassThroughFinder.passThroughUseCases(in: $0.tree) })
        guard !passThrough.isEmpty else { return [] }

        var violations: [Violation] = []
        for file in module.tests {
            let references = ReferenceCollector()
            references.walk(file.tree)
            let locations = converter(file)
            for (name, node) in references.firstReference where passThrough.contains(name) {
                violations.append(Violation(
                    path: file.path, line: SpecSyntax.line(of: node, locations), ruleID: id,
                    message: "\(name)는 저장소 호출을 넘기기만 한다 — 테스트하지 않는다(실제 동작은 구현 레이어에서 확인)",
                    severity: severity
                ))
            }
        }
        return violations
    }
}

public enum PassThroughFinder {
    /// 모든 메서드가 "저장소 메서드 하나를 받은 인자 그대로 부르기"뿐인 `Default…UseCase` 이름.
    /// 뮤테이션 도구도 이 판정으로 변이 대상에서 뺀다(테스트하지 않기로 한 코드라).
    public static func passThroughUseCases(in tree: SourceFileSyntax) -> [String] {
        tree.statements.compactMap { item in
            guard let decl = item.item.as(ClassDeclSyntax.self),
                  decl.name.text.hasPrefix("Default"), decl.name.text.hasSuffix("UseCase") else { return nil }
            let functions = decl.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            guard !functions.isEmpty, functions.allSatisfy(isForwarding) else { return nil }
            return decl.name.text
        }
    }

    private static func isForwarding(_ function: FunctionDeclSyntax) -> Bool {
        guard let statements = function.body?.statements, statements.count == 1,
              let call = forwardedCall(Syntax(statements.first!.item)),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              member.base != nil else { return false }
        let parameters = Set(function.signature.parameterClause.parameters.map {
            ($0.secondName ?? $0.firstName).text
        })
        return call.arguments.allSatisfy { argument in
            guard let reference = argument.expression.as(DeclReferenceExprSyntax.self) else { return false }
            return parameters.contains(reference.baseName.text)
        }
    }

    private static func forwardedCall(_ node: Syntax) -> FunctionCallExprSyntax? {
        if let statement = node.as(ReturnStmtSyntax.self), let expression = statement.expression {
            return forwardedCall(Syntax(expression))
        }
        if let statement = node.as(ExpressionStmtSyntax.self) { return forwardedCall(Syntax(statement.expression)) }
        if let expression = node.as(TryExprSyntax.self) { return forwardedCall(Syntax(expression.expression)) }
        if let expression = node.as(AwaitExprSyntax.self) { return forwardedCall(Syntax(expression.expression)) }
        return node.as(FunctionCallExprSyntax.self)
    }
}

// MARK: - 분기·throw가 있는 코드는 테스트가 있어야 한다

/// 분기(if·guard·switch·삼항)나 throw가 있는 타입은 규칙을 가진 타입이다 — 테스트에서 한 번은 불려야 한다.
struct TestRequiredRule: ModuleRule {
    let id = "test-required"
    let severity: Severity = .error

    func applies(to path: String) -> Bool { SpecModuleFiles.applies(to: path) }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        guard let module = SpecModuleFiles(moduleName: moduleName, files: files) else { return [] }
        let passThrough = Set(module.sources.flatMap { PassThroughFinder.passThroughUseCases(in: $0.tree) })

        var tested: Set<String> = []
        for file in module.tests {
            let references = ReferenceCollector()
            references.walk(file.tree)
            tested.formUnion(references.firstReference.keys)
        }

        var violations: [Violation] = []
        var reported: Set<String> = []
        for file in module.sources {
            let locations = converter(file)
            for item in file.tree.statements {
                guard let (name, decl) = Self.typeDeclaration(item.item),
                      !passThrough.contains(name), !tested.contains(name), !reported.contains(name) else { continue }
                let branches = RuleBranchFinder()
                branches.walk(decl)
                guard branches.found else { continue }
                reported.insert(name)
                violations.append(Violation(
                    path: file.path, line: SpecSyntax.line(of: decl, locations), ruleID: id,
                    message: "\(name)에 분기·throw가 있는데 테스트가 없다 — 이 규칙을 명세하는 테스트를 쓴다",
                    severity: severity
                ))
            }
        }
        return violations
    }

    /// top-level 타입 선언·확장의 이름과 노드.
    static func typeDeclaration(_ item: CodeBlockItemSyntax.Item) -> (String, Syntax)? {
        if let decl = item.as(StructDeclSyntax.self) { return (decl.name.text, Syntax(decl)) }
        if let decl = item.as(ClassDeclSyntax.self) { return (decl.name.text, Syntax(decl)) }
        if let decl = item.as(EnumDeclSyntax.self) { return (decl.name.text, Syntax(decl)) }
        if let decl = item.as(ActorDeclSyntax.self) { return (decl.name.text, Syntax(decl)) }
        if let decl = item.as(ExtensionDeclSyntax.self) { return (decl.extendedType.trimmedDescription, Syntax(decl)) }
        return nil
    }
}

private final class RuleBranchFinder: SyntaxVisitor {
    private(set) var found = false

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind { mark() }
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind { mark() }
    override func visit(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind { mark() }
    override func visit(_ node: UnresolvedTernaryExprSyntax) -> SyntaxVisitorContinueKind { mark() }
    override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind { mark() }
    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind { mark() }

    private func mark() -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }
}

// MARK: - 검증 에러 case마다 #expect(throws:)

/// `Sources/Entity/`에 있는 에러 enum(검증 에러)은 case마다 그 에러가 나는 상황을 테스트한다.
/// `#expect(throws: X.self)`처럼 타입만 보면 다른 case가 나도 통과하므로 case를 직접 적어야 한다.
struct TestErrorCaseRule: ModuleRule {
    let id = "test-error-case"
    let severity: Severity = .error

    func applies(to path: String) -> Bool { SpecModuleFiles.applies(to: path) }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        guard let module = SpecModuleFiles(moduleName: moduleName, files: files) else { return [] }

        var expected: Set<String> = []
        for file in module.tests {
            let finder = ThrowsExpectationCaseFinder()
            finder.walk(file.tree)
            expected.formUnion(finder.names)
        }

        var violations: [Violation] = []
        for file in module.sources where file.path.contains("/Sources/Entity/") {
            let finder = ErrorEnumFinder()
            finder.walk(file.tree)
            let locations = converter(file)
            for (enumName, element) in finder.cases where !expected.contains(element.name.text) {
                violations.append(Violation(
                    path: file.path, line: SpecSyntax.line(of: element, locations), ruleID: id,
                    message: "\(enumName).\(element.name.text)가 나는 상황을 #expect(throws:)로 확인하는 테스트가 없다",
                    severity: severity
                ))
            }
        }
        return violations
    }
}

private final class ErrorEnumFinder: SyntaxVisitor {
    private(set) var cases: [(String, EnumCaseElementSyntax)] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let inherited = node.inheritanceClause?.inheritedTypes.map { $0.type.trimmedDescription } ?? []
        guard inherited.contains(where: { $0 == "Error" || $0.hasSuffix(".Error") }) else { return .visitChildren }
        for member in node.memberBlock.members {
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements { cases.append((node.name.text, element)) }
        }
        return .visitChildren
    }
}

/// `#expect(throws: …)`의 throws 인자에 적힌 case 이름들.
private final class ThrowsExpectationCaseFinder: SyntaxVisitor {
    private(set) var names: Set<String> = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        collect(node.macroName.text, node.arguments)
        return .visitChildren
    }

    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        collect(node.macroName.text, node.arguments)
        return .visitChildren
    }

    private func collect(_ name: String, _ arguments: LabeledExprListSyntax) {
        guard name == "expect", let first = arguments.first, first.label?.text == "throws" else { return }
        let members = MemberNameCollector()
        members.walk(first.expression)
        names.formUnion(members.names)
    }
}

private final class MemberNameCollector: SyntaxVisitor {
    private(set) var names: Set<String> = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        names.insert(node.declName.baseName.text)
        return .visitChildren
    }
}

// MARK: - 기대값에 소스 상수를 쓰지 않는다

/// `WithdrawalReasonDraft.maxCustomReasonLength`처럼 소스의 `static let`을 테스트에 쓰면,
/// 상수가 잘못 바뀌어도 테스트가 따라 바뀌어 통과한다. 명세의 값(80)을 직접 쓴다.
struct TestSourceConstantRule: ModuleRule {
    let id = "test-source-constant"
    let severity: Severity = .error

    func applies(to path: String) -> Bool { SpecModuleFiles.applies(to: path) }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        guard let module = SpecModuleFiles(moduleName: moduleName, files: files) else { return [] }

        var constants: Set<String> = []
        for file in module.sources {
            let finder = StaticConstantFinder()
            finder.walk(file.tree)
            constants.formUnion(finder.names)
        }
        guard !constants.isEmpty else { return [] }

        var violations: [Violation] = []
        for file in module.tests {
            let finder = TypeMemberAccessFinder()
            finder.walk(file.tree)
            let locations = converter(file)
            for node in finder.accesses where constants.contains(node.declName.baseName.text) {
                violations.append(Violation(
                    path: file.path, line: SpecSyntax.line(of: node, locations), ruleID: id,
                    message: "소스 상수 \(node.trimmedDescription)를 쓴다 — 상수가 틀려도 테스트가 따라간다. 명세의 값을 직접 쓴다",
                    severity: severity
                ))
            }
        }
        return violations
    }
}

private final class StaticConstantFinder: SyntaxVisitor {
    private(set) var names: Set<String> = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let isStatic = node.modifiers.contains { $0.name.text == "static" }
        guard isStatic, node.bindingSpecifier.text == "let" else { return .skipChildren }
        for binding in node.bindings {
            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self) { names.insert(pattern.identifier.text) }
        }
        return .skipChildren
    }
}

/// `Type.member` 모양(앞이 대문자 타입 이름)의 멤버 접근.
private final class TypeMemberAccessFinder: SyntaxVisitor {
    private(set) var accesses: [MemberAccessExprSyntax] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let base = node.base?.as(DeclReferenceExprSyntax.self), base.baseName.text.first?.isUppercase == true {
            accesses.append(node)
        }
        return .visitChildren
    }
}

// MARK: - 공용

/// 파일에서 타입·값 이름이 처음 나온 곳.
final class ReferenceCollector: SyntaxVisitor {
    private(set) var firstReference: [String: Syntax] = [:]

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        record(node.baseName.text, Syntax(node))
        return .visitChildren
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        record(node.name.text, Syntax(node))
        return .visitChildren
    }

    private func record(_ name: String, _ node: Syntax) {
        if firstReference[name] == nil { firstReference[name] = node }
    }
}
