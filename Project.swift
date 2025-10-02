import ProjectDescription

let project = Project(
    name: "WSS-iOS-V2",
    targets: [
        .target(
            name: "WSS-iOS-V2",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.WSS-iOS-V2",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["WSS-iOS-V2/Sources/**"],
            resources: ["WSS-iOS-V2/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "WSS-iOS-V2Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.WSS-iOS-V2Tests",
            infoPlist: .default,
            sources: ["WSS-iOS-V2/Tests/**"],
            resources: [],
            dependencies: [.target(name: "WSS-iOS-V2")]
        ),
    ]
)
