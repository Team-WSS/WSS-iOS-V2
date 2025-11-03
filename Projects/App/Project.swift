import ProjectDescription

let settings = Settings.settings(
    base: [:],
    configurations: [
        .debug(name: .debug, xcconfig: "Sources/Config/Config_Debug.xcconfig"),
        .release(name: .release, xcconfig: "Sources/Config/Config_Release.xcconfig")
    ]
)

let project = Project(
    name: "App",
    settings: settings,
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.WSS-iOS-V2",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ],
                    "CFBundleDisplayName": "WSS-iOS-V2",
                    "TEST_TOKEN": "$(TEST_TOKEN)",
                    "BASE_URL": "$(BASE_URL)",
                    "BUCKET_URL": "$(BUCKET_URL)",
                    "KAKAO_APP_KEY": "$(KAKAO_APP_KEY)",
                    "AMPLITUDE_API_KEY": "$(AMPLITUDE_API_KEY)"
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [.project(target: "Utilites", path: "../Core/Utilites")]
        ),
        .target(
            name: "AppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.WSS-iOS-V2Tests",
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            dependencies: [.target(name: "App")]
        )
    ],
    schemes: [
        Scheme.scheme(name: "DEBUG-WSS",
                      buildAction: .buildAction(targets: ["App"]),
                      runAction: .runAction(configuration: .debug),
                      archiveAction: .archiveAction(configuration: .debug),
                      profileAction: .profileAction(configuration: .debug),
                      analyzeAction: .analyzeAction(configuration: .debug)
                     ),
        Scheme.scheme(name: "RELEASE-WSS",
                      buildAction: .buildAction(targets: ["App"]),
                      runAction: .runAction(configuration: .release),
                      archiveAction: .archiveAction(configuration: .release),
                      profileAction: .profileAction(configuration: .release),
                      analyzeAction: .analyzeAction(configuration: .release)
                     )
    ]
)
