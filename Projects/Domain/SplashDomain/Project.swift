//
//  Project.swift
//  AppManifests
//
//  Created by YunhakLee on 8/31/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.splash).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))]
)
