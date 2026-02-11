//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 1/28/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createCoreModule(
    name: ModuleType.Domain.feed.name,
    targets: [.sources, .demo, .tests]
)
