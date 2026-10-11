import Foundation
import SwiftSyntax

/// 규칙⑮ 테스트 명세 형식 — "테스트는 읽히는 기능 명세"(docs/TESTING.md)를 문법으로 검사한다.
/// `Projects/**/Tests/`의 Swift Testing 코드가 대상이다. `Testing/`(Mock)은 테스트 코드가 아니라 제외한다.
///
/// `enforcedModules`에 든 모듈만 검사하고 다른 모듈은 보고하지 않는다 — 고칠 계획이 없는 경고가 CI 로그를
/// 덮지 않게 하려는 것. 모듈을 목록에 넣으면 위반이 한꺼번에 드러나고, error · warning을 0으로 청소한 뒤
/// 머지한다(A1 교훈: 초록으로 만든 뒤 승격).
///
/// 한 규칙이 하위 규칙 여러 개를 낸다(ruleID로 구분).
/// - 구조(S1 ~ S5, error): 문법이 곧 위반이다.
///   - `test-suite-required` S1: `@Test`는 `@Suite`를 붙인 타입 안에 둔다(extension은 같은 파일에 선언된 타입만 본다)
///   - `test-suite-name` S2: `@Suite("한국어 이름")` + 타입 이름은 `…Tests`
///   - `test-name-sentence` S3: `@Test("…다")` 보간 없는 한국어 문장(끝의 괄호 보충 · 마침표는 뗀다)
///   - `test-name-slash` S4: 표시 이름에 `/` 금지 — XcodeBuildMCP 리포터가 스위트 구분자로 읽는다
///   - `test-name-duplicate` S5: 같은 파일의 같은 Suite(extension 포함) 안에서 표시 이름이 겹치지 않는다
/// - 프록시(warning): 문법이 위반의 근사치일 뿐이라 막지 않는다. 그래도 적용 모듈에서는 0으로 유지한다.
///   - `test-assertion` S6: 본문에 `#expect`/`#require`가 있다(헬퍼 안에서 단언하면 오탐)
///   - `test-func-verb` W1: 함수 이름은 3인칭 동사로 시작하는 영어 lowerCamelCase(`rejects…` · `doesNot…`)
///   - `test-name-vague` W2: 결과를 감추는 모호어 금지 — 무엇이 어떻게 되는지를 쓴다
///   - `test-name-identifier` W3: Domain · Feature 표시 이름에 메서드 · 프로퍼티 이름 금지(타입 이름은 허용).
///     Core 등은 식별자 자체가 계약(예: `withoutToken`)이라 제외한다.
struct TestSpecRule: Rule {
    let id = "test-spec"
    let severity: Severity = .error
    let enforcedModules: Set<String>

    func applies(to path: String) -> Bool {
        path.hasSuffix(".swift") && path.contains("/Projects/") && path.contains("/Tests/")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let location = ModuleLocation(path: path)
        guard enforcedModules.contains(location.module) else { return [] }
        let visitor = TestSpecVisitor(
            path: path,
            converter: converter,
            checksIdentifiers: location.layer == "Domain" || location.layer == "Feature"
        )
        visitor.walk(tree)
        return visitor.violations
    }
}

/// `…/Projects/<Layer>/<Module>/…`에서 레이어와 모듈 이름을 꺼낸다. 전체 경로 · 레포 상대 경로 모두 받는다.
private struct ModuleLocation {
    let layer: String
    let module: String

    init(path: String) {
        let components = path.split(separator: "/").map(String.init)
        guard let index = components.firstIndex(of: "Projects"), index + 2 < components.count else {
            layer = ""
            module = ""
            return
        }
        layer = components[index + 1]
        module = components[index + 2]
    }
}

private enum DisplayName {
    case missing
    case interpolated
    case literal(String)
}

/// 테스트를 감싼 타입 하나. `@Test`를 만나면 가장 안쪽 프레임에 표시하고, 타입을 나갈 때 S1을 판정한다 —
/// 직접 멤버만 보면 `#if` 안의 `@Test`를 놓친다.
private struct TypeFrame {
    enum Kind {
        case suite
        case plain(TokenSyntax)
        case `extension`(TypeSyntax)
    }

    let name: String
    let kind: Kind
    var hasTests = false
}

private final class TestSpecVisitor: SyntaxVisitor {
    private static let vagueWords = ["성공적으로", "정상적으로", "올바르게", "제대로"]

