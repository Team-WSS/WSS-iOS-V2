//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 7/20/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.search).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))]
)
