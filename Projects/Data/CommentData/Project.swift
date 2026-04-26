//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 4/9/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.comment).name,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.data(.base)),
        .module(.domain(.base)),
        .module(.domain(.comment))
    ]
)
