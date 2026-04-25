//
//  Project.swift
//  AppManifests
//
//  Created by onesunny2 on 4/24/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.profile).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.domain(.profile)),
        .module(.domain(.base)),
        .module(.data(.base))
    ]
)