    private(set) var violations: [Violation] = []
    private let path: String
    private let converter: SourceLocationConverter
    private let structuralSeverity: Severity = .error
    private let checksIdentifiers: Bool
    /// 감싼 타입 스택(extension은 확장한 타입 경로). 비어 있으면 파일 최상위다.
    private var frames: [TypeFrame] = []
    /// 타입 전체 경로(`OuterTests.InnerTests`)별로 본 표시 이름 — 같은 파일의 extension에 나눠 둔 테스트도 같은 Suite로 본다.
    private var seenNames: [String: Set<String>] = [:]
    /// 이 파일에서 `@Suite` 없이 선언한 타입 경로 — 같은 파일 extension의 `@Test`를 S1로 잡는 데 쓴다.
    private var plainTypePaths: Set<String> = []
    /// `@Test`를 담은 extension(확장한 타입 경로, 위치). 파일을 다 본 뒤 `plainTypePaths`와 대조한다.
    private var extensionsWithTests: [(path: String, node: TypeSyntax)] = []

    init(path: String, converter: SourceLocationConverter, checksIdentifiers: Bool) {
        self.path = path
        self.converter = converter
        self.checksIdentifiers = checksIdentifiers
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: - 타입

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind { enterType(node) }
    override func visitPost(_ node: StructDeclSyntax) { leaveType() }
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind { enterType(node) }
    override func visitPost(_ node: ClassDeclSyntax) { leaveType() }
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind { enterType(node) }
    override func visitPost(_ node: EnumDeclSyntax) { leaveType() }
    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind { enterType(node) }
    override func visitPost(_ node: ActorDeclSyntax) { leaveType() }

    /// extension은 원래 타입의 `@Suite`를 직접 볼 수 없어 이름만 쌓고, 같은 파일의 선언과는 파일 끝에서 대조한다.
    /// 다른 파일에 선언된 타입은 볼 수 없다(파일 단위 검사의 한계).
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        // `ATests . InnerTests`처럼 띄어 써도 선언 경로(`ATests.InnerTests`)와 맞춘다
        let name = node.extendedType.trimmedDescription.filter { !$0.isWhitespace }
        frames.append(TypeFrame(name: name, kind: .extension(node.extendedType)))
        return .visitChildren
    }
    override func visitPost(_ node: ExtensionDeclSyntax) { leaveType() }

    override func visitPost(_ node: SourceFileSyntax) {
        for (path, node) in extensionsWithTests where plainTypePaths.contains(path) {
            report(node, "test-suite-required", structuralSeverity,
                   "\(path): @Test를 담은 extension의 원래 타입에 @Suite(\"한국어 이름\")를 붙인다")
        }
    }

    private func enterType(_ node: some DeclGroupSyntax & NamedDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text

        guard let suite = attribute("Suite", in: node.attributes) else {
            frames.append(TypeFrame(name: name, kind: .plain(node.name)))
            plainTypePaths.insert(typePath)
            return .visitChildren
        }
        frames.append(TypeFrame(name: name, kind: .suite))

        if !name.hasSuffix("Tests") {
            report(node.name, "test-suite-name", structuralSeverity, "\(name): @Suite 타입 이름은 Tests로 끝낸다")
        }
        switch displayName(of: suite) {
        case .missing:
            report(suite, "test-suite-name", structuralSeverity,
                   "\(name): @Suite에 한국어 표시 이름이 없다 — 기능 단위 명사구로 쓴다(@Suite(\"작품 평가\"))")
        case .interpolated:
            report(suite, "test-suite-name", structuralSeverity, "\(name): @Suite 표시 이름은 보간 없는 문자열 리터럴로 쓴다")
        case .literal(let text) where !containsHangul(text):
            report(suite, "test-suite-name", structuralSeverity, "\(name): @Suite 표시 이름은 한국어로 쓴다: \"\(text)\"")
        case .literal(let text):
            checkSlash(text, at: suite)
        }
        return .visitChildren
    }

    private func leaveType() {
        let path = typePath
        let frame = frames.removeLast()
        guard frame.hasTests else { return }
        switch frame.kind {
        case .suite:
            break
        case .plain(let name):
            report(name, "test-suite-required", structuralSeverity,
                   "\(frame.name): @Test를 담은 타입에는 @Suite(\"한국어 이름\")를 붙인다")
        case .extension(let type):
            extensionsWithTests.append((path, type))
        }
    }

