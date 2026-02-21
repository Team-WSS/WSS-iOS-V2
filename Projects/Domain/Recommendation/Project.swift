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
    name: ModuleType.Domain.recommendation.name,
    targets: [.sources, .demo, .tests, .testing],
    internalDependencies: [.Domain.BaseDomain]
)
