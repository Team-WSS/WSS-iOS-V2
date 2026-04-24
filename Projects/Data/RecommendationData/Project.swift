//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 10/31/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.recommendation).name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.data(.base)),
        .module(.domain(.base)),
        .module(.domain(.recommendation))
    ]
)
