import Testing

import MutationCore

private let module = "Projects/Domain/AuthDomain"
private let token = "Projects/Domain/AuthDomain/Sources/Entity/Token.swift"
private let draft = "Projects/Domain/AuthDomain/Sources/Entity/WithdrawalDraft.swift"
private let useCase = "Projects/Domain/AuthDomain/Sources/UseCase/LogoutUseCase.swift"
private let sources = [token, draft, useCase]

@Suite("뮤테이션 도구 — 바뀐 곳만 고르기")
struct ChangedScopeTests {

    @Test("바뀐 소스 파일에만 버그를 심는다")
    func mutatesOnlyChangedSources() {
        // 다른 모듈의 소스 변경도 섞어, 이 모듈 소스만 남는지 본다.
        let changed = [draft, "Projects/Domain/NovelDomain/Sources/Entity/Novel.swift", token]

        let decision = ChangedScope.decide(sourceFiles: sources, changedPaths: changed, moduleDirectory: module)

        #expect(decision == .onlyChanged([token, draft]))
    }

    @Test(
        "모듈의 테스트나 가짜 객체가 바뀌면 바뀐 소스와 상관없이 모듈 전체에 심는다",
        arguments: [
            "Projects/Domain/AuthDomain/Tests/Entity/WithdrawalDraftTests.swift", // 테스트를 약하게 고침
            "Projects/Domain/AuthDomain/Testing/Mock/MockAuthRepository.swift"    // 가짜 객체가 바뀜
        ]
    )
    func mutatesWholeModuleWhenTestsChange(testPath: String) {
        let decision = ChangedScope.decide(sourceFiles: sources, changedPaths: [token, testPath], moduleDirectory: module)

        #expect(decision == .wholeModule)
    }

    @Test("이름 앞부분만 같은 다른 모듈의 테스트가 바뀐 것은 모듈 전체에 심을 이유가 아니다")
    func ignoresTestsOfModuleWithSamePrefix() {
        let changed = [token, "Projects/Domain/AuthDomainX/Tests/SomeTests.swift"]

        let decision = ChangedScope.decide(sourceFiles: sources, changedPaths: changed, moduleDirectory: module)

        #expect(decision == .onlyChanged([token]))
    }

    @Test("모듈 경로 끝에 슬래시가 있어도 테스트 변경을 알아본다")
    func acceptsModuleDirectoryWithTrailingSlash() {
        let changed = ["Projects/Domain/AuthDomain/Tests/Entity/TokenTests.swift"]

        let decision = ChangedScope.decide(sourceFiles: sources, changedPaths: changed, moduleDirectory: module + "/")

        #expect(decision == .wholeModule)
    }

    @Test("지워진 소스 파일은 심을 곳에서 빠진다")
    func skipsDeletedSources() {
        // 지운 파일은 git diff에는 나오지만 지금 Sources에는 없다.
        let deleted = "Projects/Domain/AuthDomain/Sources/Entity/OldToken.swift"

        let decision = ChangedScope.decide(sourceFiles: sources, changedPaths: [deleted, draft], moduleDirectory: module)

        #expect(decision == .onlyChanged([draft]))
    }

    @Test("모듈 소스가 하나도 안 바뀌었으면 심을 곳이 없다")
    func findsNothingWhenNoSourceChanged() {
        // 같은 모듈이어도 Sources 밖(문서·프로젝트 설정)만 바뀐 경우.
        let changed = ["Projects/Domain/AuthDomain/CLAUDE.md", "Projects/Domain/AuthDomain/Project.swift"]

        let decision = ChangedScope.decide(sourceFiles: sources, changedPaths: changed, moduleDirectory: module)

        #expect(decision == .onlyChanged([]))
    }

    @Test("git 출력에서 빈 줄과 앞뒤 공백은 버리고 경로만 남긴다")
    func readsPathsFromGitOutput() {
        let output = "\(token)\n\n  \(draft)  \n"

        let paths = ChangedScope.paths(fromGitOutput: output)

        #expect(paths == [token, draft])
    }
}
