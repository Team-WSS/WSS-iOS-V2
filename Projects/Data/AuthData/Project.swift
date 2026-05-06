//
//  Project.swift
//  AppManifests
//
//  Created by YunhakLee on 11/25/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.data(.auth).name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.core(.keychain)),
        .module(.data(.base)),
        .module(.domain(.base)),
        .module(.domain(.auth))
    ]
)
