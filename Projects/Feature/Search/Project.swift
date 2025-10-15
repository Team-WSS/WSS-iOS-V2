//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/15/25.
//

import ProjectDescription

let project = Project(
    name: "Search",
    targets: [
        .target(
            name: "Search",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.Search",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "Search"
                ]
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "DesignSystem", path: "../../DesignSystem")
            ]
        )
    ]
)
