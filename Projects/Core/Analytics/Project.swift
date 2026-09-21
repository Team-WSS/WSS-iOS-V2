//
//  Project.swift
//  AppManifests
//
//  Created by Claude on 9/7/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createCoreModule(
    name: ModuleType.core(.analytics).name,
    targets: [.sources]
)
