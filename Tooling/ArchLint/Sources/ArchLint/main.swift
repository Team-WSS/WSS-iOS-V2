import Foundation
import ArchLintCore

// 얇은 실행 파일 — 로직은 ArchLintCore. 사용법: arch-lint [repoRoot]  (기본 ".")
//   ARCHLINT_DEBUG=1 이면 스캔·매칭 진단을 stderr로 출력.
let repoRoot = CommandLine.arguments.dropFirst().first ?? "."
let env = ProcessInfo.processInfo.environment
exit(runArchLint(
    repoRoot: repoRoot,
    isGitHubActions: env["GITHUB_ACTIONS"] == "true",
    debug: env["ARCHLINT_DEBUG"] == "1"
))
