//
//  Package.swift
//  AppManifests
//
//  Created by YunhakLee on 10/21/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createCoreModule(
    name: ModuleType.core(.keychain).name,
    targets: [.sources, .demo, .tests]
)
