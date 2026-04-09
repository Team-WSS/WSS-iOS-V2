//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 2/9/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.novel).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))]
)
