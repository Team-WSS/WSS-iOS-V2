//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/15/25.
//

import ProjectDescription

let project = Project(
    name: "Core",
    targets: [
        .target(
            name: "Core",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.Core",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:]
                ]
            ),
            sources: ["Sources/**"],
            dependencies: [
            ]
        )
    ]
)
