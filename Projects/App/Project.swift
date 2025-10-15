//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/14/25.
//

import ProjectDescription

let project = Project(
    name: "App",
    targets: [
        .target(
            name: "App",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.App",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "App"
                ]
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Core", path: "../Core"),
            ]
        )
    ]
)
