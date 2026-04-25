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
    name: ModuleType.data(.social).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.domain(.social)),
        .module(.domain(.base)),
        .module(.data(.base))
    ]
)
