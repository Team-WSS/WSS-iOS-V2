import Foundation
import SwiftSyntax

// #293 "테스트 = 기능 명세" 규칙들이 함께 쓰는 도구 모음.
// 규칙 자체는 Test*Rule.swift 파일들에 있다.

/// 명세 규칙이 적용되는 모듈. **재작성을 마친 모듈만** 넣는다 —
/// 아직 안 고친 모듈까지 넣으면 옛 테스트가 전부 error로 떠서 게이트가 막힌다.
enum TestSpecScope {
    static let modules: Set<String> = ["AuthDomain"]

    /// 경로에서 `Projects/<레이어>/<모듈>/<구역>/…`의 모듈과 구역(Sources·Tests·Testing)을 뽑는다.
    static func locate(_ path: String) -> (module: String, part: String)? {
        let components = path.split(separator: "/").map(String.init)
        guard let index = components.firstIndex(of: "Projects"), components.count > index + 3 else { return nil }
        return (components[index + 2], components[index + 3])
    }

    /// 명세 모듈의 해당 구역(`Tests`·`Testing`·`Sources`)에 있는 Swift 파일인가.
    static func contains(_ path: String, part: String) -> Bool {
        guard path.hasSuffix(".swift"), let location = locate(path) else { return false }
        return modules.contains(location.module) && location.part == part
    }
}

/// `@Test`가 붙은 함수 하나.
struct SpecTest {
    let function: FunctionDeclSyntax
    let attribute: AttributeSyntax
    /// `@Test("…")`의 첫 문자열. 없으면 nil.
    let displayName: String?
    /// `arguments:`에 넘긴 식. 없으면 nil.
    let arguments: ExprSyntax?
    /// 감싼 `@Suite` 타입의 구문 id. `@Suite` 밖이면 nil.
    let suiteID: SyntaxIdentifier?
}

/// `@Suite`가 붙은 타입 하나.
struct SpecSuite {
    let node: Syntax
    let displayName: String?
}

/// 파일에서 `@Suite` 타입과 `@Test` 함수를 모은다.
final class SpecTestCollector: SyntaxVisitor {
    private(set) var tests: [SpecTest] = []
    private(set) var suites: [SpecSuite] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        recordSuite(Syntax(node), node.attributes)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        recordSuite(Syntax(node), node.attributes)
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let attribute = SpecSyntax.attribute(named: "Test", in: node.attributes) else { return .skipChildren }
        tests.append(SpecTest(
            function: node,
            attribute: attribute,
            displayName: SpecSyntax.displayName(of: attribute),
            arguments: SpecSyntax.argument(labeled: "arguments", of: attribute),
            suiteID: enclosingSuiteID(of: node)
        ))
        return .skipChildren
    }

    private func recordSuite(_ node: Syntax, _ attributes: AttributeListSyntax) {
        guard let attribute = SpecSyntax.attribute(named: "Suite", in: attributes) else { return }
        suites.append(SpecSuite(node: node, displayName: SpecSyntax.displayName(of: attribute)))
    }

    /// 함수를 감싼 가장 가까운 타입이 `@Suite`면 그 id.
    private func enclosingSuiteID(of node: FunctionDeclSyntax) -> SyntaxIdentifier? {
        var current = node.parent
        while let parent = current {
            if let decl = parent.as(StructDeclSyntax.self) {
                return SpecSyntax.attribute(named: "Suite", in: decl.attributes) == nil ? nil : decl.id
            }
            if let decl = parent.as(ClassDeclSyntax.self) {
                return SpecSyntax.attribute(named: "Suite", in: decl.attributes) == nil ? nil : decl.id
            }
            current = parent.parent
        }
        return nil
    }
}

/// 구문 트리에서 테스트 관련 모양을 읽는 함수들.
enum SpecSyntax {
    static func attribute(named name: String, in list: AttributeListSyntax) -> AttributeSyntax? {
        for element in list {
            if case .attribute(let attribute) = element, attribute.attributeName.trimmedDescription == name {
                return attribute
            }
        }
        return nil
    }

    static func displayName(of attribute: AttributeSyntax) -> String? {
        guard case .argumentList(let arguments)? = attribute.arguments,
              let first = arguments.first, first.label == nil,
              let literal = first.expression.as(StringLiteralExprSyntax.self) else { return nil }
        return literal.segments.compactMap { $0.as(StringSegmentSyntax.self)?.content.text }.joined()
    }

    static func argument(labeled label: String, of attribute: AttributeSyntax) -> ExprSyntax? {
        guard case .argumentList(let arguments)? = attribute.arguments else { return nil }
        return arguments.first { $0.label?.text == label }?.expression
    }

