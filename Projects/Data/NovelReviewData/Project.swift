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
        .module(.core(.logger)),
        .module(.domain(.novelReview)),
        .module(.domain(.base))
    ]
)
