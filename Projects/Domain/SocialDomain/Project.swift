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
    name: ModuleType.Domain.social.name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.Domain.BaseDomain]
)