    /// 문장이 매크로 호출(`#expect`·`#require` 등)이면 이름과 인자. `try`·`await`·`let x =`를 벗겨 본다.
    static func macro(in node: Syntax) -> (name: String, arguments: LabeledExprListSyntax)? {
        if let item = node.as(CodeBlockItemSyntax.self) { return macro(in: Syntax(item.item)) }
        if let statement = node.as(ExpressionStmtSyntax.self) { return macro(in: Syntax(statement.expression)) }
        if let expression = node.as(TryExprSyntax.self) { return macro(in: Syntax(expression.expression)) }
        if let expression = node.as(AwaitExprSyntax.self) { return macro(in: Syntax(expression.expression)) }
        if let expression = node.as(MacroExpansionExprSyntax.self) {
            return (expression.macroName.text, expression.arguments)
        }
        if let declaration = node.as(MacroExpansionDeclSyntax.self) {
            return (declaration.macroName.text, declaration.arguments)
        }
        if let declaration = node.as(VariableDeclSyntax.self),
           declaration.bindings.count == 1,
           let value = declaration.bindings.first?.initializer?.value {
            return macro(in: Syntax(value))
        }
        return nil
    }

    /// `#expect`·`#require` 문장인가.
    static func isAssertion(_ item: CodeBlockItemSyntax) -> Bool {
        guard let name = macro(in: Syntax(item))?.name else { return false }
        return name == "expect" || name == "require"
    }

    /// `#expect(throws: …)` 문장인가.
    static func isThrowsExpectation(_ item: CodeBlockItemSyntax) -> Bool {
        guard let found = macro(in: Syntax(item)), found.name == "expect" else { return false }
        return found.arguments.first?.label?.text == "throws"
    }

    /// 함수 본문을 빈 줄 기준 구역으로 나눈다(준비 / 실행 / 확인).
    static func sections(of body: CodeBlockSyntax) -> [[CodeBlockItemSyntax]] {
        var sections: [[CodeBlockItemSyntax]] = []
        for (index, item) in body.statements.enumerated() {
            if index == 0 || startsAfterBlankLine(item) {
                sections.append([item])
            } else {
                sections[sections.count - 1].append(item)
            }
        }
        return sections
    }

    /// 노드 앞에 빈 줄이 있는가. 주석 줄은 빈 줄로 치지 않는다.
    static func startsAfterBlankLine(_ node: some SyntaxProtocol) -> Bool {
        var newlines = 0
        for piece in node.leadingTrivia {
            switch piece {
            case .newlines(let count), .carriageReturnLineFeeds(let count), .carriageReturns(let count):
                newlines += count
                if newlines >= 2 { return true }
            case .spaces, .tabs:
                continue
            default:
                newlines = 0
            }
        }
        return false
    }

    static func line(of node: some SyntaxProtocol, _ converter: SourceLocationConverter) -> Int {
        node.startLocation(converter: converter, afterLeadingTrivia: true).line
    }

    static func hasHangul(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
    }
}

/// 노드 아래에서 이름이 같은 매크로 호출을 센다.
final class MacroCounter: SyntaxVisitor {
    private(set) var names: [String] = []

    init() { super.init(viewMode: .sourceAccurate) }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        names.append(node.macroName.text)
        return .visitChildren
    }

    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        names.append(node.macroName.text)
        return .visitChildren
    }
}

/// `// archlint:allow <규칙 id> — 이유`가 위반 줄이나 바로 윗줄에 있으면 그 위반을 뺀다.
/// 이유가 비어 있으면 빼지 않는다 — 예외는 왜 예외인지 남겨야 사람이 리뷰할 수 있다.
enum AllowComment {
    static func filter(_ violations: [Violation], lines: (String) -> [String]?) -> [Violation] {
        violations.filter { violation in
            guard let fileLines = lines(violation.path) else { return true }
            let candidates = [violation.line - 1, violation.line - 2].filter { fileLines.indices.contains($0) }
            return !candidates.contains { allows(fileLines[$0], ruleID: violation.ruleID) }
        }
    }

    static func allows(_ line: String, ruleID: String) -> Bool {
        let marker = "archlint:allow " + ruleID
        guard let range = line.range(of: marker) else { return false }
        let rest = line[range.upperBound...]
        // 접두만 같은 다른 규칙(test-aaa vs test-aaa-act)을 막는다.
        if let next = rest.first, next != " " { return false }
        let reason = rest.trimmingCharacters(in: CharacterSet(charactersIn: " —-:").union(.whitespaces))
        return !reason.isEmpty
    }
}
