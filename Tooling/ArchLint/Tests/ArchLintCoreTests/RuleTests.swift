import Testing
@testable import ArchLintCore

// 규칙별 자체 테스트 — "검사기가 계속 제대로 작동하는지" 자동 검증.
// 각 규칙을 소스 문자열에 돌려 위반을 단언한다(디스크 fixture 불필요).
// path는 스코프 판정에도 쓰이므로 실제와 같은 `/Projects/...` 형태로 준다.

private let featurePath = "/Projects/Feature/Sample/Sources/Sample.swift"
private let servicePath = "/Projects/Data/SampleData/Sources/Service/DefaultSampleService.swift"
private let domainManifest = "/Projects/Domain/SampleDomain/Project.swift"

@Suite("ArchLint 규칙 자체 검증")
struct RuleTests {

    // MARK: - ① vm-contract (네거티브, error)

    @Test("① @Published·ObservableObject 채택을 error로 잡는다")
    func vmContractCatchesBannedTokens() {
        let src = """
        import SwiftUI
        final class SampleViewModel: ObservableObject {
            @Published var count = 0
        }
        """
        let vs = lint(source: src, path: featurePath, rules: [VMContractRule()])
        #expect(vs.count == 2)
        #expect(vs.allSatisfy { $0.ruleID == "vm-contract" && $0.severity == .error })
    }

    @Test("① 주석 속 @Published는 오탐하지 않는다")
    func vmContractIgnoresComments() {
        let src = """
        // 예전엔 @Published 를 썼지만 이제 @Observable
        @Observable
        final class SampleViewModel { private(set) var state = 0 }
        """
        #expect(lint(source: src, path: featurePath, rules: [VMContractRule()]).isEmpty)
    }

    // MARK: - ② vm-observable-state (포지티브, error)

    @Test("② @Observable/state 없는 *ViewModel을 error로 잡는다")
    func vmPositiveCatchesMissing() {
        let src = "final class SampleViewModel { var count = 0 }"
        let vs = lint(source: src, path: featurePath, rules: [VMStateContractRule()])
        #expect(vs.count == 2) // @Observable 누락 + state 누락
        #expect(vs.allSatisfy { $0.ruleID == "vm-observable-state" && $0.severity == .error })
    }

    @Test("② @Observable + private(set) var state면 통과")
    func vmPositivePasses() {
        let src = """
        @Observable
        final class SampleViewModel {
            private(set) var state = State()
            private let dependency = 0
            struct State {}
        }
        """
        #expect(lint(source: src, path: featurePath, rules: [VMStateContractRule()]).isEmpty)
    }

    // MARK: - ③ dependency-direction (error)

    @Test("③ Domain이 Data를 의존하면 error")
    func depDirectionCatchesDomainToData() {
        let src = """
        let project = Project.createDomainModule(
            name: "SampleDomain",
            targets: [.sources],
            internalDependencies: [.module(.domain(.base)), .module(.data(.novel))]
        )
        """
        let vs = lint(source: src, path: domainManifest, rules: [DependencyDirectionRule()])
        #expect(vs.count == 1)
        #expect(vs.first?.ruleID == "dependency-direction")
        #expect(vs.first?.severity == .error)
    }

    @Test("③ ui→domain은 허용된다")
    func depDirectionAllowsUIToDomain() {
        let src = """
        let project = Project.createUIModule(
            name: "SampleUI",
            targets: [.sources],
            internalDependencies: [.module(.domain(.base)), .module(.ui(.designSystem))]
        )
        """
        #expect(lint(source: src, path: "/Projects/UI/SampleUI/Project.swift", rules: [DependencyDirectionRule()]).isEmpty)
    }

    // MARK: - ⑤ service-no-branch (warning)

    @Test("⑤ Service의 if/switch는 warning으로 잡고 guard는 제외한다")
    func serviceBranchCatchesIfSwitchNotGuard() {
        let src = """
        struct DefaultSampleService {
            func f(_ x: Int) -> Int {
                guard x > 0 else { return 0 }
                if x > 1 { return 1 }
                switch x { default: return 2 }
            }
        }
        """
        let vs = lint(source: src, path: servicePath, rules: [ServiceBranchRule()])
        #expect(vs.count == 2) // if + switch (guard 제외)
        #expect(vs.allSatisfy { $0.ruleID == "service-no-branch" && $0.severity == .warning })
    }

    @Test("⑤ 삼항(?:)도 warning으로 잡는다")
    func serviceBranchCatchesTernary() {
        let src = """
        struct DefaultSampleService {
            func f(_ x: Int) -> Int? { x > 0 ? 1 : nil }
        }
        """
        #expect(lint(source: src, path: servicePath, rules: [ServiceBranchRule()]).count == 1)
    }

    // MARK: - ⑦ service-no-query-build (warning)

    @Test("⑦ Service의 XxxQuery() 생성은 warning, client.request·파라미터 타입은 제외")
    func serviceQueryBuildCatchesConstructionOnly() {
        let src = """
        struct DefaultSampleService {
            func f(_ q: FooQuery) async throws {
                _ = FooQuery(a: 1)
                _ = try await client.request(Endpoint.foo(q))
            }
        }
        """
        let vs = lint(source: src, path: servicePath, rules: [ServiceNoQueryBuildRule()])
        #expect(vs.count == 1)
        #expect(vs.first?.ruleID == "service-no-query-build")
        #expect(vs.first?.severity == .warning)
    }
}
