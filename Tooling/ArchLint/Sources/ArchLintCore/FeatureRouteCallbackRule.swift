import Foundation
import SwiftSyntax

/// 규칙⑭ Feature 라우트 콜백 — 프록시(warning).
/// Feature 모듈의 **public 함수**(사실상 `*FeatureFactory`의 make 진입점 — ⑬이 그 외 public을 막는다)가
/// 화면 전환 의도 콜백을 낱개 클로저(`onXxxTapped:`/`onXxxSelected:`)로 받으면 경고한다 —
/// 모듈별 `*Route` enum + `onRoute:` 단일 클로저로 통일한다(#253, 패턴 정본은
/// `NovelDetailFeature/Sources/Navigation/NovelDetailRoute.swift`).
///
/// 왜 이 패턴인가: 낱개 클로저는 기본값 no-op가 배선 누락을 조용히 삼킨 전례가 있고(#228의 죽은
/// "수정" 버튼), Route enum은 App 쪽 exhaustive switch가 케이스 추가를 컴파일 타임에 강제한다.
///
/// 왜 warning인가(A4 철학): `on…Tapped/Selected`가 화면 전환 의도라는 건 이 레포의 네이밍 관행에
/// 기댄 **프록시**다(문법==의미가 아님). 비-라우팅 콜백(세션 이벤트 `onAuthenticationRequired`,
/// 완료 결과 `onSubmitted`/`onSaved`/`onUserBlocked` 등)은 과거형·명사형 네이밍이라 이 패턴에
/// 안 걸리는 게 정상 — 걸리지 않는 이름으로 우회하는 신종 낱개 라우팅 콜백까지 잡지는 못한다.
/// ⚠️ 실제 미탐 전례: `on…Requested`·`onBrowseNovels`류는 이 패턴 밖이라 #253 전파 때 `onBrowseNovels`가
/// 라우팅 의도인 채 새어나갔다(리뷰가 잡아 Route로 편입) — 이 패턴 밖 이름의 화면 전환 콜백은 리뷰가 본다.
/// internal 함수·서브뷰의 로컬 `onXxxTapped`는 모듈 경계가 아니므로 대상이 아니다(public만).
struct FeatureRouteCallbackRule: Rule {
    let id = "feature-route-callback"
    let severity: Severity = .warning

    func applies(to path: String) -> Bool {
        path.hasSuffix(".swift")
            && path.contains("/Projects/Feature/")
            && path.contains("/Sources/")
    }

    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation] {
        let visitor = FeatureRouteCallbackVisitor(ruleID: id, severity: severity, path: path, converter: converter)
        visitor.walk(tree)
        return visitor.violations
    }
}

private final class FeatureRouteCallbackVisitor: SyntaxVisitor {
    private(set) var violations: [Violation] = []
    private let ruleID: String
    private let severity: Severity
    private let path: String
    private let converter: SourceLocationConverter

    init(ruleID: String, severity: Severity, path: String, converter: SourceLocationConverter) {
        self.ruleID = ruleID
        self.severity = severity
        self.path = path
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard Self.isEffectivelyPublic(node) else { return .visitChildren }

        for param in node.signature.parameterClause.parameters {
            let label = param.firstName.text
            guard Self.isRouteStyleCallbackName(label), Self.isClosureType(param.type) else { continue }
            let line = param.startLocation(converter: converter, afterLeadingTrivia: true).line
            violations.append(Violation(
                path: path, line: line, ruleID: ruleID,
                message: "\(label): 화면 전환 의도는 낱개 클로저가 아니라 모듈 Route enum + onRoute: (XxxRoute) -> Void 하나로 노출한다(#253)",
                severity: severity
            ))
        }
        return .visitChildren
    }

    /// 함수 자신에 `public`이 없어도 `public extension` 안이면 실질 public이다 —
    /// `public extension XxxFeatureFactory { static func makeView(...) }` 형태의 미탐을 막는다.
    /// (조상에 명시 접근제어가 있는 함수는 자기 modifier가 우선이므로 함수 쪽을 먼저 본다.)
    private static func isEffectivelyPublic(_ node: FunctionDeclSyntax) -> Bool {
        if node.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) }) { return true }
        // 자기 자신에 다른 접근제어가 명시돼 있으면 public이 아니다(예: public extension 안의 private func).
        let accessKeywords: [TokenKind] = [
            .keyword(.private), .keyword(.fileprivate), .keyword(.internal), .keyword(.package)
        ]
        if node.modifiers.contains(where: { accessKeywords.contains($0.name.tokenKind) }) { return false }
        var current: Syntax? = node.parent
        while let ancestor = current {
            if let ext = ancestor.as(ExtensionDeclSyntax.self) {
                return ext.modifiers.contains { $0.name.tokenKind == .keyword(.public) }
            }
            current = ancestor.parent
        }
        return false
    }

    /// 화면 전환 의도로 쓰여 온 콜백 네이밍 — `on` + 대문자 시작 + `Tapped`/`Selected` 종결.
    private static func isRouteStyleCallbackName(_ name: String) -> Bool {
        guard name.hasPrefix("on"), name.count > 2 else { return false }
        let third = name[name.index(name.startIndex, offsetBy: 2)]
        guard third.isUppercase else { return false }
        return name.hasSuffix("Tapped") || name.hasSuffix("Selected")
    }

    /// 파라미터 타입이 클로저인가 — `@escaping` 등 attribute 래핑을 벗기고 함수 타입인지 본다.
    private static func isClosureType(_ type: TypeSyntax) -> Bool {
        if let attributed = type.as(AttributedTypeSyntax.self) {
            return isClosureType(attributed.baseType)
        }
        if let optional = type.as(OptionalTypeSyntax.self) {
            return isClosureType(optional.wrappedType)
        }
        if let tuple = type.as(TupleTypeSyntax.self), tuple.elements.count == 1,
           let only = tuple.elements.first {
            return isClosureType(only.type)
        }
        return type.is(FunctionTypeSyntax.self)
    }
}
