//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/15/25.
//

import ProjectDescription

let project = Project(
    name: "FeatureMain",
    targets: [
        .target(
            name: "FeatureMain",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.FeatureMain",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "FeatureMain"
                ]
            ),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "Home", path: "../Home"),
                .project(target: "Search", path: "../Search")
            ]
        )
    ]
)
