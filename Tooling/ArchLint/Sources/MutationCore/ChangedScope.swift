import Foundation

/// `--changed-since`로 돌릴 때 어떤 소스에 버그를 심을지 정한다.
/// 경로는 모두 레포 루트 기준 상대 경로(`Projects/Domain/AuthDomain/Sources/…`)다.
public enum ChangedScope {

    public enum Decision: Equatable, Sendable {
        /// 모듈의 테스트나 가짜 객체가 바뀌었다 — 모듈 전체에 버그를 심는다.
        case wholeModule
        /// 바뀐 소스 파일에만 버그를 심는다. 비어 있으면 심을 곳이 없다.
        case onlyChanged([String])
    }

    /// - Parameters:
    ///   - sourceFiles: 지금 모듈 `Sources/`에 있는 Swift 파일.
    ///   - changedPaths: 기준 이후 바뀐 파일(`git diff --name-only`).
    ///   - moduleDirectory: `Projects/<레이어>/<모듈>`.
    ///
    /// 테스트가 바뀌면 소스는 그대로여도 결과가 달라진다 — 테스트를 지우거나 약하게 바꾸면
    /// 손대지 않은 소스의 버그가 새로 살아남는다. 그래서 그때는 바뀐 파일만이 아니라 모듈 전체를 본다.
    public static func decide(sourceFiles: [String], changedPaths: [String], moduleDirectory: String) -> Decision {
        let module = moduleDirectory.hasSuffix("/") ? String(moduleDirectory.dropLast()) : moduleDirectory
        let testsChanged = changedPaths.contains { path in
            path.hasPrefix(module + "/Tests/") || path.hasPrefix(module + "/Testing/")
        }
        if testsChanged { return .wholeModule }
        // 지워진 파일은 지금 소스 목록에 없으니 자연히 빠진다.
        let changed = Set(changedPaths)
        return .onlyChanged(sourceFiles.filter { changed.contains($0) })
    }

    /// `git diff --name-only` 출력을 줄 단위 경로로 나눈다.
    public static func paths(fromGitOutput output: String) -> [String] {
        output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
