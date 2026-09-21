//
//  Project.swift
//  AppManifests
//
//  Created by YunhakLee on 8/18/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.collection).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.data(.base)),
        .module(.domain(.base)),
        .module(.domain(.collection))
    ]
)
