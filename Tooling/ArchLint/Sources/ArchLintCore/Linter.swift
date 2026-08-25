import Foundation
import SwiftParser
import SwiftSyntax

/// 등록된 규칙 전체. 새 규칙은 여기 추가한다.
let allRules: [Rule] = [
    VMContractRule(),
    VMStateContractRule(),
    DependencyDirectionRule(),
    ServiceBranchRule(),
    ServiceNoQueryBuildRule()
]

/// 소스 문자열 하나에 규칙을 적용해 위반을 반환한다(테스트 진입점).
/// `path`는 스코프 판정(applies)과 리포트에 함께 쓰인다 → 테스트는 `/Projects/...` 형태로 준다.
func lint(source: String, path: String, rules: [Rule] = allRules) -> [Violation] {
    let tree = Parser.parse(source: source)
    let converter = SourceLocationConverter(fileName: path, tree: tree)
    var result: [Violation] = []
    for rule in rules where rule.applies(to: path) {
        result.append(contentsOf: rule.check(tree, path: path, converter: converter))
    }
    return result
}

/// <repoRoot>/Projects 아래 모든 .swift 파일의 전체 경로.
func swiftFiles(under repoRoot: String) -> [String] {
    let projectsRoot = repoRoot + "/Projects"
    guard let enumerator = FileManager.default.enumerator(atPath: projectsRoot) else {
        FileHandle.standardError.write(Data("ArchLint: Projects 디렉토리를 찾지 못했습니다: \(projectsRoot)\n".utf8))
        return []
    }
    var files: [String] = []
    for case let relative as String in enumerator where relative.hasSuffix(".swift") {
        files.append(projectsRoot + "/" + relative)
    }
    return files.sorted()
}

/// 리포트·주석용 레포 루트 기준 경로(repoRoot 접두·선행 "./" 제거).
func repoRelative(_ path: String, repoRoot: String) -> String {
    var p = path
    let prefix = repoRoot + "/"
    if p.hasPrefix(prefix) { p.removeFirst(prefix.count) }
    if p.hasPrefix("./") { p.removeFirst(2) }
    return p
}

/// 전체 실행: <repoRoot>/Projects 스캔 → 규칙 적용 → 출력 → 종료코드(error>0 이면 1).
/// GitHub Actions 환경이면 ::error/::warning 주석도 emit 한다.
public func runArchLint(repoRoot: String, isGitHubActions: Bool, debug: Bool) -> Int32 {
    func debugLog(_ message: String) {
        guard debug else { return }
        FileHandle.standardError.write(Data(("DEBUG " + message + "\n").utf8))
    }

    var allViolations: [Violation] = []
    let scanned = swiftFiles(under: repoRoot)
    debugLog("scanned .swift files: \(scanned.count)")

    for file in scanned {
        // applies는 전체경로(Projects 앞에 슬래시가 있는)로 판정하고, 리포트는 레포 상대경로로.
        let applicable = allRules.filter { $0.applies(to: file) }
        guard !applicable.isEmpty else { continue }
        debugLog("applicable [\(applicable.map { $0.id }.joined(separator: ","))] -> \(file)")

        guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
            debugLog("read failed -> \(file)")
            continue
        }
        let tree = Parser.parse(source: source)
        let relPath = repoRelative(file, repoRoot: repoRoot)
        let converter = SourceLocationConverter(fileName: relPath, tree: tree)
        for rule in applicable {
            allViolations.append(contentsOf: rule.check(tree, path: relPath, converter: converter))
        }
    }

    allViolations.sort { ($0.path, $0.line) < ($1.path, $1.line) }
    for v in allViolations {
        print("\(v.severity.rawValue.uppercased()) \(v.path):\(v.line) [\(v.ruleID)] \(v.message)")
        if isGitHubActions {
            print("::\(v.severity.rawValue) file=\(v.path),line=\(v.line)::[\(v.ruleID)] \(v.message)")
        }
    }

    let errorCount = allViolations.filter { $0.severity == .error }.count
    let warningCount = allViolations.filter { $0.severity == .warning }.count
    print("ArchLint: error \(errorCount)건, warning \(warningCount)건")
    return errorCount > 0 ? 1 : 0
}
