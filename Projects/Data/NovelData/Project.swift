//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 3/27/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.novel).name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.data(.base)),
        .module(.domain(.base)),
        .module(.domain(.novel))
    ]
)
