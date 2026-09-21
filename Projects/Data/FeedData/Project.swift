//
//  Project.swift
//  AppManifests
//
//  Created by WonsunLee on 4/25/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.feed).name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.domain(.base)),
        .module(.domain(.feed)),
        .module(.data(.base))
    ]
)
