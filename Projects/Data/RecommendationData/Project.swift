//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/31/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createModule(
    name: ModuleType.Data.RecommendationData.name,
    product: .framework,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .Core.Networking
    ]
)
