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

/// 파싱된 파일 하나(모듈 단위 규칙에 넘기는 단위).
struct ParsedFile {
    let path: String                 // 레포 루트 기준 경로(리포트용)
    let tree: SourceFileSyntax
}

/// 모듈 단위 규칙. 파일 하나가 아니라 **한 모듈에 속한 파일 전체**를 함께 보고 검사한다.
/// 파일 단위 `Rule`로는 "이 모듈에 X가 존재한다" 같은 집계 조건을 표현할 수 없기 때문
/// (예: "각 Data 모듈은 public *DataFactory를 노출한다"는 존재성 규칙).
/// 드라이버(`runArchLint`)가 **Project.swift를 가진 정식 모듈**만 골라(유령 폴더 제외)
/// 모듈별로 `check`를 호출한다.
protocol ModuleRule: Sendable {
    var id: String { get }
    var severity: Severity { get }
    /// 이 파일이 규칙의 관심 대상인지(모듈 그룹핑 시 파싱할 파일을 1차로 거른다).
    func applies(to path: String) -> Bool
    /// 한 모듈의 (applies를 통과한) 파일들을 받아 위반을 반환. moduleName은 모듈 디렉토리명.
    func check(moduleName: String, files: [ParsedFile]) -> [Violation]
}
