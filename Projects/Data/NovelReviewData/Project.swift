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
    name: ModuleType.data(.novelReview).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [
        .module(.core(.networking)),
        .module(.data(.base)),
        .module(.domain(.novelReview)),
        .module(.domain(.base))
    ]
)
