//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 11/25/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createUIModule(
    name: ModuleType.ui(.designSystem).name,
    targets: [.sources, .demo]
)
