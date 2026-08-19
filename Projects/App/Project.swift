import ProjectDescription

import ConfigurationPlugin
import DependencyPlugin
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
        // Apple 로그인(SignInWithAppleButton) capability. 없으면 인증 시도 시 실패한다.
        entitlements: .file(path: "Support/WSS-iOS.entitlements"),
        // KakaoSDK.initSDK(appKey:) 앱 진입점 초기화 + AuthController.handleOpenUrl용.
        dependencies: [
            .external(name: "KakaoSDKCommon"),
            .external(name: "KakaoSDKAuth"),
            // 온보딩 플로우 조립(App이 유일한 DI 지점) — Feature + Domain(UseCase 타입) + Data(Factory 구현체) + Core.
            .module(.feature(.onboarding)),
            .module(.domain(.base)),
            .module(.domain(.auth)),
            .module(.domain(.setting)),
            .module(.domain(.profile)),
            .module(.data(.base)),
            .module(.data(.auth)),
            .module(.data(.setting)),
            .module(.data(.profile)),
            .module(.core(.networking)),
            .module(.core(.logger)),
            .module(.ui(.designSystem))
        ],
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
