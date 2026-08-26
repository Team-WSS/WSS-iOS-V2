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

    // MARK: - ⑧ vm-naming-reverse (error)

    @Test("⑧ @Observable인데 이름이 *ViewModel이 아니면 error")
    func vmNamingReverseCatchesMisnamed() {
        let src = """
        import Observation
        @Observable
        final class SampleStore { private(set) var state = 0 }
        """
        let vs = lint(source: src, path: featurePath, rules: [VMNamingReverseRule()])
        #expect(vs.count == 1)
        #expect(vs.first?.ruleID == "vm-naming-reverse")
        #expect(vs.first?.severity == .error)
    }

    @Test("⑧ @Observable *ViewModel과 @Observable 없는 클래스는 통과")
    func vmNamingReversePasses() {
        let src = """
        @Observable
        final class SampleViewModel { private(set) var state = 0 }
        final class SampleHelper {}
        """
        #expect(lint(source: src, path: featurePath, rules: [VMNamingReverseRule()]).isEmpty)
    }

    // MARK: - ⑨/⑩ protocol-naming (error) — protocol만 검사, co-locate 타입은 무시

    @Test("⑨ UseCase 폴더의 protocol이 *UseCase가 아니면 error, 곁 타입은 무시")
    func usecaseNamingChecksProtocolsOnly() {
        let rule = ProtocolNamingRule(
            id: "usecase-naming", layerPathFragment: "/Projects/Domain/",
            folderName: "UseCase", requiredSuffix: "UseCase"
        )
        let path = "/Projects/Domain/SampleDomain/Sources/UseCase/LoadSample.swift"
        let src = """
        public protocol LoadSample {}   // 위반: UseCase로 안 끝남
        public struct SampleData {}     // protocol 아님 → 무시(HomeData 같은 반환 Entity)
        """
        let vs = lint(source: src, path: path, rules: [rule])
        #expect(vs.count == 1)
        #expect(vs.first?.ruleID == "usecase-naming")
        #expect(vs.first?.severity == .error)
    }

    @Test("⑨ *UseCase protocol과 그 Default 구현은 통과")
    func usecaseNamingPasses() {
        let rule = ProtocolNamingRule(
            id: "usecase-naming", layerPathFragment: "/Projects/Domain/",
            folderName: "UseCase", requiredSuffix: "UseCase"
        )
        let path = "/Projects/Domain/SampleDomain/Sources/UseCase/LoadSampleUseCase.swift"
        let src = """
        public protocol LoadSampleUseCase {}
        public final class DefaultLoadSampleUseCase: LoadSampleUseCase {}
        """
        #expect(lint(source: src, path: path, rules: [rule]).isEmpty)
    }

    @Test("⑩ Repository 폴더의 protocol이 *Repository가 아니면 error, 곁 enum은 무시")
    func repositoryNamingChecksProtocolsOnly() {
        let rule = ProtocolNamingRule(
            id: "repository-naming", layerPathFragment: "/Projects/Domain/",
            folderName: "Repository", requiredSuffix: "Repository"
        )
        let path = "/Projects/Domain/SampleDomain/Sources/Repository/SampleStore.swift"
        let src = """
        public protocol SampleStore {}          // 위반
        public enum SampleError: Error {}       // protocol 아님 → 무시(AuthError·ProfileTarget 류)
        """
        let vs = lint(source: src, path: path, rules: [rule])
        #expect(vs.count == 1)
        #expect(vs.first?.ruleID == "repository-naming")
        #expect(vs.first?.severity == .error)
    }

    @Test("⑨/⑩ 중첩·기능그룹 폴더와 소문자 Usecase도 스코프에 든다(평평한 폴더만 보지 않는다)")
    func protocolNamingCoversNestedAndLowercaseFolders() {
        let ucRule = ProtocolNamingRule(
            id: "usecase-naming", layerPathFragment: "/Projects/Domain/",
            folderName: "UseCase", requiredSuffix: "UseCase"
        )
        // 기능그룹 하위 폴더의 오명명 protocol → 잡아야 한다(예: SettingDomain/AppUpdate/UseCase).
        let nested = "/Projects/Domain/SettingDomain/Sources/AppUpdate/UseCase/CheckUpdate.swift"
        #expect(lint(source: "public protocol CheckUpdate {}", path: nested, rules: [ucRule]).count == 1)
        // 소문자 `Usecase/` 폴더도 스코프(RecommendationDomain·BaseDomain).
        let lower = "/Projects/Domain/RecommendationDomain/Sources/Usecase/LoadHome.swift"
        #expect(lint(source: "public protocol LoadHome {}", path: lower, rules: [ucRule]).count == 1)
        // 올바른 이름은 통과.
        #expect(lint(source: "public protocol CheckUpdateUseCase {}", path: nested, rules: [ucRule]).isEmpty)

        let repoRule = ProtocolNamingRule(
            id: "repository-naming", layerPathFragment: "/Projects/Domain/",
            folderName: "Repository", requiredSuffix: "Repository"
        )
        let nestedRepo = "/Projects/Domain/NotificationDomain/Sources/Push/Repository/PushSetting.swift"
        #expect(lint(source: "public protocol PushSetting {}", path: nestedRepo, rules: [repoRule]).count == 1)
    }

    // MARK: - ⑪ factory-existence (module rule, error)

    @Test("⑪ public *DataFactory가 있으면 통과")
    func factoryExistencePasses() {
        let sources = [
            (path: "/Projects/Data/SampleData/Sources/Factory/SampleDataFactory.swift",
             source: "public enum SampleDataFactory {}"),
            (path: "/Projects/Data/SampleData/Sources/Repository/DefaultSampleRepository.swift",
             source: "struct DefaultSampleRepository {}")
        ]
        #expect(lintModule(sources: sources, moduleName: "SampleData", rule: FactoryExistenceRule()).isEmpty)
    }

    @Test("⑪ public *DataFactory가 없으면 error (internal factory는 존재 인정 안 됨)")
    func factoryExistenceCatchesMissing() {
        let sources = [
            (path: "/Projects/Data/SampleData/Sources/Repository/DefaultSampleRepository.swift",
             source: "struct DefaultSampleRepository {}"),
            (path: "/Projects/Data/SampleData/Sources/Factory/SampleDataFactory.swift",
             source: "enum SampleDataFactory {}")   // public 아님
        ]
        let vs = lintModule(sources: sources, moduleName: "SampleData", rule: FactoryExistenceRule())
        #expect(vs.count == 1)
        #expect(vs.first?.ruleID == "factory-existence")
        #expect(vs.first?.severity == .error)
    }

    @Test("⑪ BaseData와 비-Data 모듈은 Factory 없어도 통과(스코프 밖)")
    func factoryExistenceSkipsBaseAndNonData() {
        let baseSources = [(
            path: "/Projects/Data/BaseData/Sources/Storage/AppStorage.swift",
            source: "public struct AppStorage {}"
        )]
        #expect(lintModule(sources: baseSources, moduleName: "BaseData", rule: FactoryExistenceRule()).isEmpty)

        let domainSources = [(
            path: "/Projects/Domain/SampleDomain/Sources/UseCase/SampleUseCase.swift",
            source: "public protocol SampleUseCase {}"
        )]
        #expect(lintModule(sources: domainSources, moduleName: "SampleDomain", rule: FactoryExistenceRule()).isEmpty)
    }

    // MARK: - ⑫ factory-exclusivity (module rule, error)

    @Test("⑫ Factory만 public이고 나머지가 internal이면 통과")
    func factoryExclusivityPasses() {
        let sources = [
            (path: "/Projects/Data/SampleData/Sources/Factory/SampleDataFactory.swift",
             source: "public enum SampleDataFactory {}"),
            (path: "/Projects/Data/SampleData/Sources/Repository/DefaultSampleRepository.swift",
             source: "struct DefaultSampleRepository {}"),
            (path: "/Projects/Data/SampleData/Sources/DTO/SampleResponse.swift",
             source: "struct SampleResponse: Decodable {}")
        ]
        #expect(lintModule(sources: sources, moduleName: "SampleData", rule: FactoryExclusivityRule()).isEmpty)
    }

    @Test("⑫ Factory 외 public 타입이 있으면 error (타입별로 1건씩)")
    func factoryExclusivityCatchesPublicTypes() {
        let sources = [
            (path: "/Projects/Data/SampleData/Sources/Factory/SampleDataFactory.swift",
             source: "public enum SampleDataFactory {}"),
            (path: "/Projects/Data/SampleData/Sources/Repository/DefaultSampleRepository.swift",
             source: "public struct DefaultSampleRepository {}"),   // 위반
            (path: "/Projects/Data/SampleData/Sources/DTO/SampleResponse.swift",
             source: "public struct SampleResponse: Decodable {}")  // 위반
        ]
        let vs = lintModule(sources: sources, moduleName: "SampleData", rule: FactoryExclusivityRule())
        #expect(vs.count == 2)
        #expect(vs.allSatisfy { $0.ruleID == "factory-exclusivity" && $0.severity == .error })
    }

    @Test("⑫ top-level public func/extension도 위반, 타입 내부 멤버 public은 허용")
    func factoryExclusivityCatchesNonTypeAndAllowsMembers() {
        // 타입 내부 멤버의 public은 바깥 타입이 internal이면 무해 → 통과.
        let memberSources = [(
            path: "/Projects/Data/SampleData/Sources/DTO/SampleResponse.swift",
            source: "struct SampleResponse { public let id: Int }"
        )]
        #expect(lintModule(sources: memberSources, moduleName: "SampleData", rule: FactoryExclusivityRule()).isEmpty)

        // 최상위 public func·extension은 위반.
        let topLevelSources = [(
            path: "/Projects/Data/SampleData/Sources/Support/Helpers.swift",
            source: """
            public func makeSomething() {}
            public extension String {}
            """
        )]
        #expect(lintModule(sources: topLevelSources, moduleName: "SampleData", rule: FactoryExclusivityRule()).count == 2)
    }

    @Test("⑫ BaseData와 비-Data 모듈은 스코프 밖(통과)")
    func factoryExclusivitySkipsBaseAndNonData() {
        let baseSources = [(
            path: "/Projects/Data/BaseData/Sources/Storage/AppStorage.swift",
            source: "public struct AppStorage {}"
        )]
        #expect(lintModule(sources: baseSources, moduleName: "BaseData", rule: FactoryExclusivityRule()).isEmpty)

        let domainSources = [(
            path: "/Projects/Domain/SampleDomain/Sources/UseCase/SampleUseCase.swift",
            source: "public protocol SampleUseCase {}"
        )]
        #expect(lintModule(sources: domainSources, moduleName: "SampleDomain", rule: FactoryExclusivityRule()).isEmpty)
    }

    // MARK: - ⑬ feature-exclusivity (module rule, error)

    @Test("⑬ Factory만 public이고 View/VM이 internal이면 통과")
    func featureExclusivityPasses() {
        let sources = [
            (path: "/Projects/Feature/SampleFeature/Sources/Factory/SampleFactory.swift",
             source: "public enum SampleFactory {}"),
            (path: "/Projects/Feature/SampleFeature/Sources/SampleView.swift",
             source: "struct SampleView {}"),
            (path: "/Projects/Feature/SampleFeature/Sources/SampleViewModel.swift",
             source: "final class SampleViewModel {}")
        ]
        #expect(lintModule(sources: sources, moduleName: "SampleFeature", rule: FeatureExclusivityRule()).isEmpty)
    }

    @Test("⑬ Factory 외 public View/VM이 있으면 error (선언별 1건씩)")
    func featureExclusivityCatchesPublicViewAndVM() {
        let sources = [
            (path: "/Projects/Feature/SampleFeature/Sources/Factory/SampleFactory.swift",
             source: "public enum SampleFactory {}"),
            (path: "/Projects/Feature/SampleFeature/Sources/SampleView.swift",
             source: "public struct SampleView {}"),        // 위반
            (path: "/Projects/Feature/SampleFeature/Sources/SampleViewModel.swift",
             source: "public final class SampleViewModel {}")  // 위반
        ]
        let vs = lintModule(sources: sources, moduleName: "SampleFeature", rule: FeatureExclusivityRule())
        #expect(vs.count == 2)
        #expect(vs.allSatisfy { $0.ruleID == "feature-exclusivity" && $0.severity == .error })
    }

    @Test("⑬ Navigation/ 폴더의 public 조립 seam은 허용")
    func featureExclusivityAllowsNavigationSeam() {
        let sources = [
            (path: "/Projects/Feature/SampleFeature/Sources/Factory/SampleFactory.swift",
             source: "public enum SampleFactory {}"),
            (path: "/Projects/Feature/SampleFeature/Sources/Navigation/TabContentBuilder.swift",
             source: "public typealias TabContentBuilder = () -> Void")   // seam — 허용
        ]
        #expect(lintModule(sources: sources, moduleName: "SampleFeature", rule: FeatureExclusivityRule()).isEmpty)
    }

    @Test("⑬ 비-Feature 모듈은 스코프 밖(통과)")
    func featureExclusivitySkipsNonFeature() {
        let dataSources = [(
            path: "/Projects/Data/SampleData/Sources/DTO/SampleResponse.swift",
            source: "public struct SampleResponse {}"
        )]
        #expect(lintModule(sources: dataSources, moduleName: "SampleData", rule: FeatureExclusivityRule()).isEmpty)
    }
}
