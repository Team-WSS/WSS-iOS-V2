//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/15/25.
//

import ProjectDescription

let project = Project(
    name: "Home",
    targets: [
        .target(
            name: "Home",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.Home",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "Home"
                ]
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "DesignSystem", path: "../../DesignSystem")
            ]
        )
    ]
)
