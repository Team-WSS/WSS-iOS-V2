import Foundation
import ArchLintCore

// 얇은 실행 파일 — 로직은 ArchLintCore. 사용법: arch-lint [--write-test-specs] [repoRoot]  (기본 ".")
//   --write-test-specs: 명세 모듈의 테스트 목록 파일(TEST_SPEC.md)을 새로 쓴다(없으면 최신인지 검사만).
//   ARCHLINT_DEBUG=1 이면 스캔·매칭 진단을 stderr로 출력.
let arguments = CommandLine.arguments.dropFirst()
let repoRoot = arguments.first { !$0.hasPrefix("--") } ?? "."
let env = ProcessInfo.processInfo.environment
exit(runArchLint(
    repoRoot: repoRoot,
    isGitHubActions: env["GITHUB_ACTIONS"] == "true",
    debug: env["ARCHLINT_DEBUG"] == "1",
    writeTestSpecs: arguments.contains("--write-test-specs")
))
