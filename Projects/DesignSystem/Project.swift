//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/15/25.
//

import ProjectDescription

let project = Project(
    name: "DesignSystem",
    targets: [
        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "io.tuist.DesignSystem",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "DesignSystem",
                    "UIAppFonts": [ "Pretendard-Bold.ttf",
                                    "Pretendard-SemiBold.ttf",
                                    "Pretendard-Medium.ttf",
                                    "Pretendard-Regular.ttf"
                    ]
                ]
            ),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [ ]
        )
    ]
)
