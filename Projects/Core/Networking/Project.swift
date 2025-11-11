//
//  Package.swift
//  AppManifests
//
//  Created by YunhakLee on 10/21/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createModule(
    name: ModuleType.Core.Networking.name,
    product: .framework,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .Core.Logger
    ]
)
