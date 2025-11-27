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
    name: ModuleType.UI.designSystem.name,
    targets: [.sources, .demo, .tests]
)
