import Foundation
import SwiftSyntax

/// 규칙⑬ Feature Factory 배타성 — 하드 게이트(error). **모듈 단위 규칙**(`ModuleRule`).
/// 각 Feature 모듈은 조립 진입점 `public *Factory`(+ 명시적 조립 seam)만 외부에 노출한다.
/// View·ViewModel·상태 enum 등 나머지 top-level 선언은 internal이어야 한다.
///
/// Data의 `factory-exclusivity`(⑫)를 Feature로 옮긴 것 — 판정 로직(`publicTopLevelOffense`)은 공유하고
/// **허용 접미사만 `Factory`로** 바꾼다. Feature Factory는 반환을 `some View`(opaque)로 두어야
/// 구체 View/VM이 internal로 숨는다(→ Projects/Feature/CLAUDE.md의 Factory 골격).
///
/// - **Data엔 없는 정당한 예외 — 조립 seam**: Feature 간 직접 의존 없이 App이 콘텐츠를 주입하는 공개 접점
///   (예: SearchFeature의 `KeywordTabContentBuilder`)은 `Sources/Navigation/`에 두고 이 규칙이 허용한다.
///   "화면 간 이동은 App/조정 계층에서" 원칙을 화면 전환이 아니라 콘텐츠 주입으로 적용한 형태라 public이 정당하다.
/// - **정식 모듈만 / top-level만**: `factory-exclusivity`와 동일(유령 폴더·타입 내부 멤버 제외).
///
/// (현재 전 Feature 모듈이 Factory(+Navigation seam)만 public → 베이스라인 초록.)
struct FeatureExclusivityRule: ModuleRule {
    let id = "feature-exclusivity"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        path.hasSuffix(".swift")
            && path.contains("/Projects/Feature/")
            && path.contains("/Sources/")
    }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        guard moduleName.hasSuffix("Feature") else { return [] }

        var violations: [Violation] = []
        for file in files {
            // 조립 seam은 Sources/Navigation/에 둔다 — App이 Feature 간 직접 의존 없이 콘텐츠를 주입하는 공개 접점.
            if file.path.range(of: "/Navigation/", options: .caseInsensitive) != nil { continue }
            let converter = SourceLocationConverter(fileName: file.path, tree: file.tree)
            for statement in file.tree.statements {
                guard let offense = publicTopLevelOffense(statement.item, allowedSuffix: "Factory") else { continue }
                let line = offense.node.startLocation(converter: converter, afterLeadingTrivia: true).line
                violations.append(Violation(
                    path: file.path,
                    line: line,
                    ruleID: id,
                    message: "\(offense.label): Feature 모듈은 조립 진입점 *Factory(+ Navigation/ 조립 seam)만 public으로 노출한다(View·VM 등은 internal, Factory는 some View 반환)",
                    severity: severity
                ))
            }
        }
        return violations
    }
}