    private var typePath: String {
        frames.map(\.name).joined(separator: ".")
    }

    // MARK: - 테스트

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let test = attribute("Test", in: node.attributes) else { return .visitChildren }
        let name = node.name.text

        if frames.isEmpty {
            report(test, "test-suite-required", structuralSeverity,
                   "func \(name): @Test는 @Suite(\"한국어 이름\")를 붙인 타입 안에 둔다")
        } else {
            frames[frames.count - 1].hasTests = true
        }

        switch displayName(of: test) {
        case .missing:
            report(test, "test-name-sentence", structuralSeverity,
                   "func \(name): @Test에 한국어 표시 이름이 없다 — 동작을 설명하는 '…다' 문장으로 쓴다")
        case .interpolated:
            report(test, "test-name-sentence", structuralSeverity, "func \(name): @Test 표시 이름은 보간 없는 문자열 리터럴로 쓴다")
        case .literal(let text) where !containsHangul(text):
            report(test, "test-name-sentence", structuralSeverity, "func \(name): @Test 표시 이름은 한국어로 쓴다: \"\(text)\"")
        case .literal(let text):
            if !endsAsSentence(text) {
                report(test, "test-name-sentence", structuralSeverity,
                       "func \(name): @Test 표시 이름은 '…다'로 끝나는 문장으로 쓴다(보충은 끝에 괄호로): \"\(text)\"")
            }
            checkSlash(text, at: test)
            checkDuplicate(text, at: test)
            checkVagueWords(text, at: test)
            if checksIdentifiers {
                checkCodeIdentifiers(text, at: test)
            }
        }

