//
//  Package.swift
//  AppManifests
//
//  Created by YunhakLee on 10/21/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.Domain.setting.name,
    targets: [.sources, .demo, .testing, .tests],
    internalDependencies: [.Domain.BaseDomain]
)
