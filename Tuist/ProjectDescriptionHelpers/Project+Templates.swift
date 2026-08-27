import ProjectDescription

import ConfigurationPlugin
import EnvironmentPlugin
import DependencyPlugin

let configurations: [Configuration] = [
    .debug(name: .debug,
           xcconfig: .relativeToXCConfig(type: .dev, name: env.targetName)),
    .release(name: .release,
             xcconfig: .relativeToXCConfig(type: .prod, name: env.targetName))
]

/// Swift 6 language mode를 **Sources 타깃에만** 얹는 세팅(A4 5단계: strict concurrency 경고 0을 달성한
/// 레이어를 error로 승격 → 회귀를 컴파일 단에서 막는다).
///
/// 코드만 봐선 모르는 배경:
///   - **왜 SWIFT_VERSION=6만**: language mode 6이면 strict concurrency가 `complete`로 강제돼
///     concurrency 위반이 warning이 아니라 **error**가 된다(별도 SWIFT_STRICT_CONCURRENCY 불필요).
///   - **왜 Sources 타깃 한정**(baseSetting/Project 전역이 아니라): #219는 프로덕션(Sources)만 청소했고
///     Demo/Testing/Tests는 아직 strict concurrency 미청소다. 전역에 얹으면 그쪽이 error로 깨진다.
///   - **왜 Feature 제외**: `NovelDetailFeature`의 `TopBounceDisabler` KVO 3건이 남아 있고
///     실기기 스크롤 검증이 필요해 자동으로 못 고친다(→ docs/TODO.md 4번). 정리 후 편입.
let swift6SourcesSettings: SettingsDictionary = [
    "SWIFT_VERSION": "6"
]

extension Project {
    
    //MARK: - 공통으로 Target을 생성하는 함수
    
    private static func makeBaseTargets(
        name: String,
        product: Product,
        targets: Set<TargetType>,
        sources: SourceFilesList,
        resources: ResourceFileElements?,
        internalDependencies: [TargetDependency],
        externalDependencies: [TargetDependency],
        demoDependencies: [TargetDependency],
        testDependencies: [TargetDependency],
        deploymentTarget: DeploymentTargets?,
        infoPlist: InfoPlist,
        demoInfoPlist: InfoPlist? = nil,
        demoEntitlements: Entitlements? = nil,
        sourcesSettings: SettingsDictionary = [:]
    ) -> [Target] {

        var allTargets: [Target] = []
        let dependencies = internalDependencies + externalDependencies

        // Sources
        // sourcesSettings는 Sources 타깃에만 얹는다(Swift 6 승격 등) — Demo/Testing/Tests는 무영향.
        allTargets.append(
            .target(
                name: name,
                destinations: env.destination,
                product: product,
                bundleId: "\(env.organizationName).\(name)",
                deploymentTargets: deploymentTarget,
                infoPlist: infoPlist,
                sources: sources,
                resources: resources,
                dependencies: dependencies,
                settings: sourcesSettings.isEmpty ? nil : .settings(base: sourcesSettings)
            )
        )

        // Demo
        if targets.contains(.demo) {
            var demoDeps = demoDependencies
            demoDeps.append(.target(name: name))

            allTargets.append(
                .target(
                    name: "\(name)Demo",
                    destinations: env.destination,
                    product: .app,
                    bundleId: "\(env.organizationName).\(name)Demo",
                    deploymentTargets: deploymentTarget,
                    infoPlist: demoInfoPlist ?? infoPlist,
                    sources: ["Demo/**"],
                    resources: [],
                    entitlements: demoEntitlements,
                    dependencies: demoDeps
                )
            )
        }
        
        // Testing
        if targets.contains(.testing) {
            allTargets.append(
                .target(
                    name: "\(name)Testing",
                    destinations: env.destination,
                    product: .framework,
                    bundleId: "\(env.organizationName).\(name)Testing",
                    deploymentTargets: deploymentTarget,
                    infoPlist: infoPlist,
                    sources: ["Testing/**"],
                    resources: [],
                    dependencies: [.target(name: name)]
                )
            )
        }

        // Tests
        if targets.contains(.tests) {
            var testDeps = testDependencies
            testDeps.append(.target(name: name))
            if targets.contains(.testing) {
                testDeps.append(.target(name: "\(name)Testing"))
            }

            allTargets.append(
                .target(
                    name: "\(name)Tests",
                    destinations: env.destination,
                    product: .unitTests,
                    bundleId: "\(env.organizationName).\(name)Tests",
                    deploymentTargets: deploymentTarget,
                    infoPlist: infoPlist,
                    sources: ["Tests/**"],
                    resources: [],
                    dependencies: testDeps
                )
            )
        }

        return allTargets
    }
    
