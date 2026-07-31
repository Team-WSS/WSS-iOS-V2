//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 7/20/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.search).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.data(.base)),
        .module(.domain(.base)),
        .module(.domain(.search))
    ]
)
