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
        infoPlist: InfoPlist
    ) -> [Target] {
        
        var allTargets: [Target] = []
        let dependencies = internalDependencies + externalDependencies
        
        // Sources
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
                dependencies: dependencies
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
                    infoPlist: infoPlist,
                    sources: ["Demo/**"],
                    resources: [],
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
        demoDependencies: [TargetDependency] = []
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
            testDependencies: [],
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.feature.infoPlist
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
        externalDependencies: [TargetDependency] = []
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
            testDependencies: [],
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.domain.infoPlist
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
        externalDependencies: [TargetDependency] = []
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
            testDependencies: [],
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.data.infoPlist
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
        externalDependencies: [TargetDependency] = []
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
            testDependencies: [],
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.core.infoPlist
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
        demoDependencies: [TargetDependency] = []
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
            testDependencies: [],
            deploymentTarget: env.deploymentTarget,
            infoPlist: ModuleInfoPlist.ui.infoPlist
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
