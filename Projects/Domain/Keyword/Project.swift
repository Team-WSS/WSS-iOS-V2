//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 2/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.Domain.keyword.name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [.Domain.BaseDomain]
)
