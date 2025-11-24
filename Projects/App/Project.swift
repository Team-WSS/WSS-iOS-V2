import ProjectDescription

import ConfigurationPlugin
import EnvironmentPlugin

//MARK: - Configurations

let configurations: [Configuration] = [
    .debug(name: .debug,
           xcconfig: .relativeToXCConfig(type: .dev, name: env.targetName)),
    .release(name: .release,
           xcconfig: .relativeToXCConfig(type: .prod, name: env.targetName))
]

//MARK: - Settings

let settings: Settings =
    .settings(
        base: env.baseSetting,
        configurations: configurations
    )

// MARK: - Targets

let targets: [Target] = [
    .target(
        name: env.targetName,
        destinations: .iOS,
        product: .app,
        productName: env.appName,
        bundleId: "\(env.organizationName).\(env.targetName)",
        infoPlist: .file(path: "Support/Info.plist"),
        sources: ["Sources/**"],
        dependencies: [],
        settings: .settings(
            base: env.baseSetting,
            configurations: configurations),
    ),
    .target(
        name: env.targetTestName,
        destinations: .iOS,
        product: .unitTests,
        bundleId: "\(env.organizationName).\(env.targetName)Tests",
        infoPlist: .file(path: "Support/Info.plist"),
        sources: ["Tests/**"],
        resources: [],
        dependencies: [.target(name: env.targetName)]
    ),
]

//MARK: - Schemes

let schemes: [Scheme] = [
    .scheme(
        name: "\(env.targetName)-DEBUG",
        shared: true,
        buildAction: .buildAction(targets: ["\(env.targetName)"]),
        testAction: TestAction.targets(
            ["\(env.targetTestName)"],
            configuration: .debug,
            options: TestActionOptions.options(
                coverage: true,
                codeCoverageTargets: ["\(env.targetName)"]
            )
        ),
        runAction: .runAction(configuration: .debug),
        archiveAction: .archiveAction(configuration: .debug),
        profileAction: .profileAction(configuration: .debug),
        analyzeAction: .analyzeAction(configuration: .debug)
    ),
    .scheme(
        name: "\(env.targetName)-RELEASE",
        shared: true,
        buildAction: .buildAction(targets: ["\(env.targetName)"]),
        testAction: nil,
        runAction: .runAction(configuration: .release),
        archiveAction: .archiveAction(configuration: .release),
        profileAction: .profileAction(configuration: .release),
        analyzeAction: .analyzeAction(configuration: .release)
    )
]

//MARK: - Project

let project = Project(
    name: env.targetName,
    settings: settings,
    targets: targets,
    schemes: schemes,
    additionalFiles: [
        "../../Config/Config_Shared.xcconfig"
    ]
)
