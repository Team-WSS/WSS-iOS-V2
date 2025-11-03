//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/31/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "RecommendationData",
    dependencies: [
        .project(target: "Networking", path: "../../Core/Networking")
    ],
    hasTests: true,
    hasDemo: true
)
