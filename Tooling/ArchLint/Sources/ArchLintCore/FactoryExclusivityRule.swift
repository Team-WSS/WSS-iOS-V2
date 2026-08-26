import Foundation
import SwiftSyntax

/// 규칙⑫ Factory 배타성 — 하드 게이트(error). **모듈 단위 규칙**(`ModuleRule`).
/// 각 비-Base Data 모듈은 조립 진입점 `public *DataFactory` "만" 외부에 노출한다.
/// Repository·Service·Mapper·DTO·Logger 등 나머지 top-level 선언은 전부 internal이어야 한다.
///
/// `factory-existence`(Factory가 **있어야** 한다)의 짝 — 이쪽은 "Factory'만' public"으로 조인다.
/// "상위 레이어는 Factory만 알면 된다"는 Data 레이어 규약(→ Projects/Data/CLAUDE.md)을 구조로 고정.
///
/// - **BaseData 제외**: 공용 토대라 다른 Data 모듈이 직접 import하는 public API(Networking·Storage 등)를 가진다.
/// - **정식 모듈만**: 드라이버가 Project.swift 가진 디렉토리만 넘긴다(레지스트리 밖 유령 폴더 자동 제외).
/// - **top-level만 검사**: 타입 내부 멤버의 `public`은 바깥 타입이 internal이면 모듈 밖으로 새지 않으므로 무해.
///   따라서 SyntaxVisitor로 재귀하지 않고 `tree.statements`(파일 최상위)만 훑는다.
/// - 유일한 허용은 이름이 `DataFactory`로 끝나는 **타입**. 그 외 public/open 최상위 선언
///   (func·var·typealias·extension 포함)은 전부 위반이다(판정은 공유 `publicTopLevelOffense`).
///
/// (현재 12개 비-Base Data 모듈이 Factory만 public → 베이스라인 초록.)
struct FactoryExclusivityRule: ModuleRule {
    let id = "factory-exclusivity"
    let severity: Severity = .error

    func applies(to path: String) -> Bool {
        path.hasSuffix(".swift")
            && path.contains("/Projects/Data/")
            && path.contains("/Sources/")
    }

    func check(moduleName: String, files: [ParsedFile]) -> [Violation] {
        // Data 레이어 모듈만(이름이 Data로 끝남). BaseData는 공용 토대라 제외.
        guard moduleName.hasSuffix("Data"), moduleName != "BaseData" else { return [] }

        var violations: [Violation] = []
        for file in files {
            let converter = SourceLocationConverter(fileName: file.path, tree: file.tree)
            for statement in file.tree.statements {
                guard let offense = publicTopLevelOffense(statement.item, allowedSuffix: "DataFactory") else { continue }
                let line = offense.node.startLocation(converter: converter, afterLeadingTrivia: true).line
                violations.append(Violation(
                    path: file.path,
                    line: line,
                    ruleID: id,
                    message: "\(offense.label): 비-Base Data 모듈은 조립 진입점 *DataFactory만 public으로 노출한다(나머지는 internal)",
                    severity: severity
                ))
            }
        }
        return violations
    }
}