    // MARK: - Feature Module
    
    public static func createFeatureModule(
        name: String,
        targets: Set<TargetType>,
        internalDependencies: [TargetDependency] = [],
        externalDependencies: [TargetDependency] = [],
        demoDependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = [],
        demoEntitlements: Entitlements? = nil
    ) -> Project {

        let allTargets = makeBaseTargets(
            name: name,
            product: .framework,
            targets: targets,
            sources: ["Sources/**"],
            resources: nil,
            internalDependencies: internalDependencies,
            externalDependencies: externalDependencies,
            demoDependencies: demoDependencies,
            testDependencies: testDependencies,
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.feature.infoPlist,
            demoInfoPlist: ModuleInfoPlist.featureDemo.infoPlist,
            demoEntitlements: demoEntitlements
        )
        
        return Project(
            name: name,
            organizationName: env.organizationName,
            settings: .settings(
                base: env.baseSetting,
                configurations: configurations,
                defaultSettings: .recommended
            ),
            targets: allTargets
        )
    }

    // MARK: - Domain Module
    
    public static func createDomainModule(
        name: String,
        targets: Set<TargetType>,
        internalDependencies: [TargetDependency] = [],
        externalDependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = []
    ) -> Project {

        let allTargets = makeBaseTargets(
            name: name,
            product: .framework,
            targets: targets,
            sources: ["Sources/**"],
            resources: nil,
            internalDependencies: internalDependencies,
            externalDependencies: externalDependencies,
            demoDependencies: [],
            testDependencies: testDependencies,
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.domain.infoPlist,
            sourcesSettings: swift6SourcesSettings
        )
        
        return Project(
            name: name,
            organizationName: env.organizationName,
            settings: .settings(
                base: env.baseSetting,
                defaultSettings: .recommended
            ),
            targets: allTargets
        )
    }
    
    // MARK: - Data Module
    
    public static func createDataModule(
        name: String,
        targets: Set<TargetType>,
        internalDependencies: [TargetDependency] = [],
        externalDependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = []
    ) -> Project {

        let allTargets = makeBaseTargets(
            name: name,
            product: .framework,
            targets: targets,
            sources: ["Sources/**"],
            resources: nil,
            internalDependencies: internalDependencies,
            externalDependencies: externalDependencies,
            demoDependencies: [],
            testDependencies: testDependencies,
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.data.infoPlist,
            sourcesSettings: swift6SourcesSettings
        )
        
        return Project(
            name: name,
            organizationName: env.organizationName,
            settings: .settings(
                base: env.baseSetting,
                configurations: configurations,
                defaultSettings: .recommended
            ),
            targets: allTargets
        )
    }
    
    // MARK: - Core Module
    
    public static func createCoreModule(
        name: String,
        targets: Set<TargetType>,
        internalDependencies: [TargetDependency] = [],
        externalDependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = []
    ) -> Project {

        let allTargets = makeBaseTargets(
            name: name,
            product: .framework,
            targets: targets,
            sources: ["Sources/**"],
            resources: nil,
            internalDependencies: internalDependencies,
            externalDependencies: externalDependencies,
            demoDependencies: [],
            testDependencies: testDependencies,
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.core.infoPlist,
            sourcesSettings: swift6SourcesSettings
        )
        
        return Project(
            name: name,
            organizationName: env.organizationName,
            settings: .settings(
                base: env.baseSetting,
                configurations: configurations,
                defaultSettings: .recommended
            ),
            targets: allTargets
        )
    }
    
    // MARK: - UI Module
    
    public static func createUIModule(
        name: String,
        targets: Set<TargetType>,
        internalDependencies: [TargetDependency] = [],
        externalDependencies: [TargetDependency] = [],
        demoDependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = []
    ) -> Project {

        let allTargets = makeBaseTargets(
            name: name,
            product: .framework,
            targets: targets,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            internalDependencies: internalDependencies,
            externalDependencies: externalDependencies,
            demoDependencies: demoDependencies,
            testDependencies: testDependencies,
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.ui.infoPlist,
            sourcesSettings: swift6SourcesSettings
        )
        
        return Project(
            name: name,
            organizationName: env.organizationName,
            settings: .settings(
                base: env.baseSetting,
                defaultSettings: .recommended
            ),
            targets: allTargets
        )
    }
}
