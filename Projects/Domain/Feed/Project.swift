//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 1/28/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.Domain.feed.name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [.Domain.BaseDomain]
)
