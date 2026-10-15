import ArchLintCore
import Foundation
import SwiftParser
import SwiftSyntax

/// 소스에 심는 버그 하나.
public struct Mutant: Sendable, Equatable {
    public let path: String
    public let line: Int
    public let original: String
    public let replacement: String
    /// 바꿀 구간(UTF-8 바이트 오프셋).
    let start: Int
    let end: Int

    public var summary: String {
        let shown = original.split(separator: "\n").first.map(String.init) ?? original
        return replacement.isEmpty ? "`\(shown)` 삭제" : "`\(shown)` → `\(replacement)`"
    }

    public func apply(to source: String) -> String {
        var bytes = Array(source.utf8)
        bytes.replaceSubrange(start..<end, with: Array(replacement.utf8))
        return String(decoding: bytes, as: UTF8.self)
    }
}

/// 소스 하나에서 심을 수 있는 버그를 모두 만든다.
/// - 비교·논리·산술 연산자 뒤집기(`<`↔`<=`, `==`↔`!=`, `&&`↔`||`, `+`↔`-`)
/// - `!` 지우기, `true`↔`false`, 정수 +1(경계값)
/// - 문장 지우기(대입·호출·guard·if) — 그 문장이 하는 일을 테스트가 보는지
/// 넘기기만 하는 `Default…UseCase`는 테스트하지 않기로 한 코드라 건너뛴다.
public enum MutantGenerator {
    public static func mutants(in source: String, path: String) -> [Mutant] {
        let tree = Parser.parse(source: source)
        let skipped = Set(PassThroughFinder.passThroughUseCases(in: tree))
        let visitor = MutantVisitor(path: path, converter: SourceLocationConverter(fileName: path, tree: tree), skipped: skipped)
        visitor.walk(tree)
        return visitor.mutants
    }
}

private final class MutantVisitor: SyntaxVisitor {
    private(set) var mutants: [Mutant] = []
    private let path: String
    private let converter: SourceLocationConverter
    private let skipped: Set<String>

    private static let operatorSwaps: [String: String] = [
        "==": "!=", "!=": "==",
        "<": "<=", "<=": "<", ">": ">=", ">=": ">",
        "&&": "||", "||": "&&",
        "+": "-", "-": "+"
    ]

    init(path: String, converter: SourceLocationConverter, skipped: Set<String>) {
        self.path = path
        self.converter = converter
        self.skipped = skipped
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        skipped.contains(node.name.text) ? .skipChildren : .visitChildren
    }

    override func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if let swapped = Self.operatorSwaps[node.operator.text] {
            add(node.operator, swapped)
        }
        return .visitChildren
    }

    override func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        if node.operator.text == "!" {
            add(node, node.expression.trimmedDescription)
        }
        return .visitChildren
    }

    override func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        add(node, node.literal.text == "true" ? "false" : "true")
        return .visitChildren
    }

    override func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        // Int.max에 1을 더하면 넘친다 — 그런 리터럴은 건너뛴다.
        if let value = Int(node.literal.text.replacingOccurrences(of: "_", with: "")), value < Int.max {
            add(node, String(value + 1))
        }
        return .visitChildren
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if isDeletable(node) { add(node, "") }
        return .visitChildren
    }

    /// 함수·생성자·접근자 본문의 대입·호출·guard·if 문장. 선언과 return은 지우면 컴파일이 안 되거나 의미가 없어 뺀다.
    private func isDeletable(_ node: CodeBlockItemSyntax) -> Bool {
        guard node.parent?.parent?.is(CodeBlockSyntax.self) == true else { return false }
        switch node.item {
        case .expr:
            return true
        case .stmt(let statement):
            if statement.is(GuardStmtSyntax.self) { return true }
            return statement.as(ExpressionStmtSyntax.self) != nil
        case .decl:
            return false
        }
    }

    private func add(_ node: some SyntaxProtocol, _ replacement: String) {
        let start = node.positionAfterSkippingLeadingTrivia.utf8Offset
        let end = node.endPositionBeforeTrailingTrivia.utf8Offset
        mutants.append(Mutant(
            path: path,
            line: node.startLocation(converter: converter, afterLeadingTrivia: true).line,
            original: node.trimmedDescription,
            replacement: replacement,
            start: start,
            end: end
        ))
    }
}
