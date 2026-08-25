import Foundation
import SwiftParser
import SwiftSyntax

// WSS 아키텍처 검사기 진입점.
// 사용법: arch-lint [repoRoot]   (repoRoot 기본값 ".")
//   <repoRoot>/Projects 아래 .swift 를 모두 파싱해 등록된 규칙을 적용한다.
//   error 위반이 하나라도 있으면 종료코드 1(게이트 실패), warning만 있으면 0.
//   GITHUB_ACTIONS 환경에서는 ::error / ::warning 주석도 emit 해 PR diff에 인라인 표시한다.
//   ARCHLINT_DEBUG=1 이면 스캔·매칭 진단을 stderr로 출력한다.

let repoRoot = CommandLine.arguments.dropFirst().first ?? "."
let isGitHubActions = ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true"
let isDebug = ProcessInfo.processInfo.environment["ARCHLINT_DEBUG"] == "1"

let rules: [Rule] = [
    VMContractRule(),
    ServiceBranchRule(),
    ServiceNoQueryBuildRule()
]

func debugLog(_ message: String) {
    guard isDebug else { return }
    FileHandle.standardError.write(Data(("DEBUG " + message + "\n").utf8))
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

/// 리포트·주석용 레포 루트 기준 경로. GitHub 주석이 PR diff에 붙으려면 워크스페이스
/// 루트 기준 경로여야 하므로, repoRoot 접두(절대·상대 모두)와 선행 "./" 를 벗겨낸다.
func repoRelative(_ path: String) -> String {
    var p = path
    let prefix = repoRoot + "/"
    if p.hasPrefix(prefix) { p.removeFirst(prefix.count) }
    if p.hasPrefix("./") { p.removeFirst(2) }
    return p
}

var allViolations: [Violation] = []
let scanned = swiftFiles(under: repoRoot)
debugLog("scanned .swift files: \(scanned.count)")

for file in scanned {
    let applicable = rules.filter { $0.applies(to: file) }
    guard !applicable.isEmpty else { continue }
    let ids = applicable.map { $0.id }.joined(separator: ",")
    debugLog("applicable [\(ids)] -> \(file)")

    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
        debugLog("read failed -> \(file)")
        continue
    }

    let tree = Parser.parse(source: source)
    let relPath = repoRelative(file)
    let converter = SourceLocationConverter(fileName: relPath, tree: tree)

    for rule in applicable {
        allViolations.append(contentsOf: rule.check(tree, path: relPath, converter: converter))
    }
}

// 출력: 사람이 읽는 줄 + (CI면) GitHub 주석.
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

exit(errorCount > 0 ? 1 : 0)
