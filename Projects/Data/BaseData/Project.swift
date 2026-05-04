//
//  Project.swift
//  Manifests
//
//  Created by Wonsun Lee on 4/13/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.base).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.domain(.base))
    ]
)
