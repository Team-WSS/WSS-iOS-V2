import ProjectDescription

let settings = Settings.settings(
    base: [:],
    configurations: [
        .debug(name: "Debug", xcconfig: "Sources/Config.xcconfig"),
        .release(name: "Release", xcconfig: "Sources/Config.xcconfig"),
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
                        "UIImageName": "",
                        "TEST_TOKEN": "$(TEST_TOKEN)",
                        "BASE_URL": "$(BASE_URL)",
                        "BUCKET_URL": "$(BUCKET_URL)",
                        "KAKAO_APP_KEY": "$(KAKAO_APP_KEY)",
                        "AMPLITUDE_API_KEY": "$(AMPLITUDE_API_KEY)",
                    ],
                    "CFBundleDisplayName": "WSS-iOS-V2"
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: []
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
        ),
    ]
)
