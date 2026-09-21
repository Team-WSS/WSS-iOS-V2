//
//  Project.swift
//  AppManifests
//
//  Created by YunhakLee on 8/18/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.collection).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))]
)
