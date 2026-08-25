import Foundation
import SwiftSyntax

/// 위반 심각도. error는 게이트를 실패시키고, warning은 리포트만 한다.
/// (A4 철학: warning으로 수집하다 프록시 정확도가 검증되면 error로 승격.)
enum Severity: String {
    case error
    case warning
}

/// 한 건의 규칙 위반.
struct Violation {
    let path: String   // 레포 루트 기준 경로
    let line: Int
    let ruleID: String
    let message: String
    let severity: Severity
}

/// 아키텍처 규칙. 각 규칙은 자신이 적용될 파일을 스스로 판정하고(applies),
/// 파싱된 구문 트리에서 위반을 찾는다(check).
protocol Rule: Sendable {
    var id: String { get }
    var severity: Severity { get }
    /// 이 규칙이 해당 파일에 적용되는가(경로 기반 스코프).
    func applies(to path: String) -> Bool
    /// 위반 목록을 반환. path는 레포 루트 기준 경로(리포트·주석용).
    func check(_ tree: SourceFileSyntax, path: String, converter: SourceLocationConverter) -> [Violation]
}