        if !startsWithThirdPersonVerb(name) {
            report(node.name, "test-func-verb", .warning,
                   "func \(name): 함수 이름은 3인칭 동사로 시작하는 영어 lowerCamelCase로 쓴다(rejects… · returns… · doesNot…)")
        }
        if let body = node.body, !AssertionFinder.contains(body) {
            report(test, "test-assertion", .warning, "func \(name): 본문에 #expect · #require가 없다 — 무엇을 확인하는지 드러낸다")
        }
        return .skipChildren
    }

    // MARK: - 표시 이름 검사

    private func checkSlash(_ text: String, at node: some SyntaxProtocol) {
        guard text.contains("/") else { return }
        report(node, "test-name-slash", structuralSeverity,
               "표시 이름에 '/'를 쓰지 않는다 — XcodeBuildMCP가 스위트 구분자로 읽어 이름을 쪼갠다: \"\(text)\"")
    }

    private func checkDuplicate(_ text: String, at node: some SyntaxProtocol) {
        guard !frames.isEmpty else { return }
        // 짧은 이름을 키로 쓰면 다른 Suite에 중첩된 동명 타입(`SuccessTests`)끼리 겹친다
        let typeName = typePath
        let (inserted, _) = seenNames[typeName, default: []].insert(text)
        if !inserted {
            report(node, "test-name-duplicate", structuralSeverity, "\(typeName): 같은 Suite에 같은 표시 이름이 있다: \"\(text)\"")
        }
    }

    private func checkVagueWords(_ text: String, at node: some SyntaxProtocol) {
        guard let word = Self.vagueWords.first(where: text.contains) else { return }
        report(node, "test-name-vague", .warning,
               "'\(word)'는 확인하는 결과를 감춘다 — 무엇이 어떻게 되는지 쓴다: \"\(text)\"")
    }

    /// 소문자로 시작하고 대문자가 섞인 ASCII 낱말(`markAsInterested`) · 호출 표기(`save()`)를 코드 식별자로 본다.
    /// 대문자로 시작하는 타입 이름(`RepositoryError`)은 도메인 용어로 보고 허용한다.
    private func checkCodeIdentifiers(_ text: String, at node: some SyntaxProtocol) {
        let scalars = Array(text.unicodeScalars)
        var index = 0
        while index < scalars.count {
            guard isIdentifierScalar(scalars[index]) else {
                index += 1
                continue
            }
            let start = index
            while index < scalars.count, isIdentifierScalar(scalars[index]) {
                index += 1
            }
            let word = String(String.UnicodeScalarView(scalars[start..<index]))
            let isLowerCamel = word.first?.isLowercase == true && word.contains(where: \.isUppercase)
            let isCall = index + 1 < scalars.count && scalars[index] == "(" && scalars[index + 1] == ")"
            if isLowerCamel || isCall {
                report(node, "test-name-identifier", .warning,
                       "표시 이름에 코드 식별자 '\(word)'가 있다 — 구현 이름 대신 동작을 쓴다: \"\(text)\"")
                return
            }
        }
    }

    // MARK: - 도움

    private func attribute(_ name: String, in attributes: AttributeListSyntax) -> AttributeSyntax? {
        for element in attributes {
            if let attribute = element.as(AttributeSyntax.self),
               [name, "Testing.\(name)"].contains(attribute.attributeName.trimmedDescription) {
                return attribute
            }
        }
        return nil
    }

    /// 첫 인자가 레이블 없는 문자열 리터럴일 때만 표시 이름이다. `@Test(.tags(…))`처럼 트레이트로 시작하면 없는 것이다.
    private func displayName(of attribute: AttributeSyntax) -> DisplayName {
        guard case .argumentList(let arguments)? = attribute.arguments,
              let first = arguments.first, first.label == nil,
              let literal = first.expression.as(StringLiteralExprSyntax.self)
        else { return .missing }
        var text = ""
        for segment in literal.segments {
            guard case .stringSegment(let part) = segment else { return .interpolated }
            text += part.content.text
        }
        return .literal(text)
    }

    /// 마침표 → 끝 괄호 보충 → 마침표 순으로 떼고 '다'를 본다(`다. (보충)` · `다(보충).` 둘 다 허용).
    private func endsAsSentence(_ text: String) -> Bool {
        var sentence = text.trimmingCharacters(in: .whitespaces)
        if sentence.hasSuffix(".") {
            sentence.removeLast()
        }
        if let open = openingOfTrailingParenthesis(in: sentence) {
            sentence = sentence[..<open].trimmingCharacters(in: .whitespaces)
        }
        if sentence.hasSuffix(".") {
            sentence.removeLast()
        }
        return sentence.hasSuffix("다")
    }

    /// 끝의 `)`와 짝이 맞는 `(` 위치 — 보충 안에 괄호가 중첩돼도(`(a(b))`) 바깥 괄호를 찾는다.
    private func openingOfTrailingParenthesis(in text: String) -> String.Index? {
        guard text.hasSuffix(")") else { return nil }
        var depth = 0
        var index = text.endIndex
        while index > text.startIndex {
            index = text.index(before: index)
            switch text[index] {
            case ")": depth += 1
            case "(":
                depth -= 1
                if depth == 0 { return index }
            default: break
            }
        }
        return nil
    }

    /// 첫 낱말(연속 소문자)이 s로 끝나는지 — rejects · returns · does(NotRetry) · is
    private func startsWithThirdPersonVerb(_ name: String) -> Bool {
        let isAlphanumeric = name.unicodeScalars.allSatisfy { $0.isASCII && CharacterSet.alphanumerics.contains($0) }
        guard isAlphanumeric, name.first?.isLowercase == true else { return false }
        return name.prefix(while: \.isLowercase).hasSuffix("s")
    }

    private func containsHangul(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
    }

    private func isIdentifierScalar(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "_")
    }

    private func report(_ node: some SyntaxProtocol, _ ruleID: String, _ severity: Severity, _ message: String) {
        let line = node.startLocation(converter: converter, afterLeadingTrivia: true).line
        violations.append(Violation(path: path, line: line, ruleID: ruleID, message: message, severity: severity))
    }
}

/// 함수 본문에서 `#expect` · `#require` 매크로를 찾는다(중첩 클로저 안 포함).
private final class AssertionFinder: SyntaxVisitor {
    private static let names: Set<String> = ["expect", "require"]
    private(set) var found = false

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        if Self.names.contains(node.macroName.text) { found = true }
        return found ? .skipChildren : .visitChildren
    }

    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        if Self.names.contains(node.macroName.text) { found = true }
        return found ? .skipChildren : .visitChildren
    }

    static func contains(_ node: some SyntaxProtocol) -> Bool {
        let finder = AssertionFinder(viewMode: .sourceAccurate)
        finder.walk(node)
        return finder.found
    }
}
