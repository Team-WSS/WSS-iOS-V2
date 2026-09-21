//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 2/18/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.recommendation).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))]
)
