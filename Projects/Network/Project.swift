//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/15/25.
//

import ProjectDescription

let project = Project(
    name: "Network",
    targets: [
        .target(
            name: "Network",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.Network",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "Network"
                ]
            ),
            sources: ["Sources/**"],
            dependencies: [
            ]
        )
    ]
)
